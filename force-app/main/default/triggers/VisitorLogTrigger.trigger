/**
 * VisitorLogTrigger
 *
 * Thin trigger - all logic lives in VisitorLogTriggerHandler. This keeps
 * the trigger itself bulk-safe by construction and easy to unit test.
 */
trigger VisitorLogTrigger on Visitor_Log__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        VisitorLogTriggerHandler.handleAfterInsert(Trigger.new);
    }
}
