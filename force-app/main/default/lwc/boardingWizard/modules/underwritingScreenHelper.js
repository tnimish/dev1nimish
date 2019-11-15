import updateAssignedCAOnInitiatingAccount from '@salesforce/apex/BWUnderwritingStageHelper.updateAssignedCAOnInitiatingAccount';
import fetchInitiatingAccountCA from '@salesforce/apex/BWUnderwritingStageHelper.fetchInitiatingAccountCA';
import evaluateInsuranceOptions from '@salesforce/apex/BWUnderwritingStageHelper.evaluateInsuranceOptions';
import activeUsersList from '@salesforce/apex/BWUnderwritingStageHelper.activeUsersList';

// update selected credit analyst on initiating account.
function updateAssignedCreditAnalyst(accountid, userid)
{
    return new Promise(
        (resolve, reject) =>{  
            updateAssignedCAOnInitiatingAccount({initiatingAcctId: accountid, userId:userid }) 
          .then(newresult => 
          {
            // eslint-disable-next-line no-alert
            if(newresult)
            {
                resolve(newresult); 
            }
          }).catch(e => 
            {
              reject('Error occured while constructing the address wrapper :'+JSON.stringify(e));
            });
          });
}

function fetchActiveUsersList()
{
    return new Promise(
        (resolve, reject) =>{  
          activeUsersList() 
          .then(newresult => 
          {
            // eslint-disable-next-line no-alert
            if(newresult)
            {
                resolve(newresult); 
            }
          }).catch(e => 
            {
              reject('Error occured while fetching active users :'+JSON.stringify(e));
            });
          });
}
//fetch initiating account to load the assigned credit analyst.
function fetchInitAccount(accountid)
{
    return new Promise(
        (resolve, reject) =>{  
            fetchInitiatingAccountCA({initiatingAcctId: accountid }) 
          .then(newresult => 
          {
            // eslint-disable-next-line no-alert
            if(newresult)
            {
                resolve(newresult); 
            }
          }).catch(e => 
            {
              reject('Error occured while fetching initiating account in underwriting screen :'+JSON.stringify(e));
            });
          });
}
// update the step display text on step 4.  
function fetchInsuranceOptions(uwId)
{
    return new Promise(
        (resolve, reject) =>{  
            evaluateInsuranceOptions({underwritingId: uwId }) 
          .then(newresult => 
          {
            // eslint-disable-next-line no-alert
            if(newresult)
            {
                resolve(newresult); 
            }
          }).catch(e => 
            {
              reject('Error occured while fetching insurance options in underwriting screen :'+JSON.stringify(e));
            });
          });
}

export {updateAssignedCreditAnalyst, fetchInitAccount,fetchInsuranceOptions,fetchActiveUsersList};