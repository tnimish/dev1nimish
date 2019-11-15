/* eslint-disable consistent-return */
/* eslint-disable no-loop-func */
/* eslint-disable no-console */
/* eslint-disable vars-on-top */
/* eslint-disable no-undef */
// eslint-disable-next-line no-unused-vars

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

let allScreensList;
let requestStageScreensList;
let underwritingStageScreensList;
let docCreationStageScreensList;
let accountSetupStageScreensList;

let isWelcomeScreen = false;
let isFirstNonWelcomeScreen = false;
let isLastScreen = false;
let isRequestStageScreen = false;
let isUnderwritingStageScreen = false;
let isDocCreationStageScreen = false;
let isAccountSetupStageScreen = false;
let isThisScreenLastOnStage;

let screenNamesEnum = 
{
  WELCOME: '',
  ///////////////////////////
  // REQUEST STAGE SCREENS //
  ///////////////////////////
  DUP_APPS: 'Duplicate Applications',
  NDA_VER: 'NDA Verification',
  DUP_CHECK: 'Duplicates Check',
  ENT_VER: 'Entity Verification',
  FRM_DOCS: 'Formation Documents',
  BUS_DATA_VER: 'Business Data Verification',
  CBR_VER: 'Credit Bureau Verification',
  ADDR_VER: 'Address Verification',
  ASSOC_VER: 'Associations Verification',
  OR_AND_EXCP: 'Overrides and Exceptions',
  OM: 'Origination Model',
  DLR_DSCN: 'Dealer Discussion',
  DOC_VAULT: 'Doc Vault',
  MOVE_TO_UW_STAGE: 'Proceed to Underwriting stage',
  ////////////////////////////////
  // UNDERWRITING STAGE SCREENS //
  ////////////////////////////////
  UNDERWRITING:'Underwriting',
  MOVE_TO_DOC_CREATION_STAGE: 'Proceed to Document Creation stage',
  /////////////////////////////////////
  // DOCUMENT CREATION STAGE SCREENS //
  /////////////////////////////////////
  DOC_QA: 'Doc QA',
  DOC_PREP: 'Doc Prep',
  DOC_ACCEP:'Doc Acceptance',
  SEC_SEARCH: 'Security Search & Filing',
  PMSI: 'PMSI',
  MOVE_TO_ACCT_SETUP_STAGE: 'Proceed to Account Setup stage',
  /////////////////////////////////
  // ACCOUNT SETUP STAGE SCREENS //
  /////////////////////////////////
  PRE_WMS_SETUP: 'Pre-WMS Setup Review',
  CLOSE_AUDIT:'Closing Audit',
  WMS_SETUP: 'Pre-WMS Setup Review',
  REG_CHECK:'Reg Checks'
};

let uwStageNamesEnum = 
{
  REQ: 'Request',
  UW: 'Underwriting',
  DOC_CREATION: 'Document Creation',
  ACCT_SETUP: 'Account Setup',
  COMPLETE: 'Complete'   
};

function getStepByStepTitle(stepTitle, steps)
{
  let step;

  if(steps)
  {
    for(let element of steps)
    {
      if(element.stepTitle === stepTitle)
      {
        step = element;
        break;
      }
    }

    return step; 
  }
}

function populateScrPropertiesAndLists(screenName, currStage, stgToScreenWrappersListMap)
{
  console.log('In common.populateScrPropertiesAndLists');
  
  allScreensList = [];
  requestStageScreensList = [];
  underwritingStageScreensList = [];
  docCreationStageScreensList = [];
  accountSetupStageScreensList = [];

  isRequestStageScreen = false;
  isUnderwritingStageScreen = false;
  isDocCreationStageScreen = false;
  isAccountSetupStageScreen = false;
  
  isThisScreenLastOnStage = false;

  for(var key in stgToScreenWrappersListMap)
  {
    //Determine the last screen in this stage
    let screensListSize = stgToScreenWrappersListMap[key].length;

    if(key === uwStageNamesEnum.REQ)
    {
      stgToScreenWrappersListMap[key].forEach(element => 
      {
        if(element.name == screenName)
        {
          isRequestStageScreen = true;
          element.isActive = true;
        }

        if(currStage === key && screenName === stgToScreenWrappersListMap[key][screensListSize-1].name)
        {
          isThisScreenLastOnStage = true;
        }

        //Show all screens as links in Request stage always
        element.displayScreenAsLink = true;
        
        requestStageScreensList.push(element);
        allScreensList.push(element);
      });
    }
    else if(key === uwStageNamesEnum.UW)
    {
      stgToScreenWrappersListMap[key].forEach(element => 
      {
        if(element.name == screenName)
        {
          isUnderwritingStageScreen = true;
          element.isActive = true;
        }

        if(currStage === key && screenName === stgToScreenWrappersListMap[key][screensListSize-1].name)
        {
          isThisScreenLastOnStage = true;
        }

        //Show screen names as links if the current stage is this stage or subsequent stage
        if(currStage === uwStageNamesEnum.UW || currStage === uwStageNamesEnum.DOC_CREATION || currStage === uwStageNamesEnum.ACCT_SETUP)
        {
          element.displayScreenAsLink = true; 
        }

        underwritingStageScreensList.push(element);
        allScreensList.push(element);
      });
    }
    else if(key === uwStageNamesEnum.DOC_CREATION)
    {
      stgToScreenWrappersListMap[key].forEach(element => 
      {
        if(element.name == screenName)
        {
          isDocCreationStageScreen = true;
          element.isActive = true;
        }

        if(currStage === key && screenName === stgToScreenWrappersListMap[key][screensListSize-1].name)
        {
          isThisScreenLastOnStage = true;
        }
        
        //Show screen names as links if the current stage is this stage or subsequent stage
        if(currStage === uwStageNamesEnum.DOC_CREATION || currStage === uwStageNamesEnum.ACCT_SETUP)
        {
          element.displayScreenAsLink = true; 
        }

        docCreationStageScreensList.push(element);
        allScreensList.push(element);
      });
    }
    else if(key === uwStageNamesEnum.ACCT_SETUP)
    {
      stgToScreenWrappersListMap[key].forEach(element => 
      {
        if(element.name == screenName)
        {
          isAccountSetupStageScreen = true;
          element.isActive = true;
        }

        //Show screen names as links if the current stage is this stage
        if(currStage === uwStageNamesEnum.ACCT_SETUP)
        {
          element.displayScreenAsLink = true; 
        }

        accountSetupStageScreensList.push(element);
        allScreensList.push(element);
      });
    }
  }

  if(screenName !== 'Welcome')
  {
    isWelcomeScreen = false;
  }
  else
  {
    isWelcomeScreen = true;
  }  
}



function getStepsCompletedFlag(screenName)
{
    let showStepsCompletedText = false;
    
    if(
         screenName === screenNamesEnum.DUP_APPS 
      || screenName === screenNamesEnum.NDA_VER
      || screenName === screenNamesEnum.DUP_CHECK
      || screenName === screenNamesEnum.CBR_VER
      || screenName === screenNamesEnum.ADDR_VER
      || screenName === screenNamesEnum.ASSOC_VER
      || screenName === screenNamesEnum.OR_AND_EXCP
      || screenName === screenNamesEnum.OM
      || screenName === screenNamesEnum.DLR_DSCN
      || screenName === screenNamesEnum.DOC_VAULT
      || screenName === screenNamesEnum.UNDERWRITING 
      || screenName === screenNamesEnum.DOC_QA 
      || screenName === screenNamesEnum.DOC_PREP 
      || screenName === screenNamesEnum.DOC_ACCEP 
      || screenName === screenNamesEnum.SEC_SEARCH 
      || screenName === screenNamesEnum.PMSI
      || screenName === screenNamesEnum.REG_CHECK
      || screenName === screenNamesEnum.CLOSE_AUDIT 
      || screenName === screenNamesEnum.WMS_SETUP
      
      )
      {
        showStepsCompletedText = true;
      }

      return showStepsCompletedText;
  }


//Displays a toast message
/*  "variant" values:
        info    —(Default) A gray box with an info icon.
        success —A green box with a checkmark icon.
        warning —A yellow box with a warning icon.
        error   —A red box with an error icon.

        "mode" values:
        dismissable —(Default) Remains visible until the user clicks the close button or 3 seconds has elapsed, whichever comes first.
        pester      —Remains visible for 3 seconds.
        sticky      —Remains visible until the user clicks the close button.


*/
function toastNotification(message,title,variant){
  dispatchEvent(
    new ShowToastEvent({
      title: title,
      message: message,
      variant: variant, 
    })
  );
}

//Displays a toast message that will remain until user clicks closed
function toastSticky(message,title,variant){
  dispatchEvent(
    new ShowToastEvent({
      title: title,
      message: message,
      variant: variant, 
      mode: "sticky"
    })
  );
}

//Creates an option values list from a string array (to be used for displaying values in a combobox)
function createOptionsListFromStringList(strArray)
{ 
  let optionsList = [];

  strArray.forEach(element =>
  {
    optionsList = [...optionsList, {label: element+'', value: element+''}];
  });

  return optionsList;
}

//Check to see if all the screens for a stage have been completed
function areAllScreensForStageCompleted(stageName)
{
  let allScreensForStageCompleted = true;

  if(stageName === uwStageNamesEnum.REQ)
  {
    requestStageScreensList.forEach(element =>
    {
      if(element.name !== screenNamesEnum.MOVE_TO_UW_STAGE && (element.isCompleted === false || allScreensForStageCompleted === false))
      {
        allScreensForStageCompleted = false;
      }
    });
  }
  else if(stageName === uwStageNamesEnum.UW)
  {
    underwritingStageScreensList.forEach(element =>
    {
      if(element.name !== screenNamesEnum.MOVE_TO_DOC_CREATION_STAGE && (element.isCompleted === false || allScreensForStageCompleted === false))
      {
        allScreensForStageCompleted = false;
      }
    });
  }
  else if(stageName === uwStageNamesEnum.DOC_CREATION)
  {
    docCreationStageScreensList.forEach(element =>
    {
      if(element.name !== screenNamesEnum.MOVE_TO_ACCT_SETUP_STAGE && (element.isCompleted === false || allScreensForStageCompleted === false))
      {
        allScreensForStageCompleted = false;
      }
    });
  }
  else if(stageName === uwStageNamesEnum.ACCT_SETUP)
  {
    accountSetupStageScreensList.forEach(element =>
    {
      if(element.isCompleted === false || allScreensForStageCompleted === false)
      {
        allScreensForStageCompleted = false;
      }
    });
  }

  return allScreensForStageCompleted;
}


function validateZipCode(elementValue, country)
{
  var zipCodePattern;
  if(country.toLowerCase() === 'united states')
  {
    zipCodePattern = /^\d{5}(-\d{4})?$/;
  }
  else if(country.toLowerCase() === 'canada')
  {
    zipCodePattern = /^[ABCEGHJKLMNPRSTVXY]{1}\d{1}[A-Z]{1} *\d{1}[A-Z]{1}\d{1}$/;
  }    
  return zipCodePattern.test(elementValue);
}


//Export the following functions from this module
export {populateScrPropertiesAndLists, areAllScreensForStageCompleted, getStepsCompletedFlag, getStepByStepTitle, toastNotification, toastSticky, createOptionsListFromStringList,validateZipCode};
//Export the following variables from this module
export {isWelcomeScreen, isFirstNonWelcomeScreen, isLastScreen, isRequestStageScreen, isUnderwritingStageScreen, isDocCreationStageScreen, isAccountSetupStageScreen,isThisScreenLastOnStage};
export {requestStageScreensList, underwritingStageScreensList, docCreationStageScreensList, accountSetupStageScreensList, allScreensList, screenNamesEnum, uwStageNamesEnum};