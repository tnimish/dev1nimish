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
import deDupeRecords from '@salesforce/apex/BWRequestStageHelper.deDupeRecords';
import * as common from './common.js';

var apps = [];

function dupeAppTableCheckboxPressed(elementAction1,elementAction2){// rename to match handler
    var objIndex = elementAction1.slice(elementAction1.length - 1, elementAction1.length);     

    for(var i=0; i< elementAction2.length; i++){
        //console.log("elementaction1: "+elementAction1);
        //console.log("elementAction2: "+elementAction2);
        //console.log("objIndex: "+objIndex);
        //console.log("i: "+i);
        if(objIndex == i){
        //console.log("elementaction1: "+elementAction1);
            if(elementAction1.includes("nda")){
                //console.log("primaryNDA setting for: "+i);
                if(elementAction2[i].primaryNDA === false){
                    elementAction2[i].primaryNDA = true;
                    elementAction2[i].coBorrower = false;
                }
                else if(elementAction2[i].primaryNDA === true){
                    elementAction2[i].primaryNDA = false;
                }
                //console.log("primaryNDA "+elementAction2[i].primaryNDA);
            }
            else if(elementAction1.includes("coBorrower")){
                //console.log("coBorrower setting from: "+elementAction2[i].coBorrower);
                if(elementAction2[i].coBorrower === false){
                    elementAction2[i].coBorrower = true;
                    elementAction2[i].primaryNDA = false;
                }
                else if(elementAction2[i].coBorrower === true){
                    elementAction2[i].coBorrower = false;
                }
                //console.log("coBorrower "+elementAction2[i].coBorrower);
            }
        }
        else if(objIndex != i){
            if(elementAction1.includes("nda")){
                //console.log("primaryNDA setting from: "+elementAction2[i].primaryNDA);
                elementAction2[i].primaryNDA = false;
                
                //console.log("primaryNDA "+elementAction2[i].primaryNDA);
            }          
        }                
    }

    apps = elementAction2;

}


function updateDupAppTableRecords(dupApps){
    var coBorrower = 0;
    var primaryNDA = 0;
    for(var i=0; i< dupApps.length; i++){
        if(dupApps[i].coBorrower === true){
            coBorrower++;
        }
        if(dupApps[i].primaryNDA === true){
            primaryNDA++;
        } 
    }
    return new Promise(
        (resolve,reject) =>{
            if(coBorrower != dupApps.length && primaryNDA == 1){
                
                    deDupeRecords({appRows:dupApps})
                    .then(result => {
                        resolve(result); 
                    })
                    .catch(e => {
                        common.toastNotification(null,"Save Failed","error");
                        reject('Failed. '+e.message);
                    });
                
            }
            else if(coBorrower == dupApps.length){
                common.toastNotification("All Records Cannot Be Selected As Co-Borrower.","Save Did Not Occur","warning");
                reject();
            }
            else if(coBorrower == 0 && primaryNDA == 0){
                common.toastNotification("No Records Selected.","Save Did Not Occur","warning");
                reject();
            }
            else if(primaryNDA == 0){
                common.toastNotification("No Primary Selected For NDA.","Save Did Not Occur","warning");
                reject();
            }
        }
    )

}




export {updateDupAppTableRecords,dupeAppTableCheckboxPressed,apps}