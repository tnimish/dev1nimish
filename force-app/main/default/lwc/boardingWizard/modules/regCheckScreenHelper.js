/* eslint-disable no-console */
import areAllRegCheckCasesClosed from '@salesforce/apex/BWDocumentCreationStageHelper.areAllRegCheckCasesClosed';
import regulatoryCheckCasesExist from '@salesforce/apex/BWDocumentCreationStageHelper.regulatoryCheckCasesExist';
import isDocumentCreationStageComplete from '@salesforce/apex/BWDocumentCreationStageHelper.isDocumentCreationStageComplete';

function fetchRegulatoryCheckCases(uwId)
{
  
  return new Promise(
    (resolve, reject) =>{  
      regulatoryCheckCasesExist({underwritingId: uwId}) 
      .then(newresult => 
      {
        // eslint-disable-next-line no-console
        console.log('=== newresult ===='+newresult);

        resolve(newresult); 
      
      }).catch(e => 
        {
          reject('Error occured while fecthing other products :'+JSON.stringify(e));
        });
      });
}

function allRegCheckCaseClosed(uwId)
{
  // eslint-disable-next-line no-console
  console.log('=== uwId =='+uwId);

  return new Promise(
    (resolve, reject) =>{  
      areAllRegCheckCasesClosed({underwritingId: uwId}) 
      .then(newresult => 
      {
        // eslint-disable-next-line no-console
        console.log('=== newresult ===='+newresult);
        if(newresult)
        {
          resolve(newresult); 
        }
        
      }).catch(e => 
        {
          reject('Error occured while fecthing other products :'+JSON.stringify(e));
        });
      });
}

function moveUWToNextStage(uwId)
{
  console.log("In regCheckScreenHelper.moveUWToNextStage");
  return new Promise
  (
      (resolve) => 
      {  
        isDocumentCreationStageComplete({underwritingId: uwId}) 
        .then(newresult => 
        {
          if(newresult)
          {
            resolve(newresult);
          } 
        })
        .catch(e => 
        {
          //reject(+JSON.stringify(e));
          //resolve(e.message); 
        });
      });
}

export{allRegCheckCaseClosed, fetchRegulatoryCheckCases, moveUWToNextStage}