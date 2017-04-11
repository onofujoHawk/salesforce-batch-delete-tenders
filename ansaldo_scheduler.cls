/**
 * @author f.onofrio@reply.it
 *
 * @date Apr 2017
 *
 * @description Apex schedulator for Batch jobs
 */
global class AnsaldoScheduler implements Schedulable 
{

   	public static String CRON_EXP = '0 0 0 1 * ? *'; //Means at midnight each month.


   	/**
	 * Set the scheduler   	 
   	 */
    global static String scheduleMe() {
        AnsaldoScheduler AenScheduler = new AnsaldoScheduler(); 
        return System.schedule('Delete batch', CRON_EXP, AenScheduler);
    }


    /**
     * Schedulate the Batch
     */
    global void execute(SchedulableContext sc) {
        DeleteArchivedTenders delOffers = new DeleteArchivedTenders();
        ID batchProcessID = Database.executeBatch(delOffers, 50);           
    }


}
