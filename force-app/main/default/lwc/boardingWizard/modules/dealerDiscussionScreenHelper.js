/* eslint-disable no-unused-vars */
/* eslint-disable vars-on-top */
/* eslint-disable no-console */
// eslint-disable-next-line no-unused-vars
import * as common from './common.js';

/* this function checks all the request stage screens and returns 2 string values:
   result[0] = {list of all critical screens that must be completed before viewing the page}
   result[1] = {list of all non-critical screens that should be completed before calling the dealer}
   if all pages are complete, the result string === 'PASS'
*/
function checkPreviousRequestStageScreens(requestStageScreensList){
    var result = [];
    result.push('');
    result.push('');

    for (var i=0; i<requestStageScreensList.length; i++) {
        
        if(!requestStageScreensList[i].isCompleted){
            //block user to view the page if these are incomplete: ENT_VER  ADDR_VER  CBR_VER   OM
            if(requestStageScreensList[i].name === common.screenNamesEnum.ENT_VER || requestStageScreensList[i].name === common.screenNamesEnum.OM ||
             requestStageScreensList[i].name === common.screenNamesEnum.CBR_VER || requestStageScreensList[i].name === common.screenNamesEnum.ADDR_VER){
                result[0] += requestStageScreensList[i].name+', ';
            }
            //if some other Request screen is incomplete, send warning toast
            else if(requestStageScreensList[i].name !== common.screenNamesEnum.DLR_DSCN && requestStageScreensList[i].name !== common.screenNamesEnum.DOC_VAULT &&
                requestStageScreensList[i].name !== common.screenNamesEnum.MOVE_TO_UW_STAGE){
                result[1] += requestStageScreensList[i].name+', ';
            }
        }

        //DLR_DSCN  DOC_VAULT
    }
    for (var p=0; p<2; p++){
        var lastComma = result[p].lastIndexOf(",");
        if(lastComma > 0){
            result[p] = result[p].substring(0, lastComma);
        } else {
            result[p] = 'PASS';
        }
    }
   
    return result;
}

export { checkPreviousRequestStageScreens }; //functions