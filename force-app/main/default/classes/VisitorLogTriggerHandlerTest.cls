@IsTest
private class VisitorLogTriggerHandlerTest {

    @IsTest
    static void testTriggerEnqueuesAnalyticsJob() {
        Test.startTest();
        insert new Visitor_Log__c(
            Page_Viewed__c = 'Home',
            Visited_Date__c = Datetime.now(),
            Session_Id__c = 'test-session-1'
        );
        // AsyncApexJob only actually runs when Test.stopTest() flushes the queue
        Test.stopTest();

        Integer completedJobs = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'VisitorAnalyticsQueueable'
            AND Status = 'Completed'
        ];
        System.assertEquals(1, completedJobs, 'Queueable job should have run and completed after Test.stopTest()');
    }

    @IsTest
    static void testBulkInsertEnqueuesJobOnce() {
        List<Visitor_Log__c> logs = new List<Visitor_Log__c>();
        for (Integer i = 0; i < 50; i++) {
            logs.add(new Visitor_Log__c(
                Page_Viewed__c = 'Home',
                Visited_Date__c = Datetime.now(),
                Session_Id__c = 'bulk-session-' + i
            ));
        }

        Test.startTest();
        insert logs;
        Test.stopTest();

        // Even with 50 records in one DML, the handler should only enqueue
        // a single Queueable for this transaction, not one per record.
        Integer jobCount = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'VisitorAnalyticsQueueable'
        ];
        System.assertEquals(1, jobCount, 'Bulk insert of 50 records should enqueue exactly one analytics job');
    }
}