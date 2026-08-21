/**
 * GetProjectDetailsAction
 *
 * Backs the "projects_explorer" subagent. Give it a project name or
 * keyword and it returns full detail (description, tech stack, links,
 * GitHub stats) for matching Project__c records. Leave the input blank
 * to get an overview of all projects.
 */
public with sharing class GetProjectDetailsAction {

    public class Request {
        @InvocableVariable(
            label='Project Name or Keyword'
            description='Name or keyword identifying which project to get details about, e.g. "portfolio platform" or "TensorFlow Acrobot". Leave blank to list all projects.'
        )
        public String projectName;
    }

    public class Result {
        @InvocableVariable(label='Project Details' description='Full details of the matching project(s), ready to read back to the user.')
        public String resultSummary;

        @InvocableVariable(label='Match Count' description='Number of matching projects found.')
        public Integer matchCount;
    }

    @InvocableMethod(
        label='Get Project Details'
        description='Retrieves full details about one or more technical projects belonging to Anshul Bharati, including description, tech stack, GitHub link, and live demo link. Use when a visitor asks about a specific project or what Anshul has built.'
    )
    public static List<Result> getProjectDetails(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            List<Project__c> matches = PortfolioDataService.queryProjects(req.projectName);

            Result r = new Result();
            r.matchCount = matches.size();
            r.resultSummary = PortfolioDataService.formatProjectDetails(matches);
            results.add(r);
        }

        return results;
    }
}