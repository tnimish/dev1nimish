/* eslint-disable no-unused-vars */
/* eslint-disable vars-on-top */
/* eslint-disable no-console */
// eslint-disable-next-line no-unused-vars

import upsertStepResultWithDetail from '@salesforce/apex/BWRequestStageHelper.upsertStepResultWithDetail';

//suffix picklist
function getSuffixOptions(){
    var single = [ '', 'II', 'III', 'Jr', 'Sr' ];
    var aresult = [];
    for(var i=0; i<single.length; i++){
      aresult.push({label: single[i], value:single[i]});
    }

    return aresult;
}

function scrapeCBRTable(elements, bArray){

  //loop through lightning input elements to scrape the non-saved user inputs, assign to the js variable
  for (var i=0; i<elements.length; i++) {
      if(       elements[i].name === 'firstName'){
        bArray[elements[i].dataset.index].firstName = elements[i].value;
      } else if(elements[i].name === 'middleName'){
        bArray[elements[i].dataset.index].middleName = elements[i].value;
      } else if(elements[i].name === 'lastName'){
        bArray[elements[i].dataset.index].lastName = elements[i].value;
      } else if(elements[i].name === 'linesuffix'){
        bArray[elements[i].dataset.index].suffix = elements[i].value;
      } else if(elements[i].name === 'cbrssn'){
        bArray[elements[i].dataset.index].ssn = elements[i].value;
      } else if(elements[i].name === 'cbrdob'){
        bArray[elements[i].dataset.index].dob = elements[i].value;
      }
      //console.log(elements[i].dataset.index +' => '+elements[i].name +' => '+elements[i].value);
    }

}

function cbrOwnerChangeStepResult(event, underwritingId, value, stepArray){
  if(event.target.dataset.steptitle === 'Ownership Change'){
    var longDetail = '';
    var comp = event.target.dataset.stepcompleted;
    if(value === 'Yes'){
      longDetail = 'This underwriting involves an ownership change.';
      comp = false;
    } else if(value === 'No'){
      longDetail = 'No ownership change (or business information form) for this underwriting.';
      comp = true;
    } else {
      value = '(Select One)';
      longDetail = '';
      comp = false;
    }
    stepArray.forEach(element => {
      if(element.stepRecordId === event.target.dataset.stepid){
        element.stepCompleted = comp;
        element.element1Wrapper.elementSelectedPicklistValue = value;
        element.userAnswer = value;
        console.log(element.element1Wrapper.elementSelectedPicklistValue);
      }
    });
    upsertStepResultWithDetail({ underwritingId:underwritingId, screenStepId:event.target.dataset.stepid, isStepComplete:comp, answer:value, longDetail:longDetail })
  }
}


export { getSuffixOptions, scrapeCBRTable, cbrOwnerChangeStepResult }; //functions