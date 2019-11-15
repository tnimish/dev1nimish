//Class with functionality that can be used across multiple stages in BW

public class BWHelper
{
    public static Underwriting__c getUnderwritingRecord(string uwCaseOrNDARecId)
    {
        List<Underwriting__c> uwList;
        Underwriting__c r;

        if(uwCaseOrNDARecId.startsWith('a2L'))
        {
            uwList = [select id, name, recordtype.developername,recordtype.name, consolidateduw__c, stage__c, review_type__c,care_number__c, Initiating_Account__r.Care_Number__c, initiating_account__r.billingcountry, Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name from Underwriting__c where connected_request__c =:uwCaseOrNDARecId and Underwriting_Request_Level__c = 'CARE Level'];
             
            if(uwList != null && uwList.size() > 0)
                r = uwList[0];

            system.debug('nda:'+r);    
        }
        else if(uwCaseOrNDARecId.startsWith('500'))
        {
            uwList = [select id, name, recordtype.developername,recordtype.name, consolidateduw__c, stage__c, review_type__c,care_number__c, Initiating_Account__r.Care_Number__c, initiating_account__r.billingcountry, Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name from Underwriting__c where case_id__c =:uwCaseOrNDARecId and Underwriting_Request_Level__c = 'CARE Level'];
             
            if(uwList != null && uwList.size() > 0)
                r = uwList[0];

            system.debug('case:'+r);        
        }
        else if(uwCaseOrNDARecId.startsWith('a4Y'))
        {
            uwList = [select id, name, recordtype.developername,recordtype.name, consolidateduw__c, stage__c, review_type__c,care_number__c, Initiating_Account__r.Care_Number__c, initiating_account__r.billingcountry, Case_ID__c,Case_ID__r.CaseNumber,Connected_Request__c,Connected_Request__r.Name,Initiating_Account__c,Initiating_Account__r.Name,Owner.Name from Underwriting__c where id =:uwCaseOrNDARecId and Underwriting_Request_Level__c = 'CARE Level'];
             
            if(uwList != null && uwList.size() > 0)
                r = uwList[0];

            system.debug('uw:'+r);        
        }

        return r;
    }

    public static List<string> getUWStages()
    { 
      List<string> options = new List<string>();
      
      Schema.DescribeFieldResult fieldResult =  Underwriting__c.Stage__c.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
      
      for( Schema.PicklistEntry f : ple)
      {
        options.add(f.getLabel());
      }

      return options;
    }     

    public static List<string> getUWStageStatuses(string uwStage)
    {
        List<string> uWStageStatuses = new List<string>();

        Map<string, List<string>> pickValueMap = GetDependentOptions('Underwriting__c','Stage__c','Status__c');
      
        //uWStageStatuses.add('');

        if(pickValueMap.get(uwStage) != null)
        {
            for(String s: pickValueMap.get(uwStage))
            {
                if(!(s.equalsIgnoreCase('New') || s.equalsIgnoreCase('Complete'))){
                    uWStageStatuses.add(s);
                }
            }
        }

        return uWStageStatuses;
    }


    public static Map<String,List<String>> GetDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName)
    {           
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        
        //get the type being dealt with
        Schema.SObjectType pType = objGlobalMap.get(pObjName);
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        //get the control values
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
                
        //iterate through the values and get the ones valid for the controlling field name
        PickListUtils.Bitset objBitSet = new PickListUtils.Bitset();
        
        //set up the results
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++)
        {
            //get the pointer to the entry
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            String pControllingLabel = ctrl_entry.getLabel();
            //create the entry with the label
            objResults.put(pControllingLabel,new List<String>());
        }
                
        //check the dependent values
        for(Integer pDependentIndex=0; pDependentIndex < dep_ple.size(); pDependentIndex++)
        {
            //get the pointer to the dependent index
            Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
            //get the valid for
            String pEntryStructure = JSON.serialize(dep_entry);
            PickListUtils.PicklistDetails objDepPLE = (PickListUtils.PicklistDetails)JSON.deserialize(pEntryStructure, PickListUtils.PicklistDetails.class);
            
            //iterate through the controlling values
            for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++)
            {
              if(objBitSet.fitBit(objDepPLE.validFor,pControllingIndex))
              {
                //get the label
                String pControllingLabel = ctrl_ple[pControllingIndex].getLabel();
                objResults.get(pControllingLabel).add(objDepPLE.label);
              }
            }
        }
        return objResults;
    }

    public static void updateUWStageAndStatus(string uwRecId, string uwStage, string uwStatus)
    { 
       Underwriting__c uw = new Underwriting__c(id=uwRecId, stage__c = uwStage, status__c = uwStatus);

       update uw;
    } 
    
    public static string constructStringForChartRow(String actualData, string key, string value)
    {
        actualData+= key+'='+value+';';
        return actualData;
    }
    
    public static Map<String, String> deconstructList(String Data)
    {
        List<String> dataList = new List<String>();
        Map<String, String> values = new Map<String, String>();
        if(String.isNotBlank(Data))
        {
            if(Data.contains(';'))
            {
                dataList =Data.split(';');
                
            }
            else
            {
                dataList.add(Data);
            }
            
            if(dataList.size() >0)
            {
                for(String d: dataList)
                {
                    List<String> dataInfo = d.Split('=');
                    //values.put(dataInfo[0], dataInfo[1]);
                    try
                    {
                        values.put(dataInfo[0], dataInfo[1]);
                    }
                    catch(exception e)
                    {
                        if(dataInfo.size() ==1)
                        {
                            values.put(dataInfo[0], '');
                        }
                    } 
                }
            }
        }
        
        return values;
    }

    /*@params:  string jsonList = a serialized string of a List<> variable 
    example: {relationshipId:001235234, dob:2019-05-01, firstName:Jerome}
    string objectOrClassName        = example: 'Account'
    Map<string, string> fieldAPINameToJsonKeyMap = example: {id=>relationshipId, date_of_birth__c=>dob, first_name__c=>firstName}
    Map<string, string> fieldAPINameTypeMap      = example: { id=>id, date_of_birth__c=> date, name=string}
    */
    public static List<Sobject> convertJSONToSObjectList(string jsonList, string objectOrClassName, Map<string, string> fieldAPINameToJsonKeyMap, Map<string, string> fieldAPINameTypeMap){
        List<Sobject> resultList = new List<Sobject>();
        List<Object> bigList = (List<Object>)JSON.deserializeUntyped(jsonList);
        for(object o: bigList){
            Map<string, Object> rowMap = (Map<string, Object>)o;
            
            sObject sObj = Schema.getGlobalDescribe().get(objectOrClassName).newSObject();
            
            for(string field: fieldAPINameTypeMap.keySet()){
                if(fieldAPINameToJsonKeyMap.containsKey(field)){
                    string jsonKey = fieldAPINameToJsonKeyMap.get(field);
                    
                    if(rowMap.containsKey(jsonKey)){
                        try{
                            if(fieldAPINameTypeMap.get(field).EqualsIgnoreCase('string')){
                                sObj.put(field, (string)rowMap.get(jsonKey));
                            }
                            else if(fieldAPINameTypeMap.get(field).EqualsIgnoreCase('id')){
                                sObj.put(field, (id)rowMap.get(jsonKey));
                            }
                            else if(fieldAPINameTypeMap.get(field).EqualsIgnoreCase('date') && !string.isblank((string)rowMap.get(jsonKey))){
                                sobj.put(field, date.valueOf((string)rowMap.get(jsonKey)));
                            }
                        } catch(exception e){
                            system.debug(e);
                        }
                    }
                }
            }
            resultList.add(sObj);
        }
        return resultList;
    }

 

    /*  this method converts [ 'a', 'b', 'c'] => [{ value:'a', label:'a' }, { value:'b', label:'b' }, { value:'c', label:'c' }]
                                                this format is compatible with lwc <lightning-combobox options={cbOptions} />
    */
    public static List<CommonWrapperClass.BWcbOption> convertStringsToComboBoxOptions(List<string> stringArray){
        List<CommonWrapperClass.BWcbOption> cbOptions = new List<CommonWrapperClass.BWcbOption>();
        for(string y: stringArray){
           CommonWrapperClass.BWcbOption cbo = new CommonWrapperClass.BWcbOption();
           cbo.value = y; cbo.label = y;
           cbOptions.add(cbo);
        }
        return cbOptions;
    }

}