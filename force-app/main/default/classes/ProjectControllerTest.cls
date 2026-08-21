@IsTest
private class ProjectControllerTest {

    private class GitHubMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"stargazers_count": 5, "language": "JavaScript", "pushed_at": "2026-06-01T09:00:00Z"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void setup() {
        insert new List<Project__c>{
            new Project__c(Name = 'Portfolio Site', Display_Order__c = 1, GitHub_Repo_Path__c = 'abharat1/sf-portfolio'),
            new Project__c(Name = 'Word Lookup API', Display_Order__c = 2)
        };
    }

    @IsTest
    static void testGetProjectsReturnsOrderedList() {
        Test.startTest();
        List<Project__c> results = ProjectController.getProjects();
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Both seeded projects should be returned');
        System.assertEquals('Portfolio Site', results[0].Name, 'Results should be ordered by Display_Order__c ascending');
    }

    @IsTest
    static void testRefreshProjectStats() {
        Test.setMock(HttpCalloutMock.class, new GitHubMockSuccess());
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Portfolio Site' LIMIT 1];

        Test.startTest();
        ProjectController.refreshProjectStats(proj.Id);
        Test.stopTest();

        Project__c updated = [SELECT Star_Count__c FROM Project__c WHERE Id = :proj.Id];
        System.assertEquals(5, updated.Star_Count__c, 'Star count should reflect mocked GitHub response');
    }

    @IsTest
    static void testLogVisitAndGetCount() {
        Test.startTest();
        Integer countAfterFirst = ProjectController.logVisitAndGetCount('Home', 'session-abc-123');
        Integer countAfterSecond = ProjectController.logVisitAndGetCount('Home', 'session-abc-123');
        Test.stopTest();

        System.assertEquals(1, countAfterFirst, 'First visit should bring total to 1');
        System.assertEquals(2, countAfterSecond, 'Second visit should bring total to 2');
    }
}