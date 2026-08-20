@IsTest
private class PortfolioAgentActionsTest {

    @TestSetup
    static void setup() {
        insert new List<Project__c>{
            new Project__c(
                Name = 'Salesforce Developer Portfolio Platform',
                Tech_Stack__c = 'Apex,LWC,Experience Cloud,REST API',
                Description__c = 'A Salesforce-native developer portfolio with Apex triggers and async processing.',
                GitHub_URL__c = 'https://github.com/abharat1/sf-developer-portfolio',
                Live_Demo_URL__c = 'https://resilient-bear-ltto5c-dev-ed.trailblaze.my.site.com/',
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
            ),
            new Project__c(
                Name = 'Pet Shelter Portal',
                Tech_Stack__c = 'Visualforce,Experience Cloud',
                Description__c = 'An adoption workflow integrated with an Experience Cloud portal.',
                GitHub_URL__c = null, // deliberately no GitHub link, to test repo-list filtering
                Display_Order__c = 4
            )
        };
    }

    // ---- PortfolioDataService ----

    @IsTest
    static void testQueryProjectsBlankReturnsAll() {
        List<Project__c> all = PortfolioDataService.queryProjects('');
        System.assertEquals(4, all.size(), 'Blank search term should return every project');
    }

    @IsTest
    static void testQueryProjectsFiltersByTechStack() {
        List<Project__c> matches = PortfolioDataService.queryProjects('Python');
        System.assertEquals(1, matches.size(), 'Should match only the TensorFlow Acrobot project');
        System.assertEquals('TensorFlow Acrobot', matches[0].Name);
    }

    // ---- GetProjectDetailsAction ----

    @IsTest
    static void testGetProjectDetails_specificProject() {
        GetProjectDetailsAction.Request req = new GetProjectDetailsAction.Request();
        req.projectName = 'Portfolio Platform';

        List<GetProjectDetailsAction.Result> results = GetProjectDetailsAction.getProjectDetails(
            new List<GetProjectDetailsAction.Request>{ req }
        );

        System.assertEquals(1, results[0].matchCount);
        System.assert(results[0].resultSummary.contains('Salesforce Developer Portfolio Platform'));
        System.assert(results[0].resultSummary.contains('Live demo:'), 'Should surface the live demo link when present');
    }

    @IsTest
    static void testGetProjectDetails_blankReturnsOverview() {
        GetProjectDetailsAction.Request req = new GetProjectDetailsAction.Request();
        req.projectName = null;

        List<GetProjectDetailsAction.Result> results = GetProjectDetailsAction.getProjectDetails(
            new List<GetProjectDetailsAction.Request>{ req }
        );

        System.assertEquals(4, results[0].matchCount, 'Blank input should return an overview of all projects');
    }

    // ---- GetTechStackAction ----

    @IsTest
    static void testGetTechStack_match() {
        GetTechStackAction.Request req = new GetTechStackAction.Request();
        req.technology = 'REST API';

        List<GetTechStackAction.Result> results = GetTechStackAction.getTechStackExperience(
            new List<GetTechStackAction.Request>{ req }
        );

        System.assertEquals(2, results[0].matchCount, 'Two projects list REST API in their tech stack');
        System.assert(results[0].resultSummary.contains('Anshul has experience with REST API'));
    }

    @IsTest
    static void testGetTechStack_blankPromptsForInput() {
        GetTechStackAction.Request req = new GetTechStackAction.Request();
        req.technology = '   ';

        List<GetTechStackAction.Result> results = GetTechStackAction.getTechStackExperience(
            new List<GetTechStackAction.Request>{ req }
        );

        System.assertEquals(0, results[0].matchCount);
        System.assert(results[0].resultSummary.contains('specify a technology'));
    }

    // ---- GetGitHubReposAction ----

    @IsTest
    static void testGetGitHubRepos_allExcludesProjectsWithoutLinks() {
        GetGitHubReposAction.Request req = new GetGitHubReposAction.Request();
        req.filterKeyword = null;

        List<GetGitHubReposAction.Result> results = GetGitHubReposAction.getGitHubRepos(
            new List<GetGitHubReposAction.Request>{ req }
        );

        // 4 projects total, but Pet Shelter Portal has no GitHub_URL__c
        System.assertEquals(3, results[0].matchCount, 'Only projects with a GitHub link should be counted');
        System.assert(!results[0].resultSummary.contains('Pet Shelter Portal'), 'Project without a repo link should be excluded from the list');
    }

    @IsTest
    static void testGetGitHubRepos_filtered() {
        GetGitHubReposAction.Request req = new GetGitHubReposAction.Request();
        req.filterKeyword = 'Java';

        List<GetGitHubReposAction.Result> results = GetGitHubReposAction.getGitHubRepos(
            new List<GetGitHubReposAction.Request>{ req }
        );

        System.assertEquals(1, results[0].matchCount);
        System.assert(results[0].resultSummary.contains('wordlookup'));
    }
}
