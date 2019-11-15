public class BWUnderwritingStageHelper
{
   public static final integer APPONLY_LIMIT= 750000;
   public static final integer UWONLYLIMIT = 2000000;
   
  public static Map<String, String> screenMessage= new Map<String, String>
    {
         'ENOUGH_INSURANCE_COVERAGE' =>'No Condition Added as the Insurance Requirements have been met.',
         'CONDITION_ADDED_APPONLY' =>'A condition has been added to verify the Insurance coverage through a Dealer conversation or email which includes Inventory Coverage Amount ${0}, Loss Payee listed as {1}, Policy Number & Expiration Date. A verbal conversation must be documented to indicate the information, date, and the person who provided it. Insurance coverage should be 75% of the CARE credit line. If the CARE credit line includes a RIA account, separate insurance certificates/verification must be obtained from the TCFIF accounts.',
         'CONDITION_ADDED_WITHIN_UWLIMIT' =>'Obtain a copy of the Insurance Certificate or a verbal confirmation directly from the Dealer\'s Agent verifying the Inventory Coverage Amount ${0}, Loss Payee listed as {1}, Policy Number & Expiration Date and all Dealer Locations. Insurance coverage should be 75% of the CARE credit line. If the CARE credit line includes a RIA account, separate insurance certificates/verification must be obtained from the TCFIF accounts.',
         'CONDITION_ADDED_ABOVE_UWLIMIT' =>'Obtain a current Insurance Certificate which needs to include the Inventory Coverage Amount of ${0}, Loss Payee listed as {1}, Policy Number, Expiration Date and all Dealer Locations. Insurance coverage should be 75% of the CARE credit line. If the CARE credit line includes a RIA account, separate insurance certificates/verification must be obtained from the TCFIF accounts.'
     };
     
    public static Map<String, String> conditionMessage= new Map<String, String>
    {
         'ENOUGH_INSURANCE_COVERAGE' =>'No Condition Added.',
         'CONDITION_ADDED_APPONLY' =>'Verify the Insurance coverage through a Dealer conversation or email which includes Inventory Coverage Amount ${0}, Loss Payee listed as {1}, Policy Number & Expiration Date. A verbal conversation must be documented to indicate the information, date, and the person who provided it.',
         'CONDITION_ADDED_WITHIN_UWLIMIT' =>'Obtain a copy of the Insurance Certificate or a verbal confirmation directly from the Dealer\'s Agent verifying the Inventory Coverage Amount ${0}, Loss Payee listed {1}, Policy Number & Expiration Date and all Dealer Locations.',
         'CONDITION_ADDED_ABOVE_UWLIMIT' =>'Obtain a current Insurance Certificate which needs to include the Inventory Coverage Amount of ${0}, Loss Payee listed as {1}, Policy Number & Expiration Date and all Dealer Locations.'
     };
 
   @AuraEnabled
   public static string updateAssignedCAOnInitiatingAccount(String initiatingAcctId, String userId)
    {
        try
        {
            account a=[select id,assigned_credit_analyst__c from account where id=:initiatingAcctId];
            a.assigned_credit_analyst__c=userId;
            update a;
            return 'success';
        }
        catch(exception e)
        {
            utilityClass.logError(e,'Error occured while updating initiating account on underwriting screen',null, e.getMessage());
            return e.getMessage();
        }
        
    }
    
    @AuraEnabled(cacheable=true)
   public static Map<String, List<string>> fetchInitiatingAccountCA(String initiatingAcctId)
    {
        Map<String, List<String>> userInfo = new Map<string, List<String>>();
        try
        {
            account a=[select id,assigned_credit_analyst__c,assigned_credit_analyst__r.Name from account where id=:initiatingAcctId];
            system.debug('=== a ==='+a.assigned_credit_analyst__r.Name);
            if(a.assigned_credit_analyst__c!=null)
            {
                user u= [select id, name from user where id =:a.assigned_credit_analyst__c];
                if(u!=null)
                {
                    List<String> uInfo =new List<String>();
                    uInfo.add(u.Id);
                    uInfo.add(u.Name);
                    userInfo.put('success', uInfo);
                }
            
            }
            system.debug('=== userInfo =='+userInfo);
            return userInfo;
        }
        catch(exception e)
        {
            utilityClass.logError(e,'Error occured while updating initiating account on underwriting screen',null, e.getMessage());
            userInfo.put('exception', new List<String>{e.getMessage()});
            return userInfo;
        }
    }
    
   
@AuraEnabled
public static string evaluateInsuranceOptions(Id underwritingId)
{
    try
    {
    underwriting__c uw=[select id, Recommended_Credit_Line_Amount__c,initiating_account__r.TCF_Legal_Entity__c,connected_Request__c, review_type__c ,Country__c, Account__r.Selected_Language__c,RIA__c,Account__c, Initiating_Account__c,Initiating_Account__r.name, Connected_Request__r.Inside_Sales_Rep__r.id, Initiating_Account__r.Legal_Entity_Name__c,ownerId from underwriting__c where Id =:underwritingId];
    
    if(uw.Recommended_Credit_Line_Amount__c!=null)
    {
        Integer minimumInsuranceAmountRequired= Integer.valueOf(uw.Recommended_Credit_Line_Amount__c*.75);
        String initiatingAccountLE = uw.initiating_account__r.TCF_Legal_Entity__c;
        
        String leType='TCFIF';
        
        if (uw.Country__c == 'United States') 
        {
          if(uw.RIA__c) 
          {
            leType ='RIA';
          }
        }
        else if (uw.Country__c == 'Canada') 
        {
          if(uw.Account__r.Selected_Language__c == 'FRENCH CANADIAN') 
          {
            leType ='QUEBEC';
          }
          else 
          {
            leType ='TCFCFC';
          }
        }
        
        
        if(uw.review_type__c =='New')
        {
            if(uw.connected_Request__c!=null)
            {
                decimal recommendedCreditLine=  uw.Recommended_Credit_Line_Amount__c;
                
                new_dealer_application__c nda=[select id,name,  Inventory_Insurance_Coverage_Amount__c, Inventory_Insurance_Carrier__c from new_dealer_application__c where id=:uw.connected_Request__c];
                decimal actualInsuranceAmount= nda.Inventory_Insurance_Coverage_Amount__c;
                String InsuranceOption = evaluateInsuranceOptions(recommendedCreditLine, minimumInsuranceAmountRequired, actualInsuranceAmount, leType, initiatingAccountLE, uw );
                return InsuranceOption;
            }
        }
        else
        {
            decimal recommendedCreditLine=  uw.Recommended_Credit_Line_Amount__c;
            
            account a=[select id, Inventory_Coverage_Amount__c, Inventory_Coverage_Expiration_Date__c, Inventory_Insurance_Carrier__c from account where id =:uw.initiating_account__c];
            decimal actualInsuranceAmount= a.Inventory_Coverage_Amount__c;
            
            String InsuranceOption = evaluateInsuranceOptions(recommendedCreditLine, minimumInsuranceAmountRequired, actualInsuranceAmount, leType,initiatingAccountLE, uw);
            return InsuranceOption;
        }
      }
      else
      {
           return 'Please enter a recommended credit line on summary table';
      }
    }
    catch(exception e)
    {
         try
         {
            utilityClass.logError(e, 'exception in evaluateInsuranceOptions method underwriting screen', '', e.getMessage());
         }
          
         catch(exception ex)
         {
            
         }
        return e.getMessage();
    }
    return '';
}


private static string evaluateInsuranceOptions(decimal recommendedCreditLine,decimal minimumInsuranceAmountRequired, decimal actualInsuranceAmount, string leType,String initiatingAccountLE, underwriting__c uw)
{
   
    String conditionName= 'Insurance Verification according to TCFIF Policy';
    String initiatingAccLeName=uw.Initiating_Account__r.Legal_Entity_Name__c;
    List<Condition__c> cond=[select id,Condition_Description__c from Condition__c where Underwriting__c =:uw.Id and Condition_Status__c ='Open' and From_Lookup__c= :initiatingAccLeName and Condition_List_VF__c=:conditionName limit 1];
    
    if(recommendedCreditLine<=APPONLY_LIMIT)
    {

        if(actualInsuranceAmount >=minimumInsuranceAmountRequired)
        {
            return screenMessage.get('ENOUGH_INSURANCE_COVERAGE');
        }
        else
        {
            String screenMessage =screenMessage.get('CONDITION_ADDED_APPONLY');
            screenMessage = constructMessage(screenMessage, String.valueOf(minimumInsuranceAmountRequired), String.valueOf(initiatingAccountLE));
            
            String condMsg =conditionMessage.get('CONDITION_ADDED_APPONLY');
            condMsg = constructMessage(condMsg, String.valueOf(minimumInsuranceAmountRequired), String.valueOf(initiatingAccountLE));
            
            if(cond==null || (cond!=null && cond.size() ==0))
            {
                condition__c c = createCondition(conditionName, leType, uw);
                c.Condition_Description__c =condMsg;
                insert c;
            }
            else
            {
                if(cond[0].condition_Description__c==null || cond[0].condition_Description__c=='' || cond[0].condition_Description__c.toLowerCase() != condMsg.toLowerCase())
               {
                   cond[0].Condition_Description__c = condMsg;
                   update cond[0];
               }
            }
           return screenMessage;
          
        }
    }
    else if(recommendedCreditLine > APPONLY_LIMIT && recommendedCreditLine <=UWONLYLIMIT)
    {
        String screenMessage =screenMessage.get('CONDITION_ADDED_WITHIN_UWLIMIT');
        screenMessage = constructMessage(screenMessage, String.valueOf(minimumInsuranceAmountRequired), String.valueOf(initiatingAccountLE));
        
        String condMsg =conditionMessage.get('CONDITION_ADDED_WITHIN_UWLIMIT');
        condMsg = constructMessage(condMsg, String.valueOf(minimumInsuranceAmountRequired), String.valueOf(initiatingAccountLE));
        
        if(cond ==null || (cond!=null && cond.size() ==0))
        {
            condition__c c = createCondition(conditionName, leType, uw);
            c.Condition_Description__c =condMsg;
            insert c;
        }
        else
        {
           if(cond[0].condition_Description__c==null || cond[0].condition_Description__c=='' || cond[0].condition_Description__c.toLowerCase() != condMsg.toLOwerCase())
           {
               cond[0].Condition_Description__c = condMsg;
               update cond[0];
           }
        }
        return screenMessage;
    }
    else if(recommendedCreditLine > UWONLYLIMIT)
    {
        String screenMessage =screenMessage.get('CONDITION_ADDED_ABOVE_UWLIMIT');
        screenMessage = constructMessage(screenMessage, String.valueOf(minimumInsuranceAmountRequired), String.valueOf(initiatingAccountLE));
        
        String condMsg =conditionMessage.get('CONDITION_ADDED_ABOVE_UWLIMIT');
        condMsg = constructMessage(condMsg, String.valueOf(minimumInsuranceAmountRequired), String.valueOf(initiatingAccountLE));

        if(cond ==null || (cond!=null && cond.size() ==0))
        {
            condition__c c = createCondition(conditionName, leType, uw);
            c.Condition_Description__c = condMsg;
            insert c;
        }
         else
        {
           if(cond[0].condition_Description__c==null || cond[0].condition_Description__c=='' || cond[0].condition_Description__c.toLowerCase() != condMsg.toLOwerCase())
           {
               cond[0].Condition_Description__c = condMsg;
               update cond[0];
           }
        }
        return screenMessage;
    }
    return '';
}

private static Condition__c createCondition(string cname, string coa, underwriting__c loan)
 {
        String reviewType= loan.review_Type__c;
        
        Condition__c newCondition = new Condition__c(Condition_List_VF__c = cname, Conditions_of_Approval__c = coa, Condition_Type__c = 'Pre-Funding Condition (For Approval Letter)', 
            Account_Lookup__c = loan.Account__c, Underwriting__c = loan.Id, From__c = loan.Initiating_Account__r.name, 
            Condition_Status__c ='Open', From_Lookup__c= loan.Initiating_Account__r.Legal_Entity_Name__c);
        
        if(reviewType =='New')
        {
            newCondition.Assigned_To__c= loan.Connected_Request__r.Inside_Sales_Rep__r.id;
        }
        else
        {
            newCondition.Assigned_To__c= loan.ownerid;
        }
        Set<string> noFromLookup = new Set<string>{ 'Secretary\'s Certificate', 'Attestion du Secretaire (Secretary\'s Certificate)' };  //'Sole Proprietor Certificate',   
        if(noFromLookup.contains(cname))
        {
            newCondition.from_lookup__c = null;
        }
        return newCondition;
  }
private static string constructmessage(string message, String value1, String value2)
{
    message = message.replace('{0}', value1);
    message = message.replace('{1}',value2);
    return message;
}
  
  @AuraEnabled(cacheable=true)
  public static List<Id> activeUsersList()
  {
      List<id> activeUserIds = new List<Id>();
      
      for(user u:[select id from user where isActive=TRUE])
      {
          activeUserIds.add(u.id);
      }
      return activeUserIds;
  }
}