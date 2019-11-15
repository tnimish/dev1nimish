/* eslint-disable no-unused-vars */
/* eslint-disable no-loop-func */
/* eslint-disable eqeqeq */
/* eslint-disable no-console */
// eslint-disable-next-line no-unused-vars
import retrieveCSCRecord from '@salesforce/apex/BWRequestStageHelper.retrieveCSCRecord';
import saveFormationDocChartRows from '@salesforce/apex/BWRequestStageHelper.saveFormationDocChartRows';


let formDocTable = [];
let sharepointBaseURL = 'https://tcfifsharepoint.sf.tcf.biz/sites/ip/PortalDashboards/CareOnly.aspx?q=';
let formationOptionPrevious;


function handleBillingCode(var1,var2,var3,var4,var5){
    return new Promise(
        (resolve,reject) =>{ 
            formationOptionPrevious = var2[var1].formationOption;
            var2[var1].formationOption = var3;
            retrieveCSCRecord({underwritingId:var4,borrowerId:var2[var1].relationshipId,borrowerName:var2[var1].relationshipName,billingCode:var2[var1].formationOption,billingChange:true})
                .then(result =>{
                    if(result !== undefined){
                        var2[var1].formationOption = formationOptionPrevious;
                        var2[var1].formationLinkShow = true;
                        console.log('Change1');        
                    }
                    else if(result === undefined && var2[var1].formationOption === 'On File'){
                        var2[var1].formationLinkShow = false;
                        console.log('Change2');
                    }
                    else if(result === undefined || formationOptionPrevious === 'None'){
                        var2[var1].formationLinkShow = true;
                        console.log('Change3');
                    }
                    console.log('before save');
                    saveFormationDocChartRows({screenName:var5, underwritingId:var4, data:var2})
                    .then(saveResult =>{
                        var2 = saveResult;
                        resolve(var2);
                    })
                    .catch(e => {
                        // eslint-disable-next-line no-alert
                        alert('Error:'+e+'\nmessage='+e.message);
                    })        
                
                })
                .catch(error =>{
                    console.log(error);
                });                
        }
    )        
}


function checkMasterBox(var1){
    let masterCheck = false;
    let count = 0;
    
    for(let i=0; i< var1.length; i++){
        if(var1[i].formationLinkCheck === true){
            count++;
        }
    }
    if(count == var1.length){
        masterCheck = true;
    }

    return masterCheck;
}

function checkLegalName(var1){
    let masterCheck = false;
    let count = 0;
    
    for(let i=0; i< var1.length; i++){
        if(var1[i].formationDocMatch === true){
            count++;
        }
        
    }
    if(count == var1.length){
        masterCheck = true;
    }

    return masterCheck;
}

function checkFormOption(var1){
    let masterCheck = false;
    let count = 0;
    
    for(let i=0; i< var1.length; i++){
        if(var1[i].uploadedDocVaultMatch === true){
            count++;
        }
        
    }
    if(count == var1.length){
        masterCheck = true;
    }

    return masterCheck;
}

export{formDocTable, handleBillingCode,checkMasterBox,checkLegalName,checkFormOption,sharepointBaseURL}