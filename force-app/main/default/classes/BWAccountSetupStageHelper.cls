public class BWAccountSetupStageHelper
{
    @AuraEnabled
    public static CommonWrapperClass.BWStepActionOutComeWrapper createWMSChangeFormCase(String underwritingId, String initiatingAccountId)
    {
       CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
       try
       {
           case c = new case(underwriting__c =underwritingId, accountId= initiatingAccountId, recordtypeId=constants.caseRTMap.get('WMS_Change_Form') );
           insert c;

           cw.outCome =true;
           return cw;
       }
       catch(exception e)
       {
           utilityClass.logError(e, 'Exception occured while inserting WMSChange case from Pre WMS Setup screen', null, 'Exception occured while inserting WMS Change case from Pre WMS Setup screen underwritingId: '+underwritingId+' Initiating account id : '+initiatingAccountId);
           cw.outCome =false;
           cw.errorString='method was not found';
           return cw;
       } 
    }
    
    @AuraEnabled
    public static List<case> fetchAllWMSChangeFormCases(String underwritingId)
    {

         List<case> wmsChangeFormCases =[select id, casenumber, recordtype.name, status from case where underwriting__c =: underwritingId and recordtypeId=:constants.caseRTMap.get('WMS_Change_Form') ];
         List<Boarding_Wizard_Step_Result__c> res= [select id,Step_Completed__c from Boarding_Wizard_Step_Result__c where Boarding_Wizard_Screen_Step__r.Step_Title__c='CreateWMSChangeCase' and Underwriting__c=:underwritingId];
         BW_Screen_Step__c stepRecord =[select id from BW_Screen_Step__c where step_Title__c ='CreateWMSChangeCase' and Boarding_Wizard_Screen__r.Name= 'Pre-WMS Setup Review'];
         
         boolean stepCompleted = true;
         
         if(wmsChangeFormCases!=null && wmsChangeFormCases.size() >0)
        {
            stepCompleted =true;
        }
        else
        {
            stepCompleted =false;
        }
        
        if(res!=null && res.size()>0)
        {
            if(res[0].Step_Completed__c != stepCompleted)
            {
                BoardingWizardVFC.upsertStepAnswer(underwritingId, stepRecord.id, null, null, stepCompleted);
            }
        }
        else
        {
            BoardingWizardVFC.upsertStepAnswer(underwritingId, stepRecord.id, null, null, stepCompleted);
        }
         return wmsChangeFormCases;
     
    }
}