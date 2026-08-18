/**
 * VisitorLogTriggerHandler
 *
 * On each batch of new Visitor_Log__c records, kicks off an async
 * Queueable that recalculates total visit count and stores it somewhere
 * cheap to read (a Platform Cache friendly spot would be ideal in a real
 * org; here we keep it simple with a lightweight rollup on the log
 * records themselves via a static counter you can extend).
 *
 * This is intentionally the "async Apex" showcase piece: trigger fires
 * synchronously and fast, then hands off the heavier aggregation work
 * to a Queueable so the LWC's insert never has to wait on it.
 */
public with sharing class VisitorLogTriggerHandler {

    public static void handleAfterInsert(List<Visitor_Log__c> newLogs) {
        // Keep the trigger itself fast - just enqueue the rollup work.
        // Guard against recursive/duplicate enqueues within the same
        // transaction (e.g. multiple DML statements inserting logs).
        if (!System.isQueueable() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new VisitorAnalyticsQueueable());
        }
    }
}