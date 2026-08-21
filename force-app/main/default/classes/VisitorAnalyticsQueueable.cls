/**
 * VisitorAnalyticsQueueable
 *
 * Async job that rolls up total visit counts. Kept deliberately simple
 * (a total count + a debug log) so it's easy to extend: a natural next
 * step is writing the aggregate onto a singleton Portfolio_Stats__c
 * record so the LWC can display "X total views" without a live COUNT()
 * query on every page load.
 */
public with sharing class VisitorAnalyticsQueueable implements Queueable {

    public void execute(QueueableContext context) {
        Integer totalVisits = [SELECT COUNT() FROM Visitor_Log__c];
        Integer todaysVisits = [
            SELECT COUNT()
            FROM Visitor_Log__c
            WHERE Visited_Date__c = TODAY
        ];

        System.debug(
            LoggingLevel.INFO,
            'Portfolio analytics rollup - total visits: ' + totalVisits + ', today: ' + todaysVisits
        );

        // Extension point: upsert these numbers onto a Portfolio_Stats__c
        // custom setting/object so the LWC dashboard can read a single
        // cached record instead of running COUNT() queries on every load.
    }
}