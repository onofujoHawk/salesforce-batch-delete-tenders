/**
 * @author f.onofrio@reply.it
 *
 * @date Apr 2017
 *
 * @description Apex Batch that delete all the archived offers.
 */ 
global without sharing class DeleteArchivedTenders implements Database.Batchable<sObject>, Database.Stateful 
{
    
    
    global Integer recordsProcessed = 0;

    
    /**
     * Start batch
     */
    global Database.QueryLocator start(Database.BatchableContext ctx) {
        
        //Get each offer with archived true
        String offersQuery = 'SELECT ' + Utils.getObjectFields('Tender__c') + ' '
                           + 'FROM Tender__c '
                           + 'WHERE IsDeleted = false '
                           + 'AND Archived__c = true ';
        
        return Database.getQueryLocator(offersQuery);
    }

    
    /**
     * Execute batch
     */ 
     global void execute(Database.BatchableContext ctx, List<Tender__c> scope) {
        
        //Process each batch of record
        List<Tender__c> batchOffers = new List<Tender__c>();
        for (Tender__c offer : scope) {
            if (offer.Archived__c == true) 
            {
                offer.RecordTypeId = RecordTypeUtils.getInstance().getRecordType('Tender__c', 'RT_Cancel');
                offer.Tender_Stage__c = 'Tender Cancelled';
                RecursiveTriggerHelper.setAlreadyFired();
                batchOffers.add(offer);
                recordsProcessed = recordsProcessed + 1;
            }
        }
        
        update batchOffers;
     }
     
     
     /**
      * Finish batch
      */ 
      global void finish(Database.BatchableContext ctx) {
          
          System.debug(LoggingLevel.DEBUG, recordsProcessed + ' records processed');
          
          AsyncApexJob asyncJob = [SELECT ID, 
                                          Status, 
                                          NumberOfErrors, 
                                          JobItemsProcessed, 
                                          TotalJobItems, 
                                          CreatedBy.Email
                                   FROM AsyncApexJob 
                                   WHERE ID = :ctx.getJobId()];
          
          //Call some utility to send email
          EmailUtils.sendMessage(a, recordsProcessed);
      }
      
        /** Method returning the string with all the fields of the object passed as parameter
         *   param1: name of the object
         *   @return: Stringof the object's fields separated with comma
         */
        public static String getObjectFields(String objName) {

            String fieldnames = '';

            Map < String, Schema.SObjectType > m = Schema.getGlobalDescribe();
            Schema.SObjectType s = m.get(objName);
            Schema.DescribeSObjectResult r = s.getDescribe();

            //get fields
            Map < String, Schema.SObjectField > fields = r.fields.getMap();
            for (string field : fields.keySet()) {
                if (fieldnames == '') {
                    fieldnames = field;
                } else {
                    fieldnames += ',' + field;
                }
            }

            return fieldnames;

        }

    

}
