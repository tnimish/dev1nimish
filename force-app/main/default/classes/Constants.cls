//   7/31/18 updated for new sobject Underwriting__c
//    10/15/18  updated for auto-decision
public without sharing class Constants {
   
   //This Set holds the objects to query for recordTypes
   // Wi 2594- 101 soql error. objectToRecordTypeMap will contain all the recordtypes tied to object and all soql query related to recordtype are removed i.e.[select id, developername from recordType]
   // Going forward this objectToRecordTypeMap can be used for accessing recordTypes.
   static Set<String> ObjectNamesToQuery =new Set<String>{'Account', 'New_Dealer_Application__c', 'Additional_Location__c', 'Bank__c', 'Case', 'Task', 'Underwriting__c', 'Mitigant_Reason__c', 'Billing_Payment__c'};
    
    //Main query to fetch all the recordtypes
     public static Map<String, List<RecordType>> objectToRecordTypeMap 
    {
        get 
        {
            if(objectToRecordTypeMap == null) 
            {
                objectToRecordTypeMap = new Map<String, List<RecordType>>();
                
                for(RecordType rt : [Select Id, DeveloperName,SObjectType from RecordType where sObjectType IN: ObjectNamesToQuery]) 
                {
                    if(objectToRecordTypeMap.get(rt.SObjectType)==null)
                    {
                        objectToRecordTypeMap.put(rt.SObjectType, new List<RecordType>{rt});
                    }
                    else
                    {
                        objectToRecordTypeMap.get(rt.SObjectType).add(rt);
                    }
                        
                }
            }
            
            return objectToRecordTypeMap;
        }
        set;
    }

    //added 1.24.19
    public static Map<Id,String> AccountRTId2NameMap{
        get{
            if(AccountRTId2NameMap == null){
                AccountRTId2NameMap = new Map<id, String>();
                if(objectToRecordTypeMap.containsKey('Account') && objectToRecordTypeMap.get('Account')!=null)
                {
                       for(RecordType rt :objectToRecordTypeMap.get('Account'))
                       {
                            AccountRTId2NameMap.put(rt.Id, rt.DeveloperName);
                       }                   
                }
            }
            return AccountRTId2NameMap;
            
        }
        
    
        set;
    }

    public static Map<String, Id> AccountRTMap 
    {
        get 
        {
            if(AccountRTMap == null) 
            {
                AccountRTMap = new Map<String, Id>();
                
                //for(RecordType rt : [Select Id, DeveloperName from RecordType Where SObjectType = 'Account']) {
                   if(objectToRecordTypeMap.containsKey('Account') && objectToRecordTypeMap.get('Account')!=null)
                   {
                       for(RecordType rt :objectToRecordTypeMap.get('Account'))
                       {
                            AccountRTMap.put(rt.DeveloperName, rt.Id);
                       }                   
                   }
                }
                return AccountRTMap;
            }
        set;
      }
      
    // Santosh - changes made to reference developerNames instead of label WI 1535
    public static Map<String, Id> NewDealerAppRTMap     
   {        
       get {
            if(NewDealerAppRTMap == null)
             {
                NewDealerAppRTMap = new Map<String, Id>();
                if(objectToRecordTypeMap.containsKey('New_Dealer_Application__c') && objectToRecordTypeMap.get('New_Dealer_Application__c')!=null)
                {
                       for(RecordType rt :objectToRecordTypeMap.get('New_Dealer_Application__c'))
                       {
                            NewDealerAppRTMap.put(rt.DeveloperName, rt.Id);
                       }
                }                
            }
              return NewDealerAppRTMap;
        }
        
        set;
   }
    
     public static Map<String, Id> AdditionalLocationRTMap 
     {
        get 
        {
            if(AdditionalLocationRTMap == null) 
            {
                AdditionalLocationRTMap = new Map<String, Id>();
                     if(objectToRecordTypeMap.containsKey('Additional_Location__c') && objectToRecordTypeMap.get('Additional_Location__c')!=null)
                    {
                           for(RecordType rt :objectToRecordTypeMap.get('Additional_Location__c'))
                           {
                                AdditionalLocationRTMap.put(rt.DeveloperName, rt.Id);
                           }
                    }
            }            
            return AdditionalLocationRTMap;    
        }
        set;
    }
    
     public static Map<String, Id> BankRTMap 
     {
        get 
        {
            if(BankRTMap == null) 
            {
                BankRTMap = new Map<String, Id>();
               // for(RecordType rt : [Select Id, DeveloperName from RecordType Where SObjectType = 'Bank__c']) {
                        
                        if(objectToRecordTypeMap.containsKey('Bank__c') && objectToRecordTypeMap.get('Bank__c')!=null)
                        {
                               for(RecordType rt :objectToRecordTypeMap.get('Bank__c'))
                               {
                                    BankRTMap.put(rt.DeveloperName, rt.Id);
                               }
                        }
            }
            return BankRTMap;
        }
         set;
       }
       
    public static map<String, Schema.RecordTypeInfo> AccountRTs = Schema.SObjectType.Account.getRecordTypeInfosByName();
    //Added by Nimish
    public static map<String, Schema.RecordTypeInfo> CaseRTs = Schema.SObjectType.Case.getRecordTypeInfosByName();
    public static map<String, Schema.RecordTypeInfo> UnderwritingRequestRTs = Schema.SObjectType.Underwriting__c.getRecordTypeInfosByName();
    public static map<String, Schema.RecordTypeInfo> TaskRTs = Schema.SObjectType.Task.getRecordTypeInfosByName();
    public static map<String, Schema.RecordTypeInfo> NewDealerAppRTs = Schema.SObjectType.New_Dealer_Application__c.getRecordTypeInfosByName(); 
    public static map<String, Schema.RecordTypeInfo> AdditionalLocationRTs = Schema.SObjectType.Additional_Location__c.getRecordTypeInfosByName();
    public static map<String, Schema.RecordTypeInfo> BankRTs = Schema.SObjectType.Bank__c.getRecordTypeInfosByName();  
    //
    
    public static String AccountRTCareNumber = AccountRTMap.get('Care_Number');
    
    // Santosh - changes made to reference developerNames instead of label WI 1535
    //public static String AccountRTBuyingGroup = AccountRTs.get('Buying Group').getRecordTypeId();
    public static String AccountRTBuyingGroup  = AccountRTMap.get('Client_Buying_Group');
      
    public static String AccountRTConsolidatedDealer = AccountRTMap.get('Consolidated_Dealer');
    public static String AccountRTDealer = AccountRTMap.get('Client_Dealer');
    
    //public static String AccountRTDistributor = AccountRTs.get('Distributor').getRecordTypeId();
      public static String AccountRTDistributor = AccountRTMap.get('Client_Distributor');
     
    //public static String AccountRTGuarantor = AccountRTs.get('Guarantor, Owner or Affiliate').getRecordTypeId();
      public static String AccountRTGuarantor = AccountRTMap.get('Guarantors');
    
    //public static String AccountRTManufacturer = AccountRTs.get('Manufacturer').getRecordTypeId();
      public static String AccountRTManufacturer = accountRTMap.get('Client_Manufacturer');
    
   // public static String AccountRTProspectManufacturer = AccountRTs.get('Prospect Manufacturer').getRecordTypeId();
    public static String AccountRTProspectManufacturer = accountRTMap.get('Prospect_Manufacturer');
   
   // public static String AccountRTProspectBuyingGroup = AccountRTs.get('Prospect Buying Group').getRecordTypeId();
      public static String AccountRTProspectBuyingGroup = accountRTMap.get('Prospect_Buying_Group');
      
   // public static String AccountRTProspectDealer = AccountRTs.get('Prospect Dealer').getRecordTypeId();
    public static String AccountRTProspectDealer = AccountRTMap.get('Prospect_Dealer');
   
   // public static String AccountRTProspectDistributor = AccountRTs.get('Prospect Distributor').getRecordTypeId();
    public static String AccountRTProspectDistributor = AccountRTMap.get('Prospect_Distributor');
    
    public static String AccountRTClientDealer {get {
        if(AccountRTClientDealer == null) {
            //AccountRTClientDealer = [Select Id from RecordType Where SOBjectType = 'Account' And DeveloperName = 'Client_Dealer'].Id;
            AccountRTClientDealer = accountRTMap.get('Client_Dealer');
        }
        return AccountRTClientDealer;
    }set;}
    
    // Santosh - added for bugFix Wi 0427
   // public static String legalEntity = accountRTs.get('Legal Entity').getRecordTypeId();
      public static String legalEntity = Constants.AccountRTMap.get('Legal_Entity');
    //
    
   
    
    public static Map<String, Id> CaseRTMap 
    {
        get 
        {
            if(CaseRTMap == null) 
            {
                CaseRTMap = new Map<String, Id>();
                //for(RecordType rt : [Select Id, DeveloperName from RecordType Where SObjectType = 'Case']) {
                     if(objectToRecordTypeMap.containsKey('Case') && objectToRecordTypeMap.get('Case')!=null)
                      {
                           for(RecordType rt :objectToRecordTypeMap.get('Case'))
                           {
                                CaseRTMap.put(rt.DeveloperName, rt.Id);
                           }
                     }
            }
        
             return CaseRTMap;
        }
        set;
    }
    
     public static String CaseRTDeficiency {get{
        if(CaseRTDeficiency == null)
        {
           // CaseRTDeficiency = [SELECT Id FROM RecordType WHERE DeveloperName = 'Deficiency' AND SobjectType = 'Case'].Id;
           CaseRTDeficiency = CaseRTMap.get('Deficiency');
        }
        return CaseRTDeficiency;
    }set;}
    
     // Santosh - added for bugFix WI 0183
    public static String SLRrecordType = CaseRTMap.get('Special_Loan_Report');
    
       public static Map<String, Id> taskRTMap 
       {
            get 
            {
                if(taskRTMap == null) 
                {
                    taskRTMap = new Map<String, Id>();
                    //for(RecordType rt : [Select Id, DeveloperName from RecordType Where SObjectType = 'Task']) {
                     if(objectToRecordTypeMap.containsKey('Task') && objectToRecordTypeMap.get('Task')!=null)
                     {
                           for(RecordType rt :objectToRecordTypeMap.get('Task'))
                           {
                                taskRTMap.put(rt.DeveloperName, rt.Id);
                           }
                    }
                }
                
                return taskRTMap;
            }
            set;
        }
    
    //
    public static Set<Id> CommunityOpenRequestRTIds {get {
        if(CommunityOpenRequestRTIds == null) {
            CommunityOpenRequestRTIds = new Set<Id>();
            CommunityOpenRequestRTIds.add(CaseRTMap.get('Buyout_Existing_Customer'));
            CommunityOpenRequestRTIds.add(CaseRTMap.get('Location_Additions_Changes'));
            CommunityOpenRequestRTIds.add(CaseRTMap.get('Dealer_Increase_Credit_Review_300_000'));
            CommunityOpenRequestRTIds.add(CaseRTMap.get('Product_Line_Add_Request'));
            CommunityOpenRequestRTIds.add(CaseRTMap.get('Trade_In'));
            CommunityOpenRequestRTIds.remove(null);
        }
        return CommunityOpenRequestRTIds;
    } set;}
    
    public static Set<String> CommunityRequestURTypes = new Set<String> {'Buyout_Existing_Customer', 'Dealer_Increase_Credit_Review_300_000', 'Product_Line_Add_Request'};
    public static Map<String, String> CommunityRequestRTtoProduct = new Map<String, String> {'Buyout_Existing_Customer' => 'Inventory Buyout', 'Dealer_Increase_Credit_Review_300_000' => 'Increase', 'Product_Line_Add_Request' => 'Product Add'};
    
    public static Map<String, Id> MitigantReasonRTMap 
    {
        get 
        {
            if(MitigantReasonRTMap == null) 
            {
                MitigantReasonRTMap = new Map<String, Id>();
                //for(RecordType rt : [Select Id, DeveloperName from RecordType Where SObjectType = 'Mitigant_Reason__c']) {
                   if(objectToRecordTypeMap.containsKey('Mitigant_Reason__c') && objectToRecordTypeMap.get('Mitigant_Reason__c')!=null)
                   {
                       for(RecordType rt :objectToRecordTypeMap.get('Mitigant_Reason__c'))
                       {
                             MitigantReasonRTMap.put(rt.DeveloperName, rt.Id);
                             
                       }
                   }
            }
            
            return MitigantReasonRTMap;
        }
        set;
    }
    
    public static Map<String, Id> UnderwritingRTMap 
    {
        get 
        {
            if(UnderwritingRTMap == null) 
            {
                UnderwritingRTMap = new Map<String, Id>();
                //for(RecordType rt : [Select Id, DeveloperName from RecordType Where SObjectType = 'Underwriting__c']) {
                 if(objectToRecordTypeMap.containsKey('Underwriting__c') && objectToRecordTypeMap.get('Underwriting__c')!=null)
                 {
                           for(RecordType rt :objectToRecordTypeMap.get('Underwriting__c'))
                           {
                                UnderwritingRTMap.put(rt.DeveloperName, rt.Id);
                           }
                }
            }
            
            return UnderwritingRTMap;
        }
         set;
     }
    
    public static Map<String, Id> BillingPaymentRTMap 
    {
        get 
        {
        
            if(BillingPaymentRTMap == null) 
            {
                BillingPaymentRTMap = new Map<String, Id>();
                //for(RecordType rt: [Select Id, DeveloperName from RecordType Where SObjectType = 'Billing_Payment__c']) {
                    if(objectToRecordTypeMap.containsKey('Billing_Payment__c') && objectToRecordTypeMap.get('Billing_Payment__c')!=null)
                     {
                               for(RecordType rt :objectToRecordTypeMap.get('Billing_Payment__c'))
                               {
                                    BillingPaymentRTMap.put(rt.DeveloperName, rt.Id);
                               }
                
                     }
            }
            
            return BillingPaymentRTMap;
          }
          
          set;
    }

    public static Set<String> populateCARENumberAccountRTs = new Set<String> {AccountRTBuyingGroup, AccountRTDealer, AccountRTDistributor, AccountRTManufacturer, AccountRTProspectBuyingGroup, AccountRTProspectDistributor, AccountRTProspectManufacturer};
    
    public static map<String, Schema.RecordTypeInfo> AssetVerificationRTs = Schema.SObjectType.Asset_Verification__c.getRecordTypeInfosByName();
    public static String AssetVerificationRTAssetVerification = AssetVerificationRTs.get('Asset Verification').getRecordTypeId();
    public static String AssetVerificationRTParent = AssetVerificationRTs.get('Parent').getRecordTypeId();
    
    public static Set<Id> SiloEligibleRecordTypes = new Set<Id> {UnderwritingRTMap.get('Carve_Out_Review_App_Only'), UnderwritingRTMap.get('Carve_Out_Review_Standard'), UnderwritingRTMap.get('Carve_Out_Review_TCF_Bank'), UnderwritingRTMap.get('Dealer_Increase_App_Only_Review'), UnderwritingRTMap.get('Increase_Review_Standard'), UnderwritingRTMap.get('Increase_Review_TCF_Bank'), UnderwritingRTMap.get('New_Dealer_App_Only'), UnderwritingRTMap.get('New_Dealer_Bank'), UnderwritingRTMap.get('New_Dealer_Standard')};
    public static Set<Id> URLockedRTIds = new Set<Id> {        
        UnderwritingRTMap.get('Carve_Out_Review_App_Only_Locked'),
        UnderwritingRTMap.get('Carve_Out_Review_Standard_Locked'),
        UnderwritingRTMap.get('Carve_Out_Review_TCF_Bank_Locked'),
        UnderwritingRTMap.get('Commercial_Loan_Record_Type_Locked'),
        UnderwritingRTMap.get('Continuation_Review_Standard_Locked'),
        UnderwritingRTMap.get('Continuation_Review_TCF_Bank_Locked'),
        UnderwritingRTMap.get('Credit_Extension_Review_Locked'),
        UnderwritingRTMap.get('Credit_Exception_Review_300_000_Locked'),
        UnderwritingRTMap.get('Interim_Financial_Review_Dealer_Locked'),
        UnderwritingRTMap.get('Dealer_Increase_App_Only_Review_Locked'),
        UnderwritingRTMap.get('Increase_Review_Standard_Locked'),
        UnderwritingRTMap.get('Increase_Review_TCF_Bank_Locked'),
        UnderwritingRTMap.get('Memo_Locked'),
        UnderwritingRTMap.get('New_Dealer_App_Only_Locked'),
        UnderwritingRTMap.get('New_Dealer_Standard_Locked'),
        UnderwritingRTMap.get('New_Dealer_Bank_Locked'),
        UnderwritingRTMap.get('New_Seller_Review_Standard_Locked'),
        UnderwritingRTMap.get('New_Seller_Review_WCC_Locked'),
        UnderwritingRTMap.get('Overline_Locked'),
        UnderwritingRTMap.get('Product_Line_Add_Request_Locked'),
        UnderwritingRTMap.get('Inventory_Buyout_Locked'),
        UnderwritingRTMap.get('Risk_Rating_Change_Locked'),
        UnderwritingRTMap.get('Silo_Review_App_Only_Locked'),
        UnderwritingRTMap.get('Temporary_Increase_Locked')
        };
    
    public static Set<Id> URUnlockedRTIds = new Set<Id> {
        UnderwritingRTMap.get('Carve_Out_Review_App_Only'),
        UnderwritingRTMap.get('Carve_Out_Review_Standard'),
        UnderwritingRTMap.get('Carve_Out_Review_TCF_Bank'),
        UnderwritingRTMap.get('Commercial_Loan_Record_Type'),
        UnderwritingRTMap.get('Continuation_Review_Standard'),
        UnderwritingRTMap.get('Continuation_Review_TCF_Bank'),
        UnderwritingRTMap.get('Credit_Extension_Review'),
        UnderwritingRTMap.get('Credit_Exception_Review_300_000'),
        UnderwritingRTMap.get('Interim_Financial_Review_Dealer'),
        UnderwritingRTMap.get('Dealer_Increase_App_Only_Review'),
        UnderwritingRTMap.get('Increase_Review_Standard'),
        UnderwritingRTMap.get('Increase_Review_TCF_Bank'),
        UnderwritingRTMap.get('Memo'),
        UnderwritingRTMap.get('New_Dealer_App_Only'),
        UnderwritingRTMap.get('New_Dealer_Standard'),
        UnderwritingRTMap.get('New_Dealer_Bank'),
        UnderwritingRTMap.get('New_Seller_Standard'),
        UnderwritingRTMap.get('New_Seller_Bank'),
        UnderwritingRTMap.get('Overline'),
        UnderwritingRTMap.get('Product_Line_Add_Request'),
        UnderwritingRTMap.get('Inventory_Buyout'),
        UnderwritingRTMap.get('Silo_Review_App_Only'),
        UnderwritingRTMap.get('Temporary_Increase')
        };
        
    public static Organization currentOrg = [Select Id, IsSandbox From Organization limit 1];
    public static String informaticaUsername = currentOrg.isSandbox ? 'Integration@tcfif.com' : 'Integration@tcfif.com.prod';
    
    public static string MoodysAPIEndpoint = currentOrg.isSandbox ? 'https://devmoodysws.tcfif.com' : 'https://moodysws.tcfif.com';
    
    public static string MoodysAPIUsername = currentOrg.isSandbox ? 'integration' : 'integration';
    public static string MoodysAPIPassword = currentOrg.isSandbox ? 'Lincoln18'   : 'G0ldF1sh';
    
    //WI 2395//
    //Add a dnbUserId and dnbPassword for CA dnb requests
    public static String dnbUSUserId = '372348';
    public static String dnbUSEncryptedHexStringPassword = '0c43c610e80c66e96c1ad5b44c200c9b0c9234764c5e5ff69f320e22f36b393e';
    
    public static String dnbCAUserId = '153404TCF';
    public static String dnbCAEncryptedHexStringPassword ='e05b43435c43135303920ebe5f64818198dc0f04f944f399b5aaec1c4b0a9ef8';
    
    //public static String dnbCAUserId = '356782';
    //public static String dnbCAEncryptedHexStringPassword ='0c43c610e80c66e96c1ad5b44c200c9b0c9234764c5e5ff69f320e22f36b393e';
    //
         
    //WI 1839//
    public static String passwordEncryptionKey;
    public static String informaticaPassword = currentOrg.isSandbox ? '2425855ecfc038fb84ae309a91562a2a204f5d0aec8a98b5dbd01fa6faafbcc3' : '46d6b1991a1e7d5e305beb8da5cf4af7e540bc102a4adae3cdd61efcc39d0bc1';
    
    public static string getDecryptedPassword(string encryptedHexStringPassword)
    {
      passwordEncryptionKey = AES256Key__c.getAll().Values()[0].value__c;
      return Crypto.decryptWithManagedIV('AES256', System.EncodingUtil.convertFromHex(passwordEncryptionKey), System.EncodingUtil.convertFromHex(encryptedHexStringPassword)).toString();
    }
    ///////////////////////////////////
    
    /**
        This method is used for determing what types of accounts have u/w's. 
              
        This method will use of basic app setting.
        Basic App Setting Name:- Record Types For UW Creation
        String Value Set 1: Client_Buying_Group,Prospect_Manufacturer,Client_Dealer,Client_Distributor,Client_Manufacturer, Prospect_Buying_Group,Prospect_Dealer, Prospect_Distributor
        Active: TRUE.
        
        This method is used caseCareLevelVFC and CaseManager class.
    */
    public static Set<String>  recordTypesToIncludeForUnderwritingCreation()
    {
        Set<String> recordTypeIds = new Set<String>();
        Set<String> recordTypesToQuery = new Set<String>();
        
        List<Basic_App_Setting__c > appSettings = [SELECT id, EmailAddresses__c, Active__c, name, Email_Template_Dev_Name__c, String_Value_Set_1__c, String_Value_Set_2__c, Send_Admin_Only__c FROM Basic_App_Setting__c WHERE Active__c = true AND name = 'Record Types For Child UW Creation'];
    
        If(appSettings!=null && appSettings.size() >0 && !String.isBlank(appSettings[0].String_Value_Set_1__c))
        {
            String recordTypes = appSettings[0].String_Value_Set_1__c;
            
            System.debug('=== recordTypes ==='+recordTypes);
            
            if(!recordTypes.contains(','))
                recordTypesToQuery.add(recordTypes.replaceAll('\\s+',''));
        
            else if(recordTypes.contains(','))  
                recordTypesToQuery.addAll(recordTypes.replaceAll('\\s+','').split(','));
        
        
            System.debug('==== recordTypesToQuery ==='+recordTypesToQuery);
            
            for(String recType: recordTypesToQuery)
            {
                System.debug('==== recType ==='+recType);
                if(constants.accountRTMap.containsKey(recType))
                {
                    recordTypeIds.add(constants.accountRTMap.get(recType));
                }
            }
        } 
        else
        {
            throw new customException('There are no record types found for child u/w creation."Record Types For Child UW Creation" Data missing in basic app settings. ');
        }
        
        if(recordTypeIds.size() ==0)  
        {
            throw new customException('There are no record types found for child u/w creation. Please make sure "Record Types For Child UW Creation" data entered in basic app settings is accurate. ');
        }
        return recordTypeIds;
    }
    
    public class CustomException extends Exception {}
    
    //map from short code => actual name in Boarding_Wizard_Screen__c table
    public static Map<string, string> getBWScreenNameMap(){
        Map<string, string> result = new Map<string,string>{
          'WELCOME' => 'Welcome',
          //REQUEST STAGE SCREENS
          'DUP_APPS' => 'Duplicate Applications',
          'NDA_VER' => 'NDA Verification',
          'DUP_CHECK' => 'Duplicates Check',
          'ENT_VER' => 'Entity Verification',
          'FRM_DOCS' => 'Formation Documents',
          'BUS_DATA_VER' => 'Business Data Verification',
          'CBR_VER' => 'Credit Bureau Verification',
          'ADDR_VER' => 'Address Verification',
          'ASSOC_VER' => 'Associations Verification',
          'OR_AND_EXCP' => 'Overrides and Exceptions',
          'OM' => 'Origination Model',
          'DLR_DSCN' => 'Dealer Discussion',
          'DOC_VAULT' => 'Doc Vault',
          'MOVE_TO_UW_STAGE' => 'Proceed to Underwriting stage',
          //UNDERWRITING STAGE SCREENS
          'UNDERWRITING' => 'Underwriting',
          'MOVE_TO_DOC_CREATION_STAGE' => 'Proceed to Document Creation stage',
          //DOCUMENT CREATION STAGE SCREENS
          'DOC_QA' => 'Doc QA',
          'DOC_PREP' => 'Doc Prep',
          'DOC_ACCEP' =>'Doc Acceptance',
          'SEC_SEARCH' => 'Security Search & Filing',
          'PMSI' => 'PMSI',
          'MOVE_TO_ACCT_SETUP_STAGE ' => 'Proceed to Account Setup stage',
          'REG_CHECK' => 'Reg Checks',
          //ACCOUNT SETUP STAGE SCREENS
          'CLOSE_AUDIT' =>'Closing Audit',
          'WMS_SETUP' => 'Pre-WMS Setup Review'
        
        };
        return result;
    }
    
    //maps codes from transunion XML into a string used for displaying special message results
    public static Map<string, string> getCBRXMLtypeCodeMap(){
        Map<string, string> result = new Map<string, string>{
            'regular'                 => 'CONSUMER STATEMENT: ', //meant to be used in this context <consumerStatement><type>regular</type><text>...some statement here...</text></consumerStatement>
            'trueNameFraud'           => 'TRUE NAME FRAUD: ', 
            'securityAlert'           => 'SECURITY ALERT: ', 
            'initialFraudAlert'       => 'INITIAL FRAUD ALERT: ', 
            'extendedFraudAlert'      => 'EXTENDED FRAUD ALERT: ', 
            'activeMilitaryDutyAlert' => 'ACTIVE MILITARY DUTY ALERT: ', 
            'AM' => 'PUBLIC RECORD: Attachment', 
            'CB' => 'PUBLIC RECORD: Civil judgment in bankruptcy', 
            'CJ' => 'PUBLIC RECORD: Civil judgment', 
            'CP' => 'PUBLIC RECORD: Child support', 
            'CS' => 'PUBLIC RECORD: Civil suit filed', 
            'DF' => 'PUBLIC RECORD: Dismissed foreclosure', 
            'DS' => 'PUBLIC RECORD: Dismissal of court suit', 
            'FC' => 'PUBLIC RECORD: Foreclosure', 
            'FD' => 'PUBLIC RECORD: Forcible detainer', 
            'FF' => 'PUBLIC RECORD: Forcible detainer dismissed', 
            'FT' => 'PUBLIC RECORD: Federal tax lien', 
            'GN' => 'PUBLIC RECORD: Garnishment', 
            'HA' => 'PUBLIC RECORD: Homeowner\'s association assessment lein', 
            'HF' => 'PUBLIC RECORD: Hospital lien satisfied', 
            'HL' => 'PUBLIC RECORD: Hospital lien', 
            'JL' => 'PUBLIC RECORD: Judicial lien', 
            'JM' => 'PUBLIC RECORD: Judgment dismissed', 
            'LR' => 'PUBLIC RECORD: A lien attached to real property', 
            'ML' => 'PUBLIC RECORD: Mechanics lien', 
            'PC' => 'PUBLIC RECORD: Paid civil judgment', 
            'PF' => 'PUBLIC RECORD: Paid federal tax lien', 
            'PG' => 'PUBLIC RECORD: Paving assessment lien', 
            'PL' => 'PUBLIC RECORD: Paid tax lien', 
            'PQ' => 'PUBLIC RECORD: Paving assessment lien satisfied', 
            'PT' => 'PUBLIC RECORD: Puerto Rico tax lien', 
            'PV' => 'PUBLIC RECORD: Judgment paid, vacated', 
            'RL' => 'PUBLIC RECORD: Release of tax lien', 
            'RM' => 'PUBLIC RECORD: Release of mechanic\'s lien', 
            'RS' => 'PUBLIC RECORD: Real estate attachment satisfied', 
            'SF' => 'PUBLIC RECORD: Satisfied foreclosure', 
            'SL' => 'PUBLIC RECORD: State tax lien', 
            'TB' => 'PUBLIC RECORD: Tax lien included in bankruptcy', 
            'TC' => 'PUBLIC RECORD: Trusteeship canceled', 
            'TL' => 'PUBLIC RECORD: Tax lien included in bankruptcy', 
            'TP' => 'PUBLIC RECORD: Trusteeship paid/state amortization satisfied', 
            'TR' => 'PUBLIC RECORD: Trusteeship paid/state amortization satisfied', 
            'TX' => 'PUBLIC RECORD: Tax lien revived', 
            'WS' => 'PUBLIC RECORD: Water and sewer lien', 
            '1D' => 'PUBLIC RECORD: Ch 11 bankruptcy dismissed/closed', 
            '1F' => 'PUBLIC RECORD: Ch 11 bankruptcy filing', 
            '1V' => 'PUBLIC RECORD: Ch 11 bankruptcy voluntary dismissal', 
            '1X' => 'PUBLIC RECORD: Ch 11 bankruptcy discharged', 
            '2D' => 'PUBLIC RECORD: Ch 12 bankruptcy dismissed/closed', 
            '2F' => 'PUBLIC RECORD: Ch 12 bankruptcy filing', 
            '2V' => 'PUBLIC RECORD: Ch 12 bankruptcy voluntary dismissal', 
            '2X' => 'PUBLIC RECORD: Ch 12 bankruptcy discharged', 
            '3D' => 'PUBLIC RECORD: Ch 13 bankruptcy dismissed/closed', 
            '3F' => 'PUBLIC RECORD: Ch 13 bankruptcy filing', 
            '3V' => 'PUBLIC RECORD: Ch 13 bankruptcy voluntary dismissal', 
            '3X' => 'PUBLIC RECORD: Ch 13 bankruptcy discharged', 
            '7F' => 'PUBLIC RECORD: Ch 7 bankruptcy dismissed/closed', 
            '7F' => 'PUBLIC RECORD: Ch 7 bankruptcy filing', 
            '7V' => 'PUBLIC RECORD: Ch 7 bankruptcy voluntary dismissal', 
            '7X' => 'PUBLIC RECORD: Ch 7 bankruptcy discharged' 
        };
        return result;
    }
}