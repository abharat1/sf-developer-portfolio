/**
 * GetTechStackAction
 *
 * Backs the "technologies_overview" subagent. Give it a technology,
 * language, or framework name and it returns which of Anshul's projects
 * used it, framed as an experience summary rather than a raw record dump.
 */
public with sharing class GetTechStackAction {

    public class Request {
        @InvocableVariable(
            label='Technology'
            description='A specific technology, language, or framework to check for in Anshul Bharati experience, e.g. "Apex", "Python", "LWC", "REST API".'
            required=true
        )
        public String technology;
    }

    public class Result {
        @InvocableVariable(label='Experience Summary' description='A natural-language summary of Anshul Bharati experience with the requested technology.')
        public String resultSummary;

        @InvocableVariable(label='Match Count' description='Number of projects that used this technology.')
        public Integer matchCount;
    }

    @InvocableMethod(
        label='Get Tech Stack Experience'
        description='Answers questions about which technologies, languages, or frameworks Anshul Bharati has experience with, and which projects used them. Use when a visitor asks about a specific technology or Anshul Bharati skills in general.'
    )
    public static List<Result> getTechStackExperience(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result r = new Result();
            String term = req.technology == null ? '' : req.technology.trim();

            if (String.isBlank(term)) {
                r.resultSummary = 'Please specify a technology, language, or framework to check.';
                r.matchCount = 0;
                results.add(r);
                continue;
            }

            List<Project__c> matches = PortfolioDataService.queryProjects(term);
            r.matchCount = matches.size();
            r.resultSummary = PortfolioDataService.formatTechSummary(term, matches);
            results.add(r);
        }

        return results;
    }
}
