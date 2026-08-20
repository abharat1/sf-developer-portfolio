/**
 * ProjectLookupAction
 *
 * An Agentforce-facing Apex Action. Lets an agent answer natural-language
 * questions like "What Apex or integration projects has Anshul built?" by
 * searching real Project__c records and returning a plain-language summary
 * the agent can read back to the user.
 *
 * To wire this into an agent: Setup -> Agentforce -> Agents -> [your agent]
 * -> Topics -> add a Topic (e.g. "Portfolio Questions") -> Actions ->
 * New Action -> Apex -> select ProjectLookupAction. The @InvocableMethod
 * label/description below is what the agent's planner reads to decide
 * when to call this action, so keep it accurate if you extend it.
 */
public with sharing class ProjectLookupAction {

    public class LookupRequest {
        @InvocableVariable(
            label='Search Term'
            description='A technology, keyword, or topic to search for among the portfolio projects - for example "Apex", "LWC", "REST API", "Python", "machine learning", or a project name.'
            required=true
        )
        public String searchTerm;
    }

    public class LookupResult {
        @InvocableVariable(
            label='Result Summary'
            description='A natural-language summary of matching projects, ready to be read back to the user.'
        )
        public String resultSummary;

        @InvocableVariable(
            label='Match Count'
            description='Number of matching projects found.'
        )
        public Integer matchCount;
    }

    @InvocableMethod(
        label='Look Up Portfolio Projects'
        description='Searches the portfolio projects belonging to Anshul Bharati by technology, keyword, or topic (e.g. Apex, LWC, Python, REST API, machine learning) and returns a natural-language summary of matches, including tech stack, GitHub links, and live GitHub stats where available.'
    )
    public static List<LookupResult> lookupProjects(List<LookupRequest> requests) {
        List<LookupResult> results = new List<LookupResult>();

        for (LookupRequest req : requests) {
            LookupResult result = new LookupResult();
            String term = req.searchTerm == null ? '' : req.searchTerm.trim();

            if (String.isBlank(term)) {
                result.resultSummary = 'Please provide a technology, keyword, or topic to search for.';
                result.matchCount = 0;
                results.add(result);
                continue;
            }

            String likeTerm = '%' + String.escapeSingleQuotes(term) + '%';

            List<Project__c> matches = [
                SELECT Name, Description__c, Tech_Stack__c, GitHub_URL__c,
                       Live_Demo_URL__c, Star_Count__c, Primary_Language__c
                FROM Project__c
                WHERE (Tech_Stack__c LIKE :likeTerm
                   OR Name LIKE :likeTerm)
                WITH SECURITY_ENFORCED
                ORDER BY Display_Order__c ASC NULLS LAST
                LIMIT 5
            ];

            result.matchCount = matches.size();
            result.resultSummary = buildSummary(term, matches);
            results.add(result);
        }

        return results;
    }

    private static String buildSummary(String term, List<Project__c> matches) {
        if (matches.isEmpty()) {
            return 'No projects matched "' + term + '". Anshul\'s portfolio spans Salesforce '
                + '(Apex, LWC, Experience Cloud), Python/TensorFlow, and Java/Spring Boot projects '
                + '- try one of those terms instead.';
        }

        List<String> lines = new List<String>();
        for (Project__c p : matches) {
            String line = p.Name + ': ' + (String.isNotBlank(p.Description__c) ? p.Description__c : 'No description available.');
            if (String.isNotBlank(p.Tech_Stack__c)) {
                line += ' Tech stack: ' + p.Tech_Stack__c + '.';
            }
            if (p.Star_Count__c != null) {
                line += ' GitHub stars: ' + Integer.valueOf(p.Star_Count__c) + '.';
            }
            if (String.isNotBlank(p.GitHub_URL__c)) {
                line += ' GitHub: ' + p.GitHub_URL__c;
            }
            lines.add(line);
        }

        return String.join(lines, '\n\n');
    }
}
