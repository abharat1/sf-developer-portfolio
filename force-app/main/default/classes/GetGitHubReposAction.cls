/**
 * GetGitHubReposAction
 *
 * Backs the "github_repos" subagent. Returns a list of Anshul's GitHub
 * repository links, optionally filtered by keyword (project name or
 * technology). Leave the filter blank to list every repo on file.
 */
public with sharing class GetGitHubReposAction {

    public class Request {
        @InvocableVariable(
            label='Filter Keyword'
            description='Optional keyword to filter repositories by project name or technology, e.g. "Python" or "portfolio". Leave blank to list all repositories.'
        )
        public String filterKeyword;
    }

    public class Result {
        @InvocableVariable(label='Repository List' description='A list of matching GitHub repository links, ready to read back to the user.')
        public String resultSummary;

        @InvocableVariable(label='Repo Count' description='Number of repositories returned.')
        public Integer matchCount;
    }

    @InvocableMethod(
        label='Get GitHub Repositories'
        description='Lists public GitHub repositories belonging to Anshul Bharati, with links, optionally filtered by keyword. Use when a visitor asks to see his code, repositories, or GitHub profile.'
    )
    public static List<Result> getGitHubRepos(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            List<Project__c> matches = PortfolioDataService.queryProjects(req.filterKeyword);

            Result r = new Result();
            r.resultSummary = PortfolioDataService.formatRepoList(matches);
            // Count only ones that actually had a GitHub link, since that's
            // what this action is meant to report on.
            Integer withRepo = 0;
            for (Project__c p : matches) {
                if (String.isNotBlank(p.GitHub_URL__c)) {
                    withRepo++;
                }
            }
            r.matchCount = withRepo;
            results.add(r);
        }

        return results;
    }
}