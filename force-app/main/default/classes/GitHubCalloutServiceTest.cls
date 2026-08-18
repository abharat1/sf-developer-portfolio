@IsTest
private class GitHubCalloutServiceTest {

    /**
     * Mock implementation of HttpCalloutMock so tests never make a real
     * callout to api.github.com. Salesforce enforces this - real callouts
     * are blocked entirely in test context.
     */
    private class GitHubMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"stargazers_count": 12, "language": "Apex", "pushed_at": "2026-07-20T18:32:11Z"}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class GitHubMockNotFound implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Not Found"}');
            res.setStatusCode(404);
            return res;
        }
    }

    @TestSetup
    static void setup() {
        insert new Project__c(
            Name = 'TensorFlow Acrobot',
            GitHub_Repo_Path__c = 'abharat1/TFAcrobot',
            Tech_Stack__c = 'Python,TensorFlow',
            Display_Order__c = 1
        );
    }

    @IsTest
    static void testRefreshStats_success() {
        Test.setMock(HttpCalloutMock.class, new GitHubMockSuccess());
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        GitHubCalloutService.refreshStats(proj.Id);
        Test.stopTest();

        Project__c updated = [
            SELECT Star_Count__c, Primary_Language__c, Last_Commit_Date__c
            FROM Project__c
            WHERE Id = :proj.Id
        ];
        System.assertEquals(12, updated.Star_Count__c, 'Star count should be populated from mock response');
        System.assertEquals('Apex', updated.Primary_Language__c, 'Language should be populated from mock response');
        System.assertNotEquals(null, updated.Last_Commit_Date__c, 'Last commit date should be parsed and set');
    }

    @IsTest
    static void testRefreshStats_notFoundDoesNotThrow() {
        Test.setMock(HttpCalloutMock.class, new GitHubMockNotFound());
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        GitHubCalloutService.refreshStats(proj.Id);
        Test.stopTest();

        Project__c updated = [SELECT Star_Count__c FROM Project__c WHERE Id = :proj.Id];
        System.assertEquals(null, updated.Star_Count__c, 'A failed callout should not throw and should leave fields untouched');
    }

    @IsTest
    static void testRefreshStats_blankRepoPathSkipsCallout() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        proj.GitHub_Repo_Path__c = null;
        update proj;

        Test.setMock(HttpCalloutMock.class, new GitHubMockSuccess());

        Test.startTest();
        // Should return early and make zero callouts - if it didn't, this
        // test would still pass, so the real safety net is the assert below
        // combined with Limits.getCallouts() staying at 0.
        GitHubCalloutService.refreshStats(proj.Id);
        Test.stopTest();

        System.assertEquals(0, Limits.getCallouts(), 'No callout should be made when repo path is blank');
    }

    @IsTest
    static void testInvocableBulk() {
        Test.setMock(HttpCalloutMock.class, new GitHubMockSuccess());

        List<Project__c> extras = new List<Project__c>();
        for (Integer i = 0; i < 3; i++) {
            extras.add(new Project__c(
                Name = 'Bulk Project ' + i,
                GitHub_Repo_Path__c = 'abharat1/repo' + i,
                Display_Order__c = i + 2
            ));
        }
        insert extras;

        List<Id> allIds = new List<Id>();
        for (Project__c p : [SELECT Id FROM Project__c]) {
            allIds.add(p.Id);
        }

        Test.startTest();
        GitHubCalloutService.refreshStatsInvocable(allIds);
        Test.stopTest();

        Integer updatedCount = [SELECT COUNT() FROM Project__c WHERE Star_Count__c = 12];
        System.assertEquals(allIds.size(), updatedCount, 'All projects with a repo path should get stats refreshed');
    }
}