@IsTest
private class ProjectLookupActionTest {

    @TestSetup
    static void setup() {
        insert new List<Project__c>{
            new Project__c(
                Name = 'Salesforce Developer Portfolio Platform',
                Tech_Stack__c = 'Apex,LWC,Experience Cloud,REST API',
                Description__c = 'A Salesforce-native developer portfolio with Apex triggers and async processing.',
                GitHub_URL__c = 'https://github.com/abharat1/sf-developer-portfolio',
                Star_Count__c = 3,
                Display_Order__c = 1
            ),
            new Project__c(
                Name = 'TensorFlow Acrobot',
                Tech_Stack__c = 'Python,TensorFlow,ML',
                Description__c = 'A reinforcement learning agent solving a physics-based acrobot problem.',
                GitHub_URL__c = 'https://github.com/abharat1/TFAcrobot',
                Display_Order__c = 2
            ),
            new Project__c(
                Name = 'Word Lookup REST API',
                Tech_Stack__c = 'Java,Spring Boot,REST API',
                Description__c = 'A REST API for managing words and related words.',
                GitHub_URL__c = 'https://github.com/abharat1/wordlookup',
                Display_Order__c = 3
            )
        };
    }

    @IsTest
    static void testLookupByTechStackMatch() {
        ProjectLookupAction.LookupRequest req = new ProjectLookupAction.LookupRequest();
        req.searchTerm = 'Apex';

        Test.startTest();
        List<ProjectLookupAction.LookupResult> results = ProjectLookupAction.lookupProjects(
            new List<ProjectLookupAction.LookupRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result wrapper per request');
        System.assertEquals(1, results[0].matchCount, 'Should match exactly the portfolio platform project');
        System.assert(results[0].resultSummary.contains('Salesforce Developer Portfolio Platform'), 'Summary should mention the matching project name');
    }

    @IsTest
    static void testLookupByNameMatch() {
        ProjectLookupAction.LookupRequest req = new ProjectLookupAction.LookupRequest();
        req.searchTerm = 'Word Lookup';

        Test.startTest();
        List<ProjectLookupAction.LookupResult> results = ProjectLookupAction.lookupProjects(
            new List<ProjectLookupAction.LookupRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].matchCount, 'Should match via project Name');
        System.assert(results[0].resultSummary.contains('Word Lookup REST API'), 'Summary should mention the matching project name');
    }

    @IsTest
    static void testLookupNoMatchesReturnsHelpfulMessage() {
        ProjectLookupAction.LookupRequest req = new ProjectLookupAction.LookupRequest();
        req.searchTerm = 'COBOL';

        Test.startTest();
        List<ProjectLookupAction.LookupResult> results = ProjectLookupAction.lookupProjects(
            new List<ProjectLookupAction.LookupRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(0, results[0].matchCount, 'No project should match an unrelated term');
        System.assert(results[0].resultSummary.contains('No projects matched'), 'Should return a helpful no-match message rather than an empty string');
    }

    @IsTest
    static void testLookupBlankSearchTerm() {
        ProjectLookupAction.LookupRequest req = new ProjectLookupAction.LookupRequest();
        req.searchTerm = '   ';

        Test.startTest();
        List<ProjectLookupAction.LookupResult> results = ProjectLookupAction.lookupProjects(
            new List<ProjectLookupAction.LookupRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(0, results[0].matchCount, 'Blank search term should not match anything');
        System.assert(results[0].resultSummary.contains('provide a technology'), 'Should prompt the user for a real search term');
    }

    @IsTest
    static void testBulkRequests() {
        ProjectLookupAction.LookupRequest req1 = new ProjectLookupAction.LookupRequest();
        req1.searchTerm = 'Python';

        ProjectLookupAction.LookupRequest req2 = new ProjectLookupAction.LookupRequest();
        req2.searchTerm = 'Spring Boot';

        Test.startTest();
        List<ProjectLookupAction.LookupResult> results = ProjectLookupAction.lookupProjects(
            new List<ProjectLookupAction.LookupRequest>{ req1, req2 }
        );
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return one result per request in the batch');
        System.assertEquals(1, results[0].matchCount, 'First request should match TensorFlow Acrobot');
        System.assertEquals(1, results[1].matchCount, 'Second request should match Word Lookup REST API');
    }
}
