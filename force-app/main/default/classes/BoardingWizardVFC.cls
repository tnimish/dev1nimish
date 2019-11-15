public class BoardingWizardVFC
{    
    //Blah Blah
    @AuraEnabled public string recordId {get;set;}
    @AuraEnabled public Underwriting__c uw {get;set;}
    
    public string baseURL {get;set;}
        
    public boardingWizardVFC(ApexPages.StandardController stdController)
    {    
        recordId = stdController.getId();
        baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();

        if(recordId.startsWith('a4Y'))
        {  
            uw = [Select id,name, ConsolidatedUW__c, CARE_Number_Value__c, stage__c, review_type__c,Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name, Next_Follow_Up_Date__c 
                from underwriting__c where id =:recordId limit 1];
        }    
    }

    @AuraEnabled (cacheable=true)
    public static string getGlobalData(string recordId)
    {
       return getGlobalDataBaseMethod(recordId);
    }

    @AuraEnabled
    public static string getGlobalDataImperative(string recordId)
    {
       return getGlobalDataBaseMethod(recordId);
    }

    @AuraEnabled (cacheable=true)
    public static string getGlobalDataBaseMethod(string recId)
    {   
        Map<string,string> returnMap = new Map<string, string>();
        string baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
        string mydomain = baseURL.split('\\.')[0];
        boolean uwAuditPermission = false;

        List<Underwriting__c> uwList;
        Underwriting__c uData;

        returnMap.put('baseURL', baseURL);

        //BW launching record is NDA
        if(recId.startsWith('a2L'))
        {
          New_Dealer_Application__c nda = [select id, name from New_Dealer_Application__c where id =: recId limit 1];
          
          if(nda != null)
          {
            returnMap.put('ndaId', nda.id);
            returnMap.put('ndaName',nda.name);
            returnMap.put('ndaURL', baseURL + '/' + nda.id);
            returnMap.put('startingRecordName', nda.name);
            returnMap.put('startingRecordURL', baseURL + '/' + nda.id);

            List<Product_Information_For_New_Dealer_App__c> prodJuncsList = [select id, relationship__c from Product_Information_For_New_Dealer_App__c where new_dealer_application2__c =: nda.id];

            if(prodJuncsList != null && prodJuncsList.size() > 0)
                returnMap.put('selectCareNumberURL','/apex/SelectCareNumber?accountId='+prodJuncsList[0].relationship__c);

            system.debug(returnMap.get('selectCareNumberURL'));  

            uwList = [Select id, recordtype.name, initiating_account__r.billingcountry, recordtype.developerName, account__c, name, Recommended_Credit_Line_Amount__c, ConsolidatedUW__c, CARE_Number_Value__c, stage__c, status__c, review_type__c,Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name, Next_Follow_Up_Date__c, createddate,
                (Select id,createddate FROM UCC_Security_Search_PMSI__r ORDER BY createddate DESC LIMIT 1)  
                 from underwriting__c where Connected_Request__c =:recId and Underwriting_Request_Level__c = 'CARE Level']; 

            if(uwList != null && uwList.size() > 0)
            {
                system.debug(uwList[0].ConsolidatedUW__c);

                if(uwList[0].ConsolidatedUW__c != null)
                {
                    uData = [Select id, recordtype.name, initiating_account__r.billingcountry, recordtype.developerName, account__c, name, Recommended_Credit_Line_Amount__c, ConsolidatedUW__c, CARE_Number_Value__c, stage__c, status__c, review_type__c,Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name, Next_Follow_Up_Date__c, createddate,
                        (Select id,createddate FROM UCC_Security_Search_PMSI__r ORDER BY createddate DESC LIMIT 1)  
                        from underwriting__c where id=:uwList[0].ConsolidatedUW__c and Underwriting_Request_Level__c = 'CARE Level'][0];

                    returnMap.put('consolidatedUWId', uData.id);
                    returnMap.put('consolidatedUWURL', mydomain+'.lightning.force.com/lightning/n/Boarding_Wizard?c__id=' + uData.id);
                }
                else
                {
                    uData = uwList[0];
                }
            }
          }
        }
        //BW launching record is Underwriting
        else if(recId.startsWith('a4Y'))
        {
          uwList = [Select id, recordtype.name, initiating_account__r.billingcountry, recordtype.developerName, account__c, name, Recommended_Credit_Line_Amount__c, ConsolidatedUW__c, CARE_Number_Value__c, Next_Follow_Up_Date__c, stage__c, status__c, review_type__c,Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name, createddate,
              (Select id,createddate FROM UCC_Security_Search_PMSI__r ORDER BY createddate DESC LIMIT 1) from underwriting__c where id =:recId];
        
          if(uwList != null && uwList.size() > 0)
          {
            system.debug(uwList[0].ConsolidatedUW__c);

            if(uwList[0].ConsolidatedUW__c != null)
            {
                uData = [Select id, recordtype.name, initiating_account__r.billingcountry, recordtype.developerName, account__c, name, Recommended_Credit_Line_Amount__c, ConsolidatedUW__c, CARE_Number_Value__c, stage__c, status__c, review_type__c,Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name, Next_Follow_Up_Date__c, createddate,
                    (Select id,createddate FROM UCC_Security_Search_PMSI__r ORDER BY createddate DESC LIMIT 1)  
                    from underwriting__c where id=:uwList[0].ConsolidatedUW__c and Underwriting_Request_Level__c = 'CARE Level'][0];

                returnMap.put('consolidatedUWId', uData.id);
                returnMap.put('consolidatedUWURL', mydomain+'.lightning.force.com/lightning/n/Boarding_Wizard?c__id=' + uData.id);
            }
            else
            {
                uData = uwList[0];
            }
          }    
        }

        if(uData != null)
        {
            returnMap.put('uwId', uData.id);
            returnMap.put('uwName',uData.name);
            returnMap.put('uwURL', baseURL + '/' + uData.Id);
            returnMap.put('uwCurrentStage',uData.stage__c);
            returnMap.put('uwCurrentStatus',uData.status__c);
            returnMap.put('uwRecordTypeName', uData.recordtype.name);
            returnMap.put('uwRecordTypeDevName',uData.recordtype.developername);
            returnMap.put('uwCareNumber', uData.CARE_Number_Value__c);
            returnMap.put('ndaId', uData.connected_request__c);
            returnMap.put('ndaName', uData.connected_request__r.name);
            returnMap.put('ndaURL', baseURL + '/' + uData.connected_Request__c);
            returnMap.put('caseId', uData.Case_ID__c);
            returnMap.put('caseNumber', uData.Case_ID__r.CaseNumber);
            returnMap.put('uwCreatedDateTimeString', string.valueOf(uData.createddate));
            returnMap.put('uwReviewType', uData.review_type__c);
            returnMap.put('caseURL', baseURL + '/' + uData.Case_ID__c);
            returnMap.put('initiating_account__c', uData.Initiating_Account__c);
            returnMap.put('initiating_account__r.name', uData.Initiating_Account__r.name);
            returnMap.put('initiating_account__c', uData.Initiating_Account__c);
            returnMap.put('initAcctURL', baseURL + '/' + uData.Initiating_Account__c);
            returnMap.put('ownerId', uData.OwnerId);
            returnMap.put('ownerName', uData.Owner.name);
            returnMap.put('nextFollowUpDate', string.valueOf(uData.Next_Follow_Up_Date__c));
            returnMap.put('careAccountId', uData.account__c);
            returnMap.put('uwRecommendedCreditLine',string.valueof(uData.Recommended_Credit_Line_Amount__c));
            returnMap.put('uwCountry', uData.initiating_account__r.billingcountry);
 
            if(uData.review_type__c == 'New')
            {
                returnMap.put('startingRecordName', uData.Connected_Request__r.Name);
                returnMap.put('startingRecordURL', baseURL + '/' + uData.Connected_Request__c);
            }
             // santosh -added to bring caseid and casenumber if review type is other than "New".
            else
            {
                if(String.isNotBlank(uData.case_Id__c))
                {
                    returnMap.put('startingRecordName', uData.case_Id__r.CaseNumber);
                    returnMap.put('startingRecordURL', baseURL + '/' + uData.case_Id__c);
                }
            }
            if(uData.UCC_Security_Search_PMSI__r != null && uData.UCC_Security_Search_PMSI__r.size()>0){
                returnMap.put('lastUCCSearchId', uData.UCC_Security_Search_PMSI__r[0].id);
            }
        }
        
        for(PermissionSetAssignment psa: [Select Id,PermissionSetId,PermissionSet.Name,AssigneeId FROM PermissionSetAssignment WHERE AssigneeId =: UserInfo.getUserId() 
            AND PermissionSet.Name = 'Underwriting_Audits_Create' LIMIT 1]){
            uwAuditPermission = true; // running user has permission to use the "report a mistake" button
        }
        returnMap.put('uwAuditPermission', String.ValueOf(uwAuditPermission));
        
        return JSON.serialize(returnMap);
    }

    @AuraEnabled
    public static Underwriting__c getURRecord(string recId)
    {
      Underwriting__c urRecord = [select id, CARE_Number_Value__c, name, status__c,recordtype.developername,recordtype.name,stage__c, review_type__c,Initiating_Account__r.Care_Number__c, initiating_account__r.billingcountry, Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name from Underwriting__c where id =:recId];
      return urRecord;
    }

    @AuraEnabled
    public static List<CommonWrapperClass.BWStepWrapper> getScreenSteps(string screenName, string uwCaseOrNDARecId)
    {
        Underwriting__c r = BWHelper.getUnderwritingRecord(uwCaseOrNDARecId);

        if(r != null && r.ConsolidatedUW__c != null)
        {
            return null;
        }
        
        List<CommonWrapperClass.BWStepWrapper> result = new List<CommonWrapperClass.BWStepWrapper>();

        set<string> oneVersionPerStep = new set<string>();
        integer screenVersionNumber = -1;
       
        if(r != null)
        {
            string urType = 'Underwritten';
            if(r.recordtype.name.containsIgnoreCase('App Only'))
            {
                urType = 'App Only';
            }
              
            Integer stepNumberCount = 1;
        
            for(BW_Screen_Step__c s: [SELECT id,name, Display_Text__c,Boarding_Wizard_Screen__c,Boarding_Wizard_Screen__r.Title__c, 
                Element1_Type__c, Element1_Label__c, Element1_Action_Name__c, Element1_Picklist_Values__c,
                Element2_Type__c, Element2_Label__c, Element2_Action_Name__c,
                Element3_Type__c, Element3_Label__c, Element3_Action_Name__c,
                Element4_Type__c, Element4_Label__c, Element4_Action_Name__c,
                Element5_Type__c, Element5_Label__c, Element5_Action_Name__c,
                Version__c,Step_Number_Formula__c,Boarding_Wizard_Screen__r.name,Country__c,Underwriting_Type__c,Review_Types__c, Hidden_On_Boarding_Screen__c,
                Boarding_Wizard_Screen__r.Underwriting_Request_Type__c,Boarding_Wizard_Screen__r.Version__c, Step_Title__c, Show_Checkbox_As_Read_Only__c 
            FROM BW_Screen_Step__c WHERE Boarding_Wizard_Screen__r.name =: screenName AND Active__c = true /*AND Boarding_Wizard_Screen__r.Underwriting_Request_Type__c =: r.recordtype.name*/
            AND Underwriting_Type__c INCLUDES (:urType) AND Review_Types__c INCLUDES (:r.review_type__c) AND Country__c INCLUDES (:r.initiating_account__r.billingcountry)
            ORDER BY Boarding_Wizard_Screen__r.Version__c DESC,Step_Number_Formula__c ASC, Version__c DESC]){

            //only take the highest version number of screen
            screenVersionNumber = Math.Max(screenVersionNumber, Integer.ValueOf(s.Boarding_Wizard_Screen__r.Version__c));
           
            //only include the step in results if it is for the correct screen version and it is the highest version of the step
            if(!oneVersionPerStep.contains(s.name) && screenVersionNumber == Integer.ValueOf(s.Boarding_Wizard_Screen__r.Version__c)){
               oneVersionPerStep.add(s.name);
               CommonWrapperClass.BWStepWrapper tw = new CommonWrapperClass.BWStepWrapper();
               tw.stepRecordId          = s.id;
               tw.screenRecordId        = s.Boarding_Wizard_Screen__c;
               tw.displayText           = s.Display_Text__c;
               tw.stepNumber            = stepNumberCount;
               tw.hiddenOnScreen        = s.Hidden_On_Boarding_Screen__c;
               tw.stepTitle             = s.step_Title__c;
               tw.readOnlyCheckMark     = s.Show_Checkbox_As_Read_Only__c;

               tw.element1Wrapper       = createElementWrapper(s.Element1_Type__c,s.element1_label__c,s.element1_action_name__c);
               tw.element2Wrapper       = createElementWrapper(s.Element2_Type__c,s.element2_label__c,s.element2_action_name__c);
               tw.element3Wrapper       = createElementWrapper(s.Element3_Type__c,s.element3_label__c,s.element3_action_name__c);
               tw.element4Wrapper       = createElementWrapper(s.Element4_Type__c,s.element4_label__c,s.element4_action_name__c);
               tw.element5Wrapper       = createElementWrapper(s.Element5_Type__c,s.element5_label__c,s.element5_action_name__c);

               if(s.Element1_Type__c == 'Picklist')
               {
                    if(!string.isBlank(s.element1_action_name__c))
                    {
                        String[] strArr=s.element1_action_name__c.split('\\.');
                        string objectAPIName = strArr[0];
                        string fieldAPIName  = strArr[1];
                        tw.element1Wrapper.elementPicklistValues = UtilityClass.getPicklistValues(objectAPIName, fieldAPIName);
                    }
                    else if(!string.isBlank(s.element1_picklist_values__c))
                    {
                        String[] strArr=s.element1_picklist_values__c.split(';');
                        tw.element1Wrapper.elementPicklistValues = strArr;
                    }
                    
                    tw.element1Wrapper.cbOptions = BWHelper.convertStringsToComboBoxOptions(tw.element1Wrapper.elementPicklistValues);
               }
               else if(s.Element1_Type__c =='Lookup')
               {
                   tw.element1Wrapper.validLookupRecordIds=new Map<String, sObject>();
                   if(s.step_Title__c =='Credit_Analyst')
                   {
                       tw.element1Wrapper.validLookupRecordIds= BWRequestStageHelper.searchActiveList('user', 'name');
                   }
               }
               if(s.Element2_Type__c == 'Picklist')
               {
                   String[] strArr=s.element2_action_name__c.split('\\.');
                   string objectAPIName = strArr[0];
                   string fieldAPIName  = strArr[1];
                   tw.element2Wrapper.elementPicklistValues = UtilityClass.getPicklistValues(objectAPIName, fieldAPIName);
               }
               if(s.Element3_Type__c == 'Picklist')
               {
                   String[] strArr=s.element3_action_name__c.split('\\.');
                   string objectAPIName = strArr[0];
                   string fieldAPIName  = strArr[1];
                   tw.element3Wrapper.elementPicklistValues = UtilityClass.getPicklistValues(objectAPIName, fieldAPIName);
               }
               if(s.Element4_Type__c == 'Picklist')
               {
                   String[] strArr=s.element4_action_name__c.split('\\.');
                   string objectAPIName = strArr[0];
                   string fieldAPIName  = strArr[1];
                   tw.element4Wrapper.elementPicklistValues = UtilityClass.getPicklistValues(objectAPIName, fieldAPIName);
               }
               if(s.Element5_Type__c == 'Picklist')
               {
                   String[] strArr=s.element5_action_name__c.split('\\.');
                   string objectAPIName = strArr[0];
                   string fieldAPIName  = strArr[1];
                   tw.element5Wrapper.elementPicklistValues = UtilityClass.getPicklistValues(objectAPIName, fieldAPIName);
               }

               result.add(tw); 

               if(!tw.hiddenOnScreen){
 
                   stepNumberCount++;
               }
           }
        }
    }
    
    if(screenName.equalsIgnoreCase(Constants.getBWScreenNameMap().get('CBR_VER'))){
        result = BWRequestStageHelper.cbrScreenStepsFix(result, r.id);
    } else if(screenName.equalsIgnoreCase(Constants.getBWScreenNameMap().get('DLR_DSCN'))){
        result = BWRequestStageHelper.dealerDiscussionScreenStepsFix(result, r.id);
    }
    
    System.debug('=== result ==='+result);
    return result;    
   }
    
    public static CommonWrapperClass.BWElementWrapper createElementWrapper(String elementType, String label, String actionName)
    {
        CommonWrapperClass.BWElementWrapper  elementTypeWrap = new CommonWrapperClass.BWElementWrapper();
        elementTypeWrap.isButton =false;
        elementTypeWrap.isCheckbox=false;
        elementTypeWrap.isURL =false;
        elementTypeWrap.isText=false;
        elementTypeWrap.isCurrency=false;
        elementTypeWrap.isDate=false;
        elementTypeWrap.elementLabel =label;
        elementTypeWrap.elementActionName=actionName;
        elementTypeWrap.isLookup = false;
        elementTypeWrap.isButtonSpinner=false;
        if(elementType =='Lookup')
        {
            elementTypeWrap.isLookup = true;
        }
        else if(elementType == 'Button')
        {
            elementTypeWrap.isButton =true;
        }
        else if(elementType == 'Checkbox')
        {
            elementTypeWrap.isCheckbox=true;
        }
        else if(elementType == 'URL')
        {
            elementTypeWrap.isURL=true;
        }
        else if(elementType == 'Text')
        {
            elementTypeWrap.isText=true;
        }
        else if(elementType == 'Picklist')
        {
            elementTypeWrap.isPicklist =true;
        }
        else if(elementType == 'Date')
        {
            elementTypeWrap.isDate =true;
        }
        else if(elementType == 'Currency')
        {
            elementTypeWrap.isCurrency=true;
        }
        return elementTypeWrap;
    }

    @AuraEnabled (cacheable=true)
    public static Map<string,List<CommonWrapperClass.BWScreenWrapper>> getScreens(string uwCaseOrNDARecId)
    {
       return getScreensBaseMethod(uwCaseOrNDARecId, false);
    }

    @AuraEnabled
    public static Map<string,List<CommonWrapperClass.BWScreenWrapper>> getScreensImperative(string uwCaseOrNDARecId)
    {
       return getScreensBaseMethod(uwCaseOrNDARecId, true);
    }

    private static Map<string,List<CommonWrapperClass.BWScreenWrapper>> getScreensBaseMethod(string uwCaseOrNDARecId, boolean allowDML)
    {
        Underwriting__c r = BWHelper.getUnderwritingRecord(uwCaseOrNDARecId);

        if(r != null && r.ConsolidatedUW__c != null)
        {
            return null;
        }

        Map<string, List<CommonWrapperClass.BWScreenWrapper>> result = new Map<string, List<CommonWrapperClass.BWScreenWrapper>>();
        set<string> oneVersionPerScreen = new set<string>();
        List<Boarding_Wizard_Step_Result__c> newResultsToInsert = new List<Boarding_Wizard_Step_Result__c>();
        
        if(r!=null)
        {
            system.debug(r.recordtype.developername);
            string urType = 'Underwritten';
       
            if(r.recordtype.name.containsIgnoreCase('App Only'))
            {
                urType = 'App Only';
            }

            for(BW_Screen__c s: [SELECT id,name, Underwriting_Request_Type__c, Stage__c, Version__c, Screen_Completed__c,
            (select id from Boarding_Wizard_Screen_Step__r WHERE Active__c = TRUE AND Underwriting_Type__c INCLUDES (:urType) AND Review_Types__c INCLUDES (:r.review_type__c) 
            AND Country__c INCLUDES (:r.initiating_account__r.billingcountry)) 
            FROM BW_Screen__c ORDER BY Stage__c ASC, Screen_Number_Within_Stage__c ASC, Version__c DESC])
            {
                system.debug('In screens for loop');

                integer numStepsOnThisScreen = 0;

                if(s.Boarding_Wizard_Screen_Step__r != null)
                    numStepsOnThisScreen = s.Boarding_Wizard_Screen_Step__r.size();

                if(numStepsOnThisScreen > 0)
                {
                    //only include the screen in results if it is for the highest version of the screen
                    if(!oneVersionPerScreen.contains(s.name))
                    {
                        oneVersionPerScreen.add(s.name);

                        CommonWrapperClass.BWScreenWrapper bwsw = new CommonWrapperClass.BWScreenWrapper();
                    
                        bwsw.isRequestStage = false;
                        bwsw.isUnderwritingStage = false;
                        bwsw.isDocumentCreationStage = false;
                        bwsw.isAccountSetupStage = false;
                        bwsw.name = s.name;
                        bwsw.displayScreenAsLink =false;
                        bwsw.isCompleted = s.screen_completed__c;
                        
                        if(s.stage__c == 'Request')
                            bwsw.isRequestStage = true;
                        else if(s.stage__c == 'Underwriting')
                            bwsw.isUnderwritingStage = true;
                        else if(s.stage__c == 'Document Creation')
                            bwsw.isDocumentCreationStage = true;
                        else if(s.stage__c == 'Account Setup')
                            bwsw.isAccountSetupStage = true;

                        Map<string, List<string>> screenStepResultsMap = getScreenStepResultsMap(r.id, s.name);    
                
                        boolean allStepsForThisScreenCompleted = true;
                        
                        //adjusted logic here - loop thru Boarding_Wizard_Screen_Step__r   
                        //    if in the map, then result already exists.  
                        //        if incomplete, mark allstepsforthisscreen = false
                        //    if not, add to list to insert and mark as incomplete
                        for(BW_Screen_Step__c step : s.Boarding_Wizard_Screen_Step__r){
                            if(screenStepResultsMap.containsKey(step.id)){
                                if(screenStepResultsMap.get(step.id)[0] == 'false' && allStepsForThisScreenCompleted)
                                    allStepsForThisScreenCompleted = false;
                            } else {
                                 allStepsForThisScreenCompleted = false;
                                 //add new result here   
                                 newResultsToInsert.add(new Boarding_Wizard_Step_Result__c(Boarding_Wizard_Screen_Step__c = step.id, Underwriting__c = r.id, Step_Completed__c = false, External_Id__c = r.id+'-'+step.id));
                            }
                        }
                        
                        //If a step result record was created previously for all steps
                        if((screenStepResultsMap.size() == numStepsOnThisScreen) && screenStepResultsMap.size() > 0)
                        {
                            for (string key : screenStepResultsMap.keySet()) 
                            {
                                if(screenStepResultsMap.get(key)[0] == 'false')
                                    allStepsForThisScreenCompleted = false;
                            }
                        }
                        //Else if step result was not created for all steps on the screen yet (meaning some steps are still false since the step result record is created when the step completed checkbox is set to true for the first time)
                        else if(screenStepResultsMap.size() < numStepsOnThisScreen)
                        {    
                            allStepsForThisScreenCompleted = false;
                        }
                        else
                        {
                            allStepsForThisScreenCompleted = false;
                        }

                        bwsw.isCompleted = allStepsForThisScreenCompleted;

                        if(   (bwsw.name.equalsIgnoreCase('Proceed to Underwriting stage') && /*bwsw.isCompleted == false &&*/ r.stage__c.equalsIgnoreCase('Request'))
                           || (bwsw.name.equalsIgnoreCase('Proceed to Document Creation stage') && /*bwsw.isCompleted == false &&*/ (r.stage__c.equalsIgnoreCase('Underwriting') ||  r.stage__c.equalsIgnoreCase('Request')))
                           || (bwsw.name.equalsIgnoreCase('Proceed to Account Setup stage') && /*bwsw.isCompleted == false &&*/ (r.stage__c.equalsIgnoreCase('Document Creation') || r.stage__c.equalsIgnoreCase('Underwriting') ||  r.stage__c.equalsIgnoreCase('Request')))
                        )
                        {
                            bwsw.isCompleted = false;
                        }

                        if(result.containsKey(s.stage__c))
                        {   
                            system.debug('stage found'); 
                            result.get(s.stage__c).add(bwsw);
                        }
                        else 
                        {
                            system.debug('stage not found');
                            result.put(s.stage__c, new List<CommonWrapperClass.BWScreenWrapper>{bwsw});
                        }

                        system.debug(s.stage__c+','+result.get(s.stage__c)); 
                    }
                }
            }
            //this code should execute 1 time only or each underwriting.  On the first "open screen" call in the lwc that is not the Welcome screen.
            if(newResultsToInsert.size()>0 && allowDML){
                try{
                    insert newResultsToInsert;
                } catch (exception e){
                    system.debug(e);
                }
            }        
        }

        system.debug(result);

        return result;
    }
    
    @AuraEnabled
    public static List<CommonWrapperClass.BWDupeAppsRowWrapper> getDupeApps(string uwCaseOrNDARecId)
    {    
        Underwriting__c uData = BWHelper.getUnderwritingRecord(uwCaseOrNDARecId);

        List<CommonWrapperClass.BWDupeAppsRowWrapper> result = new List<CommonWrapperClass.BWDupeAppsRowWrapper>(); 
        integer count = 0;
        
        set<string> existingProducts = new set<string>();
        string key;

        for(Product_Information_For_New_Dealer_App__c p:[SELECT New_Dealer_Application2__c,New_Dealer_Application2__r.Name,Manufacturer__c,Manufacturer__r.Name,Relationship__c,Relationship__r.Name,Relationship__r.TCF_Legal_Entity__c,Underwriting__c,Underwriting__r.Name,Relationship__r.Care_Number__r.Name FROM Product_Information_For_New_Dealer_App__c where Relationship__r.Care_Number__r.Name != null and New_Dealer_Application2__c != null and Relationship__r.Care_Number__c =: uData.Initiating_Account__r.Care_Number__c and Underwriting__c != null and Underwriting__r.Stage__c != 'Complete']){
            CommonWrapperClass.BWDupeAppsRowWrapper bwDupes = new CommonWrapperClass.BWDupeAppsRowWrapper();
            
            bwDupes.prospectId = '/'+p.Relationship__c;
            bwDupes.prospectName = p.Relationship__r.Name;
            bwDupes.ndaId = '/'+p.New_Dealer_Application2__c;
            bwDupes.ndaName = p.New_Dealer_Application2__r.Name;
            bwDupes.underwritingId = '/'+p.Underwriting__c;
            bwDupes.underwritingName = p.Underwriting__r.Name;
            bwDupes.businessEntity = p.Relationship__r.TCF_Legal_Entity__c;
            bwDupes.primaryNDA = false;
            bwDupes.primaryNDAIndex = 'nda'+String.valueOf(count);
            bwDupes.coBorrower = false;
            bwDupes.coBorrowerIndex = 'coBorrower'+String.valueOf(count);
            bwDupes.index = count;
            key = string.valueof(p.New_Dealer_Application2__c)+string.valueof(p.Underwriting__c);

            if(!existingProducts.contains(key)){
                existingProducts.add(key);
                count++;
                result.add(bwDupes);
            }
        }
        
        return result;      
    }

    @AuraEnabled
    public static CommonWrapperClass.BWStepActionOutComeWrapper invokeApexAction(string action, List<String> args)
    {
      switch on action {
          
           when 'generateNDAPDF' {
             boolean recordExist = boolean.valueOf(args[2]);
             return BWRequestStageHelper.generateNDAPDF(args[0], args[1], recordExist);
           }
           
            when 'generateFinalNDAPDF' {                
                return BWRequestStageHelper.generateFinalNDAPDF(args[0], args[1]);
            }
           
            when 'createRegCheckCase' {
                return BWDocumentCreationStageHelper.createRegCheckCase(args[0], args[1]);
            }
            
             when 'createWMSChangeFormCase' {
                return BWAccountSetupStageHelper.createWMSChangeFormCase(args[0], args[1]);
            }
            
           when else {
            CommonWrapperClass.BWStepActionOutComeWrapper cw = new CommonWrapperClass.BWStepActionOutComeWrapper();
            cw.outCome =false;
            cw.errorString='method was not found';
            return cw;
           } 
         }
    }

    @AuraEnabled
    public static string upsertStepAnswer(Id uwCaseOrNDARecId, Id stepRecordId, Id stepResultRecordId, string usrAnswer, boolean stepCompletedFlag)
    {
        try
        {
            Underwriting__c r = BWHelper.getUnderwritingRecord(uwCaseOrNDARecId);

            if(r != null)
            {
                List<Boarding_Wizard_Step_Result__c> bwaList = [select id, underwriting__c, Boarding_Wizard_Screen_Step__c, Boarding_Wizard_Screen_Step__r.Boarding_Wizard_Screen__r.name, step_completed__c, Answer__c from Boarding_Wizard_Step_Result__c where Boarding_Wizard_Screen_Step__c =:stepRecordId and underwriting__c =: r.id and Boarding_Wizard_Screen_Step__r.active__c = true];     
                
                Boarding_Wizard_Step_Result__c bwa = new Boarding_Wizard_Step_Result__c();

                if(bwaList == null || (bwaList != null && bwaList.size() == 0))
                {
                    bwa = new Boarding_Wizard_Step_Result__c();
                    bwa.underwriting__c = r.id;
                    bwa.Boarding_Wizard_Screen_Step__c = stepRecordId;
                    bwa.step_completed__c = stepCompletedFlag;
                    bwa.Answer__c = usrAnswer;

                    insert bwa;
                }
                else if(bwaList != null && bwaList.size() > 0)
                {
                    bwa = bwaList[0];
                    bwa.step_completed__c = stepCompletedFlag;
                    bwa.Answer__c = usrAnswer;

                    update bwa;
                }

                getScreenStepResultsMap(r.id, bwa.Boarding_Wizard_Screen_Step__r.Boarding_Wizard_Screen__r.name);
            }
       }
       catch(Exception e)
       {
           return 'ERROR: '+e.getMessage();
       }

       return null;
    }

    @AuraEnabled    //returns a map from bw step id => string[], where [0] = true/false for isCompleted, [1]=answer__c
    public static Map<string, List<string>> getScreenStepResultsMap(string underwritingRecId, string screenName)
    {
        system.debug('#####screenName: '+screenName);
        system.debug('#####underwritingRecId: '+underwritingRecId);
        Underwriting__c r = [select recordtype.name,review_type__c,initiating_account__r.billingcountry from Underwriting__c where id=:underwritingRecId limit 1];
        
        string urType = 'Underwritten';
        
        if(r.recordtype.name.containsIgnoreCase('App Only')){
            urType = 'App Only';
        }
        Map<string, List<string>> stepResultRecIdToRecordMap = new Map<string, List<string>>();

        system.debug('#####urType: '+urType);
        system.debug('#####r.review_type__c: '+r.review_type__c);
        system.debug('#####r.initiating_account__r.billingcountry: '+r.initiating_account__r.billingcountry);
        
        List<Boarding_Wizard_Step_Result__c> screenStepResultsList = [select id, name, Boarding_Wizard_Screen_Step__c, step_completed__c, Answer__c from Boarding_Wizard_Step_Result__c where Boarding_Wizard_Screen_Step__r.Active__c = true and underwriting__c = :underwritingRecId and Boarding_Wizard_Screen_Step__r.Boarding_Wizard_Screen__r.name =: screenName AND Boarding_Wizard_Screen_Step__r.Underwriting_Type__c INCLUDES (:urType) AND Boarding_Wizard_Screen_Step__r.Review_Types__c INCLUDES (:r.review_type__c) AND Boarding_Wizard_Screen_Step__r.Country__c INCLUDES (:r.initiating_account__r.billingcountry)];

        system.debug('#####screenStepResultsList: '+screenStepResultsList);

        for(Boarding_Wizard_Step_Result__c stepResult: screenStepResultsList)
        {
            //First string element in the list below would be step_completed__C string equivalent value of its boolean value
            //Second would be step result Answer__c
            List<string> tempList = new List<string>();


            if(stepResult.step_completed__c == true)
            {
                tempList.add('true');
            }    
            else
            {
                tempList.add('false'); 
            }

            tempList.add(stepResult.Answer__c);
            
            stepResultRecIdToRecordMap.put(stepResult.Boarding_Wizard_Screen_Step__c, tempList);
        }

        system.debug(stepResultRecIdToRecordMap);
        
        return stepResultRecIdToRecordMap;
    }

    @AuraEnabled (cacheable=true)
    public static List<string> getUWStages()
    { 
      return BWHelper.getUWStages();
    }

    @AuraEnabled (cacheable=true)
    public static List<string> getUWStageStatuses(string uwStage)
    { 
      return BWHelper.getUWStageStatuses(uwStage);
    }

    @AuraEnabled
    public static CommonWrapperClass.BWStepActionOutComeWrapper updateUWStageAndStatus(string uwRecId, string uwStage, string uwStatus)
    { 
      CommonWrapperClass.BWStepActionOutComeWrapper result = new CommonWrapperClass.BWStepActionOutComeWrapper();
      result.resultString = 'Underwriting Request stage and status updated successfully.';
      result.errorString = '';
      result.outCome = true;
      result.resultRecordId = '';  
      try{
          BWHelper.updateUWStageAndStatus(uwRecId, uwStage, uwStatus);
      } catch (exception e){
          result.errorString = e.getMessage();
          result.resultString = e.getMessage();
          result.outCome = false;
      }
      
      return result;
    }
    
     @AuraEnabled
    public static string upsertStepAnswers(String underwritingRecId, List<String> stepInfo, string screenName)
    {
        try
        {
            system.debug('====stepInfo=='+stepInfo);
            
            Map<String, boolean> stepToAnswerMap = new Map<string, boolean>();
            List<Boarding_Wizard_Step_Result__c> stepResultsToUpsert = new List<Boarding_Wizard_Step_Result__c>();
            Map<id, Boarding_Wizard_Step_Result__c> bwResMap = new Map<id, Boarding_Wizard_Step_Result__c>(); 
            
            if(String.isNotBlank(underwritingRecId))
              {
                  if(String.valueof(underwritingRecId).startsWith('a2L'))
                  {
                      underwriting__c uw= [select id from underwriting__c where underwriting_request_level__c='CARE Level' and connected_Request__c=:underwritingRecId];
                      underwritingRecId =uw.id;
                  }    
              }
          
            for(string s: stepInfo)
            {
             commonwrapperclass.BWUpsertStepResultRecordInfo a = (commonwrapperclass.BWUpsertStepResultRecordInfo) System.JSON.deserialize(s, commonwrapperclass.BWUpsertStepResultRecordInfo.class);
             
             if(a!=null && a.stepRecId!=null && a.value!=null)
             {
                 stepToAnswerMap.put(a.stepRecId, boolean.valueOf(a.value));
             }
            
            }
            
            for(Boarding_Wizard_Step_Result__c bwRes: [select id, underwriting__c, Boarding_Wizard_Screen_Step__c, Boarding_Wizard_Screen_Step__r.Boarding_Wizard_Screen__r.name, step_completed__c from Boarding_Wizard_Step_Result__c where Boarding_Wizard_Screen_Step__c IN:stepToAnswerMap.keySet() and underwriting__c =:underwritingRecId and Boarding_Wizard_Screen_Step__r.Active__c = true])
            {
                bwResMap.put(bwRes.Boarding_Wizard_Screen_Step__c, bwRes);
            }
            
            System.debug('=== bwResMap ==='+bwResMap);
            
            for(Id stepId: stepToAnswerMap.keySet())
            {
                System.debug('==== bwResMap.containsKey(stepId) ==='+bwResMap.containsKey(stepId));
                if(bwResMap.containsKey(stepId))
                {
                    Boarding_Wizard_Step_Result__c bwa=  bwResMap.get(stepId);
                    bwa.step_completed__c = stepToAnswerMap.get(stepId);
                    stepResultsToUpsert.add(bwa);
                    System.debug('==== found  ==='+stepResultsToUpsert);
                }
                else
                {
                    Boarding_Wizard_Step_Result__c bwa = new Boarding_Wizard_Step_Result__c(underwriting__c = underwritingRecId, Boarding_Wizard_Screen_Step__c = stepId);
                    bwa.step_completed__c = stepToAnswerMap.get(stepId);
                    stepResultsToUpsert.add(bwa);
                    System.debug('==== new one ==='+stepResultsToUpsert);
                }
             }
             
              if(stepResultsToUpsert.size() >0)
             {
                upsert stepResultsToUpsert;
                return 'success';
             }
             
             getScreenStepResultsMap(underwritingRecId,screenName);
       }
       catch(Exception e)
       {
           return 'ERROR: '+e.getMessage();
       }
         
       return null;
    }
  
   @AuraEnabled(cacheable=true)
    public static Boarding_Wizard_Step_Result__c  fetchStepResult(String underwritingId, String stepId, String screenName)
    {
         
        List<Boarding_Wizard_Step_Result__c> stepResults =[select id,Step_Completed__c,Boarding_Wizard_Screen_Step__r.step_title__c  from Boarding_Wizard_Step_Result__c where 
        Boarding_Wizard_Screen_Step__r.Boarding_Wizard_Screen__r.Name=:screenName and underwriting__c=:underwritingId and Boarding_Wizard_Screen_Step__c=:stepId];
        
        if(stepResults!=null && stepResults.size() >0)
        {
            return stepResults[0];
        }
        else 
        {
            return null;
        } 
    }
    
    public class recordInfo
    {
        public String stepRecId;
        public string value;
    } 
      
}