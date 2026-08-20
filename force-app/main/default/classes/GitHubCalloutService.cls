/**
 * GitHubCalloutService
 *
 * Calls the public GitHub REST API to pull live repo stats (stars, last commit
 * date, primary language) for a given Project__c record and writes them back
 * onto the record.
 *
 * Setup required before this will work in an org:
 *  1. Create a Named Credential called "GitHub_API" pointing to https://api.github.com
 *     (GitHub's public repo endpoints don't require auth for read-only calls on
 *     public repos, so a simple Named Credential with no auth, or a Named
 *     Credential + a personal access token if you want higher rate limits, both work.)
 *  2. Add api.github.com to Remote Site Settings if you are not using a Named
 *     Credential (Named Credential is the recommended, more secure route).
 */
public with sharing class GitHubCalloutService {

    private static final String NAMED_CREDENTIAL = 'callout:GitHub_API';

    /**
     * Invocable so it can be called from Flow, and also callable directly
     * from ProjectController for the LWC "refresh stats" button.
     *
     * Bulk-safe by design: Salesforce disallows a callout after uncommitted
     * DML in the same transaction, so this method deliberately runs ALL
     * callouts first and defers every update into a single bulk DML at the
     * end - never interleaving "callout, then save, then callout again."
     */
    @InvocableMethod(label='Refresh GitHub Stats' description='Pulls live star count, last commit date, and language for a list of Project__c records')
    public static void refreshStatsInvocable(List<Id> projectIds) {
        List<Project__c> projects = [
            SELECT Id, GitHub_Repo_Path__c
            FROM Project__c
            WHERE Id IN :projectIds
            AND GitHub_Repo_Path__c != null
        ];

        List<Project__c> toUpdate = new List<Project__c>();

        for (Project__c proj : projects) {
            GitHubRepoStats stats = fetchRepoStats(proj.GitHub_Repo_Path__c);
            if (stats == null) {
                continue;
            }

            proj.Star_Count__c = stats.stargazers_count;
            proj.Primary_Language__c = stats.language;
            if (String.isNotBlank(stats.pushed_at)) {
                proj.Last_Commit_Date__c = parseGitHubDate(stats.pushed_at);
            }
            toUpdate.add(proj);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    /**
     * Single-record convenience wrapper for callers (like the LWC "Refresh
     * Stats" button via ProjectController) that only ever need to refresh
     * one record at a time. Safe as a standalone call since there's no
     * prior DML in that transaction to conflict with the callout.
     */
    public static void refreshStats(Id projectId) {
        refreshStatsInvocable(new List<Id>{ projectId });
    }

    /**
     * Performs the actual HTTP callout. Broken out as its own method so
     * the test class can exercise it directly with a mock, and so a
     * Queueable/batch context can call it without touching a record yet.
     */
    public static GitHubRepoStats fetchRepoStats(String ownerRepoPath) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/repos/' + ownerRepoPath);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/vnd.github+json');
        req.setTimeout(10000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            System.debug(LoggingLevel.WARN, 'GitHub callout failed: ' + res.getStatusCode() + ' ' + res.getBody());
            return null;
        }

        return (GitHubRepoStats) JSON.deserialize(res.getBody(), GitHubRepoStats.class);
    }

    private static DateTime parseGitHubDate(String isoDate) {
        // GitHub returns ISO 8601, e.g. 2026-07-20T18:32:11Z
        return (DateTime) JSON.deserialize('"' + isoDate + '"', DateTime.class);
    }

    /**
     * Minimal wrapper matching only the fields we care about from GitHub's
     * repo response payload. Deliberately not a full schema.
     */
    public class GitHubRepoStats {
        public Integer stargazers_count;
        public String language;
        public String pushed_at;
    }
}
