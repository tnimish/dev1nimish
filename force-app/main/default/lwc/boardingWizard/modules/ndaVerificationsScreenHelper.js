import getNDADocVaultId from '@salesforce/apex/BWRequestStageHelper.getNDADocVaultId';
import checkIfOtherProductExist from '@salesforce/apex/BWRequestStageHelper.checkIfOtherProductExist';
import fetchStepResult from '@salesforce/apex/BoardingWizardVFC.fetchStepResult';

function fetchNDADocVaultId(recId, steps)
{
  // eslint-disable-next-line no-undef
  return new Promise(
      (resolve, reject) =>{  
        getNDADocVaultId({recId: recId}) 
        .then(newresult => 
        {
          // eslint-disable-next-line no-console
          console.log('=== docVaultId =='+newresult);
          if(newresult)
          { 
            resolve(newresult);
          }
          else
          {
             //If docVaultId is not found then hide View Original pdf button button.
            for(let i=0; i<steps.length; i++)
              {
                    if(steps[i].element1Wrapper.elementActionName === 'viewOriginalPDF')
                    {
                       steps[i].element1Wrapper.isURL =false;
                       steps[i].element1Wrapper.isButton =false;
                    }
              }
                resolve(newresult);
          }
          
        }).catch(e => 
          {
            reject('Failed. '+e.message);
          });
        });
}

function viewOriginalPDF(docVaultId)
{
    window.open('/lightning/r/ContentDocument/'+docVaultId+'/view/')

}

function viewProducts(ndaId)
{
  window.open('/lightning/r/'+ndaId+'/related/Products_LKUP__r/view');
}

function verifyWhetherOtherProductExist(ndaId, uwId)
{
  console.log('=== ndaId =='+ndaId);
  console.log('=== uwId =='+uwId);
  return new Promise(
    (resolve, reject) =>{  
      checkIfOtherProductExist({ndaId: ndaId, uwId:uwId }) 
      .then(newresult => 
      {
        console.log('=== newresult ===='+newresult);
        // eslint-disable-next-line no-alert
       // if(newresult)
        //{
            resolve(newresult); 
        //}
        
      }).catch(e => 
        {
          reject('Error occured while fecthing other products :'+JSON.stringify(e)+'=== e.message ==='+e.message);
        });
      });
}

function fetchStepAnswer(underwritingId,stepId, screenName)
{
  return new Promise(
    (resolve, reject) =>{  
      fetchStepResult({underwritingId: underwritingId, stepId:stepId, screenName:screenName}) 
      .then(newresult => 
      {
        console.log('=== newresult ===='+newresult);
        // eslint-disable-next-line no-alert
        if(newresult)
        {
            resolve(newresult); 
        }
      
      }).catch(e => 
        {
          resolve('');
        });
      });
}
export {fetchNDADocVaultId,viewOriginalPDF,viewProducts,verifyWhetherOtherProductExist,fetchStepAnswer}