/**
 * @author f.onofrio@reply.it
 *
 * @date Apr 2017
 *
 * @description Batch class for Tender and Attachment deletion
 */
global class RemoveArchivedTendersAndAttachmentsBatch
implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts 
{
    
    String query;
    Integer attachmentRecordCount;
    Integer attachmentRecordFailed;

    public RemoveArchivedTendersAndAttachmentsBatch() {
        System.debug(LoggingLevel.INFO, '**** RemoveArchivedTendersAndAttachmentsBatch.init()');
        this.query = null;
        this.attachmentRecordCount = 0;
        this.attachmentRecordFailed = 0;
    }

    /**
     * Start Batch
     * @param  ctx  Batch context
     * @return     QueryLocator object used by finish method
     */
    global Database.QueryLocator start(Database.BatchableContext ctx) {
        System.debug(LoggingLevel.INFO, '**** RemoveArchivedTendersAndAttachments.start()');
        return Database.getQueryLocator([
            SELECT ID, 
                   ParentId,
                   Name,
                   BodyLength,
                   ContentType 
            FROM Attachment 
            WHERE ParentId IN (SELECT ID 
                               FROM Document_Collection__c 
                               WHERE Tender__r.Archived__c = true
                               AND Uploaded__c = true
                               AND UploadDate__c <= LAST_WEEK)
                               
        ]);
    }

    /**
     * Execute Batch
     * @param  ctx       Batch context var
     * @param  objScope  List of sObjects
     */
    global void execute(Database.BatchableContext ctx, List<sObject> objScope) {
        System.debug(LoggingLevel.INFO, '**** RemoveArchivedTendersAndAttachmentsBatch.execute()');
        List<Attachment> attachs = (List<Attachment>) objScope;
        this.attachmentRecordCount = attachs.size();
        System.debug('Attachment COUNT() = ' + attachmentRecordCount);
        Savepoint sp = Database.setSavepoint();
        try {
            // Unit Test section
            if(Test.isRunningTest() ) {
                System.debug('Test is running');
                List<Tender__c> tenders = [SELECT ID, Name FROM Tender__c LIMIT 10];
                system.debug('Tenders_size = ' + tenders.size());
                if(tenders.size() == 2) {
                    throw (new DmlException() );
                }
            }
            if (attachs != null && !attachs.isEmpty()) {
                System.debug('Going to delete all the attachments.');
                Database.DeleteResult[] attachResults = Database.delete(attachs);
                for (Database.DeleteResult ar : attachResults) 
                {
                    if (ar.isSuccess()) {}  //OK
                    else {  //Handle ERRORS
                        List<Database.Error> errors = ar.getErrors();
                        if (!errors.isEmpty()) {
                            System.debug(LoggingLevel.ERROR, '\nErrors occurred when deleting Attachment records');
                            for (Database.Error err : ar.getErrors()) {
                                System.debug(LoggingLevel.ERROR, err.getStatusCode() + ' ' + err.getMessage());
                                System.debug(LoggingLevel.ERROR, 'On fields = ' + err.getFields());  
                                this.attachmentRecordFailed = attachmentRecordFailed + 1;
                            }   
                        }
                    }
                }
            }            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occurred in the Batch class during record deletion:\n' + e.getMessage() + ' on line ' + e.getLineNumber());
            Database.rollback(sp);
        }
    }
    
    /**
     * Finish Batch
     * @param  ctx  the Batch context
     */
    global void finish(Database.BatchableContext ctx) {
        System.debug('**** RemoveArchivedTendersAndAttachmentsBatch.finish()');
        if (attachmentRecordFailed >= 1) 
            System.debug(LoggingLevel.DEBUG, 'How many deletion query are failed? ' + attachmentRecordFailed + '/' + attachmentRecordCount);
        else 
            System.debug(LoggingLevel.DEBUG, 'Batch process completed SUCCESSFULLY without errors.');
        AsyncApexJob asyncJob = [SELECT ID, 
                                        Status, 
                                        NumberOfErrors, 
                                        JobItemsProcessed, 
                                        TotalJobItems, 
                                        CreatedBy.Email
                                 FROM AsyncApexJob 
                                 WHERE ID = :ctx.getJobId()];
        System.debug(LoggingLevel.DEBUG, '\nAsync JOB =  ' + asyncJob);

    }
    
}
