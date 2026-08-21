/**
 * PortfolioDataService
 *
 * Shared query and formatting logic for the three Agentforce actions
 * (GetProjectDetailsAction, GetTechStackAction, GetGitHubReposAction).
 * Kept as a plain (non-invocable) helper class so all three actions stay
 * "thin" - each just adapts a search term into a query, then formats the
 * result for its own subagent's intent, without duplicating SOQL.
 */
public with sharing class PortfolioDataService {

    private static final Integer DEFAULT_LIMIT = 5;

    /**
     * Searches Project__c by tech stack, description, or name. A blank
     * search term returns everything (ordered for display), which lets
     * callers support "show me everything" as well as a filtered search
     * with the same method.
     */
    public static List<Project__c> queryProjects(String searchTerm) {
        String term = searchTerm == null ? '' : searchTerm.trim();

        if (String.isBlank(term)) {
            return [
                SELECT Name, Description__c, Tech_Stack__c, GitHub_URL__c,
                       Live_Demo_URL__c, Star_Count__c, Last_Commit_Date__c,
                       Primary_Language__c
                FROM Project__c
                WITH SECURITY_ENFORCED
                ORDER BY Display_Order__c ASC NULLS LAST
                LIMIT :DEFAULT_LIMIT
            ];
        }

        String likeTerm = '%' + String.escapeSingleQuotes(term) + '%';
        return [
            SELECT Name, Description__c, Tech_Stack__c, GitHub_URL__c,
                   Live_Demo_URL__c, Star_Count__c, Last_Commit_Date__c,
                   Primary_Language__c
            FROM Project__c
            WHERE (Tech_Stack__c LIKE :likeTerm
               OR Name LIKE :likeTerm)
            WITH SECURITY_ENFORCED
            ORDER BY Display_Order__c ASC NULLS LAST
            LIMIT :DEFAULT_LIMIT
        ];
    }

    /** Full detail summary: used by GetProjectDetailsAction. */
    public static String formatProjectDetails(List<Project__c> projects) {
        if (projects.isEmpty()) {
            return 'No matching projects found. Anshul\'s portfolio includes Salesforce, Python/ML, and Java projects - try asking about one of those areas.';
        }

        List<String> lines = new List<String>();
        for (Project__c p : projects) {
            String line = p.Name + ': ' + (String.isNotBlank(p.Description__c) ? p.Description__c : 'No description available.');
            if (String.isNotBlank(p.Tech_Stack__c)) {
                line += ' Tech stack: ' + p.Tech_Stack__c + '.';
            }
            if (p.Star_Count__c != null) {
                line += ' GitHub stars: ' + Integer.valueOf(p.Star_Count__c) + '.';
            }
            if (String.isNotBlank(p.Live_Demo_URL__c)) {
                line += ' Live demo: ' + p.Live_Demo_URL__c;
            }
            if (String.isNotBlank(p.GitHub_URL__c)) {
                line += ' GitHub: ' + p.GitHub_URL__c;
            }
            lines.add(line);
        }
        return String.join(lines, '\n\n');
    }

    /** Technology-focused summary: used by GetTechStackAction. */
    public static String formatTechSummary(String technology, List<Project__c> projects) {
        if (projects.isEmpty()) {
            return 'Anshul doesn\'t have a project specifically tagged with "' + technology
                + '", but his stack spans Apex, LWC, Python, TensorFlow, Java, and Spring Boot - try one of those.';
        }

        List<String> lines = new List<String>();
        lines.add('Anshul has experience with ' + technology + ', demonstrated in:');
        for (Project__c p : projects) {
            String line = '- ' + p.Name;
            if (String.isNotBlank(p.Tech_Stack__c)) {
                line += ' (' + p.Tech_Stack__c + ')';
            }
            if (String.isNotBlank(p.Description__c)) {
                line += ': ' + p.Description__c;
            }
            lines.add(line);
        }
        return String.join(lines, '\n');
    }

    /** Repo-link-focused summary: used by GetGitHubReposAction. */
    public static String formatRepoList(List<Project__c> projects) {
        List<String> lines = new List<String>();
        for (Project__c p : projects) {
            if (String.isBlank(p.GitHub_URL__c)) {
                continue;
            }
            String line = '- ' + p.Name + ': ' + p.GitHub_URL__c;
            if (String.isNotBlank(p.Tech_Stack__c)) {
                line += ' (' + p.Tech_Stack__c + ')';
            }
            if (p.Star_Count__c != null) {
                line += ' - ' + Integer.valueOf(p.Star_Count__c) + ' stars';
            }
            lines.add(line);
        }

        if (lines.isEmpty()) {
            return 'No GitHub repository links are available for that search.';
        }
        return String.join(lines, '\n');
    }
}