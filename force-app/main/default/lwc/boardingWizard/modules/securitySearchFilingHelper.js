/* eslint-disable consistent-return */
/* eslint-disable import/namespace */
/* eslint-disable no-empty */
/* eslint-disable eqeqeq */
/* eslint-disable no-redeclare */
/* eslint-disable no-unused-vars */
/* eslint-disable guard-for-in */
/* eslint-disable no-undef */
/* eslint-disable vars-on-top */
/* eslint-disable no-alert */
/* eslint-disable no-console */
import saveSearchFilings from '@salesforce/apex/BWDocumentCreationStageHelper.saveSearchFilings';
import retrieveSearchRecord from '@salesforce/apex/BWDocumentCreationStageHelper.retrieveSearchRecord';
import retrieveFilingRecord from '@salesforce/apex/BWDocumentCreationStageHelper.retrieveFilingRecord';
import * as common from './common.js';



function searchButtonPressed(varname,filing,index,screenName,uwRecordId){
    return new Promise(
        (resolve) =>{
        if(varname === 'RunSearch'){
            saveSearchFilings({screenName:screenName, underwritingId:uwRecordId, data:filing})
            .then(secresult =>{
                filing = secresult;
                if(!filing[index].searchBillingCode){
                    common.toastNotification('Billing Code has not been selected.',null,'warning');
                }          
                else if(!filing[index].searchType){
                    common.toastNotification('Search Type has not been selected.',null,'warning');
                }
                else{
                    retrieveSearchRecord({underwritingId:uwRecordId,data:filing[index]})
                    .then(result =>{
                        window.open('/'+result);
                        filing[index].searchId = result;
                        filing[index].existingSearch = true;
                        filing[index].searchLabel = 'View Search';
                        saveSearchFilings({screenName:screenName, underwritingId:uwRecordId, data:filing})
                        .then(thirdresult =>{
                            resolve(thirdresult);                    
                        })     
                    });
                }
            })       
            
        }
        else{
            window.open('/'+varname);   
            resolve(filing);     
        }
        });    

}


function filingButtonPressed(varname,filing,index,screenName,uwRecordId,careNumberId){    
    
    return new Promise(
        (resolve) =>{
        if(varname === 'RunFiling'){
            saveSearchFilings({screenName:screenName, underwritingId:uwRecordId, data:filing})
            .then(secresult =>{
                filing = secresult;
                if(!filing[index].searchBillingCode){
                    common.toastNotification('Billing Code has not been selected.',null,'warning');
                }
                else if(!filing[index].filingType){
                    common.toastNotification('Filing Type has not been selected.',null,'warning');
                }         
                else if(filing[index].existingSearch === false){
                    common.toastNotification('Search has not been started.',null,'warning');
                }
                else{
                retrieveFilingRecord({underwritingId:uwRecordId,data:filing[index],careNumberId:careNumberId})
                .then(result =>{
                    window.open('/'+result);
                    filing[index].filingId = result;
                    filing[index].existingFiling = true;
                    filing[index].filingLabel = 'View Filing';
                    saveSearchFilings({screenName:screenName, underwritingId:uwRecordId, data:filing})
                    .then(thirdresult =>{
                        resolve(thirdresult);                 
                    }) 
                });
                }
            })
            
        }
        else{
            window.open('/'+varname);
            resolve(filing);
        }
    });
}

export{searchButtonPressed,filingButtonPressed};