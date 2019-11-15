/* eslint-disable no-unused-vars */
/* eslint-disable vars-on-top */
/* eslint-disable no-console */
// eslint-disable-next-line no-unused-vars

//businessDataVerificationScreenHelper
var borrowerDbaList = [];
var elementList = [];


function toggleTableCheckbox(event, bArray){
    //borrowerDbaList=bArray;
    var i = event.target.dataset.index;
    var n = event.target.dataset.varname;
    if(n === 'borrowerDbaList'){
        bArray[i].verified = !bArray[i].verified;
    console.log('index '+i+'='+bArray[i].verified);
    }
}



function applyBVStyles(elements, bArray){
    console.log('applyBVStylesBeta HELPER');
    borrowerDbaList = bArray;
    console.log(borrowerDbaList);

    //loop through lightning input elements to scrape the non-saved user inputs, assign to the js variable
    for (var i=0; i<elements.length; i++) {
        var st = '';
        var br = 'border: 2px dashed red;';
        if(       elements[i].name === 'relTIN'){
          st = 'width:110px;text-align:center;';
          console.log(borrowerDbaList[elements[i].dataset.index].relTINWarn);
          if(borrowerDbaList[elements[i].dataset.index].relTINWarn !== ''){
            st = st+br;
          }
          elements[i].setAttribute('style', st)
        } else if(elements[i].name === 'relYearStart'){
          st = 'width:90px;text-align:center;';
          if(borrowerDbaList[elements[i].dataset.index].relYearStartWarn !== ''){
            st = st+br;
          }
          elements[i].setAttribute('style', st)
        } else if(elements[i].name === 'relYearOwn'){
          st = 'width:60px;text-align:center;';
          if(borrowerDbaList[elements[i].dataset.index].relYearOwnWarn !== ''){
            st = st+br;
          }
          elements[i].setAttribute('style', st)
        }
      }
      elementList = elements;
}


function scrapeBusinessVerificationTable(elements, bArray){

    //loop through lightning input elements to scrape the non-saved user inputs, assign to the js variable
    for (var i=0; i<elements.length; i++) {
        //console.log(elements[i].dataset.index +' => '+elements[i].name +' => '+elements[i].value);
        if(       elements[i].name === 'newDbaNames'){
            bArray[elements[i].dataset.index].newDbaNames = elements[i].value;
        } else if(elements[i].name === 'relTIN'){
            bArray[elements[i].dataset.index].relTIN = elements[i].value;
          //elements[i].setAttribute('style', 'border: 2px dashed red;');
        } else if(elements[i].name === 'relYearStart'){
            bArray[elements[i].dataset.index].relYearStart = elements[i].value;
        } else if(elements[i].name === 'relYearOwn'){
            bArray[elements[i].dataset.index].relYearOwn = elements[i].value;
        } else if(elements[i].name === 'verified'){
            bArray[elements[i].dataset.index].verified = elements[i].checked;
        }
      }

}

export { borrowerDbaList, elementList }; //variables
export { applyBVStyles, toggleTableCheckbox, scrapeBusinessVerificationTable }; //functions