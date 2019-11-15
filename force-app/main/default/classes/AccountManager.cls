/******************************************************************************************************************************
* @class name  : AccountManager
* @description : AccountManager has the following functionality 
                 1) Trigger changes Send_PM_Downgrade_Email__c to true to trigger workflow to send email to account owner if there are certain changes in Risk Grade.
  
* @test class  : AccountManager_UT
* @key methods : createWatchListEmailList: Looks at the new and old value of account and sets the PM Rating downgrade flag
                sendDirectContact: Creates a general task regarding deficienct Case 
                sendDirectContactForOverOneDeficientCases: Creates a general task regarding multiple deficient cases     
                sendDirectContactForOver100k: Creates a general task regarding a deficient case over 100k
                sendEmail1: Sends email based on different language
                sendEmail2: Sends email based on different language
                populateCARENumbers: Populates care numbers
                PopulateLegalEntities: Populates legal entities
                CalculateCareFieldsForAccounts:Create map based on care numbers
                UpdateCareCreditLineAmount: Update credit line amount on accounts
                consolidateDealerCreditLineAmount: Return sum of line amounts
* @author      : Joe Hessburg
* @date        : 04/20/2015             ////////////////////////////////////////////////////////////////////////////////
                   
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer                   Date(MM/DD/YYYY)       Description
* -----------------------------------------------------------------------------------------------------------------
* Joe Hessburg                  04/20/2015             Created class log.
    MT                          02/04/2019            added dispo type exclusion filter for WI 3086
    MT                          03/26/2019            WI 3590 added new logic to sendEmail method for special WSAU case (RV/MARINE)

******************************************************************************************************************************/
public class AccountManager 
{
    //Added by Nimish to eliminate execution of query each time the related method is called 
     // Santosh - changes made to reference developerNames instead of label WI 1535
      public static Id rTIdTaskGeneral = Constants.TaskRTMap.get('General');
     public static final List<String> ASSOCIATION_FILTER_TYPES = new List<String>{'Customer-Supplier Relationship'};
    // Santosh - changes made to reference developerNames instead of label WI 1535
      public static Id rTIdAccountGuarantorOwner = Constants.AccountRTGuarantor;
    

    public static List<DBA_Name__c> getDBARecordsForThisRealtionship(id relationshipId)
    {
        List<account> acctsList = [select id, (select id, dba_name__c from DBA_Names__r where relationship__c =: relationshipId) from account where id=:relationshipId];

        List<DBA_Name__c> dbaNamesList = acctsList[0].DBA_Names__r;

        return dbaNamesList;
    }

    
    //Added by Nimish
    public void assignISR(Map<id, Account> acctsMap)
    {
        User defaultSalesRep = [select id from user where isactive=true and profile.name = 'TCF Business Support Admin' order by createddate desc][0];
        
        List<Region_Assignment_By_Code__c> regionCodesList = new List<Region_Assignment_By_Code__c>();
        regionCodesList = [select id, code__c, country__c, Region_Assignment__c, Region_Assignment__r.Assigned_Inside_Sales_Rep__c from Region_Assignment_By_Code__c];
    
        List<account> acctsList = [select id, recordtypeid, care_Number__c, billingCountry, billingState, Assigned_Inside_Sales_Rep__c, New_Dealer_Application__r.Electronic_Communication_Consent__c, New_Dealer_Application__r.createddate, New_Dealer_Application__r.Name from account where id in :acctsMap.keySet()];
        
        for(Account a : acctsList)
        {
          //Added by Nimish to replace Assign Inside Sales Rep - Realtionship and Update Relationship - Application Fields flows
          //Assign Sales Rep based on account's country and state
          if((a.BillingCountry != null && a.BillingCountry != '') && (a.BillingState != null && a.BillingState != ''))
          {
            for(Region_Assignment_By_Code__c rc: regionCodesList)
            {
              if(a.BillingCountry == rc.country__c && a.BillingState == rc.code__c)
              {
                a.Assigned_Inside_Sales_Rep__c = rc.Region_Assignment__r.Assigned_Inside_Sales_Rep__c;
                break;
              }
            }
          }
          
          if(a.Assigned_Inside_Sales_Rep__c == null)
          {
            a.Assigned_Inside_Sales_Rep__c = defaultSalesRep.id;
          }
        }
        
        update acctsList;
    }
   
   /*
  //TransUnion Report indicates the subject (Gaurantor/Owner/Affiliate) to be DECEASED
  public boolean TUReportIndicatesSSNOfDeceasedSubject(Id guarantorOwnerAffiliateRelId)
  {
    boolean isDeceased = false;
    
    Account a = [select id, CBR_XML_Response_2__c from account where id=:guarantorOwnerAffiliateRelId LIMIT 1];
    
    if(a != null && a.CBR_XML_Response_2__c != null && a.CBR_XML_Response_2__c != '')
    { 
      //Look for Message code of 4001 in the TU XML Response that would indicate a deceased subject SSN.
      //Actual message will look like this: "... INPUT SSN IS REPORTED DECEASED ..."  
      if(a.CBR_XML_Response_2__c.toUpperCase().contains('<MESSAGE SOURCE=\"INPUT\"><CODE>4001</CODE></MESSAGE>'))
      {
        isDeceased = true;
      }
    }
    
    return isDeceased;
  }
  
  //TransUnion Report indicates the subject's provided SSN does not match TU records (Gaurantor/Owner/Affiliate)
  public boolean TUReportIndicatesSubjectSSNMismatch(Id guarantorOwnerAffiliateRelId)
  {
    boolean ssnMismatch = false;
    
    Account a = [select id, CBR_XML_Response_2__c from account where id=:guarantorOwnerAffiliateRelId LIMIT 1];
    
    if(a != null && a.CBR_XML_Response_2__c != null && a.CBR_XML_Response_2__c != '')
    {
      if(!a.CBR_XML_Response_2__c.toUpperCase().contains('<SSNMATCHINDICATOR>EXACT</SSNMATCHINDICATOR>'))
      {
        ssnMismatch = true;
      }
    }
    
    return ssnMismatch;
  }
  */
  
  //If TU CBR Reponse comes back with data verification issues, return true else false
  public static boolean TUCBRResponseHasDataIssues(Id guarantorOwnerAffiliateRelId)
  {
    boolean TUDataVerificationIssues = false;
    
    Account a = [select id, CBR_Error_Messages__c, ID_Mismatch_Alert__c, /*IdentityAlerts__c, HighRiskFraudAlert__c,*/ No_Score_Returned__c from account where id=:guarantorOwnerAffiliateRelId LIMIT 1];
    
    if(a != null)
    {  
      if(
              a != null 
           && (   (!string.isBlank(a.CBR_Error_Messages__c) && (a.CBR_Error_Messages__c != 'CBR Pulled within the last 120 Days'))  
                || !string.isBlank(a.ID_Mismatch_Alert__c)
                || a.No_Score_Returned__c== true
              )
              /*|| !string.isBlank(a.Identity_Alert__c) || !string.isBlank(a.HighRiskFraudAlert__c))) */
         )
          
      {
        TUDataVerificationIssues = true;
      }
      
      system.debug(TUDataVerificationIssues);
    }
    
    return TUDataVerificationIssues;  
  } 
   
   // Santosh - Commenetd WI 2076 
   /** public void createWatchListEmailList(Map<Id, Account> oldMap, Map<Id, Account> newMap){
        Account newAcct = new Account();
        List<Account> accountsToEmail = new List<Account>();
        Integer oldGrade;
        Integer newGrade;
            
        for(Account a : oldMap.values()){
            if(newMap.containsKey(a.Id)){
                newAcct = newMap.get(a.Id);
                
                if(a.LLC_BI_PARTIAL__Highest_Risk_Grade__c != newAcct.LLC_BI_PARTIAL__Highest_Risk_Grade__c){
                    if(a.LLC_BI_PARTIAL__Highest_Risk_Grade__c != null)
                        oldGrade = Integer.valueOf(a.LLC_BI_PARTIAL__Highest_Risk_Grade__c);
                    if(newAcct.LLC_BI_PARTIAL__Highest_Risk_Grade__c != null)
                        newGrade = Integer.valueOf(newAcct.LLC_BI_PARTIAL__Highest_Risk_Grade__c);
                    
                    if(oldGrade!=null && newGrade!=null){
                        boolean gradeChangeOverTwo = ((newGrade - oldGrade) >= 2);
                        
                        if(gradeChangeOverTwo && newGrade > 5){
                            if(newAcct.Add_to_Watchlist__c == true)
                                newAcct.Send_PM_Rating_Downgrade_Email__c = true;
                        }
                        else if(oldGrade > 5 && newGrade < 6 && newGrade >=2){
                                newAcct.Send_PM_Rating_Downgrade_Email__c = false;
                        }
                    }
                }
            }
        }
    } */
    
    
    
    //WI 0219 - Close aged disposition case if Current_Disposition_Code_Amount__c = 0
    public void closeAgedDispCasesWithZeroDispAmount(Map<id, account> oldMap, Map<id, account> newMap)
    {
      List<id> accountIdsToProcess = new List<id>();
      List<case> openAgedDispCasesForTriggeredAccounts = new List<case>();
     
      for(Account a: newMap.values())
      {
        if(   a.DT_Amount__c != oldMap.get(a.id).DT_Amount__c
           || a.LD_Amount__c != oldMap.get(a.id).LD_Amount__c
           || a.SM_Amount__c != oldMap.get(a.id).SM_Amount__c
           || a.NS_Amount__c != oldMap.get(a.id).NS_Amount__c
           || a.DM_Amount__c != oldMap.get(a.id).DM_Amount__c
           || a.LU_Amount__c != oldMap.get(a.id).LU_Amount__c
           || a.SU_Amount__c != oldMap.get(a.id).SU_Amount__c
           || a.LN_Amount__c != oldMap.get(a.id).LN_Amount__c
           || a.LO_Amount__c != oldMap.get(a.id).LO_Amount__c
           || a.RT_Amount__c != oldMap.get(a.id).RT_Amount__c
           || a.RM_Amount__c != oldMap.get(a.id).RM_Amount__c
           || a.SD_Amount__c != oldMap.get(a.id).SD_Amount__c
           || a.IT_Amount__c != oldMap.get(a.id).IT_Amount__c
           || a.OR_Amount__c != oldMap.get(a.id).OR_Amount__c
           || a.UV_Amount__c != oldMap.get(a.id).UV_Amount__c
           || a.UN_Amount__c != oldMap.get(a.id).UN_Amount__c
           || a.RU_Amount__c != oldMap.get(a.id).RU_Amount__c
           || a.ST_Amount__c != oldMap.get(a.id).ST_Amount__c
        )
        { 
           accountIdsToProcess.add(a.id);
        }
      }
     
     // Santosh - changes made to reference developerNames instead of label WI 1535   
     // 2.4.19 added dispo type exclusion filter for WI 3086
      openAgedDispCasesForTriggeredAccounts = [select id, status, Disposition_Type__c from case where accountid in :accountIdsToProcess and status != 'Closed' and recordtypeid=:Constants.caseRTMap.get('Aged_Dispositions') 
          AND Disposition_Type__c != 'XX' AND Current_Disposition_Code_Amount__c = 0]; 
      
      for(Case c: openAgedDispCasesForTriggeredAccounts)
      {
        c.status = 'Closed';
      }
      
      if(openAgedDispCasesForTriggeredAccounts.size() > 0)
        update openAgedDispCasesForTriggeredAccounts;
     
    }
    
    public Task sendDirectContact(Account a, Id caseId, String deficiencyType){
        Task t = new Task(
        ActivityDate = Date.today(),
        RecordTypeId = rTIdTaskGeneral,
        Description = 'Contact ' + a.Primary_Contact_Name__c + ' regarding deficienct Case: ' + caseId,
        OwnerId = a.Account_Manager__c,
        whatId = caseId,
        Subject = 'Deficient Case Direct Contact - ' + deficiencyType + ' - ' + a.WMS_Customer__c);

        return t;
    }
    
    public Task sendDirectContactForOverOneDeficientCases(Account a, Id caseId){
        Task t = new Task(
        ActivityDate = Date.today(),
        RecordTypeId = rTIdTaskGeneral,
        Description = 'Contact ' + a.Primary_Contact_Name__c + ' regarding multiple deficient cases.',
        OwnerId = a.Account_Manager__c,
        whatId = caseId,
        Subject = 'Deficient Case Direct Contact - ' + a.WMS_Customer__c);
        
        return t;
        
    }
    
    public Task sendDirectContactForOver100k(Account a, Id caseId){
        Task t = new Task(
        ActivityDate = Date.today(),
        RecordTypeId = rTIdTaskGeneral,
        Description = 'Contact ' + a.Primary_Contact_Name__c + ' regarding a deficient case over 100k.',
        OwnerId = a.Account_Manager__c,
        whatId = caseId,
        Subject = 'Deficient Case Direct Contact - ' + a.WMS_Customer__c);

        return t;
    }
    
    public Messaging.SingleEmailMessage sendEmail(Account a, Case c, Id analystEmailId, Integer emailNumber, Map<String, EmailTemplate> templateMap, Contact cnt)
{
        
        String templateName = '';
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        try
        {       
            email.setOrgWideEmailAddressId(analystEmailId);
            List<String> toAddresses = new List<String>{a.Primary_Contact_Email_Address__c};
            email.setToAddresses(toAddresses);
            
             
            
            if(c.Deficiency_Type__c == 'Past Due Interest' || c.Deficiency_Type__c == 'Past Due Curtailment' || c.Deficiency_Type__c == 'Past Due Scheduled Payment' || c.Deficiency_Type__c == 'WSAU' || c.Deficiency_Type__c == 'NP')
            {
                //added for WI 3590
                if(c.Deficiency_Type__c == 'WSAU' && (a.business_unit__c == 'RV_US' || a.business_unit__c == 'MARINE_US')){
                    templateName = 'Stat_Survey_SAU_Email_1' ;
                }
                else if(a.Selected_Language__c == 'French Canadian'){
                    if(c.Deficiency_Type__c == 'Past Due Interest')
                        templateName = 'Past_Due_Interest_Email_' + emailNumber + '_CAN_FR';
                    else if(c.Deficiency_Type__c == 'Past Due Curtailment')
                        templateName = 'Past_Due_Curtailment_Email_' + emailNumber + '_CAN_FR';
                    else if(c.Deficiency_Type__c == 'Past Due Scheduled Payment')
                        templateName = 'Past_Due_Scheduled_Pay_Email_' + emailNumber + '_CAN_FR';
                    else if(c.Deficiency_Type__c == 'WSAU')
                        templateName = 'Warranty_SAU_Email_1_CAN_FR';
                    //Anthony - Added for WI 1504
                    else if(c.Deficiency_Type__c == 'NP')
                        templateName = 'SAU_Email_' + emailNumber + '_CAN_FR';

                }
                else if(a.Finance_Company__c == '229'){
                    if(c.Deficiency_Type__c == 'Past Due Interest')
                        templateName = 'Past_Due_Interest_Email_' + emailNumber + '_RIA';
                    else if(c.Deficiency_Type__c == 'Past Due Curtailment')
                        templateName = 'Past_Due_Curtailment_Email_' + emailNumber + '_RIA';
                    else if(c.Deficiency_Type__c == 'Past Due Scheduled Payment')
                        templateName = 'Past_Due_Scheduled_Pay_Email_' + emailNumber + '_RIA';
                    else if(c.Deficiency_Type__c == 'WSAU')
                        templateName = 'Warranty_SAU_Email_1_RIA';
                    // Santosh -added for WI 1504
                    else if(c.Deficiency_Type__c == 'NP')
                        templateName = 'SAU_Email_' + emailNumber + '_RIA';

                }
                else{
                    if(c.Deficiency_Type__c == 'WSAU')
                        templateName = 'Warranty_SAU_Email_1';
                    else if(c.Deficiency_Type__c == 'Past Due Interest')
                        templateName = 'Past_Due_Deficiency_Email_' + emailNumber + '_Interest';
                    else if(c.Deficiency_Type__c == 'Past Due Curtailment')
                        templateName = 'Past_Due_Deficiency_Email_' + emailNumber + '_Curtailment';
                   // Santosh -added for WI 1504 
                    else if(c.Deficiency_Type__c == 'NP')
                        templateName = 'SAU_Email_' + emailNumber;


                    else
                        templateName = 'Past_Due_Deficiency_Email_' + emailNumber + '_Scheduled_Pay';
                }
                system.debug('templateName = ' + templateName);
                
                if(templateName != '' )
                {
                     
                     if(templateMap.containsKey(templateName))
                     {
                          email.setTemplateId(templateMap.get(templateName).Id);
                          email.setSaveAsActivity(false);
                          email.setTargetObjectId(cnt.Id);
                          email.setWhatId(a.Id);
                        
                          return email;
                      }
                      
                      // Santosh -added to log error if template Name is not found -Wi 2035
                      else if(!templateMap.containsKey(templateName))
                      {
                            try
                            {
                                 Error__c er = new Error__c(Message__c ='error in AccountManager email Creation', custom_message__c = 'error in AccountManager email Creation- Template Not Found:'+templateName+ ' The following email was affected : '+email);
                                 insert er;
                                 
                                 return null;
                            }
                            
                            catch(exception ex)
                            {
                            
                            }
                      }
               }
            }          
        }   
        
        // Santosh -added to log exception WI 2035
        catch(exception e)
        {
             try
             {
                utilityClass.logError(e, 'exception in AccountManager email Creation', '', e.getMessage()+' Template Name is :'+templateName+ 'The following email was affected : '+email);
             }
              
             catch(exception ex)
             {
                
             }
              
             return null;
        }
        
        return null;
    }
    
    
    public void populateCARENumbers(List<Account> carelessAccounts) {
             
        Set<String> wmsNumbers = new Set<String>();
        Set<String> phoneNumbers = new Set<String>();
        Set<String> legalNames = new Set<String>();
        Set<Id> parentIds = new Set<Id>();
        Set<String> parentWMSNumbers = new Set<String>();

        Set<String> guarantorNames = new Set<String>();
        Set<String> ssns = new Set<String>();
        Set<String> taxIds = new Set<String>();
        
        Set<Id> carelessAccountIds = new Set<Id>();
        
        // Santosh -added for bugfix WI 0362
         Map<Id, String> matchCriteriaMap = new Map<Id, String>();
         //
         
        Id careMatchId;
        
        // START - pulling out comparison terms
        for(Account a : carelessAccounts) {
            
            carelessAccountIds.add(a.Id);
            
            if(a.WMS_Customer__c != null)
                wmsNumbers.add(a.WMS_Customer__c);
            if(a.Phone != null)
                phoneNumbers.add(a.Phone);
                
          // Santosh -commented for WI 2076
          /**  if(a.Legal_Entity_NameOld__c != null)
                legalNames.add(a.Legal_Entity_NameOld__c); */
                
            if(a.Name != null) {
                legalNames.add(a.Name);
            }
            if(a.ParentId != null)
                parentIds.add(a.ParentId);
            if(a.Searchable_LLC_BI_Tax_Id_Number__c != null || a.Tax_Identification_Number__c != null) {
                if(a.Searchable_LLC_BI_Tax_Id_Number__c != null) {
                    taxIds.add(a.Searchable_LLC_BI_Tax_Id_Number__c);
                }
                else if (a.Tax_Identification_Number__c != null) {
                    a.Searchable_LLC_BI_Tax_Id_Number__c = EncryptionUtils.encryptSSN(a.Tax_Identification_Number__c);
                    taxIds.add(a.Searchable_LLC_BI_Tax_Id_Number__c);
                }
            }
        }
        
        //Pull related guarantors for each account
        Map<Id, List<Associated_Relationships__c>> primaryRelationshipToGuarantors = new Map<Id, List<Associated_Relationships__c>>();
        // Santosh - removed "And Primary_Relationship__c in: carelessAccountIds" from soql query
        
        for(Associated_Relationships__c ar : [Select Id, Primary_Relationship__c, Secondary_Relationship__c, Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c, Secondary_Relationship__r.Searchable_Security_Number__c, Secondary_Relationship__r.Social_Security_Number__c, Secondary_Relationship__r.Name, Secondary_Relationship__r.BillingState from Associated_Relationships__c Where /**Association_Type__c != 'Customer Supplier Relationship'*/ Association_Type__c NOT IN:ASSOCIATION_FILTER_TYPES And Association_Type__c != null And (/**Secondary_Relationship__r.RecordTypeId = :rTIdAccountGuarantor Or Secondary_Relationship__r.RecordTypeId = :rTIdAccountGuarantorConsent Or */Secondary_Relationship__r.RecordTypeId = :rTIdAccountGuarantorOwner) And Primary_Relationship__c in: carelessAccountIds]) {
            if(ar.Secondary_Relationship__r.Searchable_Security_Number__c != null) {
                ssns.add(ar.Secondary_Relationship__r.Searchable_Security_Number__c);
            }
            if(ar.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c != null) {
                taxIds.add(ar.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c);
            }
            if(ar.Secondary_Relationship__r.Name != null) {
                guarantorNames.add(ar.Secondary_Relationship__r.Name);
            }
            
            if(!primaryRelationshipToGuarantors.containsKey(ar.Primary_Relationship__c)) {
                primaryRelationshipToGuarantors.put(ar.Primary_Relationship__c, new List<Associated_Relationships__c>());
            }
            primaryRelationshipToGuarantors.get(ar.Primary_Relationship__c).add(ar);
        } // END - // pulling out comparison terms

        list<Account> wmsAccounts = [Select Id, WMS_Customer__c, Care_Number__c from Account Where WMS_Customer__c in: wmsNumbers And Care_Number__c != null];
        list<Account> phoneAccounts = [Select Id, Phone, Care_Number__c from Account Where Phone in: phoneNumbers And Care_Number__c != null];
        
        //Santosh -added for WI 2076
        //list<Account> legalAccounts = [Select Id, Legal_Entity_NameOld__c,  Name, BillingState, Care_Number__c from Account Where (Legal_Entity_NameOld__c in: legalnames Or Name in: legalnames) And Care_Number__c != null];
          list<Account> legalAccounts = [Select Id,  Name, BillingState, Care_Number__c from Account Where Name in: legalnames And Care_Number__c != null];
          
        //
        // Added encrypted field search feature
       
        List<Account> taxIdAccounts = [SELECT Id, Searchable_LLC_BI_Tax_Id_Number__c, Care_Number__c FROM Account WHERE Searchable_LLC_BI_Tax_Id_Number__c IN :taxIds AND Care_Number__c != null];

        // 
        // Guarantor match by ssn logic
        //
        List<Associated_Relationships__c> ssnAccountRelationships = [
            select 
                Id
                ,Primary_Relationship__c
                ,Primary_Relationship__r.Name
                ,Primary_Relationship__r.Care_Number__c
                ,Secondary_Relationship__r.Searchable_Security_Number__c
            from 
                Associated_Relationships__c
            where 
                /**Association_Type__c != 'Customer Supplier Relationship' */ Association_Type__c NOT IN:ASSOCIATION_FILTER_TYPES
            and 
                Association_Type__c != null
            and 
                Secondary_Relationship__r.Searchable_Security_Number__c in :ssns
            and 
                Primary_Relationship__r.Care_Number__c != null
        ];
        

        //
        // Guarantor match by name logic
       
        List<Associated_Relationships__c> guarantorNameAccountRelationships = [
            select 
                Id
                ,Primary_Relationship__c
                ,Secondary_Relationship__r.Name
                ,Primary_Relationship__r.Care_Number__c
                , Secondary_Relationship__r.BillingState
            from 
                Associated_Relationships__c
            where 
               /** Association_Type__c != 'Customer Supplier Relationship' */ Association_Type__c NOT IN:ASSOCIATION_FILTER_TYPES
            and 
                Association_Type__c != null
            and 
                Secondary_Relationship__r.Name in :guarantorNames
            and 
                Primary_Relationship__r.Care_Number__c != null
        ];
        
        List<Associated_Relationships__c> guarantorTaxIdAccountRelationships = [Select Id, Primary_Relationship__c, Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c, Primary_Relationship__r.Care_Number__c From Associated_Relationships__c Where /**Association_Type__c != 'Customer Supplier Relationship'*/ Association_Type__c NOT IN:ASSOCIATION_FILTER_TYPES And Association_Type__c != null And Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c in: taxIds And Primary_Relationship__r.Care_Number__c != null];

        Map<String, Set<Id>> wmsAccountMap = new Map<String, Set<Id>>();
        
        Map<String, Set<Id>> phoneAccountMap = new Map<String, Set<Id>>();
        for(Account a : phoneAccounts) {
            if(!phoneAccountMap.containsKey(a.Phone))
                phoneAccountMap.put(a.Phone, new set<Id>());
            phoneAccountMap.get(a.Phone).add(a.Care_Number__c);
        }
          
        Map<String, Set<Id>> legalAccountMap = new Map<String, Set<Id>>();
          //Santosh - commenetd for BugFix Wi 0362 
        for(Account a : legalAccounts) {
          
            
            if(a.Name != null) {
                if(!legalAccountMap.containsKey(a.BillingState + a.Name))
                    legalAccountMap.put(a.BillingState + a.Name, new Set<Id>());
                legalAccountMap.get(a.BillingState + a.Name).add(a.Care_Number__c);
            }
        }
        
  
        //
        // Added encrypted field search feature
        //
        Map<String, Set<Id>> ssnAccountMap = new Map<String, Set<Id>>();
        for(Associated_Relationships__c r : ssnAccountRelationships) {
            if(!ssnAccountMap.containsKey(r.Secondary_Relationship__r.Searchable_Security_Number__c)) {
                ssnAccountMap.put(r.Secondary_Relationship__r.Searchable_Security_Number__c, new Set<Id>());
            }

            ssnAccountMap.get(r.Secondary_Relationship__r.Searchable_Security_Number__c).add(r.Primary_Relationship__r.Care_Number__c);
        }
        Map<String, Set<Id>> taxIdAccountMap = new Map<String, Set<Id>>();
        for(Account a : taxIdAccounts) {
            if(!taxIdAccountMap.containsKey(a.Searchable_LLC_BI_Tax_Id_Number__c)) {
                taxIdAccountMap.put(a.Searchable_LLC_BI_Tax_Id_Number__c, new Set<Id>());
            }

            taxIdAccountMap.get(a.Searchable_LLC_BI_Tax_Id_Number__c).add(a.Care_Number__c);
        }
        for(Associated_Relationships__c r : guarantorTaxIdAccountRelationships) {
            if(!taxIdAccountMap.containsKey(r.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c)) {
                taxIdAccountMap.put(r.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c, new Set<Id>());
            }
            
            taxIdAccountMap.get(r.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c).add(r.Primary_Relationship__r.Care_Number__c);
        }
        
          
        //
        // Guarantor match by name logic
        //
        Map<String, Set<Id>> guarantorNameAccountMap = new Map<String, Set<Id>>();
        for(Associated_Relationships__c r : guarantorNameAccountRelationships) {
            // Santosh - added  r.Secondary_Relationship__r.BillingState for bugFix Wi 0362
            if(!guarantorNameAccountMap.containsKey(r.Secondary_Relationship__r.Name +  r.Secondary_Relationship__r.BillingState)) {
                guarantorNameAccountMap.put(r.Secondary_Relationship__r.Name +  r.Secondary_Relationship__r.BillingState, new Set<Id>());
            }

            guarantorNameAccountMap.get(r.Secondary_Relationship__r.Name +  r.Secondary_Relationship__r.BillingState).add(r.Primary_Relationship__r.Care_Number__c);
        }

         
        List<Account> matchlessAccounts = new List<Account>();
        
        // START - creating care match list
        for(Account a : carelessAccounts) {
            //Initialize the set
            Set<Id> careMatches = new Set<Id>();

            //Add each potential match to the set
             
            if(phoneAccountMap.keySet().contains(a.Phone)) {
                for(Id i : phoneAccountMap.get(a.Phone)) {
                    careMatches.add(i);
                }
            }
             
            
            if(a.Name != null) {
                if(legalAccountMap.keySet().contains(a.BillingState + a.Name)) {
                    for(Id i : legalAccountMap.get(a.BillingState + a.Name)) {
                        careMatches.add(i);
                    }
                }
            }
             
            // these will only be matched with Guarantor RecordTypes in the following list
            //
            if(taxIdAccountMap.keySet().contains(a.Searchable_LLC_BI_Tax_Id_Number__c)) {
                for(Id i : taxIdAccountMap.get(a.Searchable_LLC_BI_Tax_Id_Number__c)) {
                    careMatches.add(i);
                }
            }
            
            // 
            // these will only be matched with Guarantor RecordTypes in the following list
            //
            if(primaryRelationshipToGuarantors.containsKey(a.Id)) {
                for(Associated_Relationships__c ar : primaryRelationshipToGuarantors.get(a.Id)) {
                    //
                    // Added encrypted field search feature
                    //
                    if(ssnAccountMap.keySet().contains(ar.Secondary_Relationship__r.Searchable_Security_Number__c)) {
                        for(Id i : ssnAccountMap.get(ar.Secondary_Relationship__r.Searchable_Security_Number__c)) {
                            careMatches.add(i);
                            // Santosh - added for bugFix Wi 0362
                            matchCriteriaMap.put(i, 'SSNMatch');
                        }
                    }
                    
                    //
                    // Guarantor Tax Id match
                    //
                    if(taxIdAccountMap.keySet().contains(ar.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c)) {
                        for(Id i : taxIdAccountMap.get(ar.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c)) {
                            careMatches.add(i);
                            
                              if(matchCriteriaMap.get(i)!= null && matchCriteriaMap.get(i).contains('SSNMatch')){
                               String value= matchCriteriaMap.get(i).replaceAll('SSNMatch', 'SSN and TaxId Match');
                               matchCriteriaMap.put(i, value);
                           }
                           
                           else{
                             matchCriteriaMap.put(i, 'TaxIdMatch');
                             }
                             
                        }
                    }
                    
                    //
                    // Guarantor match by name logic
                      //Santosh - commenetd for BugFix Wi 0362 
 
                    // Santosh -added ar.Secondary_Relationship__r.BillingState logic to include Name and State match
                        if(guarantorNameAccountMap.keySet().contains(ar.Secondary_Relationship__r.Name +  ar.Secondary_Relationship__r.BillingState)) {
                            for(Id i : guarantorNameAccountMap.get(ar.Secondary_Relationship__r.Name +  ar.Secondary_Relationship__r.BillingState)) {
                                careMatches.add(i);
                                
                                 // Santosh -added for bugFix WI 0362- if the care Matches on Guarantor state and Name then it will look to see if it also matches on SSN and Tax -Otherwsie it is ignored   
                                  if(matchCriteriaMap.get(i)!=null && (matchCriteriaMap.get(i).contains('TaxIdMatch') || matchCriteriaMap.get(i).contains('SSNMatch') || matchCriteriaMap.get(i).contains('SSN and TaxId Match')))
                                   careMatches.add(i);
                            }
                        }
                }
            }
        
            system.debug(careMatches);
            
            // Santosh -added for BugFix WI 0427
            if(careMatches.size() > 0 ){
           
               Map<Id, String> careType = getCareNumberType(careMatches);
        
               for(Id careId: careMatches){
               // Account acc = accMap.get(careId);
               String type = careType.get(careId);
             
              if(Type == 'Problem' || Type == 'Indirect'){
               careMatches.remove(careId);

                }
            
             }
           }
           
            //If only one match exists, set the care number
            if(careMatches.size() == 1)
            {
                a.Care_Number__c = (new List<Id> (careMatches))[0];
                careMatchId = (new List<Id> (careMatches))[0];
               
            }
            else if(careMatches.size() == 0)
                matchlessAccounts.add(a);
        }

        system.debug(matchlessAccounts);        
  
        //Modified the following to accomodate multiple prospect dealer on an NDA
        if(matchlessAccounts.size() > 0) { 
            List<Account> highestCareNumberAccount = [Select Name from Account Where RecordTypeId =: Constants.AccountRTCareNumber Order By CARE_Integer__c Desc limit 1];
            Integer nextCareNumber = highestCareNumberAccount.size() == 0 ? 0 : Integer.valueOf(highestCareNumberAccount[0].Name) + 1;
            //Create care numbers for matchless accounts
            List<Account> newCares = new List<Account>();
            
           {   
              for(Integer i = 0; i < matchlessAccounts.size(); i++)
              {
                newCares.add(new Account(recordtypeid = Constants.AccountRTCareNumber, Name = String.valueOf(nextCareNumber + i)));
              }
            
              insert newCares;
           
             for(Integer i = 0; i < matchlessAccounts.size(); i++) 
              {
               matchlessAccounts[i].Care_Number__c = newCares[i].Id;
               
                
              } 
              
            
            }
            
        } // END - creating care match list
        
      
    }
    

    //Added by Nimish to improve performance of NDA app submission
    //Carenumber assignment, legal entity creation, underwriting request creation as a result now being done asynchronously when the app is being submitted instead of it happening in realtime and slowing the NDA app submission
    @future
   public static void asyncPopulateCARENumbersUpdateLEsCreateURs(List<id> accountsWithCareIdsList, List<id> carelessAccountIdsList, List<id> submittedAppIdsList, Boolean cameThroughNDA) {
        
        try
        {
        system.debug(submittedAppIdsList);
        system.debug(carelessAccountIdsList);
        system.debug(accountsWithCareIdsList);
        List<account> careLessAccounts = new List<Account>();
        List<account> updateAccountsList = new List<account>();
        Set<id> NDAIdsWithAccountsWithCareNumber = new Set<id>();
        // Santosh - added for TaxId and SSN Match
         Map<Id, String> matchCriteriaMap = new Map<Id, String>();
         Map<Id, boolean> GNamenStateMatchNoSSN = new Map<Id, boolean>();
                        
        if(carelessAccountIdsList != null && carelessAccountIdsList.size()>0)
        {
          // Santosh -commented Legal_Entity_NameOld__c for WI 2076
          carelessAccounts = [Select Name, Id, New_Dealer_Application__c, Care_Number__c, WMS_Customer__c, Phone, /**Legal_Entity_NameOld__c,*/ BillingState, ParentId, Searchable_Security_Number__c, Social_Security_Number__c, Searchable_LLC_BI_Tax_Id_Number__c, Tax_Identification_Number__c, RecordTypeId From Account Where Id in: carelessAccountIdsList];
        }
        
               
        Set<String> wmsNumbers = new Set<String>();
        Set<String> phoneNumbers = new Set<String>();
        Set<String> legalNames = new Set<String>();
        Set<Id> parentIds = new Set<Id>();
        Set<String> parentWMSNumbers = new Set<String>();

        Set<String> guarantorNames = new Set<String>();
        Set<String> ssns = new Set<String>();
        Set<String> taxIds = new Set<String>();
        
        Set<Id> carelessAccountIds = new Set<Id>();
        
        Id careMatchId;
        
        // START - pulling out comparison terms
        for(Account a : carelessAccounts) {
            
            carelessAccountIds.add(a.Id);
            
            if(a.WMS_Customer__c != null)
                wmsNumbers.add(a.WMS_Customer__c);
            if(a.Phone != null)
                phoneNumbers.add(a.Phone);
                
            // Santosh -added for WI 2076
            /**if(a.Legal_Entity_NameOld__c != null)
                legalNames.add(a.Legal_Entity_NameOld__c); */
                
            if(a.Name != null) {
                legalNames.add(a.Name);
            }
            if(a.ParentId != null)
                parentIds.add(a.ParentId);
            if(a.Searchable_LLC_BI_Tax_Id_Number__c != null || a.Tax_Identification_Number__c != null) {
                if(a.Searchable_LLC_BI_Tax_Id_Number__c != null) {
                    taxIds.add(a.Searchable_LLC_BI_Tax_Id_Number__c);
                }
                else if (a.Tax_Identification_Number__c != null) {
                    a.Searchable_LLC_BI_Tax_Id_Number__c = EncryptionUtils.encryptSSN(a.Tax_Identification_Number__c);
                    taxIds.add(a.Searchable_LLC_BI_Tax_Id_Number__c);
                }
            }
        }

        //Pull related guarantors for each account
        Map<Id, List<Associated_Relationships__c>> primaryRelationshipToGuarantors = new Map<Id, List<Associated_Relationships__c>>();
        
       // Santosh -commented as record types are not used anymore Secondary_Relationship__r.RecordTypeId = :rTIdAccountGuarantor Or Secondary_Relationship__r.RecordTypeId = :rTIdAccountGuarantorConsent Or 
        for(Associated_Relationships__c ar : [Select Id, Primary_Relationship__c, Secondary_Relationship__c, Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c, Secondary_Relationship__r.Searchable_Security_Number__c, Secondary_Relationship__r.Social_Security_Number__c, Secondary_Relationship__r.Name, Secondary_Relationship__r.BillingState from Associated_Relationships__c Where /**Association_Type__c != 'Customer Supplier Relationship'*/ Association_Type__c NOT IN:ASSOCIATION_FILTER_TYPES And Association_Type__c != null And (/**Secondary_Relationship__r.RecordTypeId = :rTIdAccountGuarantor Or Secondary_Relationship__r.RecordTypeId = :rTIdAccountGuarantorConsent Or*/ Secondary_Relationship__r.RecordTypeId = :rTIdAccountGuarantorOwner) And Primary_Relationship__c in: carelessAccountIds]) {
            if(ar.Secondary_Relationship__r.Searchable_Security_Number__c != null) {
                ssns.add(ar.Secondary_Relationship__r.Searchable_Security_Number__c);
            }
            if(ar.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c != null) {
                taxIds.add(ar.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c);
            }
            if(ar.Secondary_Relationship__r.Name != null) {
                guarantorNames.add(ar.Secondary_Relationship__r.Name);
            }
            
            if(!primaryRelationshipToGuarantors.containsKey(ar.Primary_Relationship__c)) {
                primaryRelationshipToGuarantors.put(ar.Primary_Relationship__c, new List<Associated_Relationships__c>());
            }
            primaryRelationshipToGuarantors.get(ar.Primary_Relationship__c).add(ar);
        } // END - // pulling out comparison terms

       
        list<Account> wmsAccounts = [Select Id, New_Dealer_Application__c, WMS_Customer__c, Care_Number__c from Account Where WMS_Customer__c in: wmsNumbers And Care_Number__c != null];
        list<Account> phoneAccounts = [Select Id, New_Dealer_Application__c, Phone, Care_Number__c from Account Where Phone in: phoneNumbers And Care_Number__c != null];
        
        //Santosh-added for WI 2076
        //list<Account> legalAccounts = [Select Id, New_Dealer_Application__c, Legal_Entity_NameOld__c, Name, BillingState, Care_Number__c from Account Where (Legal_Entity_NameOld__c in: legalnames Or Name in: legalnames) And Care_Number__c != null];
          list<Account> legalAccounts = [Select Id, New_Dealer_Application__c, Name, BillingState, Care_Number__c from Account Where Name in: legalnames And Care_Number__c != null];
          
        //
        // Added encrypted field search feature
        //
        List<Account> taxIdAccounts = [SELECT Id, New_Dealer_Application__c, Searchable_LLC_BI_Tax_Id_Number__c, Care_Number__c FROM Account WHERE Searchable_LLC_BI_Tax_Id_Number__c IN :taxIds AND Care_Number__c != null];

        // 
        // Guarantor match by ssn logic
        //
        List<Associated_Relationships__c> ssnAccountRelationships = [
            select 
                Id
                ,Primary_Relationship__c
                ,Primary_Relationship__r.Name
                ,Primary_Relationship__r.Care_Number__c
                ,Secondary_Relationship__r.Searchable_Security_Number__c
            from 
                Associated_Relationships__c
            where 
                /**Association_Type__c != 'Customer Supplier Relationship'*/ Association_Type__c NOT IN:ASSOCIATION_FILTER_TYPES
            and 
                Association_Type__c != null
            and 
                Secondary_Relationship__r.Searchable_Security_Number__c in :ssns
            and 
                Primary_Relationship__r.Care_Number__c != null
        ];
        

        //
        // Guarantor match by name logic
        //
        // Santosh - added Secondary_Relationship__r.BillingState for BugFix Wi 0362
        List<Associated_Relationships__c> guarantorNameAccountRelationships = [
            select 
                Id
                ,Primary_Relationship__c
                ,Secondary_Relationship__r.Name
                ,Primary_Relationship__r.Care_Number__c
                , Secondary_Relationship__r.BillingState
            from 
                Associated_Relationships__c
            where 
                /**Association_Type__c != 'Customer Supplier Relationship' */ Association_Type__c NOT IN:ASSOCIATION_FILTER_TYPES
            and 
                Association_Type__c != null
            and 
                Secondary_Relationship__r.Name in :guarantorNames
            and 
                Primary_Relationship__r.Care_Number__c != null
        ];
 
        List<Associated_Relationships__c> guarantorTaxIdAccountRelationships = [Select Id, Primary_Relationship__c, Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c, Primary_Relationship__r.Care_Number__c From Associated_Relationships__c Where /**Association_Type__c != 'Customer Supplier Relationship'*/ Association_Type__c NOT IN:ASSOCIATION_FILTER_TYPES And Association_Type__c != null And Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c in: taxIds And Primary_Relationship__r.Care_Number__c != null];

        Map<String, Set<Id>> wmsAccountMap = new Map<String, Set<Id>>();
         
        Map<String, Set<Id>> phoneAccountMap = new Map<String, Set<Id>>();
        for(Account a : phoneAccounts) {
            if(!phoneAccountMap.containsKey(a.Phone))
                phoneAccountMap.put(a.Phone, new set<Id>());
            phoneAccountMap.get(a.Phone).add(a.Care_Number__c);
        }
        Map<String, Set<Id>> legalAccountMap = new Map<String, Set<Id>>();
         //Santosh - commenetd for BugFix Wi 0362 
            for(Account a : legalAccounts) {
          
            if(a.Name != null) {
                if(!legalAccountMap.containsKey(a.BillingState + a.Name))
                    legalAccountMap.put(a.BillingState + a.Name, new Set<Id>());
                legalAccountMap.get(a.BillingState + a.Name).add(a.Care_Number__c);
            }
        }
        
        //
        // Added encrypted field search feature
        //
        Map<String, Set<Id>> ssnAccountMap = new Map<String, Set<Id>>();
        for(Associated_Relationships__c r : ssnAccountRelationships) {
            if(!ssnAccountMap.containsKey(r.Secondary_Relationship__r.Searchable_Security_Number__c)) {
                ssnAccountMap.put(r.Secondary_Relationship__r.Searchable_Security_Number__c, new Set<Id>());
            }

            ssnAccountMap.get(r.Secondary_Relationship__r.Searchable_Security_Number__c).add(r.Primary_Relationship__r.Care_Number__c);
        }
        Map<String, Set<Id>> taxIdAccountMap = new Map<String, Set<Id>>();
        for(Account a : taxIdAccounts) {
            if(!taxIdAccountMap.containsKey(a.Searchable_LLC_BI_Tax_Id_Number__c)) {
                taxIdAccountMap.put(a.Searchable_LLC_BI_Tax_Id_Number__c, new Set<Id>());
            }

            taxIdAccountMap.get(a.Searchable_LLC_BI_Tax_Id_Number__c).add(a.Care_Number__c);
        }
        for(Associated_Relationships__c r : guarantorTaxIdAccountRelationships) {
            if(!taxIdAccountMap.containsKey(r.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c)) {
                taxIdAccountMap.put(r.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c, new Set<Id>());
            }
            
            taxIdAccountMap.get(r.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c).add(r.Primary_Relationship__r.Care_Number__c);
        }

        //
        // Guarantor match by name logic
        //
        // Santosh - added for bugFix Wi 0362
        // Santosh -added  r.Secondary_Relationship__r.BillingState to include billing and state logic
        Map<String, Set<Id>> guarantorNameAccountMap = new Map<String, Set<Id>>();
        for(Associated_Relationships__c r : guarantorNameAccountRelationships) {
            if(!guarantorNameAccountMap.containsKey(r.Secondary_Relationship__r.Name + r.Secondary_Relationship__r.BillingState)) {
                guarantorNameAccountMap.put(r.Secondary_Relationship__r.Name + r.Secondary_Relationship__r.BillingState, new Set<Id>());
            }

            guarantorNameAccountMap.get(r.Secondary_Relationship__r.Name + r.Secondary_Relationship__r.BillingState).add(r.Primary_Relationship__r.Care_Number__c);
        }

        
        List<Account> matchlessAccounts = new List<Account>();
        
        // START - creating care match list
        for(Account a : carelessAccounts) {
            //Initialize the set
            Set<Id> careMatches = new Set<Id>();
            
            if(phoneAccountMap.keySet().contains(a.Phone)) {
                for(Id i : phoneAccountMap.get(a.Phone)) {
                    careMatches.add(i);
                }
            }
         
            if(a.Name != null) {
                if(legalAccountMap.keySet().contains(a.BillingState + a.Name)) {
                    for(Id i : legalAccountMap.get(a.BillingState + a.Name)) {
                        careMatches.add(i);
                    }
                }
            }
   
            // these will only be matched with Guarantor RecordTypes in the following list
            //
            if(taxIdAccountMap.keySet().contains(a.Searchable_LLC_BI_Tax_Id_Number__c)) {
                for(Id i : taxIdAccountMap.get(a.Searchable_LLC_BI_Tax_Id_Number__c)) {
                    careMatches.add(i);
                }
            }
            
            // 
            // these will only be matched with Guarantor RecordTypes in the following list
            //
            if(primaryRelationshipToGuarantors.containsKey(a.Id)) {
                for(Associated_Relationships__c ar : primaryRelationshipToGuarantors.get(a.Id)) {
                    //
                    // Added encrypted field search feature
                    //
                    if(ssnAccountMap.keySet().contains(ar.Secondary_Relationship__r.Searchable_Security_Number__c)) {
                        for(Id i : ssnAccountMap.get(ar.Secondary_Relationship__r.Searchable_Security_Number__c)) {
                            careMatches.add(i);
                            matchCriteriaMap.put(i, 'SSNMatch');
                        }
                    }
                    
                    //
                    // Guarantor Tax Id match
                    //
                    if(taxIdAccountMap.keySet().contains(ar.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c)) {
                        for(Id i : taxIdAccountMap.get(ar.Secondary_Relationship__r.Searchable_LLC_BI_Tax_Id_Number__c)) {
                            careMatches.add(i);
                           
                           if(matchCriteriaMap.get(i)!= null && matchCriteriaMap.get(i).contains('SSNMatch')){
                               String value= matchCriteriaMap.get(i).replaceAll('SSNMatch', 'SSN and TaxId Match');
                               matchCriteriaMap.put(i, value);
                           }
                           
                           else{
                             matchCriteriaMap.put(i, 'TaxIdMatch');
                             }
                        }
                    }
                    
                    //
                    // Guarantor match by name logic
                    //
                      //Santosh - commenetd for BugFix Wi 0362 
                   //  if(careMatches.isEmpty()) {
                   // Santosh -added ar.Secondary_Relationship__r.BillingState to include Billing State
                        if(guarantorNameAccountMap.keySet().contains(ar.Secondary_Relationship__r.Name +ar.Secondary_Relationship__r.BillingState)) {
                            for(Id i : guarantorNameAccountMap.get(ar.Secondary_Relationship__r.Name +ar.Secondary_Relationship__r.BillingState)) {
                           // Santosh -added for bugFix WI 0362- if the care Matches on Guarantor state and Name then it will look to see if it also matches on SSN and Tax -Otherwsie it is ignored                                  
                                if(matchCriteriaMap.get(i)!=null && (matchCriteriaMap.get(i).contains('TaxIdMatch') || matchCriteriaMap.get(i).contains('SSNMatch') || matchCriteriaMap.get(i).contains('SSN and TaxId Match')))
                                   careMatches.add(i);
                                   
                            }
                        }
                    //} 
                }
            }
        
            system.debug(careMatches);
             
        
        // Santosh - added for bugFix Wi 0457     
        if(careMatches.size() > 0 ){
           

           Map<Id, String> careType = getCareNumberType(careMatches);
        
           for(Id careId: careMatches){
           
             String type = careType.get(careId);

             
             if(Type == 'Problem' || Type == 'Indirect'){
               careMatches.remove(careId);
              
             }
            
             }
           }
         
             
            //If only one match exists, set the care number
            if(careMatches.size() == 1 )
            {
                a.Care_Number__c = (new List<Id> (careMatches))[0];
                careMatchId = (new List<Id> (careMatches))[0];
                updateAccountsList.add(a);
                NDAIdsWithAccountsWithCareNumber.add(a.New_dealer_Application__c);
            }
            //Else if no care number matches, add account to matchlessAccounts list
            else if(careMatches.size() == 0)
            {
                matchlessAccounts.add(a);
                NDAIdsWithAccountsWithCareNumber.add(a.New_dealer_Application__c);
            }
        }
        
        system.debug(matchlessAccounts);        
    
        //Modified the following to accomodate multiple prospect dealer on an NDA
        
        if(matchlessAccounts.size() > 0) {
            List<Account> highestCareNumberAccount = [Select Name from Account Where RecordTypeId =: Constants.AccountRTCareNumber Order By CARE_Integer__c Desc limit 1];
            Integer nextCareNumber = highestCareNumberAccount.size() == 0 ? 0 : Integer.valueOf(highestCareNumberAccount[0].Name) + 1;
            //Create care numbers for matchless accounts
            List<Account> newCares = new List<Account>();
            
            //If care numbers are being populated as a result of NDA App update
            if(CameThroughNDA == TRUE)
            {
              if(careMatchId!=null)
              {
                for(Integer i = 0; i < matchlessAccounts.size(); i++) 
                {
                  matchlessAccounts[i].Care_Number__c = careMatchId;
                  updateAccountsList.add(matchlessAccounts[i]);
                }
              }
              else
              {
                newCares.add(new Account(
                recordtypeid = Constants.AccountRTCareNumber, 
                Name = String.valueOf(nextCareNumber),
                /** WI 3650 - setting the Created_Through_App_Site__c to true to indicate the legal entity is created from app site*/
                 Created_Through_App_Site__c=true
                ));
                insert newCares;
                
                system.debug('newCares inserted'+newCares);
              
                for(Integer i = 0; i < matchlessAccounts.size(); i++) 
                {
                  matchlessAccounts[i].Care_Number__c = newCares[0].Id;
                  updateAccountsList.add(matchlessAccounts[i]);                  
                }
              }
            }
            //If care numbers are being populated on relationship records not as a result of NDA updates
            else
            {   
              for(Integer i = 0; i < matchlessAccounts.size(); i++)
              {
                newCares.add(new Account(recordtypeid = Constants.AccountRTCareNumber, Name = String.valueOf(nextCareNumber + i)));
              }
            
              insert newCares;
           
              for(Integer i = 0; i < matchlessAccounts.size(); i++) 
              {
                matchlessAccounts[i].Care_Number__c = newCares[i].Id;
                updateAccountsList.add(matchlessAccounts[i]);
              }
            }

            
        } // END - creating care match list
        
         //Update CareNumber on the Accounts
            if(updateAccountsList.size() > 0)
            {
              update updateAccountsList;
              system.debug(updateAccountsList); 
            }
            
            system.debug(accountsWithCareIdsList);
            
            ///////////////////////////////////////////////////////////////////////////
            //Populate Legal Entities for accounts with newly assigned Care Numbers  //
            ///////////////////////////////////////////////////////////////////////////         
            List<account>  accountsWithNewCareNumberList = new List<account>();
            
            accountsWithNewCareNumberList = [select id, New_Dealer_Application__c, recordtypeid, care_number__c, Legal_Entity_name__c, name from account where id in : updateAccountsList];

            if(accountsWithNewCareNumberList.size()>0)
            {
              system.debug('Populate Legal Entities');
              populateLegalEntities(accountsWithNewCareNumberList);
            }
            
            //Handle the situation when Care Number is manually assigned (typically when there are multiple Care Number matches when the app is first submitted) and the app is then resubmitted.
            List<account> AccountsWithCareNumList =  [select id, name, care_number__c, Legal_Entity_name__c, new_dealer_application__c from account where id in: accountsWithCareIdsList];            
            
            //WI 0672
           
            List<product_information_for_new_dealer_app__c> pList = new List<product_information_for_new_dealer_app__c>();
            
            if(accountsWithCareIdsList.size() > 0)
              pList = [select new_dealer_application2__c, relationship__c from product_information_for_new_dealer_app__c where relationship__c in: accountsWithCareIdsList and New_Dealer_Application2__c in :submittedAppIdsList];
            else if(updateAccountsList.size() > 0 || matchlessAccounts.size() > 0)
              pList = [select new_dealer_application2__c, relationship__c from product_information_for_new_dealer_app__c where (relationship__c in: updateAccountsList or  relationship__c in :matchlessAccounts) and New_Dealer_Application2__c in :submittedAppIdsList];


            for(product_information_for_new_dealer_app__c p: pList){
              NDAIdsWithAccountsWithCareNumber.add(p.New_Dealer_Application2__c);
            } 
                
            //
            
            system.debug(NDAIdsWithAccountsWithCareNumber);
            
            /////////////////////////////////////////////////////////////////////
            //CREATE UNDERWRITING REQUEST FOR EACH NDA ACCOUNT WITH CARE NUMBER//
            /////////////////////////////////////////////////////////////////////
            List<New_Dealer_Application__c> ndaList = new List<New_Dealer_Application__c>();
            ndaList = [select id, AD_Eligible__c, AD_Result__c, AD_Model_Used__c, URs_not_gen_multiple_CareNums_matched__c, manufacturer__c, RIA__c, What_is_your_requested_line_of_credit__c, Line_Type__c, Account__c, Account_Name__c, Product_Line__c, Request_Type__c from New_Dealer_Application__c where id in:NDAIdsWithAccountsWithCareNumber];
           
            system.debug(submittedAppIdsList);
            system.debug(ndaList);
            
            if(ndaList.size()>0)
            {
              system.debug('before createUR');
              NewDealerAppManager.CreateUnderWritingRequestNewDealerApp(ndaList); 
              system.debug('after createUR');
            }  
        
            //Mark the NDAs with UR not created if they were not sent for UR creation above
            List<New_Dealer_Application__c> NDAsNotSubmittedForURCreation = new List<New_Dealer_Application__c>();
            List<New_Dealer_Application__c> NDAsSubmittedForURCreation = new List<New_Dealer_Application__c>();
            
        
            for(Id submittedAppId:  SubmittedAppIdsList)
            {
               system.debug('NDA 1');
               Boolean appBeingSubmittedForURCreation = FALSE;
               
               if(ndaList.size()>0)
               {
                 for(New_Dealer_Application__c n: ndaList)
                 {
                   if(n.Id == submittedAppId)
                   {
                     appBeingSubmittedForURCreation = TRUE;
                   }
                 }
               }
               
               if(appBeingSubmittedForURCreation == FALSE)
               {  
                 New_Dealer_Application__c nda = new New_Dealer_Application__c(id = submittedAppId);
                 nda.URs_not_gen_multiple_CareNums_matched__c = TRUE;
                 NDAsNotSubmittedForURCreation.add(nda);
               }
               else
               {
                 New_Dealer_Application__c nda = new New_Dealer_Application__c(id = submittedAppId);
                 if(nda.URs_not_gen_multiple_CareNums_matched__c = TRUE)
                 {
                   nda.URs_not_gen_multiple_CareNums_matched__c = FALSE;
                   NDAsSubmittedForURCreation.add(nda);
                 }
               }
                    
            }
            
            system.debug(NDAsNotSubmittedForURCreation.size());
                        
            if(NDAsNotSubmittedForURCreation.size()>0)
              update NDAsNotSubmittedForURCreation;
        
            if(NDAsSubmittedForURCreation.size()>0)
              update NDAsSubmittedForURCreation;
        
        //In order to find similar dealers, search by
        //Care Number (for existing customers) - not doing existing customers
        //WMS Number - check
        //Phone Number - check
        //Legal Entity Name - check
        //Tax ID - not possible
        //WMS Parent Number - soon
        //Else, create a new Care Number for the customer
        
        try
        {
            Map<id, String> ndasHavingUWMap = new Map<Id, String>();
            
            for(underwriting__c uw :[select id, connected_Request__c, connected_request__r.Language__c from underwriting__c where connected_request__c IN:submittedAppIdsList AND connected_request__r.Language__c!=null])
            {
                ndasHavingUWMap.put(uw.connected_Request__c, uw.connected_request__r.Language__c);
            }
            System.debug('=== ndasHavingUWMap ==='+ndasHavingUWMap);
            
            for(Id ndaId: ndasHavingUWMap.keySet())
            {
                try
                {
                    asyncGenerateNDAPDF asyncGenPDF = new asyncGenerateNDAPDF(ndaId, ndasHavingUWMap.get(ndaId));
                    system.enqueueJob(asyncGenPDF);
                }
                catch(exception e)
                {
                     String message ='Error occured while download NDA PDF file on NDA Verification screen '+'NDA Id : '+ndaId+' Error message : '+e.getMessage();
                     utilityClass.logError(e, 'Error occured while download NDA PDF file on NDA Submission.', '', message);
                }
            }
        }
        catch(exception e)
        {
             utilityClass.logError(e, 'Error occured while download NDA PDF file on NDA Submission.', '', e.getMessage());
        }
        }
        catch(exception ex)
        {
            utilityClass.logError(ex, 'Exception occured while assigning careNumber.', submittedAppIdsList[0], ex.getMessage()+'; NDA Information : '+submittedAppIdsList);
        }
    }
    
    
    public static void PopulateLegalEntities(List<Account> parentlessAccounts){
        //Group Accounts by Care Number
        Map<Id, List<Account>> careAccountMap = new Map<Id, List<Account>>();
        Set<Id> careNumbers = new Set<Id>();
        
        for(Account a : parentlessAccounts){
            if(careAccountMap.get(a.Care_number__c)  == null){
                careNumbers.add(a.Care_number__c);
                careAccountMap.put(a.Care_Number__c, new List<account>{a});
            }else{
                List<Account> accList = careAccountMap.get(a.Care_number__c);
                accList.add(a);
                careAccountMap.put(a.Care_Number__c, accList);
            }
        }   
        
        //Create map of legal name + care number as the key and the associated legal entity.        
        Map<String, Account> legalEntitesKeyMap = new Map<String, Account>();
        for(Id care : careNumbers){
            for(Account acc : careAccountMap.get(care)){
                if(legalEntitesKeyMap.get(acc.Name + '-' + acc.Care_Number__c) == null){
                    Account a = new Account();
                    // Santosh - changes made to reference developerNames instead of label WI 1535  
                    
                    a.RecordTypeId = constants.accountRTMap.get('Legal_Entity');
                    
                    a.Name = acc.Name;
                    a.Care_Number__c = acc.Care_Number__c;
                     // WI 3650 - setting the Created_Through_App_Site__c to true to indicate the legal entity is created from app site.
                    a.Created_Through_App_Site__c=true;
                    legalEntitesKeyMap.put(a.Name + '-' + a.Care_Number__c, a);
                }
            }   
        }   
        
        List<Account> leaccountssize = legalEntitesKeyMap.values();
        
        insert legalEntitesKeyMap.values();
        
        //Update new dealer app accounts to have a parent account of the legal entity
        for(Account a : parentlessAccounts){
            Account legalEntity = legalEntitesKeyMap.get(a.Name + '-' + a.Care_Number__c);
            system.debug('name:' + a.Name );
            system.debug('legal entity name: ' + legalEntity.Name);
            a.Legal_Entity_name__c = legalEntity.id;
        }
        
        update parentlessAccounts;      
    }
    
    public void CalculateCareFieldsForAccounts(List<Account> accounts){
        Map<Id, List<Account>> careAccountMap = new Map<Id, List<Account>>();
        List<Id> careIds = new List<Id>();
        List<Account> allAccounts = new List<Account>();
        for(Account c : accounts){
           // Santosh - changes made to reference developerNames instead of label WI 1535 
             if(c.RecordTypeId == constants.accountRTMap.get('Care_Number')){
                List<Account> relatedAccounts = new List<Account>();
                careAccountMap.put(c.Id, relatedAccounts);
                careIds.add(c.Id);
            }
        }
        
        if(careIds.size() > 0 ){
            allAccounts = [select Name from Account where Care_Number__c IN :careIds];
            for(Account a : allAccounts){
                List<Account> mapList = careAccountMap.get(a.Care_Number__c);
                mapList.add(a);
            }
        }
    }
    
    
    public Decimal consolidateDealerCreditLineAmount(Account consolidatedDealer) {
        Set<Decimal> amounts = new Set<Decimal>();
        List<Decimal> allAmounts = new List<Decimal>();
        Decimal amount = 0;
        for(Account dealer : consolidatedDealer.ChildAccounts) {
            amounts.add(dealer.Credit_Line_Amount__c);
            allAmounts.add(dealer.Credit_Line_Amount__c);
        }
        
        //If there is only 1 amount, reset the list of all amounts to have the lone value
        if(amounts.size() == 1) {
            allAmounts = new List<Decimal>();
            allAmounts.addAll(amounts);
        }
        for(Decimal a : allAmounts) {
            if(a != null) {
                amount += a;
            }
        }
        
        return amount;
    }
        
    public class CareNumberDealers {
        public Id careId {get;set;}
        public List<Account> dealers {get;set;}
        public List<Account> consolidatedDealers {get;set;}
        
        public CareNumberDealers(Id care) {
            careId = care;
            dealers = new List<Account>();
            consolidatedDealers = new List<Account>();
        }
    }
    
    
    public static List<Underwriting__c> getAllUnderwritings(List<Underwriting__c> CareloanList){
         
         List<Underwriting__c> wmsLoanList = [select id,Account__r.Total_Credit_Line_Amount__c,care_underwriting__c, CARE_Number__c, Account__c, Initiating_Account__c, Stage__c, IsUnderwritingComplete__c, Underwriting_Request_Level__c, Risk_rating__c  from Underwriting__c where care_underwriting__c IN: CareloanList OR id IN: CareloanList];
         return wmsLoanList;
   }
   
   
   //Santosh -added for bugfix- 0451
   
        public void UpdateRRatingonUnderwriting(Map<id, Account> UpdateRRAccountId){
        Map<id, List<Underwriting__c>> LoanMap = new Map<id, List<Underwriting__c>>();
        List<Underwriting__c> LoantoUpdate = new List<Underwriting__c>();
       
       
        List<Underwriting__c> loansToUpdate= new List<Underwriting__c>();
        List<String> urStage = new List<String>();
        urStage.add('Request');
        urStage.add('Underwriting');
        
      
      // Query for all the careLevel Loans
         List<Underwriting__c> CareloanList = [select id,Account__r.Total_Credit_Line_Amount__c,CARE_Number__c, Account__c, Initiating_Account__c, Stage__c, IsUnderwritingComplete__c, Underwriting_Request_Level__c  from Underwriting__c where Account__c IN: UpdateRRAccountId.keySet() AND Stage__c IN: urStage and Underwriting_Request_Level__c = 'CARE Level'];
         //
        
        if(CareloanList.size() > 0)
        {
       List<Underwriting__c> LoanList = getAllUnderwritings(CareloanList); 
        for(Underwriting__c  l: LoanList){
        if(LoanMap.get(l.Account__c) == NULL){
        LoanMap.put(l.Account__c, new List<Underwriting__c>{l});
        }
        else{
        LoanMap.get(l.Account__c).add(l);
        }
        }
     
   
        for(Account a: UpdateRRAccountId.Values()){
        if(LoanMap.get(a.id) != null){
        for(Underwriting__c ln: LoanMap.get(a.id)){
        ln.Risk_rating__c = a.Risk_rating__c;
        LoantoUpdate.add(ln);
        }
        }
       } 
        if(LoantoUpdate.size() > 0){
        
        update LoantoUpdate;
        } 
        }
    }
    
    
     // Santosh - added for Wi#0427 - Care Match - This logic loops through the careNumbers abd returns careType if all accounts within a care are dealers then it is direct otherwise it is indirect
    // Santosh-added for WI 2572- recoded to make record types inclusive
    public  Static Map<Id, String> getCareNumberType(Set<Id> careAccountIds){
        
        Map<Id, List<String>> careMapType = new Map<Id, List<String>>();
        Map<Id, String>  careMap = new Map<Id, String>();
        
        Set<String> directAccountRecTypes= new Set<String>{constants.accountRTMap.get('Client_Dealer'), constants.accountRTMap.get('Prospect_Dealer'), constants.accountRTMap.get('Consolidated_Dealer')};
        Set<String> indirectAccountRecTypes= new Set<String>{constants.accountRTMap.get('Prospect_Manufacturer'),constants.accountRTMap.get('Client_Manufacturer'),constants.accountRTMap.get('Client_Distributor'),constants.accountRTMap.get('Prospect_Distributor'), constants.accountRTMap.get('Client_Buying_Group'), constants.accountRTMap.get('Prospect_Buying_Group')};
        
        List<Account> allAccountsList= [Select id, name, care_number__c, RecordTypeId from account where care_Number__c IN: careAccountIds AND customer_Status__c='Active' AND  (recordTypeId=:directAccountRecTypes OR recordTypeId IN: indirectAccountRecTypes)];
       
        System.debug('==== allAccountsList ==='+allAccountsList);
        System.debug('==== allAccountsList.size() ==='+allAccountsList.size());
        
        for(Account acc: allAccountsList)
        {
        
            if(acc.RecordTypeId!=null)
            {
                  if(directAccountRecTypes.contains(acc.RecordTypeId))
                  {
                    
                    if(careMapType.get(acc.care_Number__c) == null)
                      careMapType.put(acc.care_number__c, new List<String>{'Direct'});
                    
                    else
                       careMapType.get(acc.care_Number__c).add('Direct');
                  }
            
                  else
                  {
                
                        if(careMapType.get(acc.care_Number__c) == null)
                        {
                          careMapType.put(acc.care_number__c, new List<String>{'Indirect'});
                        }
                    
                        else 
                        {
                          careMapType.get(acc.care_Number__c).add('Indirect');
                        }
                    }                 
              }
          }
          
          System.debug('=== careMapType ===='+careMapType);
         
          if(careMapType.size() > 0)
          {
 
               for(Id careId: careAccountIds)
               {
              
                    integer inDirectValue =0;
                    integer directValue =0;
              
                    if(careMapType.get(careId)!= null) 
                    {
                      List<String> careType = careMapType.get(careId);
                      
                      for(String type: careType)
                      {
                        if(type == 'Direct')
                        {
                             directValue++;
                        }
                        
                        else if(type == 'Indirect')
                        {
                            inDirectValue++;
                        }
                      }
                      
                      if(careType.size() == directValue)
                      {
                        careMap.put(careId, 'Direct');
                      }
                      
                      else if(careType.size() == inDirectValue)
                      {
                         careMap.put(careId, 'Indirect');
                      }
                      
                      else
                      {
                         careMap.put(careId, 'Problem');
                      }
                   }
              }
          }
          System.debug('==== careMap ==='+careMap);
           return careMap;
        }
    
    // Santosh -added for CBR Score calculation at care Level and WMS Level
    public Class OwnershipAndCBR {
        public Decimal ownershipPercentage {get;set;}
        public Decimal CBR {get;set;}
        
        public OwnershipAndCBR(Decimal op, Decimal c) {
            ownershipPercentage = op;
            CBR = c;
        }
     }    
    
    public void WeightedCBRCalcCareandWMSAccount(Map<id, account> wmsAcctsMap)
    {
        Map<Id, String> cbrScoreMessage = utilityClass.fetchAndUpdateCBRScores(wmsAcctsMap.keySet());
        
        for(Id acctId: wmsAcctsMap.keySet())
        {
            if(cbrScoreMessage.containsKey(acctId))
            {
                if(cbrScoreMessage.get(acctId) !='Success')
                {
                    wmsAcctsMap.get(acctId).addError(cbrScoreMessage.get(acctId));
                }
            }
        }
        
    }
    
    // Santosh- created for WI 1205 - Creates the task for accounts without primary email address 
    public void createTaskForAccountsWithoutPrimaryEmail(List<Account> accountList)
    { 
    
        String taskRecordTypeId = constants.taskRTMap.get('General');
        List<String> closedStatus = new List<String>{'Completed','Task closed due to closed Case', 'Completed - Not Applicable'};
        List<account> accountsThatNeedTaskCreation = new List<account>();
        
        for(account a: [select id, name, OwnerId, (select id from tasks where recordTypeId=:taskRecordTypeId and subject LIKE '%Primary email Address%' and status NOT IN: closedStatus) from account where id IN: accountList])
        {
            if(a.tasks == NULL || a.tasks.size() == 0)
                accountsThatNeedTaskCreation.add(a);
        }
        
        List<Task> taskList = new List<Task>();
        
        for(account a: accountsThatNeedTaskCreation)
        {
            
            Task t = new Task();
            t.recordTypeId = taskRecordTypeId;
            t.subject = 'Update Primary email Address on account -'+ a.Name;
            t.status ='Open';
            t.OwnerId = a.ownerId;
            t.whatId = a.Id;
            
            taskList.add(t);
        }
        
        insert taskList;
    }
    
    // Santosh- added for Wi 2166 - Captures the previous pm rating on account
    public void capturePreviousPMRatingOnAccount(List<account> pmRatingChangedList)
    {
        List<account> accountsToUpdate = new List<account>();
        
        for(account a: pmRatingChangedList)
        {
            accountsToUpdate.add(new account(id=a.id,Previous_PM_Rating__c = (a.Portfolio_Model_Rating__c!=NULL?a.Portfolio_Model_Rating__c:'-'), Last_PM_Rating_Date_Changed__c = System.now()));
        }
        
        update accountsToUpdate;
    }
    
    public Static List<id> getChildRelationshipIdsForCARE(id careRelationshipId)
    {
      List<id> acctIdsList = new List<id>();
      
      for(Account a: [select id from account where Care_Number__c = :careRelationshipId])
      {
        acctIdsList.add(a.id);
      }
      
      return acctIdsList;
    }
    
    // Thsi method updates the WMS_Active_Date__c field on Used DRR 
    public List<Dual_Risk_Rating__c> updateWMSActiveDateOnDRRsUsedForDecision(List<Account> accList)
    {
        List<Dual_Risk_Rating__c> dualRRList = new List<Dual_Risk_Rating__c>();
        
        for(Dual_Risk_Rating__c d: [select id,WMS_Active_Date__c from Dual_Risk_Rating__c where Relationship__c IN: accList AND Used_to_decision_request__c=TRUE] )
        {
            dualRRList.add(new Dual_Risk_Rating__c(id=d.id, WMS_Active_Date__c= Date.Today()));
        }
        return dualRRList;
    }
}