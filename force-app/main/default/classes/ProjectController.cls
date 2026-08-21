/**
 * ProjectController
 *
 * Server-side controller backing the projectGallery LWC. Keeps the
 * component's Apex surface small and deliberate: one cacheable read,
 * one imperative "refresh from GitHub" action, one method to log a visit.
 *
 * Deliberately "without sharing": this data is meant to be fully public
 * (it powers an Experience Cloud guest-facing portfolio), and Salesforce
 * no longer allows creating new Guest User Sharing Rules through the UI
 * for orgs created after Spring '21. "without sharing" bypasses row-level
 * sharing only - it does NOT bypass field-level security (still enforced
 * via WITH SECURITY_ENFORCED below) or object CRUD permissions, which are
 * controlled separately through the Guest User Profile's object settings.
 */
public without sharing class ProjectController {

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects() {
        return [
            SELECT Id, Name, Description__c, Tech_Stack__c, GitHub_URL__c,
                   Live_Demo_URL__c, Star_Count__c, Last_Commit_Date__c,
                   Primary_Language__c
            FROM Project__c
            WITH SECURITY_ENFORCED
            ORDER BY Display_Order__c ASC NULLS LAST
        ];
    }

    /**
     * Lets the LWC know whether the current visitor is an anonymous Guest
     * User, so it can hide admin-only actions (like Refresh Stats) from
     * the public site instead of showing a button that just errors out.
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserGuest() {
        return UserInfo.getUserType() == 'Guest';
    }

    /**
     * Called from a "Refresh Stats" button on the project card. Not
     * cacheable since it performs a callout + DML.
     *
     * Explicitly blocked for Guest Users even though the LWC hides the
     * button for them - this is defense in depth. Without this check, a
     * public Experience Cloud site would let anyone on the internet
     * trigger GitHub API callouts and DML on your org just by calling
     * this Apex method directly (bypassing the UI entirely), which could
     * burn through your GitHub rate limit or hit governor limits.
     */
    @AuraEnabled
    public static void refreshProjectStats(Id projectId) {
        if (UserInfo.getUserType() == 'Guest') {
            throw new AuraHandledException('This action is not available on the public site.');
        }
        try {
            GitHubCalloutService.refreshStats(projectId);
        } catch (Exception e) {
            throw new AuraHandledException('Unable to refresh GitHub stats: ' + e.getMessage());
        }
    }

    /**
     * Logs a page view. Called once when the portfolio component loads.
     * Deliberately a simple insert here - the trigger on Visitor_Log__c
     * (see VisitorLogTrigger) is what enriches/rolls this up, so this
     * method stays a thin, fast write.
     */
    @AuraEnabled
    public static Integer logVisitAndGetCount(String pageViewed, String sessionId) {
        Visitor_Log__c log = new Visitor_Log__c(
            Page_Viewed__c = pageViewed,
            Visited_Date__c = Datetime.now(),
            Session_Id__c = sessionId
        );
        insert log;

        return [SELECT COUNT() FROM Visitor_Log__c];
    }
}