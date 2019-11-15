public class BWDocumentCreationStageHelper
{
    ///////////////////////////////
    // Start of Reg Check Screen //
    ///////////////////////////////

        @AuraEnabled
        public static CommonWrapperClass.BWStepActionOutComeWrapper createRegCheckCase(String underwritingId, string initiatingAccountId)
        {
            CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
            case c = new case(Underwriting__c = underwritingId, accountid=initiatingAccountId, recordtypeid =constants.caseRTMap.get('Regulatory_Check'));
            Database.saveResult dsr = Database.insert(c, false);
            
            if(dsr.isSuccess())
            {
                cw.outCome =true;
                cw.resultString='success';
                return cw;
            }
            else
            {
                cw.resultString='Error occured while creating regulatory check case. Error message: '+dsr.getErrors()[0].getMessage();
                utilityClass.createError(dsr.getErrors()[0], 'Error occured while creating regulatory check case from Reg Check screen',null,'Error occured while creating regulatory check case from Reg Check screen -UnderwritingId is '+underwritingId+' Initiating account id is '+initiatingAccountId);
                return cw;
            }
        }
        
        @AuraEnabled
        public static List<case> regulatoryCheckCasesExist(String underwritingId)
        {
            List<case> allRegCheckCasesList = [select id, status, caseNumber, recordtype.Name from case where Underwriting__c =:underwritingId and recordtypeid =:constants.caseRTMap.get('Regulatory_Check') order by createdDate desc ] ;
            List<Boarding_Wizard_Step_Result__c> res= [select id,Step_Completed__c from Boarding_Wizard_Step_Result__c where Boarding_Wizard_Screen_Step__r.Step_Title__c='RegulatoryCheck_Exist' and Underwriting__c=:underwritingId];
            BW_Screen_Step__c stepRecord =[select id from BW_Screen_Step__c where step_Title__c ='RegulatoryCheck_Exist' and Boarding_Wizard_Screen__r.Name= 'Reg Checks'];
            boolean stepCompleted = true;
            system.debug('==== allRegCheckCasesList ==='+allRegCheckCasesList);
            //if there is an regcheck case exist either open or closed.Then it returns true and also inserts the step answer if doesnt exist.
            if(allRegCheckCasesList!=null && allRegCheckCasesList.size() >0)
            {
                stepCompleted =true;
            }
            else
            {
                stepCompleted =false;
            }
            
            system.debug('==== stepCompleted ==='+stepCompleted);
            system.debug('==== res==='+res);
            
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
      
              return allRegCheckCasesList;
        }
        
        @AuraEnabled
        public static String areAllRegCheckCasesClosed(String underwritingId)
        {
            List<case> allRegCheckCasesList = [select id from case where Underwriting__c =:underwritingId and recordtypeid =:constants.caseRTMap.get('Regulatory_Check') ] ;
            List<case> closedRegCheckCasesList = [select id from case where Underwriting__c =:underwritingId and recordtypeid =:constants.caseRTMap.get('Regulatory_Check') and isClosed=true] ;
            List<Boarding_Wizard_Step_Result__c> res= [select id,Step_Completed__c from Boarding_Wizard_Step_Result__c where Boarding_Wizard_Screen_Step__r.Step_Title__c='RegulatoryCheck_Completed' and Underwriting__c=:underwritingId];
            BW_Screen_Step__c stepRecord =[select id from BW_Screen_Step__c where step_Title__c ='RegulatoryCheck_Completed' and Boarding_Wizard_Screen__r.Name= 'Reg Checks'];
            
            System.debug('==== closedRegCheckCasesList ===='+closedRegCheckCasesList);
            System.debug('==== allRegCheckCasesList===='+allRegCheckCasesList);
            boolean stepCompleted =true;
            String result='';
            
            if(allRegCheckCasesList!=null && allRegCheckCasesList.size() >0)
            {
                if(closedRegCheckCasesList!=null && closedRegCheckCasesList.size() >0 && closedRegCheckCasesList.size() == allRegCheckCasesList.size())
                {
                    result = closeRegCheckCondition(underwritingId);
                    
                    System.debug('==== result ==='+result);
                    if(result =='success')
                    {
                        stepCompleted =true;
                    }
                    else
                    {
                         stepCompleted =false;
                    }
                }
                else
                {
                    stepCompleted =false;
                    result='openCaseExist';
                } 
            }
            // if there are no regcheck cases at all 
            else
            {
                stepCompleted =false;
                 result='openCaseExist';
            }
            
             if(res!=null && res.size()>0)
             {
                if(res[0].Step_Completed__c != stepCompleted)
                {
                    BoardingWizardVFC.upsertStepAnswer(underwritingId, stepRecord.id, null, null, stepCompleted);
                   // return stepCompleted;
                }
               /** else
                {
                    return stepCompleted;
                } */
             }
             else
             {
                BoardingWizardVFC.upsertStepAnswer(underwritingId, stepRecord.id, null, null, stepCompleted);
               // return stepCompleted;
             }
             return result;
        }
        
        public static string closeRegCheckCondition(String underwritingId)
        {
            List<condition__c> openConditions =[select id from condition__c where Condition_Status__c!='Closed' and Underwriting__c=:underwritingId and Condition_List_VF__c='Regulatory Check'];
            List<condition__c> closedConditions =[select id from condition__c where Condition_Status__c='Closed' and Underwriting__c=:underwritingId and Condition_List_VF__c='Regulatory Check'];
            
            system.debug('==== openConditions ===='+openConditions);
            system.debug('==== closedConditions===='+closedConditions);
            
            if(openConditions!=null && openConditions.size() >0)
            {
                for(condition__c c: openConditions)
                {
                    c.Condition_Status__c ='Closed';
                }
                
                try
                {
                    update openConditions;
                    return 'success';
                }
                catch(exception e)
                {
                    return e.getMessage();
                }
            }
            else
            {
                /**if(closedConditions==null || (closedConditions!=null && closedConditions.size() ==0))
                {
                    return 'No Regulatory Conditions found.';
                }
                else
                {*/
                    return 'success';
                //}
            }
            
        }
    /////////////////////////////
    // End of Reg Check Screen //
    /////////////////////////////
    
    ////////////////////////////////////
    // Start of Doc Acceptance Screen //
    ////////////////////////////////////
    @AuraEnabled (cacheable=true)
    public static account getInsuranceData(string accountId){
        return [Select Inventory_Coverage_Amount__c,Inventory_Coverage_Expiration_Date__c from account where id =:accountId];
    }

    @AuraEnabled
    public static void setInsuranceData(string accountId, integer insuranceAmount, date insuranceDate){
        account updateInsurance = new account(id=accountId,Inventory_Coverage_Amount__c=insuranceAmount,Inventory_Coverage_Expiration_Date__c=insuranceDate);
        update updateInsurance;
    }
    //////////////////////////////////
    // End of Doc Acceptance Screen //
    //////////////////////////////////
    
    @AuraEnabled
    public static string isDocumentCreationStageComplete(String underwritingId)
    {
        List<condition__c> openPreFundingConditions =[select id from condition__c where Condition_Status__c='Open' and Condition_Type__c LIKE '%Pre-Funding Condition%' and Underwriting__c=:underwritingId];
        String msg ='';
        if(openPreFundingConditions!=null && openPreFundingConditions.size() >0)
        {
           msg='Please close all the prefunding conditions before moving to next stage';
        }
       
        return msg;
    }
    
    //////////////////////////////////////////////
    // Start of Security Search & Filing Screen //
    //////////////////////////////////////////////
    @AuraEnabled
    public static list<CommonWrapperClass.BWSecuritySearchRowWrapper> getSearchFilings(string careNumberId, string underwritingId, string screenName){
        system.debug('careNumberId: '+careNumberId);
        system.debug('underwritingId: '+underwritingId);
        system.debug('screenName: '+screenName);
        id screenId = [Select id from BW_Screen__c where name = :screenName].id;
        set<id> accountRecordTypes = new set<id>();
        accountRecordTypes.add(Constants.AccountRTMap.get('Client_Dealer'));
        accountRecordTypes.add(Constants.AccountRTMap.get('Prospect_Dealer'));
        set<id> legalEntityIds = new set<id>();
        list<account> accountList = new list<account>();
        list<CommonWrapperClass.BWSecuritySearchRowWrapper> bwrows = new list<CommonWrapperClass.BWSecuritySearchRowWrapper>();

        //Get Accounts and dedupe the accounts
        for(account a:[Select id,name,recordtype.name,recordtypeid,legal_entity_name__c, TCF_Legal_Entity__c, 
            (Select id,Secondary_Relationship__c,Secondary_Relationship__r.id,Secondary_Relationship__r.legal_entity_name__c,Secondary_Relationship__r.name,Secondary_Relationship__r.TCF_Legal_Entity__c
                from DealerManufacturer__r where Record_Type__c = 'Guarantor, Owner or Affiliate' and (Primary_Relationship__r.Legal_Entity__c = 'Sole Proprietorship' OR (Primary_Relationship__r.Legal_Entity__c = 'General Partnership' and Primary_Relationship__r.General_Partnership_Type__c = 'Without Agreement')) and Type__c = 'Individual')
            from account where care_number__c = :careNumberId and customer_status__c = 'Active' and recordtypeid IN :accountRecordTypes order by createddate asc]){
            system.debug('a: '+a);
            system.debug('a.DealerManufacturer__r: '+a.DealerManufacturer__r);
            if(accountList.size()==0){
                accountList.add(a);
                legalEntityIds.add(a.legal_entity_name__c);
            }
            else{
                if(!legalEntityIds.Contains(a.legal_entity_name__c)){
                    accountList.add(a);
                    legalEntityIds.add(a.legal_entity_name__c);
                }                  
            }
            for(Associated_Relationships__c ar: a.DealerManufacturer__r){
                if(!legalEntityIds.Contains(ar.Secondary_Relationship__c)){
                    accountList.add(ar.Secondary_Relationship__r);
                    legalEntityIds.add(ar.Secondary_Relationship__c);
                }
            }

        }
        system.debug('#####accountList:'+accountList);
        system.debug('#####legalEntityIds:'+legalEntityIds);
        //Get Existing Searches and Filings       
        map<id,BW_Chart_Row__c> bwcrMap = new map<id,BW_Chart_Row__c>();
        for(BW_Chart_Row__c bwcr: [Select id,Row_Key_Id__c,Data__c,Underwriting__c,Boarding_Wizard_Screen__c from BW_Chart_Row__c where Underwriting__c =:underwritingId and Boarding_Wizard_Screen__c =:screenId]){
            bwcrMap.put(bwcr.Row_Key_Id__c,bwcr);
        }
        
        set<id> ssIds = new set<id>();
        for(UCC_PPSA_Security_Search__c ssRecords : [Select Id from UCC_PPSA_Security_Search__c where underwriting__c =:underwritingId]){
            ssIds.add(ssRecords.id);
        }

        for(Security_Filings__c sfRecords : [Select Id from Security_Filings__c where underwriting__c =:underwritingId]){
            ssIds.add(sfRecords.id);
        }
        
        integer count = 0;
        for(account b: accountList){
            CommonWrapperClass.BWSecuritySearchRowWrapper bwrow = new CommonWrapperClass.BWSecuritySearchRowWrapper();
            bwrow.index = count;
            if(b.legal_entity_name__c != null){
                bwrow.key = b.legal_entity_name__c;
            }
            else{
                bwrow.key = b.id;
            }            
            bwrow.relationshipname = b.name;
            bwrow.relationshipId = '/'+ b.id;
            bwrow.tcfLegalEntity = b.TCF_Legal_Entity__c;
            if(bwcrMap.get(bwrow.key) != null){
                bwrow.searchBillingCode = UtilityClass.parseKeyValue(bwcrMap.get(bwrow.key).data__c, 'searchBillingCode', '=', ';');
                bwrow.searchId = UtilityClass.parseKeyValue(bwcrMap.get(bwrow.key).data__c, 'searchId', '=', ';');
                if(bwrow.searchId != 'RunSearch' && !ssIds.contains(bwrow.searchId)){
                    bwrow.searchId = 'RunSearch';
                }
                bwrow.filingType = UtilityClass.parseKeyValue(bwcrMap.get(bwrow.key).data__c, 'filingType', '=', ';');
                bwrow.filingId = UtilityClass.parseKeyValue(bwcrMap.get(bwrow.key).data__c, 'filingId', '=', ';');
                if(bwrow.filingId != 'RunFiling' && !ssIds.contains(bwrow.filingId)){
                    bwrow.filingId = 'RunFiling';
                }
                if(bwrow.filingId != 'RunFiling'){
                    bwrow.existingFiling = true;
                    bwrow.filingLabel = 'View Filing';
                }
                else{
                    bwrow.existingFiling = false;
                    bwrow.filingLabel = 'Create Filing';
                }               
                if(bwrow.searchId != 'RunSearch'){
                    bwrow.existingSearch = true;
                    bwrow.searchLabel = 'View Search';
                }
                else{
                    bwrow.existingSearch = false;
                    bwrow.searchLabel = 'Create Search';
                }
                bwrow.certified = boolean.valueof(UtilityClass.parseKeyValue(bwcrMap.get(bwrow.key).data__c, 'certified', '=', ';'));
                bwrow.specialInstructions = UtilityClass.parseKeyValue(bwcrMap.get(bwrow.key).data__c, 'specialInstructions', '=', ';');
                bwrow.chartData = bwcrMap.get(bwrow.key);
            }
            else{
                bwrow.searchBillingCode = '';
                bwrow.searchLabel = 'Create Search';
                bwrow.existingSearch = false;
                bwrow.searchId = 'RunSearch';
                bwrow.filingType = '';
                bwrow.filingLabel = 'Create Filing';
                bwrow.existingFiling = false;
                bwrow.filingId = 'RunFiling';
                bwrow.certified = false;
                bwrow.specialInstructions = '';
                bwrow.chartData = new BW_Chart_Row__c();
            }            
            bwrows.add(bwrow);
            count++;
        }
        return bwrows;
    }
   

    @AuraEnabled
    public static list<CommonWrapperClass.BWSecuritySearchRowWrapper> saveSearchFilings(string screenName, string underwritingId, list<CommonWrapperClass.BWSecuritySearchRowWrapper> data){
        string screenId = [SELECT id FROM BW_Screen__c WHERE Name =: screenName ORDER BY lastmodifieddate DESC LIMIT 1].id;
        
        list<BW_Chart_Row__c> upsertChartRows = new list<BW_Chart_Row__c>();

        system.debug('#####'+data);
        system.debug('#####'+underwritingId);
        system.debug('#####'+screenName);
        
        for(CommonWrapperClass.BWSecuritySearchRowWrapper ssrw:data){
            system.debug('#####'+ssrw.searchId);         
            ssrw.chartData.underwriting__c=underwritingId;
            ssrw.chartData.Row_Key_Id__c=ssrw.key;
            ssrw.chartData.Boarding_Wizard_Screen__c=screenId;
            ssrw.chartData.data__c = 
                'searchBillingCode='+ssrw.searchBillingCode+';'+
                'existingSearch='+ssrw.existingSearch+';'+
                'searchId='+ssrw.searchId+';'+
                'filingType='+ssrw.filingType+';'+
                'existingFiling='+ssrw.existingFiling+';'+
                'filingId='+ssrw.filingId+';'+
                'certified='+ssrw.certified+';'+
                'specialInstructions='+ssrw.specialInstructions+';';
            upsertChartRows.add(ssrw.chartData);
            
        }       

        upsert upsertChartRows;

        return data;

    }

    @AuraEnabled
    public static string retrieveSearchRecord(string underwritingId, CommonWrapperClass.BWSecuritySearchRowWrapper data){
        UCC_PPSA_Security_Search__c ss = new UCC_PPSA_Security_Search__c();
        ss.Underwriting__c = underwritingId;
        ss.Relationship_Name__c = data.relationshipId.replace('/','');
        ss.Certified__c = data.certified;
        ss.Billing_Code__c = data.searchBillingCode;
        ss.Search_Type__c = 'Summary';
        ss.Search_Details__c = data.specialInstructions;
        insert ss;
        return ss.id;
    }

    @AuraEnabled
    public static string retrieveFilingRecord(string underwritingId, CommonWrapperClass.BWSecuritySearchRowWrapper data, string careNumberId){
        Associated_Relationships__c arData = [Select id, Record_Type__c, Secondary_Relationship__r.First_Name__c, Secondary_Relationship__r.Last_Name__c, Primary_Relationship__r.TCF_Legal_Entity__c, Primary_Relationship__c from Associated_Relationships__c where Secondary_Relationship__c =:data.relationshipId.replace('/','') and Primary_Relationship__r.care_number__c =: careNumberId];

        string tcfLegal = 'Unknown';
        if(data.tcfLegalEntity == 'TCF Inventory Finance, Inc.' || (arData.Record_Type__c == 'Guarantor, Owner or Affiliate' && arData.Primary_Relationship__r.TCF_Legal_Entity__c == 'TCF Inventory Finance, Inc.')){
            if(data.filingType == 'Broad'){
                tcfLegal = 'TCFIF Broad';
            }
            else if(data.filingType == 'Specific Lines'){
                tcfLegal = 'TCFIF Specific Lines';
            }
            else if(data.filingType == 'When Financed'){
                tcfLegal = 'TCFIF When Financed By';
            }
        }
        else if(data.tcfLegalEntity == 'Red Iron Acceptance, LLC' || (arData.Record_Type__c == 'Guarantor, Owner or Affiliate' && arData.Primary_Relationship__r.TCF_Legal_Entity__c == 'Red Iron Acceptance, LLC')){            
            if(data.filingType == 'Broad'){
                tcfLegal = 'RIA Standard';
            }
            else if(data.filingType == 'Specific Lines'){
                tcfLegal = 'RIA Standard';
            }
            else if(data.filingType == 'When Financed'){
                tcfLegal = 'RIA When Financed';
            }
        }
        else if(data.tcfLegalEntity == 'TCF Commercial Finance Canada, Inc.' || data.tcfLegalEntity == 'Financement Commercial TCF Canada, Inc.' || (arData.Record_Type__c == 'Guarantor, Owner or Affiliate' && (arData.Primary_Relationship__r.TCF_Legal_Entity__c == 'TCF Commercial Finance Canada, Inc.' || arData.Primary_Relationship__r.TCF_Legal_Entity__c == 'Financement Commercial TCF Canada, Inc.'))){
            if(data.filingType == 'Broad'){
                tcfLegal = 'TCFCFC Broad';
            }
            else if(data.filingType == 'Specific Lines'){
                tcfLegal = 'TCFCFC Specific Product';
            }
            else if(data.filingType == 'When Financed'){
                tcfLegal = 'TCFCFC When Financed';
            }
        }

        system.debug('tcfLegal: '+tcfLegal);
        system.debug('data.tcfLegalEntity: '+data.tcfLegalEntity);

        Security_Filings__c sf = new Security_Filings__c();
        sf.Underwriting__c = underwritingId;
        sf.Relationship_Security__c = data.relationshipId.replace('/','');
        for(Filing_Language__c fc: [Select id, Security_Filing_Language__c, Security_Filing_Language_Type__c from Filing_Language__c]){
            if(fc.Security_Filing_Language_Type__c == tcfLegal){
                sf.UCC_PPSA_RDPRM_Filing_Language__c = fc.id;
                break;
            }
        }
        sf.Filing_Type__c = 'UCC1';
        sf.Billing_Code__c = data.searchBillingCode;
        if(arData.Record_Type__c == 'Guarantor, Owner or Affiliate'){
            sf.Debtor_Individual_Name__c = true;
            sf.Debtor_First_Name__c = arData.Secondary_Relationship__r.First_Name__c;
            sf.Debtor_Last_Name__c = arData.Secondary_Relationship__r.Last_Name__c;
            sf.Filing_Entity__c = arData.Primary_Relationship__r.TCF_Legal_Entity__c;
        }

        insert sf;
        return sf.id;
    }
    ////////////////////////////////////////////
    // End of Security Search & Filing Screen //
    ////////////////////////////////////////////
   
}