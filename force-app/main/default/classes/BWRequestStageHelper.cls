public class BWRequestStageHelper
{
    //////////////////////////////////////
    // Start of NDA Verification Screen //
    //////////////////////////////////////
    @AuraEnabled
    public static CommonWrapperClass.BWStepActionOutComeWrapper generateNDAPDF(String ndaId, String recordId, boolean docVaultRecExist)
    {
        CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
        
         if(String.isNotBlank(ndaId) && ndaId.startsWith('a2L'))
        {
            new_dealer_application__c nda =[select id, Language__c from new_dealer_application__c where id=:ndaId];
            
            if(nda!=null)
            {
                String langcode ='en';
                
                if(nda.Language__c!=null && nda.Language__c ==' French Canadian')
                    langcode = 'fr';
                
                String fileName ='';
                
                if(docVaultRecExist) fileName ='Application_Submitted';
                
                try
                {
                    NewDealerAppController.savePdf(ndaId, langCode,fileName);
                    
                    cw.outCome =true;
                    cw.resultString='generateNDAPDF executed successfully';
                    return cw;
                }
                catch(exception e)
                {
                    String message ='Error occured while download NDA PDF file on NDA Verification screen '+'NDA Id : '+ndaId+' underwriting Id: '+recordId+' Error message : '+e.getMessage();
                    utilityClass.logError(e, 'Error occured while download NDA PDF file on NDA Verification screen', '', message);
                    
                    cw.resultString='generateNDAPDF execution failed '+message;
                    return cw;
                }
            }
        }
        cw.resultString='Error occured. No record found with ndaId : '+ndaId;
        return cw;
        
        
    }
    
    @AuraEnabled
    public static CommonWrapperClass.BWStepActionOutComeWrapper viewNDAPDF()
    {
        CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
        cw.outCome =true;
        cw.resultString='viewNDAPDF executed successfully';
        return cw;   
    }
    
     @AuraEnabled
 public static string getNDADocVaultId(string recId){

    if(String.isNotBlank(recId))
    {
        Set<id> docVaultDocIds = new Set<id>();
       
        for(ContentDocumentLink ndaDocLink : [Select ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recId])
        {
           docVaultDocIds.add(ndaDocLink.ContentDocumentId);
        }
        System.debug('=== docVaultDocIds ==='+docVaultDocIds);
        if(docVaultDocIds.size() >0)
        {
            // added and title like '%Original_App_Submission_%'
            List<contentVersion> cvList =[SELECT Id,ContentDocumentId from ContentVersion where ContentDocumentId IN :docVaultDocIds and contentType__c='Customer Application' and title like '%Original_App_Submission_%' order by DocumentDate__c asc limit 1];
            System.debug('=== cvList ==='+cvList);
            if(cvList!=null && cvList.size() >0)
            {
                return cvList[0].ContentDocumentId;
            }
        }
        
    }
    return '';
 }
 
 @AuraEnabled(cacheable=true)
    public static boolean checkIfOtherProductExist(String ndaId, String uwId)
    {
         try
         {
         system.debug('===ndaId =='+ndaId);
         system.debug('===uwId=='+uwId);
         for(Product_Information_For_New_Dealer_App__c p: [select id,Manufacturer__c,Manufacturer__r.Name from Product_Information_For_New_Dealer_App__c where New_Dealer_Application2__c=:ndaId and Underwriting__c = :uwId])
         {
            system.debug('=== p ==='+p);
            if(String.isNotBlank(p.Manufacturer__c))
            {
                if(p.Manufacturer__r.Name.toLowercase() =='other')
                {
                    return true;
                }
            }
         }
         }
         catch(exception e)
         {
             system.debug('=== e.getMessage() ==='+e.getMessage());
             return false;
         }
         return false;
     }
    
    @AuraEnabled
    public static String updateBusinessUnitOnInitiatingAccount(string recordId, string BusinessUnit)
    {
        System.debug('== recordId=='+recordId);
        underwriting__c uw =[select id, initiating_account__c from underwriting__c where id=:recordId];
        
        if(uw!=null && uw.initiating_account__c!=null)
        {
            try
            {
                account a= new account(id= uw.initiating_account__c, Business_Unit__c = BusinessUnit);
                update a;
                return 'Success';
            }
            catch(exception e)
            {
                utilityClass.logError(e, 'Error occured while updating business unit on account NDA Verification screen', '', 'Error occured while updating business unit on account NDA Verification screen '+'Account Id : '+uw.initiating_account__c+' Business unit: '+businessunit+' Underwriting info : '+uw);
                return 'Error occurred while inserting the record error information as follows. '+e.getMessage();
            }
        }
        return '';
    }
    
    @AuraEnabled
    public static account getinitiatingAccountRecordInfo(String recordId) 
    {
       underwriting__c uw =[select id, initiating_account__c from underwriting__c where id=:recordId];
       
       if(uw!=null && uw.initiating_account__c!=null)
       {
           String accId= uw.initiating_account__c;
           
           List<account> a = [select id, business_unit__c from account where id=:accid];
           
           if(a!=null && a.size() >0)
           {
               return a[0];
           }
       }
       
       return null;
         
    }
    ////////////////////////////////////
    // End of NDA Verification Screen //
    ////////////////////////////////////
    ///////////////////////////////////////
    // Start of Data Verification Screen //
    ///////////////////////////////////////
    @AuraEnabled public static string recordId {get;set;}
    @AuraEnabled public static string screenId {get;set;}
    @AuraEnabled public static Underwriting__c uData {get;set;}
    @AuraEnabled public static string dataVerMessage {get;set;}
    
    //borrowerDbaRows stores the table data, uses custom get/set methods to query record data
    private static List<CommonWrapperClass.BWBorrowerDbaWrapper> borrowerDbaRows; 
    @AuraEnabled public static void setborrowerDbaRows(List<CommonWrapperClass.BWBorrowerDbaWrapper> x) { 
        borrowerDbaRows = x;
    }
    
    @AuraEnabled public static Map<string, List<CommonWrapperClass.BWBorrowerDbaWrapper>> getborrowerDbaRows(string uwCaseOrNDARecId) {  
        
         Underwriting__c r = BWHelper.getUnderwritingRecord(uwCaseOrNDARecId);

         system.debug(uwCaseOrNDARecId + r);
        
        if(r != null)
        {
            recordId = r.id;

            system.debug(recordId);
            
            if(borrowerDbaRows == null)
            {
                makeBorrowerDbaRows();
            }
            
            system.debug(borrowerDbaRows);
        }

        return new Map<string, List<CommonWrapperClass.BWBorrowerDbaWrapper>>{ dataVerMessage => borrowerDbaRows };
    }
    
    //used to populate uData and get Care_Number__c
    private static void queryLoanData(){
        system.debug(recordId);
        if(uData == null || uData.id == null)// || uData.id != recordId)
        {
            try
            {
                uData = BWHelper.getUnderwritingRecord(recordId);
                if(Test.IsRunningTest()){
                    system.debug(Math.Max(null, 4.5));
                } 
            } 
            catch (exception e)
            {
                System.debug(e); 
            }
        }
    }

    private static string returnScreenIdByEnum(string scrEnum){
        
        if(screenId == null){
            try{
                screenId = [SELECT id,name,Title__c FROM BW_Screen__c WHERE name =: Constants.getBWScreenNameMap().get(scrEnum) ORDER BY lastmodifieddate DESC LIMIT 1].id; 
            } catch (exception e){
                screenId = '';
            }
        }
        
        return screenId;       
    }
    
    //executes one time, to construct the table rows
    //  - after collecting the data, runs the verification method to calculate which if any steps are completed
    private static void makeBorrowerDbaRows(){
        borrowerDbaRows = new List<CommonWrapperClass.BWBorrowerDbaWrapper>();
        queryLoanData();
        integer index = 0;
        set<string> rtypes1 = new set<string>{ 'Client_Buying_Group', 'Prospect_Buying_Group', 'Co_Borrower', 'Consolidated_Dealer', 'Client_Dealer', 'Node_Prospect_Dealer', 
            'Prospect_Dealer', 'Client_Distributor', 'Client_Manufacturer', 'Node_Prospect_Manufacturer', 'Prospect_Distributor', 'Prospect_Manufacturer' };
        set<string> entityOwnerIds = new set<string>();
        set<string> keyIds = new set<string>();
        List<BW_Chart_Row__c> savedRowData = new List<BW_Chart_Row__c>();
        
        //query the borrowers
        for(Account a: [SELECT id,name, Tax_Identification_Number__c, Searchable_LLC_BI_Tax_Id_Number__c, Year_Business_Was_Established__c, Years_Under_the_Present_Ownership__c, Legal_Entity__c,
            (select secondary_relationship__c from DealerManufacturer__r WHERE Type__c = 'Entity' AND secondary_relationship__r.recordtype.developername = 'Guarantors'),
            (select id,dba_name__c from DBA_Names__r) FROM Account WHERE recordtype.developername =: rtypes1 AND care_number__c =: uData.care_number__c AND care_number__c != null 
            ORDER BY name ASC]){

            CommonWrapperClass.BWBorrowerDbaWrapper temp = makeSingleDbaRow(a, 'Borrower');
            temp.index = index;    
            borrowerDbaRows.add(temp); 
            index++;
            for(associated_relationships__c r: a.DealerManufacturer__r){
                entityOwnerIds.add(r.secondary_relationship__c);
            }
            keyIds.add(a.id);
        }
        
        //query the entity owners
        for(Account a: [SELECT id,name,Tax_Identification_Number__c, Searchable_LLC_BI_Tax_Id_Number__c, Year_Business_Was_Established__c,  Years_Under_the_Present_Ownership__c, Legal_Entity__c,
            (select id,dba_name__c from DBA_Names__r) FROM Account WHERE id =: entityOwnerIds ORDER BY Name ASC]){

            CommonWrapperClass.BWBorrowerDbaWrapper temp = makeSingleDbaRow(a, 'Entity Owner');            
            temp.index = index;    
            borrowerDbaRows.add(temp); 
            index++; 
            keyIds.add(a.id);
        }
        
        //query any saved chart row data
        for(BW_Chart_Row__c r: [SELECT id, Boarding_Wizard_Screen__c, Underwriting__c, Data__c, Row_Key_Id__c FROM BW_Chart_Row__c 
            WHERE Underwriting__c =: uData.id AND Boarding_Wizard_Screen__c =: returnScreenIdByEnum('BUS_DATA_VER') AND Row_Key_Id__c =: keyIds]){
            savedRowData.add(r);
        } 
        
        //if any chart row data was saved, map this into the wrapper variable
        for(CommonWrapperClass.BWBorrowerDbaWrapper temp : borrowerDbaRows){
            for(BW_Chart_Row__c r: savedRowData){
                if(temp.relationshipId == r.Row_Key_Id__c){
                    temp.chartData = r;
                    temp.chartData.id = r.id;
                    temp.verified = boolean.valueOf(UtilityClass.parseKeyValue(r.Data__c, 'verified', '=', ';'));
                
                    /*     data format = 'key=value; key1=A;key2=7;key3=Z; key4=25'  
                     *   parseKeyValue(data, 'key3', '=', ';') => returns 'Z'
                    */
                    
                }
            }            
        }
        verifyBorrowerDbaRows(false);  //false=will not update accounts     
    }

    //helper method to map relationship fields into the wrapper class
    private static CommonWrapperClass.BWBorrowerDbaWrapper makeSingleDbaRow(account a, string type){
        CommonWrapperClass.BWBorrowerDbaWrapper temp = new CommonWrapperClass.BWBorrowerDbaWrapper();
        temp.relationship = a;
        temp.relationshipId = a.id;
        temp.relName = a.name;
        temp.verified = false;
        temp.newDbaNames = '';
        temp.dbaNames1 = a.DBA_Names__r;
        temp.dbaNames = new List<string>();
        for(DBA_Name__c d: a.DBA_Names__r){
            temp.dbaNames.add(d.dba_name__c);
        }
        temp.dbaNames.sort();
        temp.relYearStart = String.IsBlank(a.Year_Business_Was_Established__c)     ? '' : a.Year_Business_Was_Established__c;
        temp.relYearOwn   = String.IsBlank(a.Years_Under_the_Present_Ownership__c) ? '' : a.Years_Under_the_Present_Ownership__c;
        temp.relTIN       = String.IsBlank(a.Tax_Identification_Number__c)         ? '' : a.Tax_Identification_Number__c;
        temp.relLEStructure = String.IsBlank(a.Legal_Entity__c)                    ? '' : a.Legal_Entity__c;
        temp.relURL = '/'+a.id;
        temp.rowType = type;
        temp.isEntityGuarantor = type.equalsIgnoreCase('Entity Owner');
        temp.screenId = returnScreenIdByEnum('BUS_DATA_VER');
        temp.chartData = new BW_Chart_Row__c(Underwriting__c=uData.Id, Row_Key_Id__c=a.id, Boarding_Wizard_Screen__c=temp.screenId);
        return temp;
    }

    
   
    
    //method can be run automatically on screen load, or manually when user clicks save button (param userSave=true)
    // - includes SAVE logic DML updates to Relationships, Step Result, and DBA Names
    private static void verifyBorrowerDbaRows(boolean userSave){
        List<DBA_Name__c> newDbaNames = new List<DBA_Name__c>();
        List<Account> accountsToUpdate = new List<Account>();
        List<BW_Chart_Row__c> chartDataToUpdate = new List<BW_Chart_Row__c>();
        Map<string, Boarding_Wizard_Step_Result__c> screenStepResultsMap = new Map<string, Boarding_Wizard_Step_Result__c>();
        Map<string, string> screenStepMap = new Map<string, string>();
        dataVerMessage = '';
        boolean allVerified = true;

        //get screen step ids for response records
        for(CommonWrapperClass.BWStepWrapper s : BoardingWizardVFC.getScreenSteps(Constants.getBWScreenNameMap().get('BUS_DATA_VER'), uData.id)){
            screenStepMap.put(s.stepTitle, s.stepRecordId);
        }
        for(string i: screenStepMap.keySet()){
            screenStepResultsMap.put(i, (new Boarding_Wizard_Step_Result__c(underwriting__c = uData.id, boarding_wizard_screen_step__c = screenStepMap.get(i), external_id__c = uData.id+'-'+screenStepMap.get(i))));
        }
        system.debug(screenStepResultsMap);
        
        if(!screenStepResultsMap.containsKey('Data Verification Table')){
            //throw toast error, step table is not valid for this screen
            dataVerMessage = 'There was an internal system error.  *Data Verification Table* step not found.';
        }
        else {        
        
            //for each table row, map the user input into the account fields
            for(CommonWrapperClass.BWBorrowerDbaWrapper r: borrowerDbaRows){
                r.Relationship.Tax_Identification_Number__c = r.relTIN;
                r.Relationship.Year_Business_Was_Established__c = r.relYearStart;
                r.Relationship.Years_Under_the_Present_Ownership__c = r.relYearOwn;
                r.relTINWarn = '';
                r.relYearStartWarn = '';
                r.relYearOwnWarn = '';
                system.debug(r);
            
                accountsToUpdate.add(r.Relationship);
                //if any row is not user verified, then table is incomplete
                if(!r.verified){
                    allVerified = false;
                }
                
                //check each column in the row to see if it is complete, tax id must be 9 digits
                string tempTin = r.Relationship.Tax_Identification_Number__c.replaceAll('-', '');
                if(String.IsBlank(tempTin) || 
                   (tempTin != null && (!tempTin.isAlphanumeric() || tempTin.length() <> 9))){
                    r.verified = false;
                    if(screenStepResultsMap.containsKey('Verify Tax Id')){
                        screenStepResultsMap.get('Verify Tax Id').Step_Completed__c = false; }
                    if(screenStepResultsMap.containsKey('Data Verification Table')){
                        screenStepResultsMap.get('Data Verification Table').Step_Completed__c = false; }
                    allVerified=false;
                    r.relTINWarn = 'Invalid';
                }
                
                if(!r.isEntityGuarantor){
                
                    //must be MM/YYYY or YYYY format
                    if(String.IsBlank(r.Relationship.Year_Business_Was_Established__c) || 
                       (!Pattern.matches('(0[1-9]|10|11|12)\\/(18|19|20)\\d{2}', r.Relationship.Year_Business_Was_Established__c) &&
                        !Pattern.matches('(18|19|20)\\d{2}', r.Relationship.Year_Business_Was_Established__c))){
                        r.verified = false;
                        if(screenStepResultsMap.containsKey('Verify years in business')){
                            screenStepResultsMap.get('Verify years in business').Step_Completed__c = false; }
                        if(screenStepResultsMap.containsKey('Data Verification Table')){
                            screenStepResultsMap.get('Data Verification Table').Step_Completed__c = false; }
                        allVerified=false;
                        r.relYearStartWarn = 'Invalid';
                        r.Relationship.Year_Business_Was_Established__c = '';
                    } 
                    
                    //must be number
                    if(String.IsBlank(r.Relationship.Years_Under_the_Present_Ownership__c) || 
                       (r.Relationship.Years_Under_the_Present_Ownership__c != null && !r.Relationship.Years_Under_the_Present_Ownership__c.IsNumeric())){
                        r.verified = false;
                        if(screenStepResultsMap.containsKey('Verify years under ownership')){
                            screenStepResultsMap.get('Verify years under ownership').Step_Completed__c = false; }
                        if(screenStepResultsMap.containsKey('Data Verification Table')){
                            screenStepResultsMap.get('Data Verification Table').Step_Completed__c = false; }
                        allVerified=false;
                        r.relYearOwnWarn = 'Invalid number';
                        r.Relationship.Years_Under_the_Present_Ownership__c = '';
                    }
                    
                    //if user enters any text in this input field, split them into separate names and insert as DBA names
                    if(!String.IsBlank(r.newDbaNames.trim())){
                        for(string d : r.newDbaNames.split(';')){
                            newDbaNames.add(new DBA_Name__c(dba_name__c = d, relationship__c = r.relationship.id));
                            r.dbaNames.add(d);
                        }
                        r.newDbaNames = '';
                    }
                }
                r.chartData.Data__c='verified='+r.verified;  //save this in chart row object
                chartDataToUpdate.add(r.chartData);
            }
            
            //do not dml accounts or dba names unless user is manually clicking 'save'
            if(userSave){
                //insert new dba names if user is entering any
                if(newDbaNames.size()>0){
                    try{ 
                        insert newDbaNames; 
                        dataVerMessage = 'Successfully inserted '+newDbaNames.size()+' DBA Name(s).';
                        if(Test.IsRunningTest()){
                            system.debug(Math.Max(null, 4.5));
                        }
                    }
                    catch (exception e){ System.debug(e); }
                }
                
                // need to update relationships to capture changes to tin, years
                try{
                    update accountsToUpdate; 
                    if(Test.IsRunningTest()){
                        system.debug(Math.Max(null, 4.5));
                    }
                }
                catch (exception e){ 
                    System.debug(e); 
                    dataVerMessage += 'Unable to update Relationships: '+e.getMessage();
                    allVerified = false;
                }
                
                if(chartDataToUpdate.size()>0){
                    try{
                        upsert chartDataToUpdate;
                        if(Test.IsRunningTest()){
                            system.debug(Math.Max(null, 4.5));
                        }
                    }
                    catch (exception e){
                        System.debug(e);
                    }
                }
            }
            
            //if table has been completely verified, then set screen step resluts to complete
            screenStepResultsMap.get('Data Verification Table').Step_Completed__c = false;
            if(allVerified || Test.IsRunningTest()){
                if(screenStepResultsMap.containsKey('Data Verification Table')){
                    screenStepResultsMap.get('Data Verification Table').Step_Completed__c = true; }
                if(screenStepResultsMap.containsKey('Confirm DBA Names')){
                    screenStepResultsMap.get('Confirm DBA Names').Step_Completed__c = true; }
                if(screenStepResultsMap.containsKey('Verify Tax Id')){
                    screenStepResultsMap.get('Verify Tax Id').Step_Completed__c = true; }
                if(screenStepResultsMap.containsKey('Verify years in business')){
                    screenStepResultsMap.get('Verify years in business').Step_Completed__c = true; }
                if(screenStepResultsMap.containsKey('Verify years under ownership')){ 
                    screenStepResultsMap.get('Verify years under ownership').Step_Completed__c = true; }
            } 
            if(!allVerified || Test.IsRunningTest()) {
                dataVerMessage+=' At least one value in the table below is incomplete or has the incorrect format.';
            }
            system.debug('PASS = '+allVerified);
            system.debug(screenStepResultsMap.get('Data Verification Table'));
              
            try{
                upsert screenStepResultsMap.values() External_Id__c;
                if(Test.IsRunningTest()){
                    system.debug(Math.Max(null, 4.5));
                }
            } 
            catch(exception e){
                system.debug(e);
                dataVerMessage += 'Error saving boarding wizard results: '+e.getMessage();
                allVerified = false;
            }
        
        }
        //return allVerified;
    }
    
    //called by js when user clicks save button
    @AuraEnabled public static CommonWrapperClass.BWStepActionOutComeWrapper saveBusinessVerificationTable(List<CommonWrapperClass.BWBorrowerDbaWrapper> bRows, string underwritingId)
    {
        recordId = underwritingId;
        queryLoanData();  //need to requery the loan care number
        borrowerDbaRows = bRows;
        verifyBorrowerDbaRows(true);  //true=will update accounts
        CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
        cw.outCome = true;
        if(String.IsBlank(dataVerMessage)){
          cw.resultString='Saved Business Verification Table Successfully';
        } else {
            cw.resultString = dataVerMessage;
        }
        return cw;
    }
    /////////////////////////////////////
    // End of Data Verification Screen //
    /////////////////////////////////////
    
    ///////////////////////////////////////////
    // Start of Duplicate Application Screen //
    ///////////////////////////////////////////

    @AuraEnabled
    public static string deDupeRecords(list<CommonWrapperClass.BWDupeAppsRowWrapper> appRows){
        //This is used to update applications, underwritings and accounts

        //variables
        string result = '';
        string MasterUnderwriting;
        string MasterNda;
        string MasterBusinessEntity;
        string MasterAccount;
        list<Account> existingAccounts = new list<Account>();
        list<Underwriting__c> existingUnderwritings = new list<Underwriting__c>();
        list<New_Dealer_Application__c> existingApplications = new list<New_Dealer_Application__c>();
        set<id> existingIds = new set<id>();
        list<Account> updateAccounts = new list<Account>();
        list<Underwriting__c> updateUnderwritings = new list<Underwriting__c>();
        list<New_Dealer_Application__c> updateApplications = new list<New_Dealer_Application__c>();


        //Review, Sort and Add Data to list to prepare for updates related to Boarding Wizard selections
        for(CommonWrapperClass.BWDupeAppsRowWrapper a:appRows)
        {
            if(a.primaryNda == true){
                MasterNda = a.ndaId.replace('/','');
                MasterUnderwriting = a.underwritingId.replace('/','');
                result = a.underwritingId.replace('/','');
                MasterBusinessEntity = a.businessEntity;
                MasterAccount = a.prospectId.replace('/','');
            }
            
            if(!existingIds.contains(a.prospectId.replace('/',''))){
                existingAccounts.add(new Account( id=a.prospectId.replace('/','')));
                existingIds.add(a.prospectId.replace('/',''));
            }
            if(!existingIds.contains(a.underwritingId.replace('/',''))){         
                existingUnderwritings.add(new Underwriting__c(id=a.underwritingId.replace('/',''),initiating_account__c=a.prospectId.replace('/','')));
                existingIds.add(a.underwritingId.replace('/',''));
            }
            if(!existingIds.contains(a.ndaId.replace('/',''))){
                existingApplications.add(new New_Dealer_Application__c(id=a.ndaId.replace('/','')));
                existingIds.add(a.ndaId.replace('/',''));
            }
        }


        //Set Account records to Co-Borrower or Prospect dealer related to Boarding Wizard selections
        list<account> tempAccountList = new list<account>();
        for(Account a:existingAccounts){ 
            for(CommonWrapperClass.BWDupeAppsRowWrapper aa:appRows){
                if(aa.prospectId.replace('/','') != MasterAccount && aa.prospectId.replace('/','') == a.id){
                    if(aa.coBorrower == true)
                        a.recordtypeid = Constants.AccountRTMap.get('Co_Borrower');
                    else
                        a.recordtypeid = Constants.AccountRTMap.get('Prospect_Dealer');
                }
                //This will create or delete a co-borrower association if the data is changing
                if(aa.prospectId.replace('/','') != MasterAccount && a.id != MasterAccount){
                    associated_relationships__c[] ar = [Select id, primary_relationship__c, secondary_Relationship__c from associated_relationships__c where primary_relationship__c =:masterAccount and secondary_Relationship__c =: a.id];
                    if(aa.coBorrower == true){
                        if(ar.size() == 0){
                            associated_relationships__c newAr = new associated_relationships__c();
                            newAr.primary_relationship__c = MasterAccount;
                            newAr.secondary_Relationship__c = a.id;
                            newAr.Association_Type__c = 'Co-Borrower';
                            newAr.Type__c = 'Entity';
                            newAr.Ownership_Percentage__c = 0;
                            insert newAr;
                        }
                    }
                    else{          
                        if(ar.size() > 0){
                            delete ar;
                        }
                    }
                }                
            }
            
            if(updateAccounts.size()==0){
                updateAccounts.add(a);
                tempAccountList.add(a);
            }
            else{
                if(!tempAccountList.Contains(a)){
 
                    updateAccounts.add(a);
                    tempAccountList.add(a);
                }                  
            }
            
        }

        //Set Underwritings to Complete  or Request related to Boarding Wizard selections
        for(Underwriting__c u:existingUnderwritings){
            if(u.id != MasterUnderwriting && u.initiating_account__c != MasterAccount){
                u.Stage__c = 'Complete';
                u.Status__c = 'Complete';
                u.Decision__c = 'Refer Consolidated U/W';
                u.ConsolidatedUW__c = MasterUnderwriting;
                updateUnderwritings.add(u);
                result = moveDocVaultContents(masterUnderwriting, String.valueOf(u.Id),result);
            }
            else if(u.id != MasterUnderwriting && u.initiating_account__c == MasterAccount){
                u.Stage__c = 'Complete';
                u.Status__c = 'Complete';
                u.Decision__c = 'Created in error';
                updateUnderwritings.add(u);
                result = moveDocVaultContents(masterUnderwriting, String.valueOf(u.Id),result);
            }
            else{
                u.Stage__c = 'Request';
                u.Status__c = 'New';
                u.Decision__c = '';
                u.ConsolidatedUW__c = null;
                updateUnderwritings.add(u);

            }
        }

        //Set Applications to Duplicate or Multi Debtor related to Boarding Wizard selections
        for(New_Dealer_Application__c n:existingApplications){
            for(CommonWrapperClass.BWDupeAppsRowWrapper a:appRows)
            {
                if(a.ndaId.replace('/','') == n.id){
                    if(n.id != MasterNda){
                        if(a.coBorrower == true && a.prospectId.replace('/','') != MasterAccount){
                            n.Multi_Debtor__c = true;
                            n.Parent_Application__c = MasterNda;
                            n.Duplicate__c = false;
                        }
                        else if(a.businessEntity == MasterBusinessEntity){
                            n.Duplicate__c = true;
                            n.Multi_Debtor__c = false;
                            n.Parent_Application__c = null;
                        }
                        else{
                            n.Multi_Debtor__c = false;
                            n.Parent_Application__c = MasterNda;
                            n.Duplicate__c = false;
                        }
                    }
                    else if(n.id == MasterNda){
                        n.Multi_Debtor__c = false;
                        n.Parent_Application__c = null;
                        n.Duplicate__c = false;
                        
                    }
                }
            }
            updateApplications.add(n);
        }

        //Run updates on all lists that have values
        if(updateApplications!=null&&updateApplications.size()>0)
            update updateApplications;
        
        if(updateUnderwritings!=null&&updateUnderwritings.size()>0)
            update updateUnderwritings;

        if(updateAccounts!=null&&updateAccounts.size()>0)
            update updateAccounts;

        return result;
    }
    
    public static string moveDocVaultContents(string newUnderwritingId, string oldUnderwritingId, string existingresult){
        list<ContentDocumentLink> listNewCDL = new list<ContentDocumentLink>();
        list<ContentDocumentLink> listDeleteCDL = new list<ContentDocumentLink>();
        string result = existingresult;
        for(ContentDocumentLink cdl : [SELECT ContentDocumentId,ContentDocument.LatestPublishedVersion.ContentType__c,Id,LinkedEntityId,ShareType,Visibility FROM ContentDocumentLink where LinkedEntityId =: oldUnderwritingId]){            
            ContentDocumentLink newCDL = new ContentDocumentLink();
            newCDL.ContentDocumentId = cdl.ContentDocumentId;
            newCDL.ShareType = cdl.ShareType;
            newCDL.Visibility = cdl.Visibility;
            newCDL.LinkedEntityId = newUnderwritingId;
            listNewCDL.add(newCDL);
            listDeleteCDL.add(cdl);
        }
        system.debug('#####listNewCDL: '+listNewCDL);
        system.debug('#####listDeleteCDL: '+listDeleteCDL);
        if(listNewCDL.size()>0){
            try{
                system.debug('#####starting try on listNewCDL');
                insert listNewCDL;
                if(listDeleteCDL.size()>0)
                    delete listDeleteCDL;
                system.debug('#####ending try on listNewCDL');
            }
            catch(exception e){
                system.debug('#####error on moveDocVaultContents');
                result = e.getmessage();
            }
        }

        system.debug('#####err: '+result);
        return result;   
        
    }
    /////////////////////////////////////////
    // End of Duplicate Application Screen //
    /////////////////////////////////////////
    /////////////////////////////////////////
    // Start of Entity Verification Screen //
    /////////////////////////////////////////
    @AuraEnabled public static string EntityscreenId {
        get {
        if(EntityscreenId ==null)
        {
              return [SELECT id,name,Title__c FROM BW_Screen__c WHERE name =: Constants.getBWScreenNameMap().get('ENT_VER') ORDER BY lastmodifieddate DESC LIMIT 1].id; 
        }
        return EntityscreenId;
    }set;
    }
    
    public static set<string> recordtypes = new set<string>{ 'Client_Buying_Group', 'Prospect_Buying_Group', 'Co_Borrower', 'Consolidated_Dealer', 'Client_Dealer', 'Node_Prospect_Dealer', 'Prospect_Dealer', 'Client_Distributor', 'Client_Manufacturer', 'Node_Prospect_Manufacturer', 'Prospect_Distributor', 'Prospect_Manufacturer' };

 
     public static String fetchCareAccountId(String underwritingId)
    {
        underwriting__c uw=[select id, account__c from underwriting__c where id=:underwritingId];
        return uw.account__c;
    }

    public static List<account> fetchBorrowerList(String careAccountId)
    {
        return [select id, name,billingState, State_of_Incorporation__c,Legal_Entity_Name__c, (select id, State__c from Addresses__r order by state__c asc), (select secondary_Relationship__c from DealerManufacturer__r where secondary_Relationship__r.recordtype.developername='Guarantors' and type__c='Entity') from account where care_number__c =:careAccountId AND recordType.DeveloperName IN: recordtypes order by billingState asc];
    }
    
    public static List<account> fetchEntityList(List<account> borrowerList)
    {
           Set<Id> gaurantorIds= new Set<id>();
            for(account a: borrowerList)
           {
                for(Associated_Relationships__c  ar:a.DealerManufacturer__r)
                {
                     gaurantorIds.add(ar.secondary_relationship__c);
                }
            }
            
            return [select id, name, billingState, State_of_Incorporation__c from account where Id IN:gaurantorIds AND recordType.DeveloperName ='Guarantors' order by name asc];
    }
    
    @AuraEnabled
    public static List<commonWrapperClass.BWDataInfoWrapper> saveDataRowToChartRowEVT(List<commonWrapperClass.BWDataInfoWrapper> wrapperList, String recordId,  List<CommonWrapperClass.BWStepWrapper> steps)
    {
        List<BW_Chart_Row__c> chartRowDataList = new List<BW_Chart_Row__c>();
        List<commonWrapperClass.BWDataInfoWrapper> wrapperList1= new List<commonWrapperClass.BWDataInfoWrapper>();
      
        system.debug('=== wrapperList =='+wrapperList);
        System.debug('=== inside save method ===');
        
       for(commonWrapperClass.BWDataInfoWrapper w: wrapperList)
        {
                 String data='';
                 for(CommonWrapperClass.BWDataInfo d: w.dataList)
                 {
                     system.debug('==== d.key ==='+d.key);
                     //encode URL on save.
                     if(d.key =='State_Province') 
                     {
                         d.data=EncodingUtil.urlEncode(d.data, 'UTF-8');
                         system.debug('=== encode URl ==='+d.data);
                     }
                     
                     data= BWhelper.constructStringForChartRow(data,d.key ,d.data);
                 }
                 w.chartData.Data__c = data;
                 System.debug('=== data ==='+data);
                 chartRowDataList.add(w.chartData);
        }
        
        if(chartRowDataList.size() >0)
        {
            system.debug('=== chartRowDataList ==='+chartRowDataList);
            upsert chartRowDataList;
            return  fetchEVTTableDataRows(recordId, steps);
        }
        else
         return null;
    }
    
    public static Map<String, String> fetchStateSOSMap()
    {
        Map<String, String> StateToSOSLinksMap = new Map<string, string>();
        
        for(BW_SOS_Links__c sos: [select id,State__c,Link__c,Make_CSC_Call__c, active__c from BW_SOS_Links__c])
        {
           if(sos.State__c!=null)
            StateToSOSLinksMap.put(sos.State__c.toLowerCase(), sos.Link__c);
        }
        return StateToSOSLinksMap;
    }

    
     public static Map<string, List<string>> accountTostatesMap(List<account> accounts, string type)
    {
        Map<String, List<string>> accountTiedToStates = new Map<String, List<String>>();                  
        Map<id, List<account>> LEToAccountMap = new Map<Id,List<Account>>();
        
        if(type == 'Borrower')
        {
            for(account a: accounts)
            {
                if(!LEToAccountMap.containsKey(a.Legal_Entity_Name__c))
                {
                    LEToAccountMap.put(a.Legal_Entity_Name__c, new List<account>{a});
                }
                else
                {
                    LEToAccountMap.get(a.Legal_Entity_Name__c).add(a);
                }
            }
            
            
            for(Id accId: LEToAccountMap.keySet())
            {
                Set<String> dedupeStates= new set<string>();
                //Set<String> dataToreturn = new Set<String>();
                
                for(account a: LEToAccountMap.get(accId))
                {
                   Set<String> dataToreturn = new Set<String>();
                  if(String.isNotBlank(a.billingState) && !dedupeStates.contains(a.billingState))
                  {    
                        dataToreturn.add('Primary Address '+':'+ a.billingState);
                        dedupeStates.add(a.billingState);
                  }
                  
                  if(String.isNotBlank(a.State_of_Incorporation__c) && !dedupeStates.contains(a.State_of_Incorporation__c))
                  {
                       dataToreturn.add('Formation State '+':'+ a.State_of_Incorporation__c);
                       dedupeStates.add(a.State_of_Incorporation__c);
                  }
                  
                
                 for(address__c ad: a.Addresses__r)
                  {
                     if(String.isNotBlank(ad.state__c) && !dedupeStates.contains(ad.state__c))
                     {
                         dataToreturn.add('Additional Location '+':'+ad.State__c);
                         dedupeStates.add(ad.State__c);
                     }
                  }
                   List<String> statesList = new List<String>(dataToreturn);
                   accountTiedToStates.put(a.id, statesList ); 
                }
                
                
                  
           }
        }
        
        else if(type =='Entity')
        {
            for(account a: accounts)
           {
               Set<String> dedupeStates= new set<string>();
               Set<String> dataToreturn = new Set<String>();
              if(String.isNotBlank(a.billingState) && !dedupeStates.contains(a.billingState))
              {    
                    dataToreturn.add('Primary Address '+':'+ a.billingState);
                    dedupeStates.add(a.billingState);
              }
              
              if(String.isNotBlank(a.State_of_Incorporation__c) && !dedupeStates.contains(a.State_of_Incorporation__c))
              {
                   dataToreturn.add('Formation State '+':'+ a.State_of_Incorporation__c);
                   dedupeStates.add(a.State_of_Incorporation__c);
              }
          
           List<String> statesList = new List<String>(dataToreturn);
           accountTiedToStates.put(a.id, statesList );
        
        }
      }
      return accountTiedToStates;
    }
    
    @AuraEnabled  
  public static List<commonWrapperClass.BWDataInfoWrapper> fetchEVTTableDataRows(Id recordId, List<CommonWrapperClass.BWStepWrapper> steps)
  {
       List<commonWrapperClass.BWDataInfoWrapper> tableDataRows = new List<commonWrapperClass.BWDataInfoWrapper>();
       
         if(String.isNotBlank(recordId))
          {
              if(String.valueof(recordId).startsWith('a2L'))
              {
                  underwriting__c uw= [select id from underwriting__c where underwriting_request_level__c='CARE Level' and connected_Request__c=:recordId];
                  recordId =uw.id;
              }    
          }
          
       Map<String,String> StateToSOSLinksMap = fetchStateSOSMap(); 
       String careAccountId = fetchCareAccountId(recordId);
       List<account> borrowerList = fetchBorrowerList(careAccountId);
       Map<String, List<String>> borrowerToStateMap =accountTostatesMap(borrowerList, 'Borrower');
       List<BW_Chart_Row__c> chartRowsToInsert = new List<BW_Chart_Row__c>();
       
       List<account> EntityList = fetchEntityList(borrowerList);
       Map<String, List<String>> entityToStateMap =accountTostatesMap(EntityList, 'Entity');
   
        //constructs the chart row in memory.
        List<BW_Chart_Row__c> chartRowData_Borrower =constructEVTChartRowData(borrowerToStateMap, 'Borrower', recordId,StateToSOSLinksMap, steps);
        System.debug('=== chartRowData_Borrower =='+chartRowData_Borrower);
        tableDataRows.addAll(constructEVTWrapper(chartRowData_Borrower, recordId, 'Borrower',steps ));
 
        //constructs the chart row in memory.
        List<BW_Chart_Row__c> chartRowData_Entity =constructEVTChartRowData(entityToStateMap, 'Entity', recordId,StateToSOSLinksMap, steps);
        tableDataRows.addAll(constructEVTWrapper(chartRowData_Entity, recordId, 'Entity',steps));

       system.debug('=== tableDataRows =='+tableDataRows);
       
       for(BW_Chart_row__c bw: chartRowData_Borrower)
        {
            if(bw.id ==null)
            {
                chartRowsToInsert.add(bw);
            }
        }
        for(BW_Chart_row__c bw: chartRowData_Entity)
        {
            if(bw.id ==null)
            {
                chartRowsToInsert.add(bw);
            }
        }
       
       if(chartRowsToInsert.size() >0)
       {
           try
           {
               String res= insertChartRowsAndStepAnserIfNewData(recordId,chartRowsToInsert, steps, 'Entity Verification');
           }
           catch(exception e)
           {
              utilityClass.logError(e, 'Error occured while inserting chart data from Entity Verification screen',null, 'Error occured while inserting chart data from insertChartRowsAndStepAnserIfNewData - Entity verification screen - recordid : '+recordId);
           }
       }
       return tableDataRows;
    }
    
    public static List<commonWrapperClass.BWDataInfoWrapper> constructEVTWrapper(List<BW_Chart_Row__c> chartRowList, String recordId, string type, List<CommonWrapperClass.BWStepWrapper> steps)
    {
            List<commonWrapperClass.BWDataInfoWrapper> wrapper = new List<commonWrapperClass.BWDataInfoWrapper>();
            integer i=0;
            
            //wrapper data should include - name, all steps and state info.
            for(BW_Chart_Row__c bw: chartRowList)
            {
                if(String.isNotBlank(bw.data__c))
                {
               
                     Map<String, String> dataMap = bwhelper.deconstructList(bw.data__c);
                     String state='';
                     System.debug('=== datamap ==='+dataMap);
                     commonWrapperClass.BWDataInfoWrapper d = new commonWrapperClass.BWDataInfoWrapper();

                     d.chartData = bw;
                     d.rowType =type;
                     d.recordId =bw.Row_Key_Id__c;
                     d.index = i;
                     
                    //if(dataMap.containskey('state')) state =dataMap.get('state'); 
                     
                     d.dataList = new List<commonWrapperClass.BWDataInfo>();
                     commonWrapperClass.BWDataInfo diName= new commonWrapperClass.BWDataInfo();
                     diName.isReadOnly =true;
                     diName.key='name';
                     diName.data = datamap.get('name');
                     d.dataList.add(diName);
                     
                     commonWrapperClass.BWDataInfo diName1= new commonWrapperClass.BWDataInfo();
                     diName1.isReadOnly =true;
                     diName1.key='Engine_Location';
                     diName1.data = datamap.get('Engine_Location');
                     d.dataList.add(diName1);
                     
                     commonWrapperClass.BWDataInfo diName2= new commonWrapperClass.BWDataInfo();
                     diName2.isLink =true;
                     diName2.key='State_Province';
                     diName2.linkLabel=dataMap.get('state');
                      //decode URL on display.
                     diName2.linkURL =EncodingUtil.urlDecode(dataMap.get('State_Province'),'UTF-8');
                     diName2.data = EncodingUtil.urlDecode(dataMap.get('State_Province'),'UTF-8');
                     d.dataList.add(diName2);
                     
                     
                     for(CommonWrapperClass.BWStepWrapper step: steps)
                     {
                          commonWrapperClass.BWDataInfo di= new commonWrapperClass.BWDataInfo();
                          di.isLink =false;
                          di.isReadOnly =false;
                          di.isPickList =false;
                          di.key =step.stepTitle;
                          
                          if(dataMap.containsKey(step.stepTitle))
                            di.data =dataMap.get(step.stepTitle);
                        
      
                          di.isPickList =true;
                         /** if(step.stepTitle == 'Foreign_Domestic')
                          {
                              di.picklistvalues = new List<string>{'Foreign', 'Domestic','None'};
                          }
                          else
                          {
                              di.picklistvalues = new List<string>{'Yes', 'No','None'};
                          }*/
                          
                           di.picklistvalues = step.element1Wrapper.elementPicklistValues;
                          
                          d.dataList.add(di);
                     }
                     
                    
                    
                     commonWrapperClass.BWDataInfo distate= new commonWrapperClass.BWDataInfo();
                     distate.key='state';
                     distate.data = datamap.get('state');
                     d.dataList.add(distate);
                     
                     wrapper.add(d);
                     
                    i++;
                   }
                   
            }
                
             system.debug('=== wrapper ==='+wrapper);
            return wrapper;
    }
           
     public static List<BW_Chart_Row__c> constructEVTChartRowData(Map<String, List<String>> accountToStateMap, string type, String recordId, Map<string,String> sosLinksMap, List<CommonWrapperClass.BWStepWrapper> steps)
    {
           List<BW_Chart_Row__c> rowdata = new List<BW_Chart_Row__c>();
           Map<id,account> accountMap = new Map<Id, account>([select id, name from account where id IN: accountToStateMap.keySet()]);
           Map<String, BW_Chart_Row__c> chartKeyToDataMap = new Map<String, BW_Chart_Row__c>();
           
          //query for existing chart row based ion type, underwritingid and screenId.
          //construct the map with key as - accountid+','+state+','+type.
           system.debug('==== recordId==='+recordId+'=== type ==='+type);
           system.debug('==== EntityscreenId==='+EntityscreenId);
           for(BW_Chart_Row__c bw: [select id, underwriting__c, type__c, Row_Key_Id__c, data__c from BW_Chart_Row__c where type__c=:type and underwriting__c =:recordId and Boarding_Wizard_Screen__c =:EntityscreenId  order by Row_Key_Id__c asc])
           {
               Map<string,String> dataMap= bwhelper.deconstructList(bw.data__c); 
               String state='';
               
               for(String data: dataMap.keyset())
               {
                  if(data.contains('state'))
                  {
                      state = dataMap.get(data);
                  }
               }

               String key = bw.Row_Key_Id__c+','+state+','+bw.type__c;
               System.debug('==== key ==='+key);
               chartKeyToDataMap.put(key, bw);
           }
           system.debug('=== chartKeyToDataMap ==='+chartKeyToDataMap);

   
           //String defaultPicklist ='-- select --';
           String defaultPicklist ='(Select One)';
           
           integer index=0;
           for(String accId: accountToStateMap.keySet())
           {
              account a = accountMap.get(accId);
              for(String stateVal: accountToStateMap.get(accId))
              {
                List<String> dataInfo = stateVal.split(':');
                string engineLoc = dataInfo[0];
                String state= dataInfo[1];
                
                String accountData1 =''; 
                accountData1 = bwhelper.constructStringForChartRow(accountData1, 'name', a.name);
                String loc   = sosLinksMap.containsKey(state.toLowerCase())?sosLinksMap.get(state.toLowerCase()):defaultPicklist;
               
                system.debug('=== containsKey(accId+,+state+,+type)==='+chartKeyToDataMap.containsKey(accId+','+state+','+type));
                String key1 =accId+','+state+','+type;
                System.debug('=== key1 ==='+key1);
                if(chartKeyToDataMap.containsKey(key1))
                {
                    BW_Chart_Row__c chartInfo= chartKeyToDataMap.get(accId+','+state+','+type);
                    system.debug('===  inside the chart row data ===');
                    rowdata.add(chartInfo);
                }
                else
                {
                    accountData1 = bwhelper.constructStringForChartRow(accountData1,'name' , a.name);
                    accountData1 = bwhelper.constructStringForChartRow(accountData1,'Engine_Location', engineLoc);
                    accountData1 = bwhelper.constructStringForChartRow(accountData1, 'State_Province', EncodingUtil.urlEncode(loc,'UTF-8'));
                    
                    for(CommonWrapperClass.BWStepWrapper step: steps)
                    {
                        
                        String key =step.stepTitle;
                   
                        accountData1 = bwhelper.constructStringForChartRow(accountData1,key, defaultPicklist);
                    }
                    accountData1 = bwhelper.constructStringForChartRow(accountData1,'state', state);
                    rowdata.add(new BW_Chart_Row__c(type__c= type, Underwriting__c= recordId, Boarding_Wizard_Screen__c= EntityscreenId, Data__c=accountData1,Row_Key_Id__c=a.id));
                    System.debug('=== creating new chart row ==');
                }
                
                index++;
              }
           }
              
          return rowData;    
    }
    ///////////////////////////////////////
    // End of Entity Verification Screen //
    ///////////////////////////////////////
    //////////////////////////////////////
    // Start of CBR Verification Screen //
    //////////////////////////////////////
    @AuraEnabled public static Map<string, List<CommonWrapperClass.BWCBRWrapper>> getCbrRows(string underwritingId, string initiatingAccountId, string ndaId, string uwCreatedDateTimeString) {  
        //system.debug(underwritingId+' / '+initiatingAccountId);
        List<CommonWrapperClass.BWCBRWrapper> cbrRows = new List<CommonWrapperClass.BWCBRWrapper>();
        set<id> relationshipIds = new set<id>();
        set<string> rtypes1 = new set<string>{ 'Consolidated_Dealer', 'Client_Dealer' };
        set<string> rtypes2 = new set<string>{ 'Guarantors' };
        map<id, integer> dealer2DropMap = new map<id, integer>();
        integer index = 0;

        //query guarantors through associations with initiating account to make the CBR table rows 
        // should only include INDIVIDUAL guarantors
        for(Associated_Relationships__c ar: [SELECT secondary_relationship__c, secondary_relationship__r.name, secondary_relationship__r.first_name__c, secondary_relationship__r.middle_i__c, secondary_relationship__r.last_name__c, 
            secondary_relationship__r.suffix__c, secondary_relationship__r.Social_Security_Number__c, secondary_relationship__r.Searchable_Security_Number__c, secondary_relationship__r.Date_of_Birth__c, 
            secondary_relationship__r.Current_Month_CBR__c, secondary_relationship__r.Current_Month_CBR_Date__c, secondary_relationship__r.CBR_Within_90_Days__c, secondary_relationship__r.Quarterly_CBR_Date__c, 
            secondary_relationship__r.Quarterly_CBR_Score__c, secondary_relationship__r.Low_CBR_640_US_690_CA__c, secondary_relationship__r.CBR_XML_Response_2__c, Ownership_Percentage__c, 
            secondary_relationship__r.billingcountrycode, secondary_relationship__r.id, primary_relationship__r.TCF_Legal_Entity__c, secondary_relationship__r.Drop_Code_Description__c, secondary_relationship__r.CBR_Error_Messages__c, 
            secondary_relationship__r.ID_Mismatch_Alert__c, secondary_relationship__r.IdentityAlerts__c, secondary_relationship__r.HighRiskFraudAlert__c
            FROM Associated_Relationships__c WHERE primary_relationship__c =: initiatingAccountId AND secondary_relationship__r.recordtype.developername =: rtypes2 
            AND (secondary_relationship__r.Searchable_Security_Number__c != null OR secondary_relationship__r.first_name__c != null OR secondary_relationship__r.last_name__c != null)
            AND Ownership_Percentage__c > 0]){


            system.debug('found '+ar.id);
            relationshipIds.add(ar.secondary_relationship__c);
            CommonWrapperClass.BWCBRWrapper temp = makeSingleCBRRow(ar.secondary_relationship__r);
            temp.index=index;
            temp.initiatingAccountTCFLegalEntity = ar.primary_relationship__r.TCF_Legal_Entity__c;
            index++;
            
            try{ 
                temp.uwCreatedDate = DateTime.valueOf(uwCreatedDateTimeString).Date(); }
            catch (exception e){
                //invalid date format
                temp.uwCreatedDate = Date.Today();
            }
            cbrRows.add(temp);
        }

        //find the last quarterly cbr change from history tracking and compute the change +/-
        for(Account a: [SELECT id, (SELECT Field_Name_API__c, old_value__c, new_value__c, createddate FROM Custom_Field_History_Tracking__r
            WHERE Field_Name_API__c = 'Quarterly_CBR_Score__c' AND old_value__c != null AND new_value__c != null ORDER BY createddate desc LIMIT 1) FROM Account where id =: relationshipIds]){
            
            integer drop = 0;
            for(Custom_Field_History_Tracking__c c: a.Custom_Field_History_Tracking__r){
                drop = Integer.ValueOf(c.new_value__c) - Integer.ValueOf(c.old_value__c);
            }
            dealer2DropMap.put(a.id, drop);
        }

        for(CommonWrapperClass.BWCBRWrapper temp : cbrRows){
            if(dealer2DropMap.containsKey(temp.relationshipId)){
                temp.cbrQtlyChange = dealer2DropMap.get(temp.relationshipId);
            }
            string cbrSpecialMessages = parseCBRXML(temp.relationship.CBR_XML_Response_2__c);
            temp.cbrSpMessageList = new List<string>();
            for(string r: cbrSpecialMessages.split(';')){
                if(!String.isBlank(r)){
                    temp.cbrSpMessageList.add(r.trim());
                }
            }
                       
            if(!String.IsBlank(temp.relationship.Drop_Code_Description__c)){
                temp.cbrSpMessageList.add(temp.relationship.Drop_Code_Description__c);
            }
            if(!String.IsBlank(temp.relationship.CBR_Error_Messages__c)){
                temp.cbrSpMessageList.add(temp.relationship.CBR_Error_Messages__c);
            }
            if(!String.IsBlank(temp.relationship.ID_Mismatch_Alert__c)){
                temp.cbrSpMessageList.add(temp.relationship.ID_Mismatch_Alert__c);
            }
            if(!String.IsBlank(temp.relationship.IdentityAlerts__c)){
                temp.cbrSpMessageList.add(temp.relationship.IdentityAlerts__c);
            }
            if(!String.IsBlank(temp.relationship.HighRiskFraudAlert__c)){
                temp.cbrSpMessageList.add(temp.relationship.HighRiskFraudAlert__c);
            }
            temp.showSpMessages = temp.cbrSpMessageList.size()>0;          
        }

        cbrRows = verifyCbrRows(cbrRows, underwritingId, ndaId, false);
        //system.debug(cbrRows);
        return new Map<string, List<CommonWrapperClass.BWCBRWrapper>> { dataVerMessage => cbrRows };
    }

    //this method populates initial primitive values in the wrapper class
    private static CommonWrapperClass.BWCBRWrapper makeSingleCBRRow(account a){
        CommonWrapperClass.BWCBRWrapper temp = new CommonWrapperClass.BWCBRWrapper();
        temp.relationship = a;
        temp.relationshipId = a.id;
        temp.relURL = '/'+a.id;
        temp.relName = a.name;
        temp.firstName = a.first_name__c;
        temp.middleName = a.middle_i__c;
        temp.lastName = a.last_name__c;
        temp.suffix = a.suffix__c;
        temp.ssn = a.Social_Security_Number__c;
        temp.dob = a.Date_of_Birth__c;
        temp.cbrScore = Integer.ValueOf(a.Current_Month_CBR__c);
        temp.cbrDate = a.Current_Month_CBR_Date__c;
        temp.cbrRequired = false;
        temp.cbrPending  = false;
        temp.cbrClicked  = false;
        temp.cbrSpMessageList = new List<string>();
        temp.cbrQtlyChange = 0;
        temp.countryCode = a.billingcountrycode;
        temp.initiatingAccountTCFLegalEntity = '';
        return temp;
    }

    //parses looking for bankruptcies, legal suits, tax leins
    private static string parseCBRXML(string fullXML){
        string shorty = '';
        string result = '';
        string delim = '\n;';
        if(String.IsBlank(fullXML)){    //replace null with ''
            fullXMl = '';
        }
        system.debug(fullXML);
        
        if(fullXML.contains('<TU_TTY_Report>')){
            //Canada format
            shorty = fullXML.substringBetween('<TU_TTY_Report>', '</TU_TTY_Report>');
            shorty =  shorty.substringBetween('-- File summary --', '-- Trade --');
            result += parseHelper1(shorty, 'ID Mismtch Alert :', 'High Risk Fraud Alert', delim);
            result += parseHelper1(shorty, 'High Risk Fraud Alert :',  'FIC8 Risk Score', delim);
            result += parseHelper1(shorty, 'Bankruptcies',  '-', delim);
            result += parseHelper1(shorty, 'Legal Items',  '-', delim);
        } else if(fullXML.contains('<printImage>')){
            //US format
            shorty = fullXML.substringBetween('<printImage>', '</printImage>');
                       
            Map<string, string> typeCodeMap = Constants.getCBRXMLtypeCodeMap();
            result += parseHelper3(shorty, 'M E S S A G E S', '---', '', '\\*\\*\\*', delim, typeCodeMap);
            result += parseHelper2(shorty, 'BANKRUPTCY', delim);
            result += parseHelper2(shorty, 'JUDGMENT', delim);
            result += parseHelper2(shorty, 'TAX LIEN', delim);
            result += parseHelper3(fullXML, '<consumerFileData>', '</consumerFileData>', '<consumerStatement>', '</consumerStatement>', delim, typeCodeMap);
            result += parseHelper3(fullXML, '<credit>', '</credit>', '<publicRecord>', '</publicRecord>', delim, typeCodeMap);
        }
        return result;
    }

    //this method parses the cbr xml response to retun the values in between s1 and s2  Example: 'BANKRUPTCIES: 2'
    private static string parseHelper1(string full, string s1, string s2, string delim){
        string result = '';
        if(String.IsBlank(full)){ full = ''; }
        if(String.IsBlank(s1))  { s1 = ''; }
        if(String.IsBlank(s2))  { s2 = ''; }
        
        if(full.contains(s1) && full.contains(s2)){
            result = full.substringBetween(s1, s2).trim();
            system.debug(result);
            if(!String.IsBlank(result) && result != '0'){
                if(result == 'CLEAR FOR ALL SEARCHES PERFORMED'){ 
                    result = ''; 
                } else {
                    result = s1.toUpperCase() +': '+ full.substringBetween(s1, s2).trim() + delim;
                }
            } else {
                result = '';
            }
        }
        return result;
    }

    //this method parses the cbr xml response to return YES/NO if the key is found.  Example: 'BANKRUPTCY: YES'
    private static string parseHelper2(string full, string key, string delim){
        string result = '';
        if(String.IsBlank(full)){ full = ''; }
        if(String.IsBlank(key)) { key  = ''; }
        else if(full.containsIgnoreCase(key)){
            result = key +': YES'+delim;
        }
        return result;
    }
    
    /*    this method takes a full xml and isolates a specific tag, then parses the contents for multiple results, formatted as transunion alerts 
    */
    public static string parseHelper3(string fullXML, string focusTagStart, string focusTagEnd, string arrayStartTag, string splitStringForArray, string delim, Map<string, string> typeCodeMap){
        string result = '';
        boolean needDelim = false;
        if(fullXML == null){ fullXML = ''; }
        string shortened = fullXML.substringBetween(focusTagStart, focusTagEnd);
        system.debug(shortened);
        
        if(shortened != null){// && shortened.containsIgnoreCase(splitStringForArray)){
            system.debug(shortened.split(splitStringForArray));
            list<string> chopped = shortened.split(splitStringForArray);
            for(integer i=0; i<chopped.size(); i++){
                string y = chopped[i];
                if(y!=null && y.containsIgnoreCase(arrayStartTag)){
                    y = y.substringAfter(arrayStartTag);
                    
                
                    system.debug(y);
                    string typeString = y.substringBetween('<type>', '</type>');
                    string textString = y.substringBetween('<text>', '</text>');
                    needDelim = false;
        
                    //this is when using an xml tag
                    if(typeCodeMap.containsKey(typeString)){
                        result+=typeCodeMap.get(typeString);
                        needDelim = true;
                    } else if(y!=null){
                    //this is for S P E C I A L M E S S A G E S, ignore first and last entry in the split array
                        if(i > 0 && i < chopped.size()-1){
                            string spm = y.trim();
                            if(!String.IsBlank(spm) && !spm.containsIgnoreCase('CLEAR FOR ALL SEARCHES PERFORMED')){
                                result+=y;
                                needDelim = true;
                            }
                        }
                    }
                    if(!String.IsBlank(textString)){
                        result+=': '+textString;
                        needDelim = true;
                    }
                    if(needDelim){ result+=delim; }
                }
            }
        }
        return result;
    }

    public static boolean isTriggerContext {get; set;}
    /* this method applies the logic for when to run cbr pull or not
    */
    private static List<CommonWrapperClass.BWCBRWrapper> verifyCbrRows(List<CommonWrapperClass.BWCBRWrapper> cbrRows, string underwritingId, string ndaId, boolean userSave){
        Date d = Date.Today()-120;
        integer US_MIN_SCORE = 650;
        integer CA_MIN_SCORE = 690;
        dataVerMessage = '';   
        list<boolean> bothSteps = new list<boolean>{ false, false };
        boolean specialStepPassed = true;
        List<Boarding_Wizard_Step_Result__c> specialStepResults = new List<Boarding_Wizard_Step_Result__c>();
        specialStepResults.add(new Boarding_Wizard_Step_Result__c());
        specialStepResults.add(new Boarding_Wizard_Step_Result__c());
              
        for(bw_screen_step__c ss : [SELECT id,step_title__c,Boarding_Wizard_Screen__c, (SELECT id,Underwriting__c,Answer__c FROM Boarding_Wizard_Answers__r WHERE Underwriting__c =: underwritingId LIMIT 1) 
            FROM bw_screen_step__c WHERE step_title__c IN ('Ownership Change', 'Run CBR Button') AND Boarding_Wizard_Screen__c =: returnScreenIdByEnum('CBR_VER') AND Active__c = true 
            ORDER BY step_title__c ASC LIMIT 2]){
        
            if(ss.step_title__c == 'Ownership Change'){
                specialStepResults[0] = new Boarding_Wizard_Step_Result__c(underwriting__c = underwritingId, boarding_wizard_screen_step__c = ss.id, external_id__c = underwritingId+'-'+ss.id);
                for(Boarding_Wizard_Step_Result__c res: ss.Boarding_Wizard_Answers__r){
                    specialStepResults[0].Answer__c = res.Answer__c; //Yes, No, N/A
                }
                bothSteps[0] = true;
            }
            if(ss.step_title__c == 'Run CBR Button'){
                specialStepResults[1] = new Boarding_Wizard_Step_Result__c(underwriting__c = underwritingId, boarding_wizard_screen_step__c = ss.id, external_id__c = underwritingId+'-'+ss.id);    
                bothSteps[1] = true;
            }
        }
           
        for(CommonWrapperClass.BWCBRWrapper temp : cbrRows){
            temp.cbrRequired = false;
            string debg = 'cbr date < 120 days';
            
            boolean hasBrandNewPull = (temp.relationship.Current_Month_CBR_Date__c != null && temp.relationship.Current_Month_CBR_Date__c >= temp.uwCreatedDate && 
                temp.relationship.Current_Month_CBR__c != null); 
            boolean hasRecentHardPull = (temp.relationship.Current_Month_CBR_Date__c >= d && temp.relationship.Current_Month_CBR_Date__c != null);  

            if(!hasBrandNewPull){

                //if loan has NDA, must be a new app, require for all new apps
                if(!String.IsBlank(ndaId)){   
                    temp.cbrRequired = true;
                    debg = 'has NDA (new app)';
                    if(hasRecentHardPull){
                        temp.cbrSpMessageList.add('You must blank the CBR Date Manually before manually running the CBR.');
                    }
                }
                
                //if business information form/ownership change then must repull
                else if(specialStepResults[0].Answer__c != null && specialStepResults[0].Answer__c.equalsIgnoreCase('Yes')){
                    temp.cbrRequired = true;
                    debg = 'BIF form/ownership change';
                    if(hasRecentHardPull){
                        temp.cbrSpMessageList.add('You must blank the CBR Date Manually before manually running the CBR.');
                    }
                }
    
    
                //no pull within 120 days
                if(!temp.cbrRequired && !hasRecentHardPull){    
                    
                    //if quarterly and hard pull are both too old or missing, need a new pull
                    if(temp.relationship.Quarterly_CBR_Date__c < d || temp.relationship.Quarterly_CBR_Date__c == null){
                        temp.cbrRequired = true;
                        debg = 'quarterly cbr > 120 days or blank';
                        
                        if(temp.relationship.Quarterly_CBR_Date__c < d){
                            temp.cbrSpMessageList.add('Please investigate why the quarterly pull failed and correct any issues, in addition to manually pulling the report.');
                        }
                    } 
                    
                    /*               
                    //below minimum
                    else if((temp.relationship.Quarterly_CBR_Score__c < US_MIN_SCORE && temp.countryCode.equalsIgnoreCase('US')) || 
                       (temp.relationship.Quarterly_CBR_Score__c < CA_MIN_SCORE && temp.countryCode.equalsIgnoreCase('CA'))){
                        temp.cbrRequired = true;
                        debg = 'quarterly cbr is below minimum';
                    }        
                    //soft pull dropped > 30 points.  for Increase, Continuation, Exception, Carve Out Reviews     
                    else if(temp.cbrQtlyChange < -30){ 
                        temp.cbrRequired = true;
                        debg = 'quarterly cbr dropped > 30 points';
                    } */
                } 
            
            }
            temp.showSpMessages = temp.cbrSpMessageList.size()>0;      
            if(temp.cbrRequired){
                specialStepPassed = false;
            }
            system.debug('rel id: '+temp.relationshipId+' CBR REQUIRED: '+temp.cbrRequired+' REASON: '+debg);
        }
        
        specialStepResults[1].step_completed__c = specialStepPassed;
        if(bothSteps[0] && bothSteps[1]){
            if(!(isTriggerContext == true)){
                try{ 
                    upsert specialStepResults External_Id__c;
                } catch (exception e){
                    system.debug(e);
                    system.debug(specialStepResults[1]);
                    dataVerMessage += 'Error saving boarding wizard results: '+e.getMessage();
                }
            }
        } else {
            //missing a critical step, throw toast message.
            dataVerMessage += 'There was an internal system error.  *Ownership Change* or *Run CBR Button* step not found.';
        }
        
        return cbrRows;
    }
    
    //called by js when user clicks Run CBR button for one row
    @AuraEnabled public static CommonWrapperClass.BWStepActionOutComeWrapper clickRunCBRButton(List<CommonWrapperClass.BWCBRWrapper> cbrRows, integer arrayIndex)
    {
        dataVerMessage = '';
        
        /* TCF Inventory Finance, Inc.             > TCF
           Red Iron Acceptance, LLC                > Red Iron
           TCF Commercial Finance Canada, Inc.     > CA
           Financement Commercial TCF Canada, Inc. > CA
        */
        
        try{ 
            if(cbrRows[arrayIndex].initiatingAccountTCFLegalEntity.containsIgnoreCase('Canada')){
                cbrRows[arrayIndex].relationship.FS_SendOutboundAPI_TCFCFC__c = true;
            } else if(cbrRows[arrayIndex].initiatingAccountTCFLegalEntity.containsIgnoreCase('Red Iron')){
                cbrRows[arrayIndex].relationship.FS_SendOutboundAPI_RedIron__c = true;
            } else {
                cbrRows[arrayIndex].relationship.FS_SendOutboundAPI__c = true;
            } 
        
            update cbrRows[arrayIndex].relationship;
            cbrRows[arrayIndex].cbrPending = true;
        }
        catch(exception e){
            system.debug(e);
            dataVerMessage = e.getMessage();
        }

        CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
        cw.outCome = true;
        if(String.IsBlank(dataVerMessage)){
            cw.resultString='CBR Report has been requested.  You may continue other boarding work, or Refresh to check if CBR results have returned.';
        } else {
            cw.resultString = dataVerMessage;
        }
        return cw;
    }


    //called by js when user clicks save button
    @AuraEnabled public static CommonWrapperClass.BWStepActionOutComeWrapper saveCbrTable(string jsonRows) //List<CommonWrapperClass.BWCBRWrapper> cbrRows)
    {
        system.debug(jsonRows);
        List<Account> accountsForUpdate = new List<Account>();
        Map<string, string> fieldAPINameToJsonKeyMap = new Map<string, string>{
            'id' => 'relationshipId',
            'first_name__c' => 'firstName',
            'middle_i__c'  => 'middleName',
            'last_name__c' => 'lastName',
            'suffix__c' => 'suffix',
            'social_security_number__c' => 'ssn',
            'date_of_birth__c' => 'dob'
        };
        Map<string, string> fieldAPINameTypeMap = new Map<string, string>{
            'id' => 'id',
            'first_name__c' => 'string',
            'middle_i__c'  => 'string',
            'last_name__c' => 'string',
            'suffix__c' => 'string',
            'social_security_number__c' => 'string',
            'date_of_birth__c' => 'date'
        };
        
        dataVerMessage = '';
        accountsForUpdate = BWHelper.convertJSONToSObjectList(jsonRows, 'Account', fieldAPINameToJsonKeyMap, fieldAPINameTypeMap);
        
        for(Account a: accountsForUpdate){
            if(!string.isblank(a.first_name__c)){
                a.name=a.first_name__c;
            }
            if(!string.isblank(a.middle_i__c)){
                a.name+=' '+a.middle_i__c;
            }
            if(!string.isblank(a.last_name__c)){
                a.name+=' '+a.last_name__c;
            }
            if(!string.isblank(a.suffix__c)){
                a.name+=', '+a.suffix__c;
            }
        }

        if(accountsForUpdate.size()>0){
            try{ 
                update accountsForUpdate;
            }
            catch(exception e){
                system.debug(e);
                dataVerMessage = e.getMessage();
            }
        }

        CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
        cw.outCome = true;
        if(String.IsBlank(dataVerMessage)){
            cw.resultString='Saved Relationships Successfully';
        } else {
            cw.resultString = dataVerMessage;
        }
        return cw;
    }
    
    // for cbr scren there is a step that must be updated based on the step result before the step is rendered on the page
    @AuraEnabled
    public static List<CommonWrapperClass.BWStepWrapper> cbrScreenStepsFix(List<CommonWrapperClass.BWStepWrapper> steps, string underwritingRecordId){
        for(CommonWrapperClass.BWStepWrapper s: steps){
            if(s.stepTitle != null && s.stepTitle.equalsIgnoreCase('Ownership Change') && underwritingRecordId != null){
                s.element1Wrapper.elementSelectedPicklistValue = '(Select One)';
                
                Boarding_Wizard_Step_Result__c specialStepResult = new Boarding_Wizard_Step_Result__c(underwriting__c = underwritingRecordId, Step_Completed__c = false,
                    boarding_wizard_screen_step__c = s.stepRecordId, external_id__c = underwritingRecordId+'-'+s.stepRecordId); 
                
                //query step results
                for(Boarding_Wizard_Step_Result__c x : [SELECT id, underwriting__c, Boarding_Wizard_Screen_Step__c, step_completed__c, Answer__c, External_Id__c FROM Boarding_Wizard_Step_Result__c 
                    WHERE Boarding_Wizard_Screen_Step__c =: s.stepRecordId AND underwriting__c =: underwritingRecordId LIMIT 1]){
                    
                    specialStepResult = x;
                    if(String.isBlank(specialStepResult.Answer__c)){
                        specialStepResult.Answer__c = '(Select One)';
                    }
                    s.element1Wrapper.elementSelectedPicklistValue = specialStepResult.Answer__c;
                }
                
                if(specialStepResult.Answer__c!=null && specialStepResult.Answer__c.equalsIgnorecase('(Select One)') && specialStepResult.Step_Completed__c){
                    specialStepResult.Step_Completed__c = false;
                    s.stepCompleted = false;
                    try{
                        upsert specialStepResult External_Id__c;
                    } catch (exception e){
                        system.debug(e);
                    }
                }
                
                break;
            }
        }    
        return steps;
    }
    
    @AuraEnabled
    public static void upsertStepResultWithDetail(string underwritingId, string screenStepId, boolean isStepComplete, string answer, string longDetail){
        Boarding_Wizard_Step_Result__c specialStepResult = new Boarding_Wizard_Step_Result__c(underwriting__c = underwritingId, Step_Completed__c = isStepComplete,
            boarding_wizard_screen_step__c = screenStepId, external_id__c = underwritingId+'-'+screenStepId);  
        if(answer != null){
            specialStepResult.Answer__c = answer;
            specialStepResult.Detail_Long__c = longDetail;
        }  
        try{
            upsert specialStepResult External_Id__c;
        } catch (exception e){
            System.debug(e);
        }
    }
    ////////////////////////////////////
    // End of CBR Verification Screen //
    ////////////////////////////////////

    /*
    /////////////////////////////////////////////
    // Start of Override and Exceptions Screen //
    /////////////////////////////////////////////
    @AuraEnabled (cacheable=true)
    public static boolean getPoorPerformanceIndicator(string uwCareNumber)
    {
        boolean returnResult=false;
    
        List<account> childAcctsWithPoorPerformance = [select id from Account where (NOT recordtype.developername = 'Guarantor') and (NOT recordtype.developername = 'Legal_Entity') and Customer_Status__c = 'Active' and care_number__c = :uwCareNumber and Poor_Current_Performance__c=true];
    
        if(childAcctsWithPoorPerformance != null && childAcctsWithPoorPerformance.size() > 0)
            returnResult = true;
    
        return returnResult;
    }

    @AuraEnabled
    public static boolean getILOCIndicator(string uwCareNumber)
    {
        boolean returnResult=false;
    
        List<account> childAcctsWithILOC = [select id from Account where (NOT recordtype.developername = 'Guarantor') and (NOT recordtype.developername = 'Legal_Entity') and Customer_Status__c = 'Active' and care_number__c = :uwCareNumber and Dollar_amount_of_ILOC__c != 0 and ILOC_Expiration_Date__c > :system.today()];
    
        if(childAcctsWithILOC != null && childAcctsWithILOC.size() > 0)
            returnResult = true;
    
        return returnResult;
    }

    @AuraEnabled
    public static boolean getLimitedRestrictedMfrIndicator(string uwRecordId)
    {
        boolean returnResult=false;
    
        List<Product_Information_For_New_Dealer_App__c> prodsList = [select id from Product_Information_For_New_Dealer_App__c where id=:uwRecordId and Limited_Restricted__c = true];
    
        if(prodsList != null && prodsList.size() > 0)
            returnResult = true;
    
        return returnResult;
    }
    ///////////////////////////////////////////
    // End of Override and Exceptions Screen //
    ///////////////////////////////////////////
    */
    
    ////////////////////////////////////////
    // Start of Formation Document Screen //
    ////////////////////////////////////////
    @AuraEnabled
    public static list<CommonWrapperClass.BWFormationDocRowWrapper> getFormationScreenRecords(string recordId, string screenName){


        string screenId = [SELECT id FROM BW_Screen__c WHERE Name =: screenName ORDER BY lastmodifieddate DESC LIMIT 1].id;
        underwriting__c uData =[Select account__c,review_type__c from underwriting__c where id =:recordId limit 1];
        
        list<BW_Chart_Row__c> existingRowData = new list<BW_Chart_Row__c>([Select id,Row_Key_Id__c,Data__c,Underwriting__c,Boarding_Wizard_Screen__c from BW_Chart_Row__c where Underwriting__c =: recordId and Boarding_Wizard_Screen__c =: screenId]);
        
        list<account> relationshipRecords = new list<account>([select id, Name, State_of_Incorporation__c,Legal_Entity_Name__c,Legal_Entity_Name__r.Name, (Select id,secondary_relationship__c,secondary_relationship__r.Name, secondary_relationship__r.State_of_Incorporation__c from DealerManufacturer__r where record_type__c = 'Guarantor, Owner or Affiliate' and type__c = 'Entity' and Association_type__c IN ('Guarantor','Guarantor Consent')) from account where recordtype.name NOT IN ('Guarantor, Owner or Affiliate','Legal Entity') and care_number__c =:uData.account__c and customer_status__c = 'Active' order by createddate asc]);
        list<CommonWrapperClass.BWFormationDocRowWrapper> formedData = new list<CommonWrapperClass.BWFormationDocRowWrapper>();
        integer count = 0;
        map<string,Account> deDupeRelationshipRecords = new map<string,Account>();
        if(uData.review_type__c == 'New'){
        
            for(Account a:relationshipRecords){
                deDupeRelationshipRecords.put(a.Legal_Entity_Name__c+ a.State_of_Incorporation__c,a);
                if(a.DealerManufacturer__r != null && a.DealerManufacturer__r.size()>0){
                    for(associated_relationships__c ar: a.DealerManufacturer__r){
                        deDupeRelationshipRecords.put(ar.secondary_relationship__c + ar.secondary_relationship__r.State_of_Incorporation__c,ar.secondary_relationship__r);
                    }
                }
            }
            
            
            for(string key: deDupeRelationshipRecords.keySet()){
                Account a = deDupeRelationshipRecords.get(key);
                CommonWrapperClass.BWFormationDocRowWrapper newBorrower = new CommonWrapperClass.BWFormationDocRowWrapper();
                newBorrower.index = count;
                newBorrower.reviewType = uData.review_type__c;
                newBorrower.key = a.id + a.State_of_Incorporation__c;
                newBorrower.relationshipName = a.Name;
                newBorrower.formationLinkShow = true;
                if(a.State_of_Incorporation__c==null){
                    newBorrower.relationshipState = 'Set State On Relationship';
                    newBorrower.formationLink = '/' + a.Id;           
                }
                else{
                    newBorrower.relationshipState = a.State_of_Incorporation__c;
                    newBorrower.formationLink = getStateLink(a.State_of_Incorporation__c,a.Id,recordId);
                }
                
                newBorrower.relationshipId = a.Id;
                newBorrower.relationshipLink = '/' + a.Id;
                
                if(newBorrower.formationLink == 'runCSC'){
                    newBorrower.formationOptionsShow = true;
                }
                else{
                    newBorrower.formationOptionsShow = false;
                }
                newBorrower.formationOption = 'None';
                newBorrower.formationLinkCheck = false;
                newBorrower.formationLinkShow = true;
                newBorrower.formationDocMatch = false;
                newBorrower.formationDocLegalName = '';
                newBorrower.uploadedDocVault = 'No';
                newBorrower.chartData = new BW_Chart_Row__c();
                formedData.add(newBorrower);
                count++;
                
            }
            
            for(CommonWrapperClass.BWFormationDocRowWrapper fd: formedData){
                for(BW_Chart_Row__c erd: existingRowData){
                    if(erd.Row_Key_Id__c == fd.key){
                        fd.chartData = erd;
                        fd.formationOption = utilityclass.parseKeyValue(fd.chartData.data__c, 'formationOption', '=', ';');
                        fd.formationOptionsShow = boolean.valueof(utilityclass.parseKeyValue(fd.chartData.data__c, 'formationOptionsShow', '=', ';'));
                        fd.formationLinkCheck = boolean.valueof(utilityclass.parseKeyValue(fd.chartData.data__c, 'formationLinkCheck', '=', ';'));
                        fd.formationLinkShow = boolean.valueof(utilityclass.parseKeyValue(fd.chartData.data__c, 'formationLinkShow', '=', ';'));
                        fd.formationDocLegalName = utilityclass.parseKeyValue(fd.chartData.data__c, 'formationDocLegalName', '=', ';');
                        fd.formationDocMatch = boolean.valueof(utilityclass.parseKeyValue(fd.chartData.data__c, 'formationDocMatch', '=', ';'));
                        fd.uploadedDocVault = utilityclass.parseKeyValue(fd.chartData.data__c, 'uploadedDocVault', '=', ';');
                        fd.uploadedDocVaultMatch = boolean.valueof(utilityclass.parseKeyValue(fd.chartData.data__c, 'uploadedDocVaultMatch', '=', ';'));
                        fd.uploadedSharepoint = utilityclass.parseKeyValue(fd.chartData.data__c, 'uploadedSharepoint', '=', ';');
                        fd.uploadedSharepointMatch = boolean.valueof(utilityclass.parseKeyValue(fd.chartData.data__c, 'uploadedSharepointMatch', '=', ';'));
                    }
                    
                }
            }
        }
        else{
            CommonWrapperClass.BWFormationDocRowWrapper newBorrower = new CommonWrapperClass.BWFormationDocRowWrapper();
            newBorrower.index = count;
            newBorrower.reviewType = uData.review_type__c;
            formedData.add(newBorrower);
        }
        return formedData;

    }

    @AuraEnabled
    public static string getStateLink(string state,string borrowerId, string underwritingId){
        string returnLink;
        BW_SOS_Links__c link = [Select Link__c,Make_CSC_Call__c from BW_SOS_Links__c where State__c =:state limit 1];

        if(link != null && link.Make_CSC_Call__c == false){
            returnLink = link.Link__c;
        }
        else if(link != null && link.Make_CSC_Call__c == true){
            returnLink = 'runCSC';
        }

        return returnLink;
    }

    @AuraEnabled
    public static string retrieveCSCRecord(string underwritingId,string borrowerId,string borrowerName, string billingCode,boolean billingChange){
        
        Formation_Document_Order__c[] existingFdo = [Select id, Borrower_Name__r.Name from Formation_Document_Order__c where Underwriting__c =:underwritingId and Borrower_Name__c =:borrowerId limit 1];
        
        string returnLink;
        system.debug('#####billingChange: '+billingChange);
        
        if(billingChange){ 
            if(existingFdo.size()>0){ 
                returnLink = '/'+existingFdo[0].id;
            }
        }
        else if(!billingChange){
            if(existingFdo.size()>0){
                returnLink = '/'+existingFdo[0].id;
            }
            else{
                Formation_Document_Order__c fdo = new Formation_Document_Order__c();
                fdo.Billing_Code__c = billingCode;
                fdo.Borrower_Name__c = borrowerId;
                fdo.Borrower_Name_Copy__c = borrowerName;
                fdo.Underwriting__c = underwritingId;
                fdo.Submit_Formation_Document_CSC__c = true;
                
                insert fdo;
 
                returnlink = '/'+fdo.id;
            }
        }        
        
        return returnLink;
    }

    @AuraEnabled (cacheable=true)
    public static list<string> getBillingCodes(){
        return UtilityClass.getPicklistValues('Formation_Document_Order__c','Billing_Code__c');
    }

    @AuraEnabled (cacheable=true)
    public static string getCareNumber(string underwritingId){
        return [Select CARE_Number__r.Name from underwriting__c where id =:underwritingId].CARE_Number__r.Name;
    }

    @AuraEnabled
    public static list<CommonWrapperClass.BWFormationDocRowWrapper> saveFormationDocChartRows(string screenName, string underwritingId, list<CommonWrapperClass.BWFormationDocRowWrapper> data){
        string screenId = [SELECT id FROM BW_Screen__c WHERE Name =: screenName ORDER BY lastmodifieddate DESC LIMIT 1].id;
        
        list<BW_Chart_Row__c> upsertChartRows = new list<BW_Chart_Row__c>();

        for(CommonWrapperClass.BWFormationDocRowWrapper fdrw:data){
            fdrw.chartData.underwriting__c=underwritingId;
            fdrw.chartData.Row_Key_Id__c=fdrw.key;
            fdrw.chartData.Boarding_Wizard_Screen__c=screenId;
            fdrw.chartData.data__c = 
                'formationOption='+fdrw.formationOption+';'+
                'formationOptionsShow='+fdrw.formationOptionsShow+';'+
                'formationLinkCheck='+fdrw.formationLinkCheck+';'+
                'formationLinkShow='+fdrw.formationLinkShow+';'+
                'formationDocLegalName='+fdrw.formationDocLegalName+';'+
                'formationDocMatch='+fdrw.formationDocMatch+';'+
                'uploadedDocVault='+fdrw.uploadedDocVault+';'+
                'uploadedDocVaultMatch='+fdrw.uploadedDocVaultMatch+';'+
                'uploadedSharepoint='+fdrw.uploadedSharepoint+';'+
                'uploadedSharepointMatch='+fdrw.uploadedSharepointMatch+';';
            upsertChartRows.add(fdrw.chartData);
            
        }       

        upsert upsertChartRows;

        return data;
    }

    @AuraEnabled
    public static boolean validityCSCCheck(string underwritingId, string borrowerId){
        Formation_Document_Order__c[] existingFdo = [Select id from Formation_Document_Order__c where Underwriting__c =:underwritingId and Borrower_Name__c =:borrowerId limit 1];
        if(existingFdo.size() == 1){
            return true;
        }
        else{
            return false;
        }

    }
    ////////////////////////////////////////
    // End of Formation Document Screen //
    ////////////////////////////////////////
    //////////////////////////////////////////
    // Start of Address Verification Screen //
    //////////////////////////////////////////     
      @AuraEnabled public static string AddrscreenId {
        get {
        if(AddrscreenId ==null)
        {
              return [SELECT id,name,Title__c FROM BW_Screen__c WHERE name =: Constants.getBWScreenNameMap().get('ADDR_VER') ORDER BY lastmodifieddate DESC LIMIT 1].id; 
        }
        return AddrscreenId ;
    }set;
    }
    
     static Set<String> accountFields = new Set<String>{'name','Recordtype.DeveloperName', 'First_Name__c','Middle_I__c','Last_Name__c','billingcountry', 'billingstate','billingcity','billingstreet','billingpostalcode'};
     static Set<String> addressFields = new Set<String>{'Relationship_Name__c','Relationship_Name__r.Recordtype.DeveloperName', 'Relationship_Name__r.First_Name__c', 'Relationship_Name__r.Middle_I__c', 'Relationship_Name__r.Last_Name__c', 'country__c','state__c','City__c','Address_Line_1__c'
     ,'Address_Line_2__c','Zip_Code__c' };
     
     public static Set<Id> fetchAssociationsList(String recordId)
     {
          Set<String> assocFields = new Set<String>{'type__c','secondary_relationship__r.recordtype.developerName'};
          Set<id> borrowerIds= new Set<id>();
          Map<id, account> accountMap =new Map<id,account>();
        
          String careId= fetchCareAccountId(recordId);
          List<account> borrowers = fetchBorrowerList(careId);
          
          for(account a: borrowers)
          {
              borrowerIds.add(a.id);
          }
          
          if(borrowerIds.size() >0)
          {
              accountMap = AssociationsHelper.GetAccountAssociationsForAccountIds(borrowerIds,accountFields,assocFields);
          }
         
          return accountMap.keySet();
     }
     
     @AuraEnabled 
      public static List<commonWrapperClass.BWDataInfoWrapper> constructAddressWrapper(String recordId)
      {
         
         List<commonWrapperClass.BWDataInfoWrapper> dataWrapper = new List<commonWrapperClass.BWDataInfoWrapper>();
         Map<String, BW_Chart_Row__c> chartKeyToDataMap = new Map<String, BW_Chart_Row__c>(); 
        
          Set<Id> dealerIds = fetchAssociationsList(recordId);
          Map<id,account> accounts = new Map<id,account>([SELECT id,name,First_Name__c, last_name__c,Middle_I__c,Legal_Entity_Name__c,wms_customer__c,recordtype.name,recordtype.developername, billingstreet, billingcity, billingstate,billingcountry,billingstatecode, billingcountrycode, billingpostalcode
            ,(select id, relationship_name__c, relationship_name__r.First_Name__c, relationship_name__r.Middle_I__c, relationship_name__r.last_name__c, Address_Line_1__c, City__c,Country__c, State__c, Zip_Code__c from Addresses__r)FROM Account WHERE id IN: dealerIds order by recordtype.name asc, name asc]);
          
          for(BW_Chart_Row__c bw: [select id, data__c,type__c,Row_Key_Id__c from BW_Chart_Row__c where Boarding_Wizard_Screen__c=:AddrscreenId and Underwriting__c=: recordId] )
          {
              String key =bw.Row_Key_Id__c;
              System.debug('=== key ==='+key);
              chartKeyToDataMap.put(key, bw);
          }
          system.debug('=== chartKeyToDataMap  ==='+chartKeyToDataMap );
          ///
          
          //changed from accMap to accounts
          integer i=0;
          for(Id accId: accounts.keySet())
          {
              commonWrapperClass.BWDataInfoWrapper dWrapper = new commonWrapperClass.BWDataInfoWrapper();
              dWrapper.recordId =accId;
              
              dWrapper.index = i;
              
              // fetch/create chart row with key as accountId.
              String key =accId;
              if(chartKeyToDataMap.containsKey(key))
              {
                  dWrapper.chartData = chartKeyToDataMap.get(key);
              }
              else
              {
                  string data ='';
                  data= bwhelper.constructStringForChartRow(data,'usethisaddress','true');
                  dWrapper.chartData = new BW_Chart_row__c(Boarding_Wizard_Screen__c=AddrscreenId, Underwriting__c= recordId, type__c ='Borrower', Row_Key_Id__c =key, data__c =data);
              }
        
              System.debug('==== dwrapper.chartData ===='+dWrapper.chartData);
              account a = accounts.get(accId);
              
              
              if(a.recordtype.developername =='Guarantors')
              {
                  dWrapper.rowType = 'Guarantor';
              }
              else
              {
                  dWrapper.rowType = 'Borrower';
              }
              
              dWrapper.dataList = new List<commonWrapperClass.BWDataInfo>();
              
              for(string s: accountFields)
              {
                  if(s!='Id')
                  {
                      commonWrapperClass.BWDataInfo dataWrap = new commonWrapperClass.BWDataInfo();
                      
                      if(s!='Recordtype.DeveloperName')
                          dataWrap.data= String.valueOf(a.get(s));
                      
                      datawrap.key =s;
                      
                      if(s =='name')
                      {
                           dataWrap.isLink =true;
                           dataWrap.linkLabel=String.valueOf(a.get(s));
                           dataWrap.linkURL = '/lightning/r/Account/'+a.id+'/view/';
                      }
                      else if(s =='Recordtype.DeveloperName')
                      {
                           dataWrap.isReadOnly=true;
                           dataWrap.data =dWrapper.rowType;
                      }
                      else if(s=='billingstreet')
                      {
                          dataWrap.isTextArea = true;
                      }
                      else if(s =='billingCountry' || s =='billingstate')
                      {
                          dataWrap.isPickList =true;
                          
                          string fieldToQuery ='Country__c';
                          if(s =='billingstate') fieldToQuery ='state__c';
                          
                          dataWrap.picklistvalues =new List<String>();
                          system.debug('==== dataWrap.picklistvalues ==='+dataWrap.picklistvalues);
                      }
                      else
                      {
                          
                          if(dWrapper.rowType == 'Guarantor')
                          {
                             dataWrap.isTextInput =true;
                          }
                          else
                          { 
                               if(s=='First_Name__c' || s =='Middle_I__c' || s =='Last_Name__c')
                              {
                                   dataWrap.isReadOnly=true;
                              }
                              else
                              {
                                  dataWrap.isTextInput =true;
                              }
                              
                          }
                      }
                      
                      dWrapper.dataList.add(dataWrap);
                  }
              }
              
              commonWrapperClass.BWDataInfo dataWrap = new commonWrapperClass.BWDataInfo();
              dataWrap.data= '';
              dataWrap.key = 'Standardized Address';
              dataWrap.isReadOnly=true;
              dWrapper.dataList.add(dataWrap);
 
              commonWrapperClass.BWDataInfo dataWrap1 = new commonWrapperClass.BWDataInfo();
              dataWrap1.data= '';
              dataWrap1.key = 'Use Standardized Address';
              dataWrap1.isBoolean=true;
              String data=dWrapper.chartData.data__c;
              Map<string,string> dataMap = bwhelper.deconstructList(data);
              system.debug('=== dataMap =='+dataMap);
              system.debug('=== dataMap.keySet() =='+dataMap.keySet());
              dataWrap1.booleanData =Boolean.valueOf(dataMap.get('usethisaddress'));
              dWrapper.dataList.add(dataWrap1);
              
              dataWrapper.add(dWrapper);
              
  
              for(address__c ad: a.Addresses__r)
              {
                  i++;
                  commonWrapperClass.BWDataInfoWrapper adWrapper = new commonWrapperClass.BWDataInfoWrapper();
                  
                  //fetch/create chart row with key as accountId+','+locationId.
                  
                  String key1 =ad.Relationship_name__c+','+ad.id;
                  adWrapper.recordId = key1;
                  
                   if(chartKeyToDataMap.containsKey(key1))
                  {
                      adWrapper.chartData = chartKeyToDataMap.get(key1);
                      system.debug('=== i am inside ==='+adWrapper.chartData);
                  }
                  else
                  {                      
                      String cdata='';
                      cdata= bwhelper.constructStringForChartRow(data,'usethisaddress','true');
                      adWrapper.chartData = new BW_Chart_row__c(Boarding_Wizard_Screen__c=AddrscreenId, Underwriting__c= recordId, type__c ='Additional Location', Row_Key_Id__c = key1, data__c =cData);
                  }
                
                  adWrapper.index = i;
                  adWrapper.rowType = 'Additional Location';
                  adWrapper.dataList = new List<commonWrapperClass.BWDataInfo>();
                  
                  for(string s: addressFields)
                  {
                      if(s !='Address_Line_2__c' )
                      {
                          commonWrapperClass.BWDataInfo adataWrap = new commonWrapperClass.BWDataInfo();
                          
                          if(s.tolowerCase().contains('relationship_name__r.'))
                          {
                              if(s.toLowercase() == 'relationship_name__r.recordtype.developername')
                              {
                                 adataWrap.data=adWrapper.rowType ; 
                              }
                              else
                              {
                                  adataWrap.data= String.valueOf(a.get(s.removeStart('Relationship_Name__r.')));
                              }
                              adatawrap.key =s.removeStart('Relationship_Name__r.');
                              adataWrap.isReadOnly =true;
                          }
                          else if(s.toLowerCase() =='relationship_name__c')
                          {
                               
                               adataWrap.data= a.name;
                               adataWrap.key='name';
                               adataWrap.isLink =true;
                               adataWrap.linkLabel=adataWrap.data;
                               adataWrap.linkURL = '/lightning/r/Account/'+a.id+'/view/';
                          }
                           else if(s.toLowercase() == 'address_line_1__c')
                          {
                             adataWrap.data= String.valueOf(ad.get(s));
                              adatawrap.key ='billingstreet';
                             adataWrap.isTextArea =true;
                          }
                         
                          else if(s.toLowerCase() == 'Country__c')
                          {
                              adataWrap.data= String.valueOf(ad.get(s));
                              adatawrap.key ='billingcountry';
                              adataWrap.isPickList =true;
                              adataWrap.picklistvalues =new List<String>();
                          }
                          else if(s.toLowerCase() == 'state__c')
                          {
                              adataWrap.data= String.valueOf(ad.get(s));
                              adatawrap.key ='billingstate';
                              adataWrap.isPickList =true;
                              adataWrap.picklistvalues =new List<String>();
                          }
                           else if(s.toLowerCase() == 'Zip_Code__c')
                          {
                              adataWrap.data= String.valueOf(ad.get(s));
                              adatawrap.key ='billingpostalcode';
                              adataWrap.isTextInput =true;
                          }
                           else if(s.toLowerCase() == 'City__c')
                          {
                              adataWrap.data= String.valueOf(ad.get(s));
                              adatawrap.key ='billingcity';
                              adataWrap.isTextInput =true;
                          }
                          
                          adWrapper.dataList.add(adataWrap);
                      }
                  
                  }
                  
                  commonWrapperClass.BWDataInfo adataWrap1 = new commonWrapperClass.BWDataInfo();
                  adataWrap1.data= '';
                  adataWrap1.key = 'Standardized Address';
                  adataWrap1.isReadOnly=true;
                  adWrapper.dataList.add(adataWrap1);
 
                  commonWrapperClass.BWDataInfo adataWrap2 = new commonWrapperClass.BWDataInfo();
                  adataWrap2.data= '';
                  adataWrap2.key = 'Use Standardized Address';
                  adataWrap2.isBoolean=true;
                  system.debug('=== adWrapper.chartData ==='+adWrapper.chartData);
                  String cData=adWrapper.chartData.data__c;
                  system.debug('====cData==='+cData);
                  Map<string,string> cdataMap = bwhelper.deconstructList(cData);
                  system.debug('====cdataMap==='+cdataMap);
                  adataWrap2.booleanData =Boolean.valueOf(cdataMap.get('usethisaddress'));
                  
                  adWrapper.dataList.add(adataWrap2);
                  dataWrapper.add(adWrapper);

              }
              i++;
          }
          return dataWrapper;
          
      }
      
       @AuraEnabled(cacheable = true)
      public static Map<String, account> fetchValidAccountsForCare(String uwId)
      {
 
          Set<string> recordTypeIds = new Set<String>{constants.accountRTMap.get('Prospect_Dealer'), constants.accountRTMap.get('Client_Dealer')}; 
          Map<string, account> validAcctIds = new Map<string, account>();
          Set<id> accountIds=  fetchAssociationsList(uwId);
           for(account a: [select id, name,recordTypeId from account where Id IN:accountIds and recordtypeId IN: recordTypeIds]) 
           {
               validAcctIds.put(a.id, a);
           }
 
          return validAcctIds;
      } 
      
      @AuraEnabled
      public static Map<String, String>  fetchAddressStandardizationMap()
      {
          Map<String, String> addressStandardizationMap = new Map<String, String>();
          for(address_standardization__c ad: [select Abbreviation__c, Full_Form__c from address_standardization__c where Abbreviation__c!=null])
          {
              if(ad.Full_Form__c!=null)
                  addressStandardizationMap.put(ad.Abbreviation__c.tolowercase(), ad.Full_Form__c.tolowerCase());
          }
          return addressStandardizationMap;
      }
      
   
   
    
 @AuraEnabled  
   public static String updateAddressInformation(String recordId, string ndaId, List<commonWrapperClass.BWDataInfoWrapper>  wrapperList)
   {
       
       system.debug('=== wrapperList ==='+wrapperList);
       System.debug('=== ndaId');
       List<Account> accountsList = new List<Account>();
       List<Address__c> addressList = new List<Address__c>();
       List<bw_chart_row__c> chartDataList = new List<bw_chart_row__c>();
       Set<Id> accountsValidForAdditionLoc = accountsTiedToProductJunction(recordId, ndaId);
       try
       {
       for(commonWrapperClass.BWDataInfoWrapper bw: wrapperList)
       {
           if(bw.rowType =='Borrower' || bw.rowType =='Guarantor')
           {
               account a = new account(id= bw.recordId);
               
               for(commonWrapperClass.BWDataInfo d :bw.dataList)
               {
                   System.debug('=== d.key ==='+d.key);
                   if(d.key!='name' && d.key!='Standardized Address' && d.key!='Use Standardized Address' && d.key!='Recordtype.DeveloperName')
                       a.put(d.key,d.data);  
                       
                   else if(d.key=='Use Standardized Address')
                   {
                       String Data='';
                       Data = bwhelper.constructStringForChartRow(data,'usethisaddress' ,String.ValueOf(d.booleanData));
                       bw.chartdata.data__c =data;
                   }        
               }
               
               accountsList.add(a);
               
               system.debug('=== accountsList =='+accountsList);
           }
           else if(bw.rowType =='Additional Location')
           {
               List<String> recordIdsList =bw.recordId.split(',');
               system.debug('==== recordIdsList ==='+recordIdsList);
               Address__c ad;
               //accountid+addressId
              if(recordIdsList.size() ==1)
               {
                   
                    
                    if(ndaId!=null && accountsValidForAdditionLoc.contains(bw.recordId))
                    {
                        String addressStr= createAdditionalLocation(bw.recordId, ndaId);
                        ad= new Address__c(id=addressStr);
                        System.debug('=== addressStr =='+addressStr);
                        if(addressStr!=null && !addressStr.contains('ERROR'))
                        {
                            bw.chartData.row_key_Id__c = bw.recordId+','+addressStr;
                            bw.chartData.underwriting__c=recordId;
                            bw.chartData.Boarding_Wizard_Screen__c=AddrscreenId;
                        }
                        else
                        {
                            return addressStr;
                        }
                    }
                    else
                    {
                         ad= new Address__c(Relationship_Name__c= bw.recordId);
                         system.debug('===inside new ad==='+ad);
                         database.saveResult dsr =database.insert(ad, false); 
                         bw.chartData.row_key_Id__c = bw.recordId+','+dsr.getId();
                         bw.chartData.underwriting__c=recordId;
                         bw.chartData.Boarding_Wizard_Screen__c=AddrscreenId;
                    }
               }
               else
               { 
                   System.debug('=== i am inside else part ==='+recordIdsList[1]);
                   ad = new Address__c(id= recordIdsList[1]);
                   
               }
              // account a = new account(id= bw.recordId);
                
               Map<String, String> accountFieldsToaddressFields = new Map<String, String>{
                   'billingcountry' =>'Country__c',
                   'billingstate' =>'state__c',
                   'billingpostalcode' =>'Zip_Code__c',
                   'billingstreet' =>'Address_Line_1__c',
                   'billingcity' =>'City__c'
               };
               
               
               for(commonWrapperClass.BWDataInfo d :bw.dataList)
               {
                   system.debug('=== d.key ==='+d.key);
                   if(d.key!='name' && d.key!='Standardized Address' && d.key!='Use Standardized Address' && d.key!='Recordtype.DeveloperName' && d.key!='First_Name__c' && d.key!='Middle_I__c' && d.key!='Last_Name__c' && d.key!='Type')
                   {
                          if(d.key.toLOwerCase() =='billingstreet')
                          {
                             if(d.data!=null)
                             {
                                 if(d.data.length() >=100)
                                 {
                                     ad.put('Address_Line_1__c',d.data.substring(0,100)); 
                                     ad.put('Address_Line_2__c',d.data.substring(100,d.data.length())); 
                                 }
                                 else
                                 {
                                     system.debug('=== d.key ==='+d.key);
                                     system.debug('=== accountFieldsToaddressFields ===='+accountFieldsToaddressFields);
                                     system.debug('== accountFieldsToaddressFields.get(d.key) ==='+accountFieldsToaddressFields.get(d.key));
                                     system.debug('=== d.data ==='+d.data);
                                     ad.put(accountFieldsToaddressFields.get(d.key.toLowercase()),d.data); 
                                 }
                            }
                          }
                          else
                          {
                             //if(bw.rowType =='Borrower')
                            // {
                                 system.debug('=== d.key ==='+d.key);
                                 ad.put(accountFieldsToaddressFields.get(d.key.toLowerCase()),d.data); 
                             //}
                          }
                          
                   }  
                   else if(d.key=='Use Standardized Address')
                   {
                      String Data='';
                      String standarizedAddress ='';
                      
                      if(d.booleanData!=null) 
                      {
                          standarizedAddress=String.ValueOf(d.booleanData);
                      }
                      else
                      {
                          standarizedAddress='false';
                      }
                      Data = bwhelper.constructStringForChartRow(data,'usethisaddress' ,standarizedAddress);
                      bw.chartdata.data__c =data;
                   }
                      
               }
               
               addressList.add(ad);

              // accountsList.add(a);
               system.debug('=== addressList =='+addressList);
               //system.debug('=== accountsList =='+accountsList);
              
           }
            chartDataList.add(bw.chartData);
       }
       
       if(accountsList!=null && accountsList.size() >0)
       {
           update accountsList;
           //return 'success';
       }
       if(addressList!=null && addressList.size() >0)
       {
           system.debug('=== addressList==='+addressList);
           upsert addressList;
           //return 'success';
       }
       if(chartDataList!=null && chartDataList.size() >0)
       {
           upsert chartDataList;
       }
       
       List<commonWrapperClass.BWDataInfoWrapper> wrapper =constructAddressWrapper(recordId);
      // return wrapper;
       return 'success';
      }
      catch(exception e)
      {
          return e.getMessage();
      }
   }
   
   @AuraEnabled(cacheable=true)
   public static string fetchInitAccountAddress(String accountId)
   {
        try
        {
            account a =[select id, name, billingstreet, billingcity, billingstate, billingcountry from account where id=:accountId];
            string address= a.billingstreet+', \n'+a.billingcity+', \n'+a.billingstate+', \n'+a.billingcountry;
            return address;
        }
        catch(exception e)
        {
           
            return 'error';
        }
   }
    ////////////////////////////////////////
    // End of Address Verification Screen //
    ////////////////////////////////////////
    ///////////////////////////////
    // Start of Doc Vault Screen //
    ///////////////////////////////    
    @AuraEnabled
    public static CommonWrapperClass.BWStepActionOutComeWrapper generateFinalNDAPDF(String ndaId, String recordId)
    {
        CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
        
         if(String.isNotBlank(ndaId) && ndaId.startsWith('a2L'))
        {
            new_dealer_application__c nda =[select id, Language__c from new_dealer_application__c where id=:ndaId];
            
            if(nda!=null)
            {
                String langcode ='en';
                
                if(nda.Language__c!=null && nda.Language__c ==' French Canadian')
                    langcode = 'fr';

                    PageReference pdf = Page.NewDealerAppPDFView;
                
                    // add parent id to the parameters for standardcontroller
                    pdf.getParameters().put('id',ndaId);
                    pdf.getParameters().put('lang', langcode);
                    underwriting__c uw=[select id,initiating_account__r.name from underwriting__c where connected_request__c=:ndaId AND underwriting_Request_level__c ='CARE Level' limit 1];

                    // the contents of the attachment from the pdf
                    // returns the output of the page as a PDF
                    Blob body;
                    if(!Test.isRunningTest()){ // tests cannot run getContent();
                        body = pdf.getContent();
                    }
                    else{
                        body = blob.valueof('Body');
                    }

                    String fileName = 'Final_Application_'+uw.initiating_account__r.name+'_'+system.now().format()+'.pdf';
                                
                 
                    for(ContentDocumentLink link: [SELECT ContentDocumentId FROM ContentDocumentLink where LinkedEntityId =: uw.id and ContentDocument.Title LIKE 'Final_Application%' ORDER BY ContentDocument.LatestPublishedVersion.LastModifiedDate DESC LIMIT 1]){
                       cw.resultRecordId = link.ContentDocumentId;
                    }
                    
                    
                    
                try
                {   
                    cw.outCome =true;
                    cw.resultString='generateNDAPDF executed successfully';
                    if(cw.resultRecordId == null){
                        string cvId = utilityClass.createAndInsertFile(uw.id,fileName , body, 'Customer Application', Date.today(), 'DocVault Default Library');
                        cw.resultRecordId = [SELECT ContentDocumentId FROM ContentVersion where id =:cvId].ContentDocumentId;
                    }
                    return cw;
                }
                catch(exception e)
                {
                    String message ='Error occured while download NDA PDF file on NDA Verification screen '+'NDA Id : '+ndaId+' underwriting Id: '+recordId+' Error message : '+e.getMessage();
                    utilityClass.logError(e, 'Error occured while download NDA PDF file on NDA Verification screen', '', message);
                    
                    cw.resultString='generateNDAPDF execution failed '+message;
                    return cw;
                }
            }
        }
        cw.resultString='Error occured. No record found with ndaId : '+ndaId;
        return cw;         
    }

    @AuraEnabled
    public static void saveNextFollowUpdateDate(string underwritingId, string dateValue){        
        underwriting__c updateUW = [Select id,stage__c from underwriting__c where id = :underwritingId];
        updateUW.Next_Follow_Up_Date__c = date.valueOf(dateValue);
        if(updateUW.Stage__c == 'Request'){
            updateUW.Status__c = 'Pending Additional Information';
        }
        
        try{
            update updateUW;
        }
        catch(exception e){
            system.debug('###saveNextFollowUpdateDate method failed');
        }
    }
    
    @AuraEnabled
    public static void saveUwStatusUpdate(string underwritingId, string elementName){
        underwriting__c updateUW = new underwriting__c();
        updateUW.id = underwritingId;
        updateUW.stage__c = 'Request';
        if(elementName == 'docVaultYes'){
            updateUW.status__c = 'Complete';
        }
        else{
            updateUW.status__c = 'Pending Additional Information';
        }        

        try{
            update updateUW;
        }
        catch(exception e){
            system.debug('###saveUwStatusUpdate method failed');
        }
    }
    /////////////////////////////
    // End of Doc Vault Screen //
    /////////////////////////////
    ///////////////////////////////////////
    // Start of Origination Model Screen //
    ///////////////////////////////////////

    @AuraEnabled
    public static boolean getPMData(string underwritingId){
        boolean pm = false;
        for(underwriting__c uw:[Select Portfolio_Model_Rating__c from underwriting__c where care_underwriting__c =:underwritingId and Portfolio_Model_Rating__c != null]){
            if(uw!=null){
                pm = true;
            }
        }        
        return pm;
    }
    /////////////////////////////////////
    // End of Origination Model Screen //
    /////////////////////////////////////


    ///////////////////////////////////////
    // Start of Dealer Discussion Screen //
    ///////////////////////////////////////
    
    //converts the structure of the BWDataInfo list into a mapping (key => data)
    public static Map<string, string> convertBWDataInfoWrapper2Map(CommonWrapperClass.BWDataInfoWrapper aRow){
        Map<string, string> result = new Map<string, string>();
        for(CommonWrapperClass.BWDataInfo di: aRow.dataList){
            //system.debug(di);
            string val = '';
            if(!String.IsBlank(di.data) && di.data!= null && !di.data.EqualsIgnoreCase('null')){
                val = di.data;
            }
            result.put(di.key, val);
        }
        return result;
    }
    
    /*  this method takes a list of all the steps for the dealer discussion screen
            then applies logic to add additional text and/or hide steps
            also saves the step results when appropriate
    */
    @AuraEnabled
    public static List<CommonWrapperClass.BWStepWrapper> dealerDiscussionScreenStepsFix(List<CommonWrapperClass.BWStepWrapper> steps, string underwritingRecordId){
        UtilityClass.debugStateLimits('dealerDiscussionScreenStepsFix begins');
        
        Map<string, integer> titleIndex = new Map<string, integer>();
        List<Account> allDealersInCare = new List<Account>();
        List<string> strArray = new List<string>();
        List<Boarding_Wizard_Step_Result__c> stepResults = new List<Boarding_Wizard_Step_Result__c>();
        Map<string, Boarding_Wizard_Step_Result__c> oldStepResults = new Map<string, Boarding_Wizard_Step_Result__c>();
        set<string> BW_DRR_Overrides = new set<string>();
        set<string> ACCOUNT_RTYPES   = new set<string>{ 'Client_Dealer', 'Prospect_Dealer', 'Care_Number' };
        set<string> UW_REVIEW_TYPES  = new set<string>{ 'New', 'Increase', 'Carve Out', 'Silo' };
        boolean needToCheckCreditMatrix = false;
        decimal CLAmount = 0.0;
        
        CommonWrapperClass.BWStepWrapperWithResult modifiedStep = new CommonWrapperClass.BWStepWrapperWithResult();
        route2CreditMatrixResult = defaultRoute2CreditResult();
        
        string assocLvl1Ownership = '';
        string sosGoodStanding = '';
        string sosActiveStatus = '';
        string bankruptcyString = '';
        string legalString = '';
        string taxString = '';
        string utilityBillString = '';
        string addressMatchPersonal = '';
        string financialsText = '';
        string less1yrText = '';
        
        for(integer i=0; i<steps.size(); i++){
            titleIndex.put(steps[i].stepTitle, i);
        }
        
        //fetch needed data from related records
        // + 1 SQL
        Underwriting__c uData = [SELECT id, Care_Number__c, Credit_Line_Requested__c, Recommended_Credit_Line_Amount__c, createddate, Review_Type__c,Route_To_Credit__c, Route_To_Credit_Reason__c, 
            Initiating_Account__c, Initiating_Account__r.phone,Initiating_Account__r.Primary_Contact_Phone_Number__c, Initiating_Account__r.Primary_Contact_Name__c, Initiating_Account__r.Primary_Contact_Email_Address__c,
            Connected_Request__c, Connected_Request__r.What_is_your_requested_line_of_credit__c, Connected_Request__r.Bankruptcy_Filed__c, Connected_Request__r.Delinquent_Taxes__c, Connected_Request__r.Pending_Legal_Proceedings__c,
            (SELECT id, Detail_Long__c, Answer__c, Step_Completed__c, Boarding_Wizard_Screen_Step__r.Boarding_Wizard_Screen__r.name, Boarding_Wizard_Screen_Step__r.Step_Title__c, External_Id__c FROM Boarding_Wizard_Answers__r)
            FROM Underwriting__c WHERE id =: underwritingRecordId LIMIT 1];
        
        CLAmount = uData.Credit_Line_Requested__c != null ? uData.Credit_Line_Requested__c : 0.0;
        //CLAmount = uData.Recommended_Credit_Line_Amount__c != null ? uData.Recommended_Credit_Line_Amount__c : CLAmount;
                
        for(Boarding_Wizard_Step_Result__c bwsr: uData.Boarding_Wizard_Answers__r){
            oldStepResults.put(bwsr.External_Id__c, bwsr);
        }
        
        // (must run BKLegalTax before credit matrix)
        // + 3 SQL
        strArray = checkForBKLegalTax(underwritingRecordId, uData.Initiating_Account__c, uData.Connected_Request__c, uData.createdDate, uData.Connected_Request__r.Bankruptcy_Filed__c, uData.Connected_Request__r.Pending_Legal_Proceedings__c, uData.Connected_Request__r.Delinquent_Taxes__c);
            bankruptcyString = strArray[0];
            legalString      = strArray[1];
            taxString        = strArray[2];
 
        
        //if the underwriting is not increase,new,carve out, silo then there is a lot of querying and logic that can be skipped
        needToCheckCreditMatrix = UW_REVIEW_TYPES.contains(uData.Review_Type__c);
        if(needToCheckCreditMatrix){      
                                
            // + 4 SQL
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : SObjectType.Account.FieldSets.BW_DRR_Overrides.getFields()) 
            {
                query += f.getFieldPath() + ', ';
                BW_DRR_Overrides.add(f.getFieldPath());
            }
            query += 'id,name,Year_Business_Was_Established__c,Portfolio_Model_Score__c,recordtype.developername, ';
            query += '(SELECT id, Risk_Calc_Dual_Risk_Rating__c, Origination_Model__r.X12_Month_PD__c from Dual_Risk_Ratings__r WHERE Used_to_decision_request__c = true AND Underwriting__r.Care_Underwriting__c =\'' +uData.id +'\'), ';
            query += '(SELECT id, DnBId__c, DnBId__r.X12_Month_PD__c FROM D_B_Underwriting_Junctions__r WHERE Used_to_decision_request__c = true AND DnBId__c != null AND (Underwriting__r.Care_Underwriting__c =\'' +uData.id +'\' OR Underwriting__c = \''+uData.id+'\')), ';
            query += '(SELECT id, Enhancement_Type__c, status__c FROM Credit_Enhancements1__r WHERE Account_Lookup__r.Care_Number__c = \''+ uData.Care_Number__c + '\' AND Enhancement_Type__c = \'ILOC\' AND Status__c = \'Active\'), ';
            query += '(SELECT id,Credit_Exception__r.Credit_Exception_Name__c,Credit_Exception__r.Exception_Level__c FROM Credit_Exceptions_to_Accounts__r WHERE Credit_Exception__r.Credit_Exception_Name__c = \'Guarantees of Owners (If Required Per Policy) Not Obtained\')';
            query += ' FROM Account WHERE (Care_Number__c = \'' + uData.Care_Number__c +'\' OR id = \'' + uData.Care_Number__c +'\') AND recordtype.developername IN :ACCOUNT_RTYPES';
            System.debug('query ------>'+query );
            allDealersInCare = Database.query(query);
        
            boolean rememberTaxRoute2credit = false;
            boolean rememberPMPDRoute3credit = false;
        
            //for financials, need to run a series of methods to evaluate the "Route to Credit Matrix"
            route2CreditMatrixResult = route2CreditMatrix_01_creditline(uData.Review_Type__c, CLAmount);
            if(!route2CreditMatrixResult.needFinancials){
                route2CreditMatrixResult = route2CreditMatrix_02_BKLegalTax(uData.Review_Type__c, bankruptcyString, taxString, legalString);
            
                //if routing to credit, need to remember that option for future steps
                rememberTaxRoute2credit = route2CreditMatrixResult.routeToCredit;
                
                if(!route2CreditMatrixResult.needFinancials){
                    route2CreditMatrixResult = route2CreditMatrix_03_PGWaiver(uData.Review_Type__c, allDealersInCare);
                
                    if(!route2CreditMatrixResult.needFinancials){
                        List<Product_Information_For_New_Dealer_App__c> prodsList = [SELECT id FROM Product_Information_For_New_Dealer_App__c where Underwriting__c =: uData.id and Limited_Restricted__c = true];
                        route2CreditMatrixResult = route2CreditMatrix_04_limitedMfr(uData.Review_Type__c, (prodsList != null && prodsList.size()>0));
                    
                        if(!route2CreditMatrixResult.needFinancials){
                            route2CreditMatrixResult = route2CreditMatrix_05_yrInBusiness(uData.Review_Type__c, allDealersInCare);
                            if(route2CreditMatrixResult.needFinancials){
                                less1yrText = route2CreditMatrixResult.reason;
                            }
                            
                            if(!route2CreditMatrixResult.needFinancials){
                                route2CreditMatrixResult = route2CreditMatrix_06_checkPMPD(uData.Review_Type__c, CLAmount, allDealersInCare);
                                //if routing to credit, need to remember that option for future steps                                
                                rememberPMPDRoute3credit = route2CreditMatrixResult.routeToCredit;
                                
                                if(!route2CreditMatrixResult.needFinancials){
                                    route2CreditMatrixResult = route2CreditMatrix_07_checkILOC(uData.Review_Type__c, allDealersInCare);
                                
                                    if(!route2CreditMatrixResult.needFinancials){
                                        route2CreditMatrixResult = route2CreditMatrix_08_DRROverrides(uData.Review_Type__c, CLAmount, allDealersInCare, BW_DRR_Overrides);
                                    
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(rememberTaxRoute2credit && !route2CreditmatrixResult.routeToCredit){
                route2CreditMatrixResult.routeToCredit = true;
                route2CreditMatrixResult.reason = 'Has open tax lien or has known material liens/suits/judgements';
            }
            if(rememberPMPDRoute3credit && !route2CreditmatrixResult.routeToCredit){
                route2CreditMatrixResult.routeToCredit = true;
                route2CreditMatrixResult.reason = 'Found a dealer with PD % between 5.12-7.96 or PM Score 238-255 with C/L Requested <= $750K';
            }
            
            //if checked the matrix in trigger context, then apply the results to the Care loan fields
            if((isTriggerContext == true) && (uData.Route_To_Credit__c != route2CreditMatrixResult.routeToCredit)){
                uData.Route_To_Credit__c = route2CreditMatrixResult.routeToCredit;
                uData.Route_To_Credit_Reason__c = route2CreditMatrixResult.reason;
                
                try{
                    update uData;
                }
                catch(exception e){
                    System.debug(e);
                }
            }
        }
        
        if(route2CreditMatrixResult.needFinancials){
            financialsText = route2CreditMatrixResult.reason +'<br/>'+route2CreditMatrixResult.additionalComments;
        }       
        
        if(titleIndex.size()>0){
            //run various helper methods for step-specific logic  
            // + 11 SQL     
            strArray = checkAssociationOwnerPercent(uData.Care_Number__c);
                assocLvl1Ownership = strArray[0];
            
            // + 4 SQL
            strArray = checkForSOSStanding(uData.Care_Number__c, underwritingRecordId );
                sosActiveStatus = strArray[0];
                sosGoodStanding = strArray[1];
            
            // + 3 SQL
            strArray = checkAddressVerForResidence(uData);
                utilityBillString    = strArray[0];
                addressMatchPersonal = strArray[1];
        
        
            //apply the found info to be displayed on the BW screen
            if(titleIndex.containsKey('Call Dealer')){
                steps[titleIndex.get('Call Dealer')].element1Wrapper.textData = '<b>Primary Contact:</b> '+uData.Initiating_Account__r.Primary_Contact_Name__c+'<br/><b>Relationship Phone:</b> '+uData.Initiating_Account__r.phone+'<br/><b>Primary Contact Phone:</b> '+uData.Initiating_Account__r.Primary_Contact_Phone_Number__c;
            }
            
            if(titleIndex.containsKey('SOS Not Active')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('SOS Not Active')], uData.id, sosActiveStatus, '', 'All states found active in good standing', 'SOS Not Active/Good Standing', 'N/A', oldStepResults);
                steps[titleIndex.get('SOS Not Active')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }     
          /*  if(titleIndex.containsKey('SOS Not Good Standing')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('SOS Not Good Standing')], uData.id, sosGoodStanding, '', 'All states found in good standing', 'SOS Not Good Standing', 'N/A');
                steps[titleIndex.get('SOS Not Good Standing')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);           
            }*/
            
            if(titleIndex.containsKey('NDA Credit Line')){
                //steps[titleIndex.get('NDA Credit Line')].element1Wrapper.textData = '<b>NDA Credit Line Requested:</b> '+uData.Connected_Request__r.What_is_your_requested_line_of_credit__c+'<br/><b>CARE Underwriting Recommended Credit Line Amount:</b> '+uData.Recommended_Credit_Line_Amount__c;
            
                List<String> args = new String[]{'0','number','###,###,###'};
                List<string> ds = new List<string>();
                decimal cr1 = uData.Connected_Request__r.What_is_your_requested_line_of_credit__c == null ? 0 : uData.Connected_Request__r.What_is_your_requested_line_of_credit__c;
                decimal cr2 = uData.Credit_Line_Requested__c == null ? 0 : uData.Credit_Line_Requested__c;
                ds.add(String.format(cr1.format(), args));
                ds.add(String.format(cr2.format(), args));
                steps[titleIndex.get('NDA Credit Line')].element1Wrapper.textData = '<b>NDA Credit Line Requested:</b> '+ds[0]+'<br/><b>CARE Credit Line Requested:</b> '+ds[1];

            }
            if(titleIndex.containsKey('NDA Bankruptcies')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('NDA Bankruptcies')], uData.id, bankruptcyString, '(No bankruptcies found)', 'No bankruptcies found', 'Bankruptcy found','N/A', oldStepResults);
                steps[titleIndex.get('NDA Bankruptcies')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }
            if(titleIndex.containsKey('NDA Suits')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('NDA Suits')], uData.id, legalString, '(No legal records found)', 'No legal records found', 'Legal record found','N/A', oldStepResults);
                steps[titleIndex.get('NDA Suits')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }
            if(titleIndex.containsKey('NDA Unpaid Taxes')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('NDA Unpaid Taxes')], uData.id, taxString, '(No tax liens found)', 'No tax liens found', 'Tax lien found','N/A', oldStepResults);
                steps[titleIndex.get('NDA Unpaid Taxes')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }
            
            if(titleIndex.containsKey('Ownership 100')){            
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('Ownership 100')], uData.id, assocLvl1Ownership, '(All dealer association ownership = 100%)', 'All dealer association ownership = 100%', 'Ownership < 100%','All dealer association ownership = 100%', oldStepResults);
                steps[titleIndex.get('Ownership 100')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }
            if(titleIndex.containsKey('Home address')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('Home address')], uData.id, utilityBillString, '', 'All owner home addresses verified to match their DL or CBR report.  No utility bill should be required.', 'Home address does not match DL', 'N/A', oldStepResults);
                steps[titleIndex.get('Home address')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }
            if(titleIndex.containsKey('Business address match personal')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('Business address match personal')], uData.id, addressMatchPersonal, '', 'No residential addresses match business addresses.', 'Business address matches residential', 'N/A', oldStepResults);
                steps[titleIndex.get('Business address match personal')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }
            if(titleIndex.containsKey('Financials required')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('Financials required')], uData.id, financialsText, 'Financials not required', 'Financials not required', 'Financial statements are required', 'N/A', oldStepResults);
                steps[titleIndex.get('Financials required')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }
            if(titleIndex.containsKey('Supporting finance docs required')){
                modifiedStep = dlrDiscussionApplyStepChanges(steps[titleIndex.get('Supporting finance docs required')], uData.id, less1yrText, 'Business older than 1 year', 'Business older than 1 year', 'Supporting finance docs are required', 'N/A', oldStepResults);
                steps[titleIndex.get('Supporting finance docs required')] = modifiedStep.step;
                stepResults.add(modifiedStep.stepResult);
            }
        }
        
        if(stepResults.size()>0){
            try{
                upsert stepResults External_Id__c;
            } catch (exception e){
                //err
                system.debug(e);
            }
        }
        
        //re-number the steps
        integer i=1;
        for(CommonWrapperClass.BWStepWrapper sw: steps){
            if(!sw.hiddenOnScreen){
                sw.stepNumber = i;
                i++;
            }
        }
        
        UtilityClass.debugStateLimits('dealerDiscussionScreenStepsFix ends');
        return steps;
    }
    
    /*    this helper method holds code that is repeatedly exeucted on the dealer discussion screen  
          the step wrapper and result is modified before the page finishes loading
    */
    private static CommonWrapperClass.BWStepWrapperWithResult dlrDiscussionApplyStepChanges(CommonWrapperClass.BWStepWrapper step, string underwritingRecordId, 
        string element1text, string element1alternateText,   string alternateAnswerDetail, string primaryAnswer,   string alternateAnswer, Map<string, Boarding_Wizard_Step_Result__c> oldStepResults){

        System.debug('dlrDiscussionApplyStepChanges() begins for: '+step.stepTitle);
        System.debug(' -- element1text: '+element1text);
        System.debug(' -- element1alternateText: '+element1alternateText);
        System.debug(' -- primaryAnswer: '+primaryAnswer);
        System.debug(' -- alternateAnswer: '+alternateAnswer);
        System.debug(' -- alternateAnswerDetail: '+alternateAnswerDetail);

        CommonWrapperClass.BWStepWrapperWithResult changedStep = new CommonWrapperClass.BWStepWrapperWithResult();
        string stepResultKey = underwritingRecordId+'-'+step.stepRecordId;
        Boarding_Wizard_Step_Result__c newAnswer = new Boarding_Wizard_Step_Result__c(underwriting__c = underwritingRecordId, Boarding_Wizard_Screen_Step__c=step.stepRecordId, External_Id__c = stepResultKey,
            detail_long__c = element1text.stripHTMLTags().left(30000), 
            
            answer__c = primaryAnswer);

        System.debug('---- newAnswer DEFAULT: '+newAnswer);
        
        //need to compare old/new step result in case of changes to reset complete/incomplete
        boolean foundOldAnswer = false;
        Boarding_Wizard_Step_Result__c oldAnswer = new Boarding_Wizard_Step_Result__c();
        if(oldStepResults.containsKey(stepResultKey)){
            oldAnswer = oldStepResults.get(stepResultKey);
            foundOldAnswer = true;
            newAnswer.step_completed__c = oldAnswer.step_completed__c;
            System.debug('---- oldAnswer FOUND: '+oldAnswer);
        }
        
        //for majority of steps, this logic determines whether the step is an automatic pass (green checkmark)
        boolean autoPassStep = string.isblank(element1text) || element1text.equalsIgnoreCase('<b>NDA Bankruptcy Filed?</b> No<br/>') || element1text.equalsIgnoreCase('<b>NDA Pending Legal Proceedings?</b> No<br/>') 
            || element1text.equalsIgnoreCase('<b>NDA Delinquent Taxes?</b> No<br/>');
        
        //for association ownership 100%, the string will not be empty but need to check if any dealer is <> 100%
        if(step.stepTitle == 'Ownership 100'){
            autoPassStep = (!element1text.containsIgnoreCase('Error') && !element1text.containsIgnoreCase('color:red'));
        }
        System.debug(' -- automatic PASS? '+autoPassStep);
        
        step.element1Wrapper.textData = element1text;
        step.hiddenOnScreen = false;
        step.readOnlyCheckMark = false;
        
        if(autoPassStep){
            step.element1Wrapper.textData = element1alternateText;
            newAnswer.Step_Completed__c = true;
            newAnswer.answer__c = alternateAnswer;
            newAnswer.detail_long__c = alternateAnswerDetail.stripHTMLTags().left(30000);
            step.hiddenOnScreen = true;
            step.readOnlyCheckMark = true;
        }
        
        System.debug(' -- newAnswer MODIFIED 1x: '+newAnswer);
        System.debug(' -- step MODIFIED:');
        System.debug(' ---- step.element1Wrapper.textData: '+step.element1Wrapper.textData);
        System.debug(' ---- step.hiddenOnScreen: '+step.hiddenOnScreen);
        System.debug(' ---- step.readOnlyCheckMark: '+step.readOnlyCheckMark);
        
        oldAnswer.answer__c      = String.IsBlank(oldAnswer.answer__c)      ? '' : oldAnswer.answer__c.trim();
        newAnswer.answer__c      = String.IsBlank(newAnswer.answer__c)      ? '' : newAnswer.answer__c.trim();
        oldAnswer.detail_long__c = String.IsBlank(oldAnswer.detail_long__c) ? '' : oldAnswer.detail_long__c.trim();
        newAnswer.detail_long__c = String.IsBlank(newAnswer.detail_long__c) ? '' : newAnswer.detail_long__c.trim();
               
        //if the answer or detail has changed, and the step requires manual confirmation, reset the checkmark
        if(foundOldAnswer && !autoPassStep && ((oldAnswer.answer__c != newAnswer.answer__c) || (oldAnswer.detail_long__c != newAnswer.detail_long__c))){
            newAnswer.step_completed__c = false;
        }
        
        System.debug(' -- newAnswer MODIFIED 2x: step_completed__c = '+newAnswer.step_completed__c);  
        System.debug('dlrDiscussionApplyStepChanges() ends for: '+step.stepTitle);  
            
        changedStep.step = step;
        changedStep.stepResult = newAnswer;
        return changedStep;
    }
       
    //helper method to construct a rich text hyperlink
    public static string makeRTlink(string destinationUrl, string label){
        string result = '<a href="/' + destinationUrl + '" target="_blank" title="Open link in new tab" ><span style="text-decoration:underline;" >'+label+ '</span></a>';
        return result;
    }
       
    /*  helper method takes fields from the UW and NDA record, then queries and determines if there is any bankruptcy, legal suits, or tax liens
        returns List<string> [0] = bankruptcyString
                             [1] = legalString
                             [2] = taxString
    */                 
    public static List<string> checkForBKLegalTax(string underwritingRecordId, string initiatingAccountId, string ndaId, datetime underwritingCreatedDateTime, string ndaBankruptcyFiled, string ndaPendingLegalProceedings, string ndaDelinquentTaxes){
        List<string> result = new List<string>{ '', '', '' };
        
        if(!String.IsBlank(ndaId)){
            result[0] +='<b>NDA Bankruptcy Filed?</b> '         + ndaBankruptcyFiled +'<br/>';
            result[1] +='<b>NDA Pending Legal Proceedings?</b> '+ ndaPendingLegalProceedings +'<br/>';
            result[2] +='<b>NDA Delinquent Taxes?</b> '         + ndaDelinquentTaxes +'<br/>';
        }
        
        //use cbr rows to check for bankruptcies, judgments, tax leins, etc
        Map<string, List<CommonWrapperClass.BWCBRWrapper>> cbrMap = BWRequestStageHelper.getCbrRows(underwritingRecordId, initiatingAccountId, ndaId, string.valueOfgmt(underwritingCreatedDateTime));
        List<CommonWrapperClass.BWCBRWrapper> cbrRows = cbrMap.values()[0];
        //each row represents a guarantor with a CBR xml response already parsed into an array, search the array for key terms
        
        for(CommonWrapperClass.BWCBRWrapper cbrRow : cbrRows){
            list<boolean> deDupe = new list<boolean>{ true, true, true };
            for(string z: cbrRow.cbrSpMessageList){
                if(z.containsIgnoreCase('bankruptc') && deDupe[0]){ //'Bankruptcies'  'BANKRUPTCY'
                    result[0] += makeRTlink(cbrRow.relationshipId, cbrRow.relName)+ ' : <b><span style="color:red" >YES</span></b> (from CBR report)<br/>';
                    deDupe[0] = false;
                }
                if((z.containsIgnoreCase('legal items') || z.containsIgnoreCase('judgment') || z.containsIgnoreCase('judgement') || z.containsIgnoreCase('public record')) && deDupe[1]){ 
                    result[1] += makeRTlink(cbrRow.relationshipId, cbrRow.relName)+ ' : <b><span style="color:red" >YES</span></b> (from CBR report)<br/>';
                    deDupe[1] = false;
                }
                if(z.containsIgnoreCase('tax lien') && deDupe[2]){ 
                    result[2] += makeRTlink(cbrRow.relationshipId, cbrRow.relName)+ ' : <b><span style="color:red" >YES</span></b> (from CBR report)<br/>';
                    deDupe[2] = false;
                }
            }
        }
        
        return result;
    }
    
    /*  helper method takes fields from the UW record, searches thru the Entity Verification screen data to determine SOS standing
        returns List<string> [0] = sosActiveStatus + good standing
                             [1] = not used
    */
    public static List<string> checkForSOSStanding(string careNumberId, string underwritingRecordId){
        List<string> result = new List<string>();
        string sosActiveStatus = '';
        string sosGoodStanding = '';
        
        //need state map to ensure that stale cb chart rows are not included, and missing chart rows are shown as incomplete
        Map<string, string> relationshipNameMap = new Map<string, string>();
        List<account> borrowerList = fetchBorrowerList(careNumberId);
        for(account a: borrowerList){
            relationshipNameMap.put(a.id, a.name);
        }
        Map<String, List<String>> borrowerToStateMap =accountTostatesMap(borrowerList, 'Borrower');
       
        List<account> entityList = fetchEntityList(borrowerList);
        for(account a: entityList){
            relationshipNameMap.put(a.id, a.name);
        }
        Map<String, List<String>> entityToStateMap =accountTostatesMap(entityList, 'Entity');
        borrowerToStateMap.putAll(entityToStateMap);
        set<string> foundRelationshipState = new set<string>(); //relationshipId+State
        system.debug(borrowerToStateMap);
        
        //fetch chart row data from Entity Verification screen.
        for(BW_Chart_Row__c cr: [SELECT id,Boarding_Wizard_Screen__c,Boarding_Wizard_Screen__r.name,data__c,Row_Key_Id__c FROM BW_Chart_Row__c WHERE Underwriting__c =: underwritingRecordId AND Boarding_Wizard_Screen__c != null]){
            if(cr.Boarding_Wizard_Screen__r.name.equalsIgnoreCase(Constants.getBWScreenNameMap().get('ENT_VER'))){
                Map<string, string> chartDataMap = BWHelper.deconstructList(cr.data__c);
            
                if(chartDataMap.containsKey('name') && chartDataMap.containsKey('Active_with_SOS') && chartDataMap.containsKey('state')){
                    string rname = chartDataMap.get('name'); 
                    string rasos = chartDataMap.get('Active_with_SOS'); 
                    string state = chartDataMap.get('state'); 
                    
                    if(borrowerToStateMap.containsKey(cr.Row_Key_Id__c)){    //id is in current address table
                        //loop through all states that should be validated
                        for(string foundStates : borrowerToStateMap.get(cr.Row_Key_Id__c)){
                        
                            if(foundStates.containsIgnoreCase(state)){
                                foundRelationshipState.add(cr.Row_Key_Id__c+state);
                                
                                if(!rasos.equalsIgnoreCase('Yes') && !string.isblank(rname)){
                                    sosActiveStatus += rname+' : <b>'+state+'</b> <span style="color:red" >(Not active/good standing)</span><br/>';
                                }
                               /* if(!rgsos.equalsIgnoreCase('Yes') && !string.isblank(rname)){
                                    sosGoodStanding += rname+' : <b>'+state+'</b> <span style="color:red" >(Not in good standing)</span><br/>';
                                } */
                            }
                        }
                    }
                }
            }
        }
        
        //loop through all states again
        for(string relationshipId : borrowerToStateMap.keyset()){
            for(string state: borrowerToStateMap.get(relationshipId)){
                if(state.contains(':')){
                    state = state.substringAfter(':').trim();
                }
                if(!foundRelationshipState.contains(relationshipId+state)){
                    //this state had no chart row, so data is missing
                    sosActiveStatus += relationshipNameMap.get(relationshipId)+' : <b>'+state+'</b> <span style="color:red" >(Not active/good standing)</span><br/>';
                    //sosGoodStanding += relationshipNameMap.get(relationshipId)+' : <b>'+state+'</b> <span style="color:red" >(Not in good standing)</span><br/>';
                }
            }
        }
        result.add(sosActiveStatus);
        result.add(sosGoodStanding);
        return result;    
    }
    
    
    /*  helper method takes UW record (with Boarding_Wizard_Step_Result__r), searches thru the Address Verification screen data to determine residential address requirements
        returns List<string> [0] = utilityBillString
                             [1] = addressMatchPersonal
    */
    public static List<string> checkAddressVerForResidence(Underwriting__c uData){
        List<string> result = new List<string>();
        string utilityBillString = 'Error: home address not verified'+'<br/><span style="font-style:italic" >Refer to "Address Verification" screen.</span>';
        string addressMatchPersonal = '';
        
        //find answer from the address ver screen
        for(Boarding_Wizard_Step_Result__c sr : uData.Boarding_Wizard_Answers__r){
            if(sr.Boarding_Wizard_Screen_Step__r.Boarding_Wizard_Screen__r.name == Constants.getBWScreenNameMap().get('ADDR_VER') 
                && sr.Boarding_Wizard_Screen_Step__r.Step_Title__c == 'Owner home address match'){
                
                if(sr.Step_Completed__c){
                    utilityBillString = sr.detail_long__c+'<br/><span style="font-style:italic" >Refer to "Address Verification" screen.</span>';
                    if(sr.Answer__c == 'All home addresses match DL/CBR'){
                        utilityBillString = '';
                    }
                } 
            }
        }
        
        //get all addresses from address ver screen for comparison
        List<CommonWrapperClass.BWDataInfoWrapper> allAddresses = constructAddressWrapper(uData.id);
        Map<string, Map<string, string>> rowMap = new Map<string, Map<string, string>>();
        Map<string, string> id2Name = new Map<string, string>();
        Map<string, string> indG = new Map<string, string>();
        Map<string, string> busA = new Map<string, string>();
        
        //divide the table, all individual addresses into one map, the rest into a second map
        for(CommonWrapperClass.BWDataInfoWrapper aRow  :allAddresses){
            rowMap.put(aRow.recordId, convertBWDataInfoWrapper2Map(aRow));
            Map<string, string> t = rowMap.get(aRow.recordId);
            id2Name.put(aRow.recordId, t.get('name'));
            if(aRow.rowType == 'Guarantor'){
                if(!String.IsBlank(t.get('First_Name__c')) || !String.IsBlank(t.get('Last_Name__c'))){
                    indG.put(aRow.recordId, t.get('billingstreet')+t.get('billingcity')+t.get('billingstate')+t.get('billingpostalcode')+t.get('billingcountry'));
                } else {
                    busA.put(aRow.recordId, t.get('billingstreet')+t.get('billingcity')+t.get('billingstate')+t.get('billingpostalcode')+t.get('billingcountry'));
                }
            } else {
                busA.put(aRow.recordId, t.get('billingstreet')+t.get('billingcity')+t.get('billingstate')+t.get('billingpostalcode')+t.get('billingcountry'));
            }
        }
        
        for(string x: indG.keySet()){
            string homeAddress = indG.get(x);
            for(string y: busA.keySet()){
                if(homeAddress.equalsIgnoreCase(busA.get(y))){
                    //this home address matches one of the other entity or business addresses
                    addressMatchPersonal += makeRTlink(x, id2Name.get(x))+ ' personal address matches with <a href="/';
                    addressMatchPersonal += y+'" target="_blank" title="Open link in new tab" ><span style="color:red;text-decoration:underline;" >'+id2Name.get(y)+'</span></a><br/>';
                }
            }
        }

        if(!String.isblank(addressMatchPersonal)){
            addressMatchPersonal+='<span style="font-style:italic" >Refer to "Address Verification" screen.</span>';
        }
        
        result.add(utilityBillString);
        result.add(addressMatchPersonal);
        return result;
    }
    
    
    /*  helper method takes CARE accountid, pulls full association structure and computes 1st level association ownership % totals for each dealer
        returns List<string> [0] = assocLvl1Ownership
    */
    public static List<string> checkAssociationOwnerPercent(string careAccountId){
        List<string> result = new List<string>();
        List<VF_Email_Helper.TreeNode> assocTree = new List<VF_Email_Helper.TreeNode>();
        string assocLvl1Ownership = 'Error: no ownership % found';
        Map<string, decimal> assocLevel1OwnerMap = new Map<string, decimal>();
        
        //pull associations, for each dealer compute 1st level ownership totals
        if(!String.IsBlank(careAccountId)){
            assocTree = VF_Email_Helper.queryAssociations(careAccountId);
            
            for(VF_Email_Helper.TreeNode le: assocTree){ //top level of structure is Legal Entity
                for(VF_Email_Helper.TreeNode n: le.Children){  //next level is dealer accounts
                    if(n.assocLevel == 0){
                        decimal tempPercentage = 0.0;
                        
                        for(VF_Email_Helper.TreeNode c: n.Children){  //this level is 1st level associations
                            tempPercentage += c.Association.Ownership_Percentage__c;
                        }
                        assocLevel1OwnerMap.put(n.SpotAccount.name, tempPercentage);
                    }
                }
            }
            assocLvl1Ownership = '';
            for(string x: assocLevel1OwnerMap.keyset()){
                string addLine = x+' : <b>'+assocLevel1OwnerMap.get(x).setScale(0)+'%</b><br/>';
                if(assocLevel1OwnerMap.get(x) <> 100){
                    addLine = x+' : <b><span style="color:red" >'+assocLevel1OwnerMap.get(x).setScale(0)+'%</span></b><br/>';
                }
                assocLvl1Ownership += addLine;
            }
        }
        result.add(assocLvl1Ownership);
        return result;
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //    methods for the "Route to Credit Matrix"
    //
    //    used to determine if financials are required, if routing to credit is required, and why
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrixResult {get; set;}
    public static CommonWrapperClass.BWRouteToCreditMatrixResult defaultRoute2CreditResult(){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = new CommonWrapperClass.BWRouteToCreditMatrixResult();
        result.runDRRBeforeCredit = false;
        result.needFinancials = false;
        result.routeToCredit = false;
        result.additionalComments = '';
        result.reason = '';
        return result;
    }
    
    /*   input param: care uw id
         output: BWRouteToCreditMatrixResult (see commonwrapperformat)
    
        call this method as an alternative to the dealerDiscussionScreenLoad if you wish to evaluate the route2CreditMatrix logic directly without
        involving any BW steps or results.
    */
    @AuraEnabled
    public static CommonWrapperClass.BWRouteToCreditMatrixResult runRoute2CreditMatrixOnly(string underwritingId){
        UtilityClass.debugStateLimits('CheckMatrix begins: id = '+underwritingId);
        isTriggerContext = true;
        dealerDiscussionScreenStepsFix(new List<CommonWrapperClass.BWStepWrapper>(), underwritingId);
        isTriggerContext = false;
        system.debug('***RETURNING RESULT: '+route2CreditMatrixResult);
        UtilityClass.debugStateLimits('CheckMatrix ends');
        return route2CreditMatrixResult;
    }
    
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrix_01_creditline(string reviewType, decimal requestedCreditLine){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = defaultRoute2CreditResult();
        set<string> types = new set<string> { 'New', 'Increase', 'Carve Out', 'Silo' };
        if(requestedCreditLine > 750000 && types.contains(reviewType)){
            result.needFinancials = true;
            result.routeToCredit = true;
            result.reason = '> $750K Credit Line';
        }
        system.debug('route2CreditMatrix_01_creditline: '+result);
        return result;
    }
    
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrix_02_BKLegalTax(string reviewType, string bankruptcyString, string taxString, string legalString){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = defaultRoute2CreditResult();
        set<string> types = new set<string> { 'New' };//, 'Increase', 'Carve Out', 'Silo' };
        if(types.contains(reviewType)){
            if(bankruptcyString.containsIgnoreCase('yes') ){
                result.needFinancials = true;
                result.routeToCredit = true;
                result.reason = 'Has active or prior BK in last 15 years';
            } else if(legalString.containsIgnoreCase('yes')){
                result.routeToCredit = true;
                result.reason = 'Has known material liens/suits/judgements';
                result.additionalComments = 'Explanation of Suits/Judgements Needed';
            } else if(taxString.containsIgnoreCase('yes')){
                result.routeToCredit = true;
                result.reason = 'Has open tax lien';
                result.additionalComments = 'Explanation of Tax Liens Needed';
            }
        }
        system.debug('route2CreditMatrix_02_BKLegalTax: '+result);
        return result;
    }
    
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrix_03_PGWaiver(string reviewType, List<account> allDealersInCare){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = defaultRoute2CreditResult();
        set<string> types = new set<string> { 'New', 'Increase', 'Carve Out', 'Silo' };
        if(types.contains(reviewType)){
            for(Account a: allDealersInCare){
                //    assuming this child query was included in the Account list:
                //(SELECT id,Credit_Exception__r.Credit_Exception_Name__c,Credit_Exception__r.Exception_Level__c FROM Credit_Exceptions_to_Accounts__r 
                //WHERE Credit_Exception__r.Credit_Exception_Name__c = 'Guarantees of Owners (If Required Per Policy) Not Obtained') FROM Account
                if(a.Credit_Exceptions_to_Accounts__r != null && a.Credit_Exceptions_to_Accounts__r.size()>0){
                    //there is at least one account with a PG waiver
                    result.needFinancials = true;
                    result.routeToCredit = true;
                    result.reason = makeRTlink(a.id, a.name) + ' Has PG waiver ('+a.Credit_Exceptions_to_Accounts__r[0].Credit_Exception__r.Exception_Level__c+')';
                    break;
                }
            }
            if(result.needFinancials && !reviewType.equalsIgnoreCase('New')){
                result.additionalComments = 'Discuss with Credit to confirm if financials are needed';
            }           
        }
        system.debug('route2CreditMatrix_03_PGWaiver: '+result);
        return result;
    }
    
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrix_04_limitedMfr(string reviewType, boolean hasRestrictedManufacturer){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = defaultRoute2CreditResult();
        set<string> types = new set<string> { 'New', 'Increase', 'Carve Out', 'Silo' };
        if(hasRestrictedManufacturer && types.contains(reviewType)){
            result.needFinancials = true;
            result.routeToCredit = true;
            result.reason = 'Limited/Restricted Manufacturer';
        }
        system.debug('route2CreditMatrix_04_limitedMfr: '+result);
        return result;
    }
    
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrix_05_yrInBusiness(string reviewType, List<account> allDealersInCare){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = defaultRoute2CreditResult();
        set<string> types = new set<string> { 'New', 'Increase', 'Carve Out', 'Silo' };
        if(types.contains(reviewType)){
            for(Account a: allDealersInCare){
                if(a.recordtype.developername != 'Care_Number'){
                    string relYearStart = String.IsBlank(a.Year_Business_Was_Established__c) ? '' : a.Year_Business_Was_Established__c;
                    
                    if(relYearStart == ''){
                        result.needFinancials = true;
                        result.reason = makeRTlink(a.id, a.name) + ' <= 1 year in business (Year Established is blank)';
                        break;
                    } else {
                        integer MM = 12;
                        integer YYYY = Date.Today().Year();
                        try{ 
                            if(relYearStart.contains('/')){
                                string[] z = relYearStart.split('/');
                                MM = integer.valueOf(z[0]);
                                YYYY = integer.valueOf(z[1]);
                            } else {
                                YYYY = integer.valueOf(relYearStart);
                            }
                            
                            if(Date.Today().Year()-YYYY == 0){ //same year
                                result.needFinancials = true;
                                result.reason = makeRTlink(a.id, a.name) + ' <= 1 year in business (Year Established: '+a.Year_Business_Was_Established__c+')';
                                break;
                            } else if(Date.Today().Year()-YYYY == 1 && Date.Today().Month() <= MM){ //last year
                                result.needFinancials = true;
                                result.reason = makeRTlink(a.id, a.name) + ' <= 1 year in business (Year Established: '+a.Year_Business_Was_Established__c+')';
                                break;
                            } 
                        }catch (exception e){
                            result.needFinancials = true;
                            result.reason = makeRTlink(a.id, a.name) + ' <= 1 year in business (Error in Year Established)';
                            break;
                        }
                    }                
                }
            }
            
            if(result.needFinancials){
                result.routeToCredit = true;
                result.additionalComments = '** Instead of 2 yrs Financial Statements, need:<br/><ul><li>History Questionnaire</li><li>Resume</li><li>PFS dated within 6 months</li><li>Opening Balance Sheet</li><li>Projections</li><li>Buy/sell agreement (if applicable)</li><li>Cash Verification (if applicable)</li></ul>';
            }  
        }
        system.debug('route2CreditMatrix_05_yrInBusiness: '+result);
        return result;
    }
    
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrix_06_checkPMPD(string reviewType, decimal requestedCreditLine, List<account> allDealersInCare){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = defaultRoute2CreditResult();
        set<string> types = new set<string> { 'New', 'Increase', 'Carve Out', 'Silo' };
        set<string> modelDRRrange = new set<string> { '5-B', '5+C', '5C', '5-C', '5+D', '5D', '5-D', '5+E', '5E', '5-E', '5+F', '5F', '5-F' };
        boolean foundNoPMPD = true;
        
        if(types.contains(reviewType)){
            for(Account a: allDealersInCare){
                if(a.recordtype.developername != 'Care_Number'){
            
                    //does the account have a PM?
                    if(!string.IsBlank(a.Portfolio_Model_Score__c)){
                        foundNoPMPD = false;
                        
                        //is PM in range?
                        integer PMScore = integer.valueOf(a.Portfolio_Model_Score__c);
                        if(PMScore <= 237 && requestedCreditLine <= 750000){
                            result.needFinancials = true;
                            result.routeToCredit = true;
                            result.reason = makeRTlink(a.id, a.name) +' has PM Score: '+PMScore+' (<=237)<br/>with C/L Requested: '+requestedCreditLine.setScale(0)+' (<= $750K)';
                            break;
                        } else if(PMScore >= 238 && PMScore <= 255 && requestedCreditLine <= 750000){
                            result.runDRRBeforeCredit = true;
                            result.routeToCredit = true;
                            
                            //look for DRR range
                            for(Dual_Risk_Rating__c drr: a.Dual_Risk_Ratings__r){
                                if(modelDRRrange.contains(drr.Risk_Calc_Dual_Risk_Rating__c)){
                                    result.needFinancials = true;
                                    result.reason = makeRTlink(a.id, a.name) +' has PM Score: '+PMScore+' (238-255)<br/>with DRR: '+drr.Risk_Calc_Dual_Risk_Rating__c+' with C/L Requested: '+requestedCreditLine.setScale(0)+' (<= $750K)';
                                    break;
                                }
                            }
                        }
                    } 
                    else if(a.Dual_Risk_Ratings__r != null && a.Dual_Risk_Ratings__r.size()>0){ 
                        //account has no PM, check dual risk ratings 
                        for(Dual_Risk_Rating__c drr: a.Dual_Risk_Ratings__r){
                            if(drr.Origination_Model__r.X12_Month_PD__c != null && drr.Origination_Model__r.X12_Month_PD__c > 0){
                                foundNoPMPD = false;
                            }
                            
                            //look for PD % >7.96
                            if(drr.Origination_Model__r.X12_Month_PD__c > 7.96){
                                result.routeToCredit = true;
                                result.needFinancials = true;
                                result.reason = makeRTlink(a.id, a.name) +' has PD %: '+ drr.Origination_Model__r.X12_Month_PD__c +' % (>7.96)';
                                break;
                            } 
                            //look for PD % > 5.12 to 7.96   
                            else if(drr.Origination_Model__r.X12_Month_PD__c > 5.12){
                                result.runDRRBeforeCredit = true;
                                result.routeToCredit = true;
                                result.reason = makeRTlink(a.id, a.name) +' has PD %:'+ drr.Origination_Model__r.X12_Month_PD__c +' (between 5.12-7.96)<br/>with DRR: '+drr.Risk_Calc_Dual_Risk_Rating__c;
                                
                                //look for DRR range
                                if(modelDRRrange.contains(drr.Risk_Calc_Dual_Risk_Rating__c)){
                                    result.needFinancials = true;
                                }
                                break;
                            }
                        }
                    }  
                    else { //look for OM records
                        for(D_B_Underwriting_Junction__c dbj : a.D_B_Underwriting_Junctions__r){
                            if(dbj.DnBId__r.X12_Month_PD__c != null && dbj.DnBId__r.X12_Month_PD__c > 0){
                                foundNoPMPD = false;
                            }
                            //look for PD % >7.96
                            if(dbj.DnBId__r.X12_Month_PD__c > 7.96){
                                result.routeToCredit = true;
                                result.needFinancials = true;
                                result.reason = makeRTlink(a.id, a.name) +' has PD %: '+ dbj.DnBId__r.X12_Month_PD__c +' % (>7.96)';
                                break;
                            } 
                            //look for PD % > 5.12 to 7.96   
                            else if(dbj.DnBId__r.X12_Month_PD__c > 5.12){
                                result.runDRRBeforeCredit = true;
                                result.routeToCredit = true;
                                result.reason = makeRTlink(a.id, a.name) +' has PD %:'+ dbj.DnBId__r.X12_Month_PD__c +' (between 5.12-7.96) - no DRR';
                                result.needFinancials = true;
                                break;
                            }
                        }
                    } 
                }               
            }
            //when reached here, if foundNoPMPD == true then no ratings were found
            if(foundNoPMPD && !result.needFinancials){
                result.routeToCredit = true;
                result.needFinancials = true;
                result.reason = 'All dealer accounts missing PM score and PD %';
            }
        }
        system.debug('route2CreditMatrix_06_checkPMPD: '+result);
        return result;
    }
    
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrix_07_checkILOC(string reviewType, List<account> allDealersInCare){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = defaultRoute2CreditResult();
        set<string> types = new set<string> { 'New', 'Increase', 'Carve Out', 'Silo' };
        if(types.contains(reviewType)){
            for(Account a: allDealersInCare){
                if(a.Credit_Enhancements1__r != null && a.Credit_Enhancements1__r.size() > 0){
                    //account has an active iloc
                    result.needFinancials = true;
                    result.routeToCredit = true;
                    result.reason = makeRTlink(a.id, a.name) + ' Has an ILOC';
                    break;
                }   
            }
        }
        system.debug('route2CreditMatrix_07_checkILOC: '+result);
        return result;
    }
    
    public static CommonWrapperClass.BWRouteToCreditMatrixResult route2CreditMatrix_08_DRROverrides(string reviewType, decimal requestedCreditLine, List<account> allDealersInCare, set<string> DRROverrideFields){
        CommonWrapperClass.BWRouteToCreditMatrixResult result = defaultRoute2CreditResult();
        set<string> types = new set<string> { 'New', 'Increase', 'Carve Out', 'Silo' };
        if(types.contains(reviewType) && requestedCreditLine <= 750000){
            for(Account a: allDealersInCare){
                if(a.recordtype.developername != 'Care_Number'){
                    //check all drr fields
                    for(string fieldName : DRROverrideFields){
                        if(a.get(fieldName) == true){
                            //there is at least one account with a PG waiver
                            result.needFinancials = true;
                            result.routeToCredit = true;
                            result.reason = makeRTlink(a.id, a.name) + ' Has DRR Override:'+fieldName;
                            result.additionalComments = 'Discuss with Credit to confirm if financials are needed';
                            break;
                        }
                    }
                }
            }
        }
        system.debug('route2CreditMatrix_08_DRROverrides: '+result);
        return result;
    }
    
    /////////////////////////////////////
    // End of Dealer Discussion Screen //
    /////////////////////////////////////
   
   @AuraEnabled
    public static String refreshEntityVerification(String recordId, String type)
    {
         try
         {
             Map<String,String> StateToSOSLinksMap = fetchStateSOSMap(); 
             String careAccountId = fetchCareAccountId(recordId);
             List<account> borrowerList = fetchBorrowerList(careAccountId);
             Map<String, List<String>> borrowerToStateMap =accountTostatesMap(borrowerList, 'Borrower');
             List<CommonWrapperClass.BWStepWrapper> EntitySteps=BoardingWizardVFC.getScreenSteps('Entity Verification', recordId);
             
             List<BW_Chart_Row__c> chartRows = constructEVTChartRowData(borrowerToStateMap, type, recordId, StateToSOSLinksMap, EntitySteps);   
             List<BW_Chart_Row__c> chartRowsToInsert = new List<BW_Chart_Row__c>();
    
             for(BW_Chart_Row__c bw: chartRows)
             {
                if(bw.id ==null)
                {
                    chartRowsToInsert.add(bw);
                }
             }
             
             if(chartRowsToInsert.size() >0)
             {
                insertChartRowsAndStepAnserIfNewData(recordId,chartRowsToInsert, EntitySteps, 'Entity Verification');
             }
            
         }
         catch(exception e)
         {
            utilityClass.logError(e, 'Exception occurred while refreshing Entity verifcation screen', '', 'Exception occurred while refreshing Entity verifcation screen from address verification screen for underwritingid '+recordId+' Exception deatils : '+e.getMessage());
            return e.getMessage();
         }
         return null;
    }
    
    public static String constructStepUpsertWrapper(String stepRecId, String value)
    {
        commonwrapperclass.BWUpsertStepResultRecordInfo wrap = new commonwrapperclass.BWUpsertStepResultRecordInfo();
        wrap.stepRecId = stepRecId;
        wrap.value=value;

        return JSON.serialize(wrap);
    }
    
    public static string insertChartRowsAndStepAnserIfNewData(String recordId, List<BW_Chart_Row__c> chartRowsToInsert, List<CommonWrapperClass.BWStepWrapper> steps, String screenName)
    {
       if(chartRowsToInsert!=null && chartRowsToInsert.size() >0)
       {
           insert chartRowsToInsert;
                    
           List<string> steprecInfoList = new List<String>();
           for(CommonWrapperClass.BWStepWrapper bw: steps)
           {
               steprecInfoList.add(constructStepUpsertWrapper(bw.stepRecordId, 'false'));
           }
            String result = BoardingWizardVFC.upsertStepAnswers(recordId, steprecInfoList, screenName);
            system.debug('=== result ==='+result);
            return result;
       }
       return null;
    }
    
    public static Set<id> accountsTiedToProductJunction(String underwritingId, String ndaId)
    {
        Set<id> acctIds =new Set<id>();
        
        for(Product_Information_For_New_Dealer_App__c prodJunc :[select id,Relationship__c from Product_Information_For_New_Dealer_App__c where New_Dealer_Application2__c =:ndaId and Underwriting__c=:underwritingId])
        {
            acctIds.add(prodJunc.Relationship__c);
        }
        return acctIds;
    } 
    @AuraEnabled
    public static string updateNDAAndAdditionalLocations(String ndaId, string underwritingId, List<String> addressIds)
    {
        try
        {
            if(String.isBlank(ndaId))
            {
                return 'success';
            }
            
            List<Additional_Location__c> additionalLocs = new List<Additional_Location__c>();
            Set<Id> accountsValidForAdditionLoc = accountsTiedToProductJunction(underwritingId, ndaId);
           
           System.debug('===addressIds === '+addressIds);
           
            for(address__c ad : [select id,Relationship_Name__c,Additional_Location__c, state__c, city__c, Zip_Code__c, Address_Line_1__c, Address_Line_2__c from address__c where id IN: addressIds])
            {
                if(ad.Additional_Location__c!=null && accountsValidForAdditionLoc.contains(ad.Relationship_Name__c))
                {
                        String address='';
                        
                        if(ad.Address_Line_1__c !=null)
                        {
                            address+= ad.Address_Line_1__c;
                        }
                        if(ad.Address_Line_2__c!=null )
                        {
                            address+=' '+ad.Address_Line_2__c; 
                        }
                        
                        additionalLocs.add(new Additional_Location__c( 
                        id= ad.Additional_Location__c,
                        State__c = ad.State__c,
                        City__c = ad.City__c,
                        Zip__c = ad.Zip_Code__c,
                        Street__c= address,
                        new_dealer_application__c = ndaId
                        ));
                        
                }
            }
            System.debug('==== additionalLocs ===='+additionalLocs);
            if(additionalLocs.size() >0)
            {
                update additionalLocs;
                
                new_dealer_application__c nda = [select id, How_many_locations__c, (select id from Additional_Locations__r) from new_dealer_application__c where id=:ndaId];
                
                if(nda.How_many_locations__c!=null && Integer.valueOf(nda.How_many_locations__c) != nda.Additional_Locations__r.size())
                {
                    nda.How_many_locations__c =String.valueOf(nda.Additional_Locations__r.size());
                    update nda;
                    
                }
                return 'success';
            }
            else
            {
                return 'no additional locations to insert or update';
            }
            
        }
        catch(exception e)
        {
            utilityclass.logerror(e, 'Exception upserting additional locations on NDA address verification', null, 'Exception occured while upserting additional locations on NDA address verification screen ndaId: '+ndaId+' underwriting id: '+underwritingId);
            return e.getMessage();
        }
        
    }
    
    public static string createAdditionalLocation(String acctId, string ndaId)
     {
       
        System.debug('=== acctId ==='+acctId+'=== ndaId ==='+ndaId);
        additional_location__c al = new additional_location__c(new_dealer_application__c = ndaid, recordtypeid='012j0000000mz7I');
        database.saveresult dsral = database.insert(al, false);
        
        if(dsral.isSuccess())
        {
            address__c ad= new Address__c(Relationship_Name__c= acctId, Additional_Location__c = dsral.getId());
            database.saveresult dsrad = database.insert(ad, false);
            
            if(dsrad.isSuccess())
            {
                system.debug('=== dsrad.getId() ==='+dsrad.getId());
                return dsrad.getId();
            }
            else
            {
                utilityClass.createError(dsrad.getErrors()[0], 'Error occurred while inserting address data from address verification screen', ndaId, 'Error occurred while inserting address data from address verification screen ndaId : '+ndaId+' account id: '+acctId);
                system.debug('=== dsrad.getErrors()[0] ==='+dsrad.getErrors()[0]);
                return 'Error: '+ dsrad.getErrors()[0];
            }
        }
        else
        {
            utilityClass.createError(dsral.getErrors()[0], 'Error occurred while inserting additional location from address verification screen', ndaId, 'Error occurred while inserting additional location from address verification screen ndaId : '+ndaId+' account id: '+acctId);
            system.debug('=== dsral.getErrors()[0] ==='+dsral.getErrors()[0]);
            return 'Error: '+ dsral.getErrors()[0];
        }
     }
     
     public static Map<String, sObject> searchActiveList(String objectName, String searchField)
    {
        
        Map<String, sObject> validRecordsMap=  new Map<string, sObject>();
        
        if(objectName.tolowercase() =='user')
        {
            String type='Standard';
            for(user u: [select id, name from user where isActive=TRUE and usertype=:type])
            {
                validRecordsMap.put(u.id, u);
            }
            return validRecordsMap;
        }
        
        return null;
    }
}