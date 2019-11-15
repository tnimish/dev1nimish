///////////////////////
// ESLINT DIRECTIVES //
///////////////////////

/* eslint-disable dot-notation */
/* eslint-disable no-redeclare */
/* eslint-disable no-unused-vars */
/* eslint-disable guard-for-in */
/* eslint-disable no-undef */
/* eslint-disable vars-on-top */
/* eslint-disable no-alert */
/* eslint-disable no-console */
/* eslint-disable no-useless-constructor */
/* eslint-disable no-mixed-spaces-and-tabs */
/* eslint-disable no-useless-return */
/* eslint-disable no-else-return */

////////////////////////////////
// JAVASCRIPT MODULES IMPORTS //
////////////////////////////////
import * as common from './modules/common.js';
import * as ndaVerif from './modules/ndaVerificationsScreenHelper.js';
import * as businessDataVerificationScreenHelper from './modules/businessDataVerificationScreenHelper.js';
import * as dupeAppHelper from './modules/dupAppsScreenHelper.js';
import * as entityVerif from './modules/entityVerificationScreenHelper.js';
import * as cbrHelper from './modules/cbrVerificationScreenHelper.js';
import * as formDoc from './modules/formationDocsScreenHelper';
import * as orandexcp from './modules/overridesAndExceptionsReviewScreenHelper.js';
import * as addressVerif from './modules/addressVerificationScreenHelper.js';
import * as uwVerif from './modules/underwritingScreenHelper.js';
import * as regCheck from './modules/regCheckScreenHelper';
import * as dealerCallHelper from './modules/dealerDiscussionScreenHelper.js';
import * as preWMS from './modules/preWMSSetupScreenHelper.js';
import * as ssHelper from './modules/securitySearchFilingHelper.js';

/////////////////////////
// APEX METHOD IMPORTS //
/////////////////////////
import getGlobalData from '@salesforce/apex/BoardingWizardVFC.getGlobalData';
import getGlobalDataImperative from '@salesforce/apex/BoardingWizardVFC.getGlobalDataImperative';
import getScreenSteps from '@salesforce/apex/BoardingWizardVFC.getScreenSteps';
import getScreens from '@salesforce/apex/BoardingWizardVFC.getScreens';
import getScreensImperative from '@salesforce/apex/BoardingWizardVFC.getScreensImperative';
import invokeApexAction from '@salesforce/apex/BoardingWizardVFC.invokeApexAction';
import upsertStepAnswer from '@salesforce/apex/BoardingWizardVFC.upsertStepAnswer';
import getScreenStepResultsMap from '@salesforce/apex/BoardingWizardVFC.getScreenStepResultsMap';
import getborrowerDbaRows from '@salesforce/apex/BWRequestStageHelper.getborrowerDbaRows';
import saveBusinessVerificationTable from '@salesforce/apex/BWRequestStageHelper.saveBusinessVerificationTable';
import getDupeApps from '@salesforce/apex/BoardingWizardVFC.getDupeApps';
import getUWStages from '@salesforce/apex/BoardingWizardVFC.getUWStages';
import getUWStageStatuses from '@salesforce/apex/BoardingWizardVFC.getUWStageStatuses';
import updateUWStageAndStatus from '@salesforce/apex/BoardingWizardVFC.updateUWStageAndStatus';
import upsertStepAnswers from '@salesforce/apex/BoardingWizardVFC.upsertStepAnswers';
import getCbrRows from '@salesforce/apex/BWRequestStageHelper.getCbrRows';
import saveCbrTable from '@salesforce/apex/BWRequestStageHelper.saveCbrTable';
import clickRunCBRButton from '@salesforce/apex/BWRequestStageHelper.clickRunCBRButton';
import getFormationScreenRecords from '@salesforce/apex/BWRequestStageHelper.getFormationScreenRecords';
import retrieveCSCRecord from '@salesforce/apex/BWRequestStageHelper.retrieveCSCRecord';
import getBillingCodes from '@salesforce/apex/BWRequestStageHelper.getBillingCodes';
import saveFormationDocChartRows from '@salesforce/apex/BWRequestStageHelper.saveFormationDocChartRows';
import getCareNumber from '@salesforce/apex/BWRequestStageHelper.getCareNumber';
import validityCSCCheck from '@salesforce/apex/BWRequestStageHelper.validityCSCCheck';
import saveNextFollowUpdateDate from '@salesforce/apex/BWRequestStageHelper.saveNextFollowUpdateDate';
import getInsuranceData from '@salesforce/apex/BWDocumentCreationStageHelper.getInsuranceData'; 
import setInsuranceData from '@salesforce/apex/BWDocumentCreationStageHelper.setInsuranceData';
import getPMData from '@salesforce/apex/BWRequestStageHelper.getPMData';
import getURRecord from '@salesforce/apex/BoardingWizardVFC.getURRecord';
import runRoute2CreditMatrixOnly from '@salesforce/apex/BWRequestStageHelper.runRoute2CreditMatrixOnly';
import getSearchFilings from '@salesforce/apex/BWDocumentCreationStageHelper.getSearchFilings';
import isDocumentCreationStageComplete from '@salesforce/apex/BWDocumentCreationStageHelper.isDocumentCreationStageComplete';

// Address verification Table - fetch address object country and state fields
import ADDRESS_OBJECT from '@salesforce/schema/Address__c';
import COUNTRY_FIELD from '@salesforce/schema/Address__c.Country__c';
import STATE_FIELD from '@salesforce/schema/Address__c.State__c'; 
import { getObjectInfo,getPicklistValues  } from 'lightning/uiObjectInfoApi';
//-end

//////////////////////////////
// STATIC RESOURCES IMPORTS //
//////////////////////////////
import BW_ICON_SMALL_IMAGE from '@salesforce/resourceUrl/bw_icon_small';
import BW_ICON_SMALL_FLASHING_IMAGE from '@salesforce/resourceUrl/bw_icon_small_flashing';
import BW_GREENCHECKMARK_IMAGE from '@salesforce/resourceUrl/bw_greencheckmark';
import BW_REDCROSSMARK_IMAGE from '@salesforce/resourceUrl/bw_redcrossmark';
import BW_GRAYCB_IMAGE from '@salesforce/resourceUrl/bw_graycheckbox';
import BW_GRAYCBCHECKEDGREEN_IMAGE from '@salesforce/resourceUrl/bw_graycheckbox_checkedgreen';
import BW_GREENCHECKMARKNOCB_IMAGE from '@salesforce/resourceUrl/bw_greencheckmark_nocheckbox';


import { LightningElement, track, wire, api} from 'lwc';

export default class BoardingWizard extends LightningElement 
{
  //Id for record in context
  @api recordId;

  @api isLoaded;
  
  /////////////////////////////////////////
  // BW Global properties (span screens) //
  /////////////////////////////////////////
  @track uwRecordName; @track startingRecordName; @track startingRecordURL; @track initiatingAccountRecordName; @track initiatingAccountRecordURL; @track initiatingAccountRecordId;
  @track selectCareNumberURL; @track currentOwnerName; @track activeSectionMessage = '';
  @track allScreensList=[];  @track requestStageScreensList=[]; @track underwritingStageScreensList=[];  @track docCreationStageScreensList=[];  @track accountSetupStageScreensList=[];  
  @track uwRecordId; @track uwName; @track uwRecordTypeDevName; @track isUWLocked; @track uwRecordURL; @track uwCareNumber; @track consolidatedUWRecId; @track isConsolidatedUW; @track uwCurrentStage; @track uwCurrentStatus; @track ndaRecordId; @track ndaName; @track ndaRecordURL; @track caseRecordId; @track caseNumber; @track caseRecordURL;
  @track showStepsCompletedText; @track careAccountId; @track uwCreatedDateTimeString; @track uwReviewType; @track showPreviousScreenButton; @track showNextScreenButton; @track displayNDAScreens; @track lastUCCSearchId; @track uwRecommendedCreditLine;
  @track isCurrentScreenLastOnStage; @track displayMoveToNextStageTable; @track requestAlreadyInNextStageMessage;

  ////////////////////////////////
  // Screen specific properties //
  ////////////////////////////////
  @track screenName; @track isWelcomeScreen; @track isFirstNonWelcomeScreen; @track isLastScreen; @track isDocCreationStageScreen; @track isAccountSetupStageScreen; 
  @track activeStageSectionName; @track activeStageIsRequest; @track activeStageIsUnderwriting; @track activeStageIsDocumentCreation; @track activeStageIsAccountSetup;
  @track steps=[]; /*@track stepRecIdToStepRecordMap=[];*/ @track buttonSpinner=false;@track openSelectCareModal;
  @track displaySelectCareNumberButton;
  @track displayScreensList;
  
  //Underwriting Status Update Modal properties
  @track openModal = false; @track uwStages = []; @track selectedUWStage; @track selectedUWStageStatus;  @track uwStageStatuses = [];  @track modalButtonSpinner=false;  @track statusesPopulated=false;
  
  //Duplicate Apps screen properties
  @track dupAppScreen = false; @track dupeApps=[];@track dupeAppDisabled = false;
  
  //NDA Verification screen properties
  @track ndaDocVaultId;  @track ndaDocVaultURL;  @track ndaId; @track otherProductExist;

  //Business Data Verification screen properties
  @track borrowerDbaList = [];  @track isDataVerificationScreen;  @track pageMessage = '';  @track FALSE = false;

  //Entity Verification screen properties
  @track isEntityVerificationScreen; @track borrowerSOSList = []; @track entitySOSList = []; @track borrowerVerified; @track EntityVerified; @track isAllStepsCompleted;
  @track bflags={}; @track eflags={}; @track bflagsMap; @track eflagsMap;@track isBorrowerEVTDataExist;@track isEntityEVTDataExist;
  
  //CBR Verification screen properties
  @track isCBRScreen; @track cbrList = [];

  //Formation Document Screen properties
  @track isFormationDocScreen = false;
  @track formationDocTable = [];
  @track step1Verified = false;
  @track step2Verified = false;
  @track step3Verified = false;
  @track step1Shown = false;
  @track step2Shown = false;
  @track step3Shown = false;
  @track newScreen = true;
  @track defaultOption = "No";
  @track optionsYN = ["No","Yes"];
  @track billingCode = [];
  @track stopCopy = false;
  @track isChanged = false;
  //@track screenId;

  //Doc Vault Screen properties
  @track isDocVaultScreen = false;
  @track defaultNextFollowUpDate;
  @track routeToCreditBoolean = false;
  @track routeToCreditReason = '';

  //Overrides and Exceptions screen properties
  @track isOverridesScreen; @track hasPoorPerformanceAccts; @track hasILOCAccts; @track hasLimitedRestrictedMfrs;

  //address Verification properties
  @track accountsList=[];
  @track isAddressVerificationScreen;
  @track addressStandardizationObj;
  @track newAddress =[];
  @track selectedRecord;
  @track isNewAddress;
  @track addressHeader=[];
  @track borrowerHeader=[];
  @track country;
  @track state;
  @track accountInfo;
  @track buttonSpinnerNewAddress;
  @track buttonSpinnerSaveAddress;
  @track validAccountsLookup =[];

  // Doc Acceptance Screen properties
  @track isDocAcceptanceScreen = false;
  @track insuranceAmount;  @track previousInsuranceAmount;  @track insuranceDate;  @track previousInsuranceDate; @track bypassRevilio;

  //Dealer Discussion screen properties
  @track hideMainSteps; @track uwAuditPermission;

  //Move to UW stage screen properties
  @track isMoveToUWStageScreen;

  //Move to Doc Creation stage screen properties
  @track isMoveToDocCreationStageScreen;

  //Move to Account Setup stage screen properties
  @track isMoveToAcctSetupStageScreen;

  //UNDERWRITING screen properties
  @track selectedUserId;
  @track activeUsersList=[];
  @track areAllUWStageScreensCompleted;
  @track InUWScreen;

  // Reg Check properties
  @track areAllDocStageScreensCompleted;
  @track allRegCheckCasesList=[];
 
  // preWMS Setup screen properties 
  @track wmsChangeCasesExist;
  @track wmsChangeCases=[];  

  // Security Search & Filing Screen Properties
  @track isSecurityFilingScreen = false;
  @track filing = [];
  @track searchType = ['Summary','Copy'];
  @track filingType = ['Broad','Specific Lines','When Financed'];

  //////////////////////////////////
  // Images from Static Resources //
  //////////////////////////////////
  bwiconimage = BW_ICON_SMALL_IMAGE;
  bwiconflashingimage = BW_ICON_SMALL_FLASHING_IMAGE;
  bwgreencheckmarkimage = BW_GREENCHECKMARK_IMAGE;
  bwredcrossmarkimage = BW_REDCROSSMARK_IMAGE;
  bwgraycheckbox = BW_GRAYCB_IMAGE;
  bwgraycheckboxcheckedgreen = BW_GRAYCBCHECKEDGREEN_IMAGE;
  bwgreencheckmarknocbimage = BW_GREENCHECKMARKNOCB_IMAGE;

  constructor() 
  {    
    super();
    this.screenName = 'Welcome';
    this.isWelcomeScreen=true;
    this.isActiveStageRequest = false;
    this.activeStageIsUnderwriting=false;
    this.activeStageIsDocumentCreation=false;
    this.activeStageIsAccountSetup=false;
    this.isFirstNonWelcomeScreen = false;
    this.isLastScreen = false;
    this.isLoaded = true;
    this.buttonSpinner = false;
    this.isBorrowerEVTDataExist = false;
    this.isEntityEVTDataExist = false;
    this.isOverridesScreen = false;
    this.isCBRScreen = false;
    this.isAddressVerificationScreen=false;
    this.buttonSpinnerNewAddress=false;
    this.buttonSpinnerSaveAddress =false;
    this.isMoveToUWStageScreen = false;
    this.isMoveToDocCreationStageScreen = false;
    this.isMoveToAcctSetupStageScreen = false;
  }
  
  @wire(getGlobalData, {recordId: '$recordId'})
  getGblData({error,data})
  {        
    if(error)
    {
      this.isConsolidatedUW = false;
    }
    else if(data)
    { 
      let globalDataMap = JSON.parse(data);

      this.uwRecordName = globalDataMap['uwName']; 
      this.uwRecordURL = globalDataMap['uwURL'];
      this.uwRecordId  = globalDataMap['uwId'];
      this.consolidatedUWRecId = globalDataMap['consolidatedUWId'];
      this.uwRecordTypeDevName = globalDataMap['uwRecordTypeDevName'];
      this.uwRecordTypeName = globalDataMap['uwRecordTypeName'];
      
      this.isUWLocked = false;

      if(this.uwRecordTypeDevName && this.uwRecordTypeDevName.toLowerCase().includes('lock'))
        this.isUWLocked = true;

      
      // if no underwriting exist.
      if(!this.uwRecordId)
      {
        this.isConsolidatedUW = false;
        this.ndaRecordId = globalDataMap['ndaId'];
        this.ndaRecordURL = globalDataMap['ndaURL'];
        this.selectCareNumberURL =globalDataMap['selectCareNumberURL'];
        this.displaySelectCareNumberButton =true;
        return;
      }
      // if underwriting exist and consolidated
      if(this.consolidatedUWRecId)
      {
        this.isConsolidatedUW = true;
        this.consolidatedUWURL = globalDataMap['consolidatedUWURL'];
      }
      // if underwriting exist and not consolidated.
      else
      {
        
        this.isConsolidatedUW = false;
        
        this.ndaRecordId = globalDataMap['ndaId'];
        this.ndaRecordURL = globalDataMap['ndaURL'];
        this.uwCurrentStage = globalDataMap['uwCurrentStage'];
        this.activeStageSectionName = this.uwCurrentStage;
        if(this.uwCurrentStage === 'Request'){
          this.activeStageIsRequest = true;
        }
        else if(this.uwCurrentStage === 'Underwriting'){
          this.activeStageIsUnderwriting = true;
        }
        else if(this.uwCurrentStage === 'Document Creation'){
          this.activeStageIsDocumentCreation = true;
        }
        else if(this.uwCurrentStage === 'Account Setup'){
          this.activeStageIsAccountSetup = true;
        }
        this.uwCurrentStatus = globalDataMap['uwCurrentStatus'];
        this.uwCareNumber = globalDataMap['uwCareNumber'];
        this.careNumber = globalDataMap['careNumber'];
        this.ndaName     = globalDataMap['ndaName'];
        this.caseRecordId = globalDataMap['caseId'];
        this.caseName     = globalDataMap['caseNumber'];
        this.caseRecordURL = globalDataMap['caseURL'];
        this.startingRecordName = globalDataMap['startingRecordName'];
        this.startingRecordURL = globalDataMap['startingRecordURL'];
        this.initiatingAccountRecordId = globalDataMap['initiating_account__c'];
        this.initiatingAccountRecordName = globalDataMap['initiating_account__r.name'];
        this.initiatingAccountRecordURL = globalDataMap['initAcctURL'];
        this.selectCareNumberURL = globalDataMap['selectCareNumberURL'];
        this.currentOwnerName = globalDataMap['ownerName'];
        this.baseURL = globalDataMap['baseURL'];
        this.defaultNextFollowUpDate = globalDataMap['nextFollowUpDate'];
        this.careAccountId =globalDataMap['careAccountId'];
        this.ndaId = this.ndaRecordId;
        this.uwCreatedDateTimeString = globalDataMap['uwCreatedDateTimeString'];
        this.uwReviewType = globalDataMap['uwReviewType'];
        this.uwAuditPermission = globalDataMap['uwAuditPermission'] === 'true'; //needs boolean format, not string
        this.lastUCCSearchId = globalDataMap['lastUCCSearchId'];
        this.uwRecommendedCreditLine = globalDataMap['uwRecommendedCreditLine'];
        this.uwCountry = globalDataMap['uwCountry'];

        if(this.ndaId)
          this.displayNDAScreens = true;
        else
          this.displayNDAScreens = false; 

        getScreensImperative( {uwCaseOrNDARecId: this.recordId}).then(newresult =>
        {
          this.populateScreenPropertiesAndLists(this.screenName, newresult);
        }).catch(e => 
        {
          console.log(e.message);
          this.displayScreensList = false;
        });
      }
     
    }
  }
  
 
  
  @wire(getObjectInfo, { objectApiName: ADDRESS_OBJECT })
  objectInfo;
  
  @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId',fieldApiName: COUNTRY_FIELD })
  countryInfo({ data, error }) 
  {
    if (data)
    {
      this.country = data.values;
    }
  }

  @wire(getPicklistValues, { recordTypeId:'$objectInfo.data.defaultRecordTypeId', fieldApiName: STATE_FIELD })
  stateInfo({ data, error }) 
  {
    if (data) 
    {
      this.state = data;
    }
  }
  

  refreshScreenData()
  {
    getGlobalDataImperative({recordId: this.recordId})
    .then(refreshScreen => 
    {
      let globalDataMap = JSON.parse(refreshScreen);
      
        this.uwRecordName = globalDataMap['uwName']; 
        this.uwRecordURL = globalDataMap['uwURL'];
        this.uwRecordId  = globalDataMap['uwId'];
        this.consolidatedUWRecId = globalDataMap['consolidatedUWId'];

        if(this.consolidatedUWRecId)
        {
          this.isConsolidatedUW = true;
          this.consolidatedUWURL = globalDataMap['consolidatedUWURL'];
        }
        else
        {
          this.isConsolidatedUW = false;
        
          this.ndaRecordId = globalDataMap['ndaId'];
          this.ndaRecordURL = globalDataMap['ndaURL'];
          this.uwCurrentStage = globalDataMap['uwCurrentStage'];
          this.uwCurrentStatus = globalDataMap['uwCurrentStatus'];
          this.uwCareNumber = globalDataMap['uwCareNumber'];
          this.careNumber = globalDataMap['careNumber'];
          this.ndaName     = globalDataMap['ndaName'];
          this.caseRecordId = globalDataMap['caseId'];
          this.caseName     = globalDataMap['caseNumber'];
          this.caseRecordURL = globalDataMap['caseURL'];
          this.startingRecordName = globalDataMap['startingRecordName'];
          this.startingRecordURL = globalDataMap['startingRecordURL'];
          this.initiatingAccountRecordId = globalDataMap['initiating_account__c'];
          this.initiatingAccountRecordName = globalDataMap['initiating_account__r.name'];
          this.initiatingAccountRecordURL = globalDataMap['initAcctURL'];
          this.selectCareNumberURL = globalDataMap['selectCareNumberURL'];
          this.currentOwnerName = globalDataMap['ownerName'];
          this.baseURL = globalDataMap['baseURL'];
          this.defaultNextFollowUpDate = globalDataMap['nextFollowUpDate'];
          this.careAccountId =globalDataMap['careAccountId'];
          this.ndaId = this.ndaRecordId;
          this.uwCreatedDateTimeString = globalDataMap['uwCreatedDateTimeString'];
          this.uwReviewType = globalDataMap['uwReviewType'];
          this.uwAuditPermission = globalDataMap['uwAuditPermission'] === 'true'; //needs boolean format, not string
          this.lastUCCSearchId = globalDataMap['lastUCCSearchId'];
          this.uwRecommendedCreditLine = globalDataMap['uwRecommendedCreditLine'];

          if(this.ndaId)
            this.displayNDAScreens = true;
          else
            this.displayNDAScreens = false; 

          //Call openscreenBase method to refresh the screen components
          this.openScreenBase(this.screenName);  
      }
    
    })
    .catch(e => 
    {
      common.toastNotification('', 'Something went wrong with the refresh.  Please contact Engine Support Team.', 'error');
      
    });
  }


  //Opens UW Status Update modal
  openUWModal()
  {
    //this.buttonSpinner=true;

    getUWStages()
      .then(stagesResult => 
      {
        
        this.uwStages = common.createOptionsListFromStringList(stagesResult);
        this.selectedUWStage=this.uwCurrentStage;

        

        getUWStageStatuses({uwStage: this.selectedUWStage})
        .then(statusesResult => 
        {
          
          this.uwStageStatuses = common.createOptionsListFromStringList(statusesResult);
          this.selectedUWStageStatus = this.uwCurrentStatus;
          this.statusesPopulated=true;
          this.openModal = true
          
        })
        .catch(e => 
        {
          
          
        });
      })
      .catch(e => 
      {
        
        
      });
  }
  
  //Closes UW Status Update modal
  closeModal()
  {
    this.openModal = false
  } 
  
  updateUWStatusFromModal(event)
  {
    this.selectedUWStage = event.target.dataset.stage;
    
    this.updateUWStageAndStatus(this.selectedUWStage, this.selectedUWStageStatus);
  }

  //Updates UW stage and status to selected values
  updateUWStageAndStatus(stage, status)
  {
    this.modalButtonSpinner=true;
    
    updateUWStageAndStatus({uwRecId: this.uwRecordId, uwStage: stage, uwStatus: status})
    .then(result => 
    {
      //added to set the current uw stage and status.
      getURRecord({recId: this.uwRecordId})
      .then(uw=>{
        
        this.uwCurrentStage = uw.Stage__c;
        this.uwCurrentStatus = uw.Status__c;
        })

      //added for to display validation error message string
      if(result.outCome === true){
        common.toastNotification(result.resultString, '', 'success');
      } else {
        common.toastNotification(result.errorString, 'Error', 'error');
      }

      this.closeModal();
      this.modalButtonSpinner=false;
    })
    .catch(e => 
    {
      
      common.toastNotification(JSON.stringify(e), 'Error', 'error');
      this.modalButtonSpinner=false;
    });
  }

  //Refreshes UW status lis based on user selected UW stage
  refreshUWStageStatuses(event)
  {
    this.selectedUWStage = event.target.value;
    

    this.statusesPopulated=false;

    getUWStageStatuses({uwStage: this.selectedUWStage})
      .then(result => 
      {
        this.uwStateStatuses =  common.createOptionsListFromStringList(result);
        
        this.statusesPopulated=true;
        this.selectedUWStageStatus = '';
      })
      .catch(e => 
      {
        
      });
  }

  //Captures selected UW status value
  captureSelectedUWStageStatus(event)
  {
    this.selectedUWStage=this.uwCurrentStage;
    this.selectedUWStageStatus = event.target.value;
    this.uwCurrentStatus = this.selectedUWStageStatus;
  }

  
    
  moveUWToNextStage(event)
  {
    let returnMessage;
    let dataId = event.target.dataset.id;

    this.buttonSpinner = true;

    if(this.screenName === common.screenNamesEnum.REG_CHECK)
    {
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
  else
  {
    //common.moveUWToNextStage(this.screenName, this.uwRecordId).then(stageRes =>
    //{
      //returnMessage = stageRes;
    
      if(returnMessage)
      {
        common.toastSticky('.',returnMessage,'');
        return;
      }
      else if(this.screenName === common.screenNamesEnum.MOVE_TO_UW_STAGE || this.screenName === common.screenNamesEnum.MOVE_TO_DOC_CREATION_STAGE || this.screenName === common.screenNamesEnum.MOVE_TO_ACCT_SETUP_STAGE)
      {
        let completed;
      
        if(this.screenName === common.screenNamesEnum.MOVE_TO_UW_STAGE)
          completed = common.areAllScreensForStageCompleted(common.uwStageNamesEnum.REQ);
        else if(this.screenName === common.screenNamesEnum.MOVE_TO_DOC_CREATION_STAGE)
        {
          completed = common.areAllScreensForStageCompleted(common.uwStageNamesEnum.UW);
        }
        else if(this.screenName === common.screenNamesEnum.MOVE_TO_ACCT_SETUP_STAGE)
          completed = common.areAllScreensForStageCompleted(common.uwStageNamesEnum.DOC_CREATION);

        if(dataId === 'docVaultYes')
        {
          if(completed)
          {          
            if(this.screenName === common.screenNamesEnum.MOVE_TO_UW_STAGE)
              this.updateUWStageAndStatus(common.uwStageNamesEnum.REQ, 'Complete');
            else if(this.screenName === common.screenNamesEnum.MOVE_TO_DOC_CREATION_STAGE)
              this.updateUWStageAndStatus(common.uwStageNamesEnum.UW, 'Complete');
            else if(this.screenName === common.screenNamesEnum.MOVE_TO_ACCT_SETUP_STAGE)
              this.updateUWStageAndStatus(common.uwStageNamesEnum.DOC_CREATION, 'Complete');  

            upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[0].stepRecordId,  usrAnswer:null, stepResultRecordId:this.steps[0].resultRecordId, stepCompletedFlag:true})
            .then(resu => 
            {
              getScreensImperative({uwCaseOrNDARecId: this.recordId})
              .then(newresu => 
              {
                this.getScreenStepsResults(this.screenName);

                if(this.screenName === common.screenNamesEnum.MOVE_TO_UW_STAGE)
                {
                  this.screenName = common.screenNamesEnum.UNDERWRITING;
                }
                else if(this.screenName === common.screenNamesEnum.MOVE_TO_DOC_CREATION_STAGE)
                {
                  this.screenName = common.screenNamesEnum.DOC_QA;
                }
                else if(this.screenName === common.screenNamesEnum.MOVE_TO_ACCT_SETUP_STAGE)
                {
                  this.screenName = common.screenNamesEnum.PRE_WMS_SETUP;
                }

                this.populateScreenPropertiesAndLists(this.screenName, newresu);

                this.openScreenBase(this.screenName);

                this.buttonSpinner = false;
              })
              .catch(e => 
              {
                
              });
            })
          }
          else
          {
            common.toastNotification("Cannot move the request to the next stage since at least one of the screens in the current stage have not been completed.",null,"info");
            this.buttonSpinner = false;
          }        
        } 
      }
      else
      {
        if(this.uwCurrentStage === common.uwStageNamesEnum.REQ)
        {
          this.updateUWStageAndStatus(common.uwStageNamesEnum.REQ, 'Complete');
        }
        else if(this.uwCurrentStage === common.uwStageNamesEnum.DOC_CREATION)
        {
          this.updateUWStageAndStatus(common.uwStageNamesEnum.DOC_CREATION, 'Complete');
        }
        else if(this.uwCurrentStage === common.uwStageNamesEnum.UW)
        {
          this.updateUWStageAndStatus(common.uwStageNamesEnum.UW, 'Complete');
        }
        else if(this.uwCurrentStage === common.uwStageNamesEnum.ACCT_SETUP)
        {
          this.updateUWStageAndStatus(common.uwStageNamesEnum.ACCT_SETUP, 'Complete');
        }

        this.determinePreviousOrNextScreen('Next');

        this.openScreenBase(this.screenName);
    }
    //});
  }
}

  //Invokes Apex method specified for the click element on the BW Step record
  invokeStepElementAction(event) 
  {
      var elementAction = event.target.dataset.id;
      let stepTitle = event.target.dataset.steptitle;
      let buttonNumber = event.target.dataset.elementnumber;
 
      let step = common.getStepByStepTitle(stepTitle, this.steps);
      let stepElement;
      
      
      if(buttonNumber ==="1")
      {
        stepElement =step.element1Wrapper;
      }
      else if(buttonNumber ==="2")
      {
        stepElement =step.element2Wrapper;
      }
      else if(buttonNumber ==="3")
      {
        stepElement =step.element3Wrapper;
      }
      else if(buttonNumber ==="4")
      {
        stepElement =step.element4Wrapper;
      }
      else if(buttonNumber ==="5")
      {
        stepElement =step.element5Wrapper;
      }
     
     
      ////////////////////////////
      // Shared Element Actions - these can be used across any screen
      ////////////////////////////
      if(elementAction === "getAssociationsComponents")
      {
        window.open('/apex/UnderwritingAssociations?id='+this.uwRecordId);
        stepElement.isButtonSpinner =false;
      } else if(elementAction === "openKYCPreviewEmail"){
        window.open('/apex/KYC_Preview?id='+this.careAccountId+'&Underwriting_Id='+this.uwRecordId+'&emailPreviewMode=true');
        stepElement.isButtonSpinner =false;
      } else if(elementAction === "openKYCPreview"){
        window.open('/apex/KYC_Preview?id='+this.careAccountId+'&Underwriting_Id='+this.uwRecordId+'&emailPreviewMode=false');
        stepElement.isButtonSpinner =false;
      } else if(elementAction === 'MassEditUCCSearchResults'){
        window.open('/apex/MassEditUCCSearchResults?id='+this.lastUCCSearchId); 
        stepElement.isButtonSpinner =false;
      }


      /////////////////////////////
      // NDA Verification Screen //
      /////////////////////////////
      else if(this.screenName === common.screenNamesEnum.NDA_VER)
      {
        stepElement.isButtonSpinner =true;
        if(elementAction ==='viewOriginalPDF')
        {
          ndaVerif.viewOriginalPDF(this.ndaDocVaultId);
          stepElement.isButtonSpinner =false;
          return;
        }
        if(elementAction === 'getProducts')
        {
          ndaVerif.viewProducts(this.ndaId);
          stepElement.isButtonSpinner =false;
          return;
        }
        if(elementAction ==='viewRelationshipsfromCare')
        {
          window.open('/lightning/r/'+this.careAccountId+'/related/Accounts__r/view');
          stepElement.isButtonSpinner =false;
          return;
        }
        
        let args = this.fetchMethodArgs(elementAction);

        invokeApexAction({action:elementAction, args:args})
        .then(result => 
        { 
          if(!result.errorString)
          {
            window.open('/apex/NewDealerAppPDFView?id='+this.ndaId);   
            if(this.isChanged === false){
              this.openScreenBase(common.screenNamesEnum.NDA_VER);
           }
           else{
             common.toastNotification("Unsaved Data, Please Save.",null,"warning")
           }   
          }
          stepElement.isButtonSpinner =false;
        })
        .catch(e => 
        {
          
          stepElement.isButtonSpinner =false;
        });
      }
      //////////////////////////////////
      // Duplicate Application Screen //
      //////////////////////////////////
      else if(this.screenName === common.screenNamesEnum.DUP_APPS)
      {
        this.buttonSpinner = true;
        if(elementAction === "saveDupeApp")
        {          
          dupeAppHelper.updateDupAppTableRecords(this.dupeApps)
            .then(result =>{
              
              if(result === this.uwRecordId){
                this.buttonSpinner = false;
                common.toastNotification(null,"Save Successful","success");
              }
              else{               
                window.open('/lightning/n/Boarding_Wizard?c__id='+result,'_self');                
              }
              
            })
            .catch(e =>{
              this.buttonSpinner = false;              
              common.toastNotification(null,"Save Failed","error");
            });
        }
      }
      ///////////////////////////////
      // Formation Document Screen //
      ///////////////////////////////
      else if(this.screenName === common.screenNamesEnum.FRM_DOCS)
      {
        var url = event.target.value;
        var index = event.target.dataset.index;
        if(elementAction === "formationLinkButton" && url !== "runCSC")
        {          
          window.open(url); 
        }
        else if(elementAction === "formationLinkButton" && url === "runCSC")
        {
          if(this.formationDocTable[index].formationOption !== "None"){
            retrieveCSCRecord({underwritingId:this.uwRecordId,borrowerId:this.formationDocTable[index].relationshipId,borrowerName:this.formationDocTable[index].relationshipName,billingCode:this.formationDocTable[index].formationOption,billingChange:false})
            .then(result =>{
              window.open(result);
            })
            .catch(error =>{
              common.toastNotification("No URL Returned",null,'warning');
            });
          }
          else{
            common.toastNotification("Billing Code Not Selected",null,'warning');
          }    
        }
        else if(elementAction === "Sharepoint"){
          getCareNumber({underwritingId:this.uwRecordId})
          .then(result =>{
            window.open(formDoc.sharepointBaseURL+result);
          })
          .catch(error =>{
            common.toastNotification('Sharepoint Failed To Open','Navigation Failure','error');
          })
        }
      }
      
      ///////////////////////////
      // Doc Acceptance Screen //
      ///////////////////////////
      else if(this.screenName === common.screenNamesEnum.DOC_ACCEP){ 
        stepElement.isButtonSpinner =true;        
        if(elementAction === 'getConditions'){ 
          window.open('/apex/UnderwritingRequestConditions?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        } 
        else if(elementAction === 'Sharepoint'){
          window.open(formDoc.sharepointBaseURL+this.uwCareNumber);
          stepElement.isButtonSpinner =false;
        }
        else{
          let args = this.fetchMethodArgs(elementAction);

          invokeApexAction({action:elementAction, args:args})
          .then(result => 
          {
            window.open('/'+result.resultRecordId);
            stepElement.isButtonSpinner =false;
            this.openScreenBase(common.screenNamesEnum.DOC_VAULT);
          })
          .catch(e => 
          {
            
            stepElement.isButtonSpinner =false;
          });
        }
      }
      ///////////////////
      // DOC QA Screen //
      ///////////////////
      else if(this.screenName === common.screenNamesEnum.DOC_QA)
      {
        stepElement.isButtonSpinner =true;        
        if(elementAction === "openDocQAPage")
        {
          window.open('/apex/DocumentationQA?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
      }
      /////////////////////
      // DOC Prep Screen //
      /////////////////////
      else if(this.screenName === common.screenNamesEnum.DOC_PREP)
      {
        stepElement.isButtonSpinner =true;
        
        if(elementAction === "openGenDocPackagePage")
        {
          window.open('/apex/UWStartDocumentation?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
        else if(elementAction === "openDocPrepPage")
        {
          window.open('/apex/UWDocPrep?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
      }
      /////////////////////////
      // UNDERWRITING SCREEN //
      /////////////////////////
      else if(this.screenName === common.screenNamesEnum.UNDERWRITING)
      {
        stepElement.isButtonSpinner =true;
        
        if(elementAction === "getCareSummary")
        {
          window.open('/apex/URSummaryInfo?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
		    else if(elementAction === "getDRR")
        {
          window.open('/apex/DualRiskRating?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
		    else if(elementAction === "getConditions")
        {
          window.open('/apex/UnderwritingRequestConditions?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
		    else if(elementAction === "getPolicyExceptions")
        {
          window.open('/apex/LoanCreditExceptions?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
		    else if(elementAction === "getCovenants")
        {
          window.open('/lightning/r/'+this.uwRecordId+'/related/Covenants__r/view');
          stepElement.isButtonSpinner =false;
        }
		    else if(elementAction === "getILOCs")
        {
          window.open('/lightning/r/'+this.uwRecordId+'/related/Credit_Enhancements__r/view');
          stepElement.isButtonSpinner =false;
        }
		    else if(elementAction === "getFSRs")
        {
          window.open('/lightning/r/'+this.careAccountId+'/related/Financial_Statement_Requirements__r/view');
          stepElement.isButtonSpinner =false;
        }
		   /* else if(elementAction === "getAssociationsComponents")
        {
          window.open('/apex/UnderwritingAssociations?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }*/
		    else if(elementAction === "getCreditDoc")
        {
          window.open('/apex/QuickReviewGeneration?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
      }
      //////////////////////////////
      // Origination Model Screen //
      //////////////////////////////
      else if(this.screenName === common.screenNamesEnum.OM)
      {
        stepElement.isButtonSpinner =true;        
        if(elementAction === "getDRR")
        {
          window.open('/apex/DualRiskRating?id='+this.uwRecordId);
          stepElement.isButtonSpinner =false;
        }
      }     
      //////////////////////
      // Reg Check Screen //
      //////////////////////
      else if(this.screenName === common.screenNamesEnum.REG_CHECK)
      {
        stepElement.isButtonSpinner =true;
        
        if(elementAction === 'createRegCheckCase')
        {
          let args = this.fetchMethodArgs(elementAction);
          invokeApexAction({action:elementAction, args:args})
            .then(result => 
            {
              stepElement.isButtonSpinner =false;
              this.openScreenBase(common.screenNamesEnum.REG_CHECK);
              getScreensImperative({uwCaseOrNDARecId: this.recordId})
              .then(refreshScreen => 
              {
                this.populateScreenPropertiesAndLists(this.screenName, refreshScreen);
              })
              .catch(e => 
              {
                stepElement.isButtonSpinner =false;
              });
            })
            .catch(e => 
            {
              stepElement.isButtonSpinner =false;
            });
        }
      }
      //////////////////////
      // Doc Vault Screen //
      //////////////////////
      else if(this.screenName === common.screenNamesEnum.DOC_VAULT)
      {
        stepElement.isButtonSpinner =true;        
        let args = this.fetchMethodArgs(elementAction);

        invokeApexAction({action:elementAction, args:args})
        .then(result => 
        {
          stepElement.isButtonSpinner =false;
          window.open('/'+result.resultRecordId);
          this.openScreenBase(common.screenNamesEnum.DOC_VAULT);
        })
        .catch(e => 
        {
        });
      }
      /////////////////////////////
       //pre WMS Setup Screen //
      ////////////////////////
      else if(this.screenName === common.screenNamesEnum.PRE_WMS_SETUP)
      {
        stepElement.isButtonSpinner =true;
        
        if(elementAction === 'createWMSChangeFormCase')
        {
          let args = this.fetchMethodArgs(elementAction);
 
          invokeApexAction({action:elementAction, args:args})
          .then(result => 
            {
              stepElement.isButtonSpinner =false;
              this.openScreenBase(this.screenName);
              getScreensImperative({uwCaseOrNDARecId: this.recordId})
              .then(refreshScreen => 
              {
                this.populateScreenPropertiesAndLists(this.screenName, refreshScreen);

                this.wmsChangeCasesExist =true;
              })
              .catch(e => 
              {
              });
            })
            .catch(e => 
            {
            })
        }
        
      }
      ////////////////////////////
      // for any other element actions that were not tied to a specific screen or hardcoded above, invoke the Apex Action
      ////////////////////////////
      else
      {
        stepElement.isButtonSpinner =true;
        
        if(TRUE) 
        {
          let args = this.fetchMethodArgs(elementAction);
          
          invokeApexAction({action:elementAction, args:args})
          .then(result => 
          {
            stepElement.isButtonSpinner =false;
          })
          .catch(e => 
          {
            stepElement.isButtonSpinner =false;
          });
        }
      }
    }

  ///////////////////////////////
  // Formation Document Screen //
  ///////////////////////////////
  handleBillingCode(event)
  {
    formDoc.handleBillingCode(event.target.dataset.id, this.formationDocTable, event.target.value, this.uwRecordId, this.screenName)
    .then(result =>{
      this.formationDocTable = result;
    })
  }  


  //Creates an array of arguments to be passed to Apex invokeAction method
  fetchMethodArgs(methodName)
  {
    let Methodargs=[];
    
    if(methodName === 'generateNDAPDF')
    { 
      let docVaultRecExist=false;

      if(this.ndaDocVaultId)
      {
        docVaultRecExist=true;
      }
      
      Methodargs.push(this.ndaId);
      Methodargs.push(this.uwRecordId);
      Methodargs.push(docVaultRecExist);
    }
    //////////////////////
    // Doc Vault Screen //
    //////////////////////
    else if(methodName === 'generateFinalNDAPDF')
    { 
      Methodargs.push(this.ndaId);
      Methodargs.push(this.uwRecordId);
      Methodargs.push(true);
    }
    ///////////////////////////////////////////
   
    ////////////////////////////////////
    // regcheck case
    /////////////////////////////////
    else if(methodName === 'createRegCheckCase')
    {
      Methodargs.push(this.uwRecordId);
      Methodargs.push(this.initiatingAccountRecordId);
    }

    ///////////////////////////////////////////
    // preWMSSetup screen
    //////////////////////////////////////////
    else if(methodName === 'createWMSChangeFormCase')
    {
      Methodargs.push(this.uwRecordId);
      Methodargs.push(this.initiatingAccountRecordId);
    }
    ///////////////////////////////////////////

    return Methodargs;
  }

  handleDupeAppTableCheckbox(event)
  {
    dupeAppHelper.dupeAppTableCheckboxPressed(event.target.dataset.id,this.dupeApps);
    this.dupeApps = dupeAppHelper.apps;
  }

  //Populates various BW screen properties 
  populateScreenPropertiesAndLists(scrName, stageToScreenWrappersListMap)
  {
    console.log('In populateScreenPropertiesAndLists method');
    
    common.populateScrPropertiesAndLists(scrName, this.uwCurrentStage, stageToScreenWrappersListMap);

    this.isWelcomeScreen = common.isWelcomeScreen;
    this.isFirstNonWelcomeScreen = common.isFirstNonWelcomeScreen;
    this.isLastScreen = common.isLastScreen;
    this.isRequestStageScreen = common.isRequestStageScreen;
    this.isUnderwritingStageScreen = common.isUnderwritingStageScreen;
    this.isDocCreationStageScreen = common.isDocCreationStageScreen;
    this.isAccountSetupStageScreen = common.isAccountSetupStageScreen;
    this.dupAppScreen = false;
    this.isFormationDocScreen = false;
    
    this.allScreensList = common.allScreensList;
    this.requestStageScreensList = common.requestStageScreensList;
    this.underwritingStageScreensList = common.underwritingStageScreensList;
    this.docCreationStageScreensList = common.docCreationStageScreensList;
    this.accountSetupStageScreensList = common.accountSetupStageScreensList;

    if(this.allScreensList.length === 0)
      this.displayScreensList=false;
    else
      this.displayScreensList=true; 
      
    this.isCurrentScreenLastOnStage= common.isThisScreenLastOnStage;
    
    this.openUpCorrectStageSectionInAccordian(); 
  }

  //This method should only be run after common.determineCurrentScreenTypeAndStage(scrName) gets executed
  //else the properties being checked will always be false by default
  openUpCorrectStageSectionInAccordian()
  {
    if(this.isRequestStageScreen)
    {
      this.activeStageIsRequest = true;
      this.activeStageSectionName = common.uwStageNamesEnum.REQ;
    }
    else if(this.isUnderwritingStageScreen)
    {
      this.activeStageIsUnderwriting = true;
      this.activeStageSectionName = common.uwStageNamesEnum.UW;
    }
    else if(this.isDocCreationStageScreen)
    {
      this.activeStageIsDocumentCreation = true;
      this.activeStageSectionName = common.uwStageNamesEnum.DOC_CREATION;
    }
    else if(this.isAccountSetupStageScreen)
    {
      this.activeStageIsAccountSetup = true;
      this.activeStageSectionName = common.uwStageNamesEnum.ACCT_SETUP;
    }
  }
  
    
  handleStepCompletedClick(event)
  {
    let cbChecked = event.target.dataset.checked;
    let stepTitle = event.target.dataset.steptitle;
    let step = common.getStepByStepTitle(stepTitle, this.steps);
    
    if(this.screenName === common.screenNamesEnum.OR_AND_EXCP)
    {      
      if(cbChecked === 'true')
      {
        step.stepCompleted = true;

        if(step.element1Wrapper.elementSelectedPicklistValue === '(Select One)' && step.element1Wrapper.isPicklist)
        {
          step.stepCompleted = false;
          common.toastSticky('Please select one value in the picklist to mark the selected step as completed.','Error','error');
          return;
        }
      } 
      else
      {
        step.element1Wrapper.elementSelectedPicklistValue = '(Select One)';
        step.userAnswer = null;
        
        step.stepCompleted = cbChecked;
      }       
    }
    else if(this.screenName === common.screenNamesEnum.CBR_VER || this.screenName === common.screenNamesEnum.ADDR_VER)
    {
      if(cbChecked === 'true' && (stepTitle === 'Ownership Change' || stepTitle === 'Owner home address match'))
      {
        step.stepCompleted = true;
        common.getStepByStepTitle(stepTitle, this.steps).userAnswer = step.element1Wrapper.elementSelectedPicklistValue;
        if(step.element1Wrapper.elementSelectedPicklistValue === '(Select One)')
        {
          step.stepCompleted = false;
          common.toastNotification('Please select one value in the picklist to mark the selected step as completed.','Error','error');
          return;
        }
      } 
    }

    upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:event.target.dataset.id, stepResultRecordId:step.stepResultRecordId, usrAnswer:common.getStepByStepTitle(stepTitle, this.steps).userAnswer, stepCompletedFlag:cbChecked})
    .then(result => 
    {
      this.getScreenStepsResults(this.screenName);
     
      getScreensImperative({uwCaseOrNDARecId: this.recordId})
      .then(newresult => 
      {
        this.populateScreenPropertiesAndLists(this.screenName, newresult);

        if(this.screenName ===common.screenNamesEnum.UNDERWRITING && this.uwCurrentStage === common.uwStageNamesEnum.UW)
        {
          this.areAllUWStageScreensCompleted=common.areAllScreensForStageCompleted(this.uwCurrentStage);
        }
        else if(this.screenName === common.screenNamesEnum.REG_CHECK && this.uwCurrentStage === common.uwStageNamesEnum.DOC_CREATION)
        {
          this.areAllDocStageScreensCompleted=common.areAllScreensForStageCompleted(this.uwCurrentStage);
        }
      })
      .catch(e => 
      {
      });
    })
    .catch(e => 
    {
    });
  }
  
  //Changes isLoaded to the opposite of its current value 
  toggleIsLoaded() 
  {
    this.isLoaded = !this.isLoaded;
  }

  //Retrieves BW screen step results records associated with BW steps on a screen
  getScreenStepsResults(scrName)
  {
   
    getScreenStepResultsMap({underwritingRecId: this.uwRecordId, screenName: scrName})
      .then(result => 
      {
        if(result)
        {
          var conts = result;


          for(var key in conts)
          { 
            for(var i=0; i< this.steps.length; i++)
            {
              if(this.steps[i].stepRecordId === key)
              {
                if(conts[key][0] === 'true')
                  this.steps[i].stepCompleted=true;
                else
                  this.steps[i].stepCompleted=false;
              
                this.steps[i].userAnswer=conts[key][1];

                if(scrName === common.screenNamesEnum.OR_AND_EXCP || scrName === common.screenNamesEnum.ADDR_VER)
                {

                  if(this.steps[i].userAnswer)
                    this.steps[i].element1Wrapper.elementSelectedPicklistValue=conts[key][1];                  
                  else
                    this.steps[i].element1Wrapper.elementSelectedPicklistValue = '(Select One)';  
                 
                }
              }
            }
            //Here we are creating the array to show on UI.
            //this.stepRecIdToStepRecordMap.push({key:key,value:conts[key]}); 

          }
        }
      })
      .catch(e => 
      {
      });
  }

  //reused code for querying steps > then results > then screens
  queryStepsResultsAndScreens(scrName, doToggleScreen, clearButtonSpinner){
    this.steps=[];
    getScreenSteps({screenName: scrName, uwCaseOrNDARecId: this.recordId})
    .then(result => 
    {
      this.steps=result;
      this.showStepsCompletedText = common.getStepsCompletedFlag(scrName);
      this.getScreenStepsResults(scrName);

      getScreensImperative({uwCaseOrNDARecId: this.recordId})
      .then(newresult => 
      {
        this.populateScreenPropertiesAndLists(scrName, newresult);

        if(doToggleScreen){
          this.toggleIsLoaded();
        }
        if(clearButtonSpinner){
          this.buttonSpinner=false;
        }
      })
      .catch(error => 
      {
        if(doToggleScreen){
          this.toggleIsLoaded();
        }
        if(clearButtonSpinner){
          this.buttonSpinner=false;
        }
      });  

    })
    .catch(error => 
    {
      this.error = error;
      if(doToggleScreen){
        this.toggleIsLoaded();
      }
      if(clearButtonSpinner){
        this.buttonSpinner=false;
      }
    });
  }

  //Determine if Previous Uncompleted Screen and Next Uncompleted Screen buttons should be shown
  //and if one of those buttons or screen name is clicked which screen should be displayed
  determinePreviousOrNextScreen(previousOrNext)
  {
    var exitPreviousScreenLoop = false;
    var exitNextScreenLoop=false;
    this.showPreviousScreenButton = false;
    this.showNextScreenButton = false;

    //If method was called by clicking "Previous Uncompleted Screen" button
    if(previousOrNext === 'Previous')
    {
      //determine which previous uncompleted screen to display and if Previous Uncompleted Screen button should be displayed for that screen
      for(var i=0; i < this.allScreensList.length && exitPreviousScreenLoop === false; i++)
      {
        if(this.allScreensList[i].name === this.screenName)
        {
          for(var j=i-1; j >= 0 && exitPreviousScreenLoop === false; j--)
          {
            if(this.allScreensList[j].isCompleted === false)
            {
              this.screenName = this.allScreensList[j].name;
              this.showPreviousScreenButton = true;
              exitPreviousScreenLoop = true;
            }
          }
        }
      }

      //determine if Next Uncompleted Screen button should be shown
      for(var i=0; i < this.allScreensList.length && exitNextScreenLoop === false; i++)
      {
        if(this.allScreensList[i].name === this.screenName)
        {
          for(var j=i+1; j < this.allScreensList.length && exitNextScreenLoop === false; j++)
          {
            if(this.allScreensList[j].isCompleted === false)
            {
              this.showNextScreenButton = true;
              exitNextScreenLoop=true;
            }
          }
        }
      }
    }
    //If method was called by clicking "Next Uncompleted Screen" button
    else if(previousOrNext === 'Next')
    {
      //determine which next uncompleted screen to display and if Next Uncompleted Screen button should be displayed for that screen
      for(var i=0; i < this.allScreensList.length && exitNextScreenLoop === false; i++)
      {
        if(this.screenName === 'Welcome')
        {
          for(var j=i; j < this.allScreensList.length && exitNextScreenLoop === false; j++)
          {
            if(this.allScreensList[j].isCompleted === false)
            {
              this.screenName = this.allScreensList[j].name;
              this.showNextScreenButton = true;
              exitNextScreenLoop=true;
            }
          }
        }
        else if(this.allScreensList[i].name === this.screenName)
        {
          for(var j=i+1; j < this.allScreensList.length && exitNextScreenLoop === false; j++)
          {
            if(this.allScreensList[j].isCompleted === false)
            {
              this.screenName = this.allScreensList[j].name;
              this.showNextScreenButton = true;
              exitNextScreenLoop=true;
            }
          }
        }
      }
     
      //determine if Previous Uncompleted Screen button should be shown
      for(var i=0; i < this.allScreensList.length && exitPreviousScreenLoop === false; i++)
      {
        if(this.allScreensList[i].name === this.screenName)
        {
          for(var j=i-1; j >= 0 && exitPreviousScreenLoop === false; j--)
          {
            if(this.allScreensList[j].isCompleted === false)
            {
              this.showPreviousScreenButton = true;
              exitPreviousScreenLoop = true;
            }
          }
        }
      }
    }
    //If method was called by clicking screen name
    else
    {
      //determine if Previous Uncompleted Screen button should be shown
      for(var i=0; i < this.allScreensList.length && exitPreviousScreenLoop === false; i++)
      {
        if(this.allScreensList[i].name === this.screenName)
        {
          for(var j=i-1; j >= 0 && exitPreviousScreenLoop === false; j--)
          {
            if(this.allScreensList[j].isCompleted === false)
            {
              this.showPreviousScreenButton = true;
              exitPreviousScreenLoop = true;
            }
          }
        }
      }
      //determine if Next Uncompleted Screen button should be shown
      for(var i=0; i < this.allScreensList.length && exitNextScreenLoop === false; i++)
      {
        if(this.allScreensList[i].name === this.screenName)
        {
          for(var j=i+1; j < this.allScreensList.length && exitNextScreenLoop === false; j++)
          {
            if(this.allScreensList[j].isCompleted === false)
            {
              this.showNextScreenButton = true;
              exitNextScreenLoop=true;
            }
          }
        }
      }
    }
  }

  //Base openScreen method to open up a screen that can be invoked by openScreen method 
  //when a user either clicks on the screenName in the list or on Continue, Previous Screen or Next Screen buttons.
  openScreenBase(scrName)
  {
      
      if(!this.bypassRevilio){
        this.isLoaded=false;         
      }
      
      this.steps=[];
      this.pageMessage = '';
      this.isBorrowerEVTDataExist = false;
      this.isEntityEVTDataExist = false;
      this.isEntityVerificationScreen = false;
      this.isDataVerificationScreen = false;
      this.isAddressVerificationScreen=false;
      this.isCBRScreen = false;
      this.isFormationDocScreen = false;
      this.isDocVaultScreen = false;
      this.hideMainSteps = false;
      this.wmsChangeCasesExist =false;
      this.InUWScreen =false;
      this.areAllUWStageScreensCompleted =false;
      this.areAllDocStageScreensCompleted=false;
      this.routeToCreditBoolean = false;
      this.routeToCreditReason = '';
      this.displayMoveToNextStageTable=false;

      /////////////////////////////
      // DATA VERIFICATION SCREEN //
      //////////////////////////////
      if(scrName === common.screenNamesEnum.BUS_DATA_VER)
      {
        //added for verification screen
        this.isDataVerificationScreen = true;
        
        getborrowerDbaRows({uwCaseOrNDARecId: this.recordId})  //added for verification screen
        .then(result4 => 
        {
          //map should always have a single key
          for (var key in result4) {
            if (result4.hasOwnProperty(key)) {
              this.borrowerDbaList = result4[key];
              if(key.includes('internal system error')){
                this.pageMessage = key;
                common.toastSticky(this.pageMessage, 'Error', 'error');
              } 
              this.queryStepsResultsAndScreens(this.screenName, true, false);
            }
          }          
        })
        .catch(error => 
        {
          this.error = error;
          this.toggleIsLoaded();
        });
      }
      
      //////////////////////////////
      // CBR VERIFICATION SCREEN ///
      //////////////////////////////
      else if(scrName === common.screenNamesEnum.CBR_VER)
      { 
        this.isCBRScreen = true;
        this.cbrList = [];
        getCbrRows({ underwritingId: this.uwRecordId, initiatingAccountId: this.initiatingAccountRecordId, ndaId: this.ndaRecordId, uwCreatedDateTimeString: this.uwCreatedDateTimeString})
        .then(result5 => 
          {
            //map should always have a single key
            for (var key in result5) {
              if (result5.hasOwnProperty(key)) {
                this.cbrList = result5[key];
                if(key.includes('internal system error')){
                  this.pageMessage = key;
                  common.toastSticky(this.pageMessage, 'Error', 'error');
                } 
                if(this.cbrList.length < 1){
                  common.toastNotification('No individual guarantor owners were found in first level associations, so there are no credit bureau reports to pull.  You may need to double check that associations are accurate.' , 'No Individual Guarantors Found', 'warning');
                }
                this.queryStepsResultsAndScreens(scrName, true, false);
              }
            }
          })
        .catch(error => 
        {
          this.error = error;
          this.toggleIsLoaded();
        });
      }
      /////////////////////////////////////////////
      // Call to Dealer screen  //
      /////////////////////////////////////////////
      else if(scrName === common.screenNamesEnum.DLR_DSCN)
      { 
        var tcheck = dealerCallHelper.checkPreviousRequestStageScreens(this.requestStageScreensList);
        if(tcheck[0] !== 'PASS'){
          this.pageMessage = 'The following Boarding Wizard screens are incomplete and must be finished: '+tcheck[0];
          common.toastSticky(this.pageMessage, 'Error', 'error');
          this.hideMainSteps = true;
        } else if(tcheck[1] !== 'PASS') {
          this.pageMessage = 'Before calling the dealer, it is recommended to complete the following Boarding Wizard screens: '+tcheck[1];
          common.toastNotification(this.pageMessage, 'Alert', 'warning');
          this.hideMainSteps = false;
        }
        this.queryStepsResultsAndScreens(scrName, true, false);
        
      }
      else
      {
      getScreensImperative({uwCaseOrNDARecId: this.recordId})
      .then(newresult => 
      {
        getScreenSteps({screenName: scrName, uwCaseOrNDARecId: this.recordId})
        .then(result => 
        {
          this.steps=result;
          
          this.showStepsCompletedText = common.getStepsCompletedFlag(scrName);
          this.getScreenStepsResults(scrName);

          console.log(this.showNextScreenButton);

          this.populateScreenPropertiesAndLists(scrName, newresult);

          console.log(this.showNextScreenButton);
          
          this.isDataVerificationScreen = false;
          this.dupAppScreen = false;
          this.isBorrowerEVTDataExist = false;
          this.isEntityEVTDataExist = false;
          this.isEntityVerificationScreen = false;
          this.isAddressVerificationScreen=false;
          this.isDocVaultScreen = false;
          this.isDocAcceptanceScreen = false;
          this.regCheckCasesExist =false;
          this.isMoveToUWStageScreen=false;
          this.isMoveToDocCreationStageScreen=false;
          this.isMoveToAcctSetupStageScreen=false;

          /////////////////////////////
          // NDA VERIFICATION SCREEN //
          /////////////////////////////
          if(this.screenName === common.screenNamesEnum.NDA_VER)
          {
            ndaVerif.fetchNDADocVaultId(this.uwRecordId, this.steps)
            .then(newRes =>
            {
              this.ndaDocVaultId =newRes;
            });

            ndaVerif.verifyWhetherOtherProductExist(this.ndaRecordId, this.uwRecordId).then(newRes1=>
              {
                  this.otherProductExist =newRes1;
                  let i=1;
                  if(!this.otherProductExist)
                  {
                    for(let step of this.steps)
                    {
                       if(step.stepTitle === 'Products Verification')
                       {
                         step.hiddenOnScreen =true;
                         ndaVerif.fetchStepAnswer(this.uwRecordId, step.stepRecordId, this.screenName).then(stepRes =>
                          {
                              let insertResult=true;
                              if(stepRes)
                              {
                                if(stepRes.Step_Completed__c)
                                {
                                  insertResult =false;
                                }
                              }
                              if(insertResult)
                              {
                                upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:step.stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:true});
                              }
                          })
                       }
                       else
                       {
                          //manipulate step numbers.
                          step.stepNumber =i;
                          i++;
                       }
                       
                    }
                  }
                
              });

            this.toggleIsLoaded();
          } 
         ///////////////////////////////////
         // DUPLICATE APPLICATIONS SCREEN //
         ///////////////////////////////////
         else if(scrName === common.screenNamesEnum.DUP_APPS)
         { 
           getDupeApps({uwCaseOrNDARecId: this.recordId})
           .then(res => 
           {
             this.dupeApps=res;
             if(this.dupeApps.length>1)
             {
               this.dupAppScreen=true;                
             }
             else
             {
              upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[0].stepRecordId,  usrAnswer:null, stepResultRecordId:null, stepCompletedFlag:true})
               
               .then(resu => 
                {
                  this.getScreenStepsResults(this.screenName);
                  
                  getScreensImperative({uwCaseOrNDARecId: this.recordId})
                  .then(newresu => 
                  {
                    this.populateScreenPropertiesAndLists(scrName, newresu);
                  })
                  .catch(e => 
                  {
                  });
                })
                .catch(e => 
                {
                });
             }
             
             this.toggleIsLoaded();
           })
           .catch(error => 
           {
              this.error = error;
              this.toggleIsLoaded(); 
           });
         }
         /////////////////////////////////
         /// Entity Verification Screen //
         /////////////////////////////////
         else if(this.screenName === common.screenNamesEnum.ENT_VER)
          {
            //this.isEntityVerificationScreen = true;
            this.borrowerSOSList=[];
            this.entitySOSList=[];
            
            // constructs the borrower and entity list.  
            entityVerif.fetchEVTDataTable(this.uwRecordId, this.steps).then( DataRes =>
            {
              if(DataRes)
              {
                for(let data of DataRes)
                { 
                  if(data.rowType==='Borrower')
                  {
                     for(let d of data.dataList)
                    {
                      
                      if(d.picklistvalues)
                      {
                        d.picklistvalues = common.createOptionsListFromStringList( d.picklistvalues);
                      }
                    } 
                    this.borrowerSOSList.push(data);
                  }
                  else if(data.rowType ==='Entity')
                  {
                     for(let d of data.dataList)
                    {
                      if(d.picklistvalues)
                      {
                         d.picklistvalues = common.createOptionsListFromStringList( d.picklistvalues);
                      }
                    }
                    this.entitySOSList.push(data);
                  }
                } 
                if(this.borrowerSOSList.length >0)
                {
                 this.bflagsMap= entityVerif.constructFlags(this.steps, this.borrowerSOSList);
                 this.bflags = Object.values(this.bflagsMap);
                 this.isBorrowerEVTDataExist = true;
                 this.isEntityVerificationScreen = true;
                }
                if(this.entitySOSList.length >0)
                {
                 this.eflagsMap= entityVerif.constructFlags(this.steps,this.entitySOSList);
                 this.eflags = Object.values(this.eflagsMap);
                 this.isEntityEVTDataExist = true;
                 this.isEntityVerificationScreen = true;
                }
                
                this.isAllStepsCompleted= entityVerif.allFlagsVerified({...this.bflagsMap, ...this.eflagsMap});
                entityVerif.setEntityScreenResultOnLoad(this.requestStageScreensList, this.isAllStepsCompleted);
                
                this.isLoaded=true;
              
              }   
              else
              {
                common.toastNotification('Error!', 'No data Found. ','error');
              }            
            }) 
          }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //Formation Document Screen
        else if(this.screenName === common.screenNamesEnum.FRM_DOCS){
          this.optionsYN = ["No","Yes"];
          this.optionsYN = common.createOptionsListFromStringList(this.optionsYN);
          getBillingCodes()
          .then(billingResult=>{
            this.billingCode = [{label: 'On File', value: 'On File'}];
            var tempBillingCode = common.createOptionsListFromStringList(billingResult);
            for(let option of tempBillingCode){
              this.billingCode = [...this.billingCode, {label: option.label+'', value: option.value+''}];
            }
            
          })
          .catch(billingError=>{
            common.toastNotification(null,"No Billing Code Choices Found","info");
          });
          getFormationScreenRecords({recordId:this.uwRecordId,screenName:this.screenName})
          .then(res => {
            this.formationDocTable = res
            if(this.formationDocTable[0].reviewType === 'New'){
              this.isFormationDocScreen = true;
              this.step1Verified = formDoc.checkMasterBox(this.formationDocTable);
              this.step2Verified = formDoc.checkLegalName(this.formationDocTable);
              this.step3Verified = formDoc.checkFormOption(this.formationDocTable);
              upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[0].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step1Verified});
              upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[1].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step2Verified});
              upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[2].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step3Verified});
            }
          })
          .catch(error =>{
            common.toastNotification(null,"No Borrowers Found","info");
          });
          
          for(let i=0; i< this.steps.length; i++){       
            if(i === 0){
              this.step1Shown = true;
            }
            else if(i === 1){
              this.step2Shown = true;
            }
            else if(i === 2){
              this.step3Shown = true;
            }
          }

          this.toggleIsLoaded();
        }
        //ADDRESS VERIFICATION SCREEN
        else if(this.screenName === common.screenNamesEnum.ADDR_VER)
        {
            this.accountsList=[];
            this.isAddressVerificationScreen=true;
        
            addressVerif.fetchInitiatingAccountAddress(this.initiatingAccountRecordId).then(accountAddResult => {
              for(let step of this.steps)
              {
                if(step.stepTitle ==='Initiating_Account_Address_Verification')
                {
                  step.element1Wrapper.textData = accountAddResult;
                }

                if(step.userAnswer === undefined || step.element1Wrapper.elementSelectedPicklistValue === undefined)
                {
                  step.element1Wrapper.elementSelectedPicklistValue = '(Select One)';
                }
              }
            });
            
            addressVerif.fetchAddressWrapper(this.uwRecordId).then(addressRes => 
            {
                if(addressRes)
                {
                  for(let data of addressRes)
                  {
                    addressVerif.populateCountryAndStatePickList(data, this.state, this.country);
                  } 

                  this.accountsList =addressRes;
                  this.borrowerHeader =addressVerif.Headertitle;
                  //this.addressHeader =addressVerif.addressHeaderTitle;

                  //populate address map.
                  addressVerif.fetchAddressMap().then(addressMap =>{
                     if(addressMap)
                     {
                      for(var key in addressMap) 
                      {
                        addressVerif.addressStandardMap.set(key,addressMap[key]); 
                      } 
                      this.addressStandardizationObj = { addressStandardization:[] };
                      this.addressStandardizationObj ={...this.addressStandardizationObj, ...addressVerif.standardizeAddresses(this.accountsList, addressVerif.addressStandardMap, this.addressStandardizationObj)}
                      
                      
                      addressVerif.populateWrapper(this.accountsList, this.addressStandardizationObj);
                      this.isLoaded =true;
                     }
                  })
                  
                  addressVerif.fetchValidAccountIdsForLookup(this.uwRecordId).then(validAccts =>{
                    if(validAccts)
                    {
                      this.validAccountsLookup = validAccts;
                    }
                    else
                    {
                       common.toastNotification('Error occured while fetching accounts.', 'Error', 'Error!');
                    }
                    
                  })
                
                }
            });
        }
        ////////////////////////////////////
        // Start of Doc Acceptance Screen //
        ////////////////////////////////////
        else if(this.screenName === common.screenNamesEnum.DOC_ACCEP)
        {
          let steptitle;
          if(common.getStepByStepTitle('8 Underwritten', this.steps) === undefined){
            steptitle = '8 App Only';
          }
          else{
            steptitle = '8 Underwritten';
          }
          if(this.insuranceAmount === undefined || this.insuranceDate === undefined)
          {
            getInsuranceData({accountId:this.initiatingAccountRecordId})
            .then(resultInsurance =>{
              this.insuranceAmount = resultInsurance.Inventory_Coverage_Amount__c;
              this.insuranceDate = resultInsurance.Inventory_Coverage_Expiration_Date__c;
              this.previousInsuranceAmount = resultInsurance.Inventory_Coverage_Amount__c;
              this.previousInsuranceDate = resultInsurance.Inventory_Coverage_Expiration_Date__c;
              common.getStepByStepTitle(steptitle, this.steps).element1Wrapper.elementSelectedPicklistValue = this.insuranceAmount;
              common.getStepByStepTitle(steptitle, this.steps).element2Wrapper.elementSelectedPicklistValue = this.insuranceDate;
          })
          .catch(error =>{
            common.getStepByStepTitle(steptitle, this.steps).element1Wrapper.elementSelectedPicklistValue = this.insuranceAmount;
              common.getStepByStepTitle(steptitle, this.steps).element2Wrapper.elementSelectedPicklistValue = this.insuranceDate;
          }) 
        }
        else {
          common.getStepByStepTitle(steptitle, this.steps).element1Wrapper.elementSelectedPicklistValue = this.insuranceAmount;
          common.getStepByStepTitle(steptitle, this.steps).element2Wrapper.elementSelectedPicklistValue = this.insuranceDate;
        }          
        this.isDocAcceptanceScreen = true;

        if(!this.bypassRevilio){
          this.toggleIsLoaded();            
        }
        this.bypassRevilio = false;
      }
    ///////////////////////////////////////
    // Start of Origination Model Screen //
    ///////////////////////////////////////
      else if(scrName === common.screenNamesEnum.OM)
      { 
        getPMData({underwritingId: this.uwRecordId})
        .then(res => 
        {
          if(res)
          {
            upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[0].stepRecordId,  usrAnswer:null, stepResultRecordId:null, stepCompletedFlag:true})
            .then(resu => 
            {
                this.getScreenStepsResults(this.screenName);
                getScreensImperative({uwCaseOrNDARecId: this.recordId})
                .then(newresu => 
                {
                  this.populateScreenPropertiesAndLists(scrName, newresu);
                })
                .catch(e => 
                {
                });
            })
            common.toastNotification("OM Process Not Required","PM Found","info");
            this.steps[0].readOnlyCheckMark = true;
          }
        })  
        .catch(e => 
        {
        });
        this.toggleIsLoaded();
      }
      //////////////////////////////////////////////
      // Start of Security Search & Filing Screen //
      //////////////////////////////////////////////
      else if(scrName === common.screenNamesEnum.SEC_SEARCH)
      {
        if(this.uwCountry === 'United States'){
          getSearchFilings({careNumberId:this.careAccountId,underwritingId:this.uwRecordId,screenName:this.screenName})
          .then(securityResult =>{
            this.filing = securityResult;
            this.billingCode = [];
            getBillingCodes()
            .then(billingResult=>{
              var tempBillingCode = common.createOptionsListFromStringList(billingResult);
              for(let option of tempBillingCode){
                this.billingCode = [...this.billingCode, {label: option.label+'', value: option.value+''}];
              }
              this.searchType = ['Summary','Copy'];
              this.searchType = common.createOptionsListFromStringList(this.searchType);
              this.filingType = ['Broad','Specific Lines','When Financed'];
              this.filingType = common.createOptionsListFromStringList(this.filingType);    
            })
            this.isSecurityFilingScreen = true;
            this.toggleIsLoaded();
          })
        }
        else{
          this.toggleIsLoaded();
        }
        
      }

      ///////////////////////////////////////
      // Move to underwriting stage screen //
      ///////////////////////////////////////
      else if(this.screenName === common.screenNamesEnum.MOVE_TO_UW_STAGE || this.screenName === common.screenNamesEnum.MOVE_TO_DOC_CREATION_STAGE || this.screenName === common.screenNamesEnum.MOVE_TO_ACCT_SETUP_STAGE)
      {

        if(this.screenName === common.screenNamesEnum.MOVE_TO_UW_STAGE)
        {
          this.isMoveToUWStageScreen =true;
        }
        else if(this.screenName === common.screenNamesEnum.MOVE_TO_DOC_CREATION_STAGE)
        {
          this.isMoveToDocCreationStageScreen =true;
        }
        else if(this.screenName === common.screenNamesEnum.MOVE_TO_ACCT_SETUP_STAGE)
        {  
          this.isMoveToAcctSetupStageScreen =true;
        }


        let screenCompleted=false;

        getScreensImperative({uwCaseOrNDARecId: this.recordId})
        .then(newresu => 
        {
          if(newresu)
          {
            this.populateScreenPropertiesAndLists(scrName, newresu);

            for(let i=0; i<this.allScreensList.length; i++)
            {
              if(this.allScreensList[i].name === this.screenName)
              {
                screenCompleted = this.allScreensList[i].isCompleted;
              }
            }
            
            if(screenCompleted === true)
            {
              this.displayMoveToNextStageTable = false;
              this.requestAlreadyInNextStageMessage = 'This underwriting request has already been progressed to a subsequent stage.';

              this.toggleIsLoaded();
            }
            else
            {

              if(this.uwCurrentStage === 'Request')
              {
                runRoute2CreditMatrixOnly({ underwritingId: this.uwRecordId})
                .then(result353 => 
                {
                  this.routeToCreditReason  = result353.reason;
                  this.routeToCreditBoolean = (result353.routeToCredit === true);

                  this.displayMoveToNextStageTable = true;

                  this.populateScreenPropertiesAndLists(this.screenName, newresu);

                  this.toggleIsLoaded();
                });
              }
              else
              {
                this.displayMoveToNextStageTable = true;

                this.populateScreenPropertiesAndLists(this.screenName, newresu);
                
                this.toggleIsLoaded();
              }  
            }
          }
          else
          {
            this.toggleIsLoaded();
          }
        })
        .catch(e => 
        {
        });
      }
      //////////////////////////
      // Undewrwriting screen //
      //////////////////////////
      else if(this.screenName === common.screenNamesEnum.UNDERWRITING)
      {
        this.InUWScreen =true;  
        
        uwVerif.fetchInitAccount(this.initiatingAccountRecordId).then(user =>{
           
        if(user.success)
        {
          let caRecInfo = {};
          caRecInfo.Id = user.success[0];
          caRecInfo.Name =user.success[1];
          common.getStepByStepTitle('Credit_Analyst', this.steps).lookupPlaceHolderText ='Enter Credit Analyst Name';
          common.getStepByStepTitle('Credit_Analyst', this.steps).lookupSelectedValue  =caRecInfo;
        }
        else if(user.exception)
        {
          common.toastNotification(null,JSON.stringify(user.exception[0]), 'Exception!');
        }
      });

      for(let step of this.steps)
      {
        if(step.element1Wrapper.isLookup)
        {
          step.element1Wrapper.lookupFieldName='Name';
          step.element1Wrapper.lookupObjectName='User';
          step.lookupPlaceHolderText ='Enter Credit Analyst Name';
        }
      }
            
            uwVerif.fetchActiveUsersList().then(activeUsers =>{
              if(activeUsers)
              {
                for(let u of activeUsers)
                {
                  this.activeUsersList.push(u);
                }
              }
              else
              {
                common.toastNotification('Error occured while fetching users','Error', 'Error!');
              }
              
            })
            uwVerif.fetchInsuranceOptions(this.uwRecordId).then(res =>{
              if(res)
              {
                common.getStepByStepTitle('Insurance_Options', this.steps).displayText =res;

                if(res ==='Please enter a recommended credit line on summary table')
                {
                  common.getStepByStepTitle('Insurance_Options', this.steps).readOnlyCheckMark =true;
                  common.getStepByStepTitle('Insurance_Options', this.steps).stepCompleted =false;
                }
                  
              }
            });
            this.isLoaded=true;
            if(this.uwCurrentStage === common.uwStageNamesEnum.UW)
            {
              this.areAllUWStageScreensCompleted=common.areAllScreensForStageCompleted(this.uwCurrentStage);
            }
        }
        /////////////////////////////////////////////
        // Overrides and Exceptions Review Screen  //
        /////////////////////////////////////////////
        else if(scrName === common.screenNamesEnum.OR_AND_EXCP)
        { 
          this.isOverridesScreen=true;
          

          for(let step of this.steps)
          {
            if(step.stepTitle === 'POOR PAYMENT PERFORMANCE')
            {
              this.hasPoorPerformanceAccts = orandexcp.getPoorPerfInd(this.uwCareNumber);

              if(this.hasPoorPerformanceAccts === true)
                step.element1Wrapper.textData = 'Yes';
              else
                step.element1Wrapper.textData = 'No';

              step.stepCompleted = true;
              step.readOnlyCheckMark = true;  
            }
            else if(step.stepTitle === 'ILOC')
            {
              this.hasILOCAccts = orandexcp.getILOCInd(this.uwCareNumber);

              if(this.hasILOCAccts === true)
                step.element1Wrapper.textData = 'Yes';
              else
                step.element1Wrapper.textData = 'No';

              step.stepCompleted = true;
              step.readOnlyCheckMark = true;
            }
            else if(step.stepTitle === 'LIMITED / RESTRICTED MANUFACTURER')
            {
              this.hasLimitedRestrictedMfrs = orandexcp.getLimitedRestrictedMfrInd(this.uwRecordId);

              if(this.hasLimitedRestrictedMfrs === true)
                step.element1Wrapper.textData = 'Yes';
              else
                step.element1Wrapper.textData = 'No';

              step.stepCompleted = true;
              step.readOnlyCheckMark = true;
            }
            else
            {
              if(step.userAnswer === undefined || step.element1Wrapper.elementSelectedPicklistValue === undefined)
              {
                step.element1Wrapper.elementSelectedPicklistValue = '(Select One)';
              }
            }

            upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:step.stepRecordId, stepResultRecordId:step.stepResultRecordId,  usrAnswer:step.element1Wrapper.textData, stepCompletedFlag:step.stepCompleted});

          }

          this.toggleIsLoaded();
        }
        // start of regcheck screen
        else if(scrName === common.screenNamesEnum.REG_CHECK)
        {
          regCheck.fetchRegulatoryCheckCases(this.uwRecordId).then(caseList =>{
            
            if(caseList)
            {
  
              this.allRegCheckCasesList =caseList;
              let step = common.getStepByStepTitle('RegulatoryCheck_Exist', this.steps);  
              step.readOnlyCheckMark=true;
              step.stepCompleted=false;
              
              if(caseList.length >0)
              {
                step.displayText+=' ( Please see the table below. )';
                this.regCheckCasesExist=true;
                step.stepCompleted=true;
              }
          
              regCheck.allRegCheckCaseClosed(this.uwRecordId, this.initiatingAccountRecordId).then(caseClosedStatus =>{
                  let stepRegCheckCompleted = common.getStepByStepTitle('RegulatoryCheck_Completed', this.steps);  
                  stepRegCheckCompleted.readOnlyCheckMark=true;
                  stepRegCheckCompleted.stepCompleted=caseClosedStatus ==='success'?true:false;
                  
                  if(caseClosedStatus ==='success' || caseClosedStatus==='openCaseExist')
                  {
                    //refresh the screen
                    this.getScreenStepsResults(this.screenName);
                    getScreensImperative({uwCaseOrNDARecId: this.recordId})
                    .then(newresult77 => 
                    {
                      this.populateScreenPropertiesAndLists(this.screenName, newresult77);

                      if(this.uwCurrentStage === common.uwStageNamesEnum.DOC_CREATION)
                      {
                        this.areAllDocStageScreensCompleted=common.areAllScreensForStageCompleted(this.uwCurrentStage);
                      }
                    })
                    .catch(e => 
                    {
                    });
                    //-end of refresh.
                 }
                  else
                  {
                    common.toastNotification('Error occured. '+caseClosedStatus, 'Error!', 'Error');
                  }
                  
 
                })
            }
              this.isLoaded =true;
            })
 
          }
          //end of regcheck screen

          //// pre-wms setup        
          else if(scrName === common.screenNamesEnum.PRE_WMS_SETUP)
          {
           preWMS.constructAllWMSChangeFormCases(this.uwRecordId).then(wmsCases =>{
              let stepWMS = common.getStepByStepTitle('CreateWMSChangeCase', this.steps);  
              stepWMS.readOnlyCheckMark=true;
              stepWMS.stepCompleted=false;
 
              if(wmsCases)
              {
                
                if(wmsCases.length > 0)
                {
                  this.wmsChangeCases = wmsCases;
                  this.wmsChangeCasesExist = true;
                  stepWMS.stepCompleted=true;
                }
              }
              this.isLoaded =true;
            })
          }
          //end of pre-wms setup screen
        else 
        {
          this.toggleIsLoaded();
        }
        })
        .catch(error => 
        {
          this.error = error;
        });
      })
      .catch(error => 
      {
        this.error = error;
      });
    }    
  }

  //Invoked by click of a screenName in the screenslist or by click of Continue, Previous Screen or Next Screen buttons
  openScreen(event){
    if(this.isChanged === false)
    {
      this.screenName = event.target.name;
      let btnClicked = event.target.dataset.id;

      if(btnClicked !== 'previousScreenBtn' && btnClicked !== 'nextScreenBtn')
      {
        this.determinePreviousOrNextScreen();
      }
      else if(btnClicked === 'previousScreenBtn')
      {
        this.determinePreviousOrNextScreen('Previous');
      }
      else if(btnClicked === 'nextScreenBtn')
      {
        this.determinePreviousOrNextScreen('Next');
      }

      this.openScreenBase(this.screenName);    
    }
    else
    {
      common.toastNotification("Unsaved Data, Please Save.",null,"warning")
    }
  }

  handleCancel(){
    this.isChanged = false;

    if(this.screenName === common.screenNamesEnum.DOC_ACCEP)
    {
      this.bypassRevilio = true;
      this.insuranceAmount = this.previousInsuranceAmount;
      this.insuranceDate = this.previousInsuranceDate;
    }
    if(this.screenName === common.screenNamesEnum.FRM_DOCS){
      getFormationScreenRecords({recordId:this.uwRecordId,screenName:this.screenName})
      .then(res => {  
        this.formationDocTable = res
        if(this.formationDocTable[0].reviewType === 'New'){
          this.isFormationDocScreen = true;
          this.step1Verified = formDoc.checkMasterBox(this.formationDocTable);
          this.step2Verified = formDoc.checkLegalName(this.formationDocTable);
          this.step3Verified = formDoc.checkFormOption(this.formationDocTable);
          upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[0].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step1Verified});
          upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[1].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step2Verified});
          upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[2].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step3Verified});
        }
      })
    }
    else{
      this.openScreenBase(this.screenName);
    }

    
  }

  handleChange(event)
  {
    var actionName = event.target.dataset.id;
    var value=event.target.value;
    var stepTitle = event.target.dataset.steptitle;

    if(this.screenName === common.screenNamesEnum.ENT_VER)
    {
      var rowIndex = event.target.dataset.index;
      var wrapperName = event.target.dataset.varname;
      var selectedCell= event.target.dataset.label;
      
      if(wrapperName === 'borrowerSOSList')
      {
        entityVerif.updateWrapper(this.borrowerSOSList[rowIndex].dataList,value,selectedCell);
        this.bflagsMap = entityVerif.constructFlags(this.steps, this.borrowerSOSList);
        this.bflags= Object.values(this.bflagsMap);
      }
      if(wrapperName === 'entitySOSList')
      {
          entityVerif.updateWrapper(this.entitySOSList[rowIndex].dataList,value,selectedCell);
          this.eflagsMap = entityVerif.constructFlags(this.steps, this.entitySOSList);
          this.eflags= Object.values(this.eflagsMap);
      }
      this.isAllStepsCompleted= entityVerif.allFlagsVerified({...this.bflagsMap, ...this.eflags});
    }
    else if(this.screenName === common.screenNamesEnum.ADDR_VER)
    {
      var selectedCell = event.target.dataset.label;
      var rowIndex = event.target.dataset.index;
      var steptitle = event.target.dataset.steptitle;
      if(steptitle === 'Owner home address match'){
        addressVerif.homeAddressChangeStepResult(event, this.uwRecordId, value, this.steps);
      } else {
        addressVerif.handleDataChange(event,this.accountsList[rowIndex],this.state,this.country,this.addressStandardizationObj);
      }
    }
    else if(this.screenName === common.screenNamesEnum.CBR_VER)
    {
      if(event.target.dataset.steptitle === 'Ownership Change')
      {
        cbrHelper.cbrOwnerChangeStepResult(event, this.uwRecordId, value, this.steps);
      }
    }
    else if(this.screenName === common.screenNamesEnum.OR_AND_EXCP)
    {
      let step = common.getStepByStepTitle(stepTitle, this.steps);  
      step.element1Wrapper.elementSelectedPicklistValue = value;

      if(step.element1Wrapper.elementSelectedPicklistValue === 'Yes' || step.element1Wrapper.elementSelectedPicklistValue === 'No')
        step.userAnswer = value;
      else if(step.element1Wrapper.elementSelectedPicklistValue === '(Select One)')
        step.userAnswer = null;
        

      var stepComp = false;

      if(step.element1Wrapper.elementSelectedPicklistValue === 'Yes' || step.element1Wrapper.elementSelectedPicklistValue === 'No')
        stepComp = true;

      
        upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:step.stepRecordId, stepResultRecordId:step.stepResultRecordId, usrAnswer:step.userAnswer, stepCompletedFlag:stepComp})
        .then(result => 
        {
          this.getScreenStepsResults(this.screenName);

         
          getScreensImperative({uwCaseOrNDARecId: this.recordId})
          .then(newresult => 
          {
            this.populateScreenPropertiesAndLists(this.screenName, newresult)
          })
          .catch(e => 
          {
          });
        })
        .catch(e => 
        {
        });

    }
    ////////////////////////////////////////////////////////////////////
    // Move to Underwriting, Doc Creation, Account Setup stage Screen //
    ////////////////////////////////////////////////////////////////////
    else if(this.screenName === common.screenNamesEnum.MOVE_TO_UW_STAGE || this.screenName === common.screenNamesEnum.MOVE_TO_DOC_CREATION_STAGE || this.screenName === common.screenNamesEnum.MOVE_TO_ACCT_SETUP_STAGE)
    {
      if(actionName === 'nextFollowUpDate')
      {
        this.buttonSpinner = true;       
        saveNextFollowUpdateDate({underwritingId:this.uwRecordId,dateValue:value})
        .then(result =>{
          this.buttonSpinner = false;
          this.defaultNextFollowUpDate = value;
        })
        .catch(error =>{
          this.buttonSpinner = false;
          this.defaultNextFollowUpDate = value;
        }); 
      }
    }
    // Doc Acceptance Screen //
    else if(this.screenName === common.screenNamesEnum.DOC_ACCEP)
    {
      if(actionName === 'getCoverageAmount'){
        if(event.target.value<(this.uwRecommendedCreditLine*0.75)){          
          common.toastNotification('Coverage is insufficient, it must be at least $'+(this.uwRecommendedCreditLine*0.75).toFixed(0).replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,'),null,'warning');
        }
        this.insuranceAmount = event.target.value;
        this.isChanged = true;
      }
      else if(actionName === 'getExpirationDate'){
        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        let yyyy = today.getFullYear();
        today = yyyy + '-' + mm + '-' + dd ;
        
          if(event.target.value>=today){
            this.insuranceDate = event.target.value;
            this.isChanged = true;
          }
          else{
            let step = common.getStepByStepTitle(stepTitle, this.steps);
            step.element2Wrapper.elementSelectedPicklistValue = null; 
            this.insuranceDate = null;
            this.isChanged = false;
            common.toastNotification('Expiration needs to be greater than '+today,null,'warning');
          }
          
      }
    }
    /////////////////////////////////////
    // Security Search & Filing Screen //
    /////////////////////////////////////
    else if(this.screenName === common.screenNamesEnum.SEC_SEARCH){

      if(varname === "billingCode"){        
        this.filing[index].searchBillingCode = value;
      }
      else if(varname === "searchType"){
        this.filing[index].searchType = value;
      }
      else if(varname === "certified"){
        if(checked === 'true'){
          this.filing[index].certified = false;
        }
        else if(checked === 'false'){
          this.filing[index].certified = true;
        }
      }
      else if(varname === "instructions"){
        this.filing[index].specialInstructions = value;
      }
      else if(varname === "filingType"){
        this.filing[index].filingType = value;
      }
      
    }
  }

  toggleBusinessVerificationTableCheckbox(event) 
  {
    businessDataVerificationScreenHelper.toggleTableCheckbox(event, this.borrowerDbaList);
  }
  
  //SAVE button on business verification screen
  saveBusinessVerification() 
  {
    //the server method should only execute on one screen
    if(this.isDataVerificationScreen)
    {
      this.buttonSpinner=true;
      this.pageMessage='';
      businessDataVerificationScreenHelper.scrapeBusinessVerificationTable(this.template.querySelectorAll('lightning-input') , this.borrowerDbaList);
   
      //execute save logic in apex class
      saveBusinessVerificationTable({bRows: this.borrowerDbaList, underwritingId: this.uwRecordId })
      .then(result => {
        this.pageMessage = result.resultString;
        
        if(this.pageMessage.includes('Successful') && !this.pageMessage.includes('Unable')){
          common.toastNotification(this.pageMessage, 'Save Complete',  'success');
        } else {
          common.toastNotification(this.pageMessage, 'Error', 'error');
        }
      
        //apex logic may have changed the table values, so need to re-get them from the helper class
        getborrowerDbaRows({uwCaseOrNDARecId: this.recordId})  
        .then(result2 => 
        {
          //map should always have a single key
          for (var key in result2) {
            if (result2.hasOwnProperty(key)) {
                //don't need toast error on save
                this.borrowerDbaList = result2[key];
            }
          }

          businessDataVerificationScreenHelper.applyBVStyles(this.template.querySelectorAll('lightning-input') , this.borrowerDbaList);

          //apex logic may have changed the screen step "completed" value, need to re-get them from the helper class
          this.queryStepsResultsAndScreens(this.screenName, false, true);
          this.buttonSpinner=false; //
        
        })
        .catch(error => 
        {
          this.error = error;
        });
      
      
      })
      .catch(e => {
      });
    }
  } 
    
  //Saves the entity and borrower table when save button is clciked.
  saveEntityVerificationTable()
  {  
    this.buttonSpinner=true;
    let allDataRows =[];

    for(let a of this.borrowerSOSList.concat(this.entitySOSList))
    {
      if(a.dataList)
      {
        for(let b of a.dataList)
        {
          if(b.picklistvalues)
          {
            if(b.key.includes('Foreign_Domestic')) 
            {
              b.picklistvalues=['Foreign', 'Domestic'];
            }
            else
            {
              b.picklistvalues=['Yes', 'No'];
            }
             
          }
        }
      }
      allDataRows.push(a);
    }


    entityVerif.saveWrapperToChartRow(allDataRows, this.recordId, this.steps).then(saveRes1 =>{
      if(saveRes1)
      {         
        this.borrowerSOSList=[];
        this.entitySOSList=[];

        // constructs the borrower and entity list.
        for(let data of saveRes1)
        { 
          if(data.rowType==='Borrower')
          {              
            for(let d of data.dataList)
            {
              if(d.picklistvalues)
              {
                d.picklistvalues = common.createOptionsListFromStringList( d.picklistvalues);
              }
            }
            this.borrowerSOSList.push(data);
          }
         if(data.rowType ==='Entity')
          {
            for(let d of data.dataList)
            {
              if(d.picklistvalues)
              {
                 d.picklistvalues = common.createOptionsListFromStringList(d.picklistvalues);
              }
            }
            this.entitySOSList.push(data);
          } 
        }
        // All the steps are completed.
         if(this.isAllStepsCompleted || (entityVerif.checkIfThisScreenAlreadyCompleted(this.requestStageScreensList)))
        {
          // constructs the argument for upsertStepAnswers. Argument takes stepRecordId and stepCompleted value.
          let stepRecInfo = {recInfo:[]}; 
          let allFlagsMap ={...this.bflagsMap, ...this.eflags};     
          for(let step of this.steps)
          {
              let jsonObj ={};
              jsonObj.stepRecId =step.stepRecordId;
              jsonObj.value= allFlagsMap[step.stepTitle+'_Verified'];
              stepRecInfo.recInfo.push(JSON.stringify(jsonObj));
          }
          
          // Upserts the all step answers in single save. 
          upsertStepAnswers({underwritingRecId:this.uwRecordId, stepInfo:JSON.stringify(stepRecInfo.recInfo), screenName:this.screenName}).then(upsertRes =>{
            //step answer upserted successfully. 
            if(upsertRes === 'success')
            {
              common.toastNotification('Success!', 'Record Saved successfully.','success');

              // refresh the screen.
              this.getScreenStepsResults(this.screenName);
              getScreensImperative({uwCaseOrNDARecId: this.recordId})
              .then(newresult => 
              {
                var conts = newresult;
                
                this.populateScreenPropertiesAndLists(this.screenName, this.uwCurrentStage, newresult);

                this.requestStageScreensList = common.requestStageScreensList; 
                this.isAllStepsCompleted =entityVerif.checkIfThisScreenAlreadyCompleted(this.requestStageScreensList);
                
                for(let screen of this.requestStageScreensList)
                {
                  if(screen.name ===common.screenNamesEnum.ENT_VER)
                  {
                    screen.isActive=true;
                  }
                }
                
                this.buttonSpinner = false;
              })
              //exception occured while upserting step answer.
              .catch(e => 
              {
                this.buttonSpinner=false;
                this.isAllStepsCompleted =false;
                common.toastNotification('Error!', 'Error occured while saving the record. '+e.message,'error');
              });
            }
            // something went wrong while upserting the step answer.
            else
            {
              this.buttonSpinner=false;
              this.isAllStepsCompleted =false;
              common.toastNotification('Error!', 'Error occured while saving the record.','error');
            }
          }).catch(e => 
            {
              this.buttonSpinner=false;
              this.isAllStepsCompleted =false;
              common.toastNotification('Error!', 'Error occured while saving the record. '+e.message,'error');
            })
        }
        //-end. 
        //chart row data saved successfully but not all the step records have been completed.
        else{
          this.buttonSpinner=false;
          this.isAllStepsCompleted =false;
          common.toastNotification('Success!', 'Record Saved successfully.','success');
        }
      }
      //chart row data insert failed.
      else
      {
        this.buttonSpinner=false;
        this.isAllStepsCompleted =false;
        common.toastNotification('Error!', 'Error occured while saving the record.','error');
      }
    });
  }

  /////////////////////////////
  // CBR VERIFICATION SCREEN //
  /////////////////////////////
  get suffixOptions(){
    var result = cbrHelper.getSuffixOptions();
    return result;
  }

  handleSuffixChange(event) {
    var i = event.target.dataset.index;
    this.cbrList[i].suffix = event.detail.value;
  }

  //run CBR button on cbr screen
  runCBRButton(event){
    if(this.isCBRScreen){
      this.pageMessage='';
      var i = event.target.dataset.index;
      this.cbrList[i].cbrClicked = true;
      clickRunCBRButton({cbrRows: this.cbrList, arrayIndex:i})
      .then(result => {
        this.pageMessage = result.resultString;
        this.cbrList[i].cbrPending = true;
        this.cbrList[i].cbrClicked = false;

        if(this.pageMessage.includes('CBR Report has been requested')){
          common.toastNotification(this.pageMessage, 'CBR Pull Requested', 'warning');
        } else {
          common.toastNotification(this.pageMessage, 'Error', 'error');
        }
      })
      .catch(e => {
        this.cbrList[i].cbrPending = false;
        this.cbrList[i].cbrClicked = false;
      });
      
    }
  }

  //Doc Acceptance Screen
  saveDocAcceptance(){
    this.buttonSpinner = true;
    setInsuranceData({accountId:this.initiatingAccountRecordId,insuranceAmount:this.insuranceAmount,insuranceDate:this.insuranceDate})
    .then(result =>{
      this.buttonSpinner = false;
      this.isChanged = false;
      common.toastNotification("Save Completed",null,"success");
      this.previousInsuranceAmount = this.insuranceAmount;
      this.previousInsuranceDate = this.insuranceDate;
      
    })
    .catch(error =>{    
      this.buttonSpinner = false;
      this.isChanged = false;
      common.toastNotification("Save Failed",null,"error");
    }) 
  }
 

  //SAVE button on cbr screen
  saveCBRTableButton() 
  { //the server method should only execute on one screen
    if(this.isCBRScreen)
    {
      this.buttonSpinner=true;
      this.pageMessage='';
      cbrHelper.scrapeCBRTable(this.template.querySelectorAll('lightning-input'), this.cbrList);
      var jl = JSON.stringify(this.cbrList);

      //execute save logic in apex class
      saveCbrTable({jsonRows: jl})
      .then(result => {
        this.pageMessage = result.resultString;
        if(this.pageMessage.includes('Success')){
          common.toastNotification(this.pageMessage, 'Save Complete', 'success');
        } else {
          common.toastNotification(this.pageMessage, 'Error', 'error');
        }
      
        //apex logic may have changed the table values, so need to re-get them from the helper class
        getCbrRows({ underwritingId: this.uwRecordId, initiatingAccountId: this.initiatingAccountRecordId, ndaId: this.ndaRecordId, uwCreatedDateTimeString: this.uwCreatedDateTimeString })
        .then(result5 => 
          {
            this.cbrList=result5;

            for (var key in result5) {
              if (result5.hasOwnProperty(key)) {
                  this.cbrList = result5[key];
              }
            } 

            //apex logic may have changed the screen step "completed" value, need to re-get them from the helper class
            this.queryStepsResultsAndScreens(this.screenName, false, true);


          })
        .catch(error => 
        {
          this.error = error;
          this.toggleIsLoaded();
        })
      })
      .catch(e => {
      });
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //Formation Document Screen

  toggleFormationCheckbox(event)
  {
    let index = event.target.dataset.index;
    let value = event.target.dataset.varname;
    let borrowerId = event.target.dataset.label;
    let data = event.target.dataset.value;

    if(data === 'false' || this.formationDocTable[index].formationOption === 'On File'){
      if(value === 'true'){
        this.formationDocTable[index].formationLinkCheck = false;
      }
      else if(value === 'false'){
        this.formationDocTable[index].formationLinkCheck = true;
      }
      this.isChanged = true;     
      this.step1Verified = formDoc.checkMasterBox(this.formationDocTable);  
      upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[0].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step1Verified});
    }
    else if (data === 'true'){
      validityCSCCheck({underwritingId:this.uwRecordId, borrowerId:borrowerId})
      .then(result =>{
        if(result){
          if(value === 'true'){
            this.formationDocTable[index].formationLinkCheck = false;
          }
          else if(value === 'false'){
            this.formationDocTable[index].formationLinkCheck = true;
          }
        this.isChanged = true;     
        this.step1Verified = formDoc.checkMasterBox(this.formationDocTable);  
        upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[0].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step1Verified});
        }
        else{
          common.toastNotification("No CSC Record has been found.","No Record","error");
        }
      })
    }
  }


  checkLegalName(event){    
    let index = event.target.dataset.index;
    let value = event.target.value;
    if(this.formationDocTable[index].relationshipName === value){
      this.formationDocTable[index].formationDocMatch = true;
      this.formationDocTable[index].formationDocLegalName = value;
    }
    else{
      this.formationDocTable[index].formationDocMatch = false;
      this.formationDocTable[index].formationDocLegalName = value;
    }
    this.isChanged = true;
    this.step2Verified = formDoc.checkLegalName(this.formationDocTable);
    upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[1].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step2Verified});
  }

  
  toggleFormOption(event){
    let index = event.target.dataset.index;
    let value = event.target.value;
    if(value === 'Yes'){
      this.formationDocTable[index].uploadedDocVaultMatch = true;
      this.formationDocTable[index].uploadedDocVault = value;
    }
    else{
      this.formationDocTable[index].uploadedDocVaultMatch = false;
      this.formationDocTable[index].uploadedDocVault = value;
    }
    this.isChanged = true;
    this.step3Verified = formDoc.checkFormOption(this.formationDocTable);
    upsertStepAnswer({uwCaseOrNDARecId:this.recordId, stepRecordId:this.steps[2].stepRecordId, stepResultRecordId:null,  usrAnswer:null, stepCompletedFlag:this.step3Verified});
  }

  /////////////////////////////////////
  // Security Search & Filing Screen //
  /////////////////////////////////////
  

  securitySearch(event){
    let varname = event.target.dataset.varname;
    let index = event.target.dataset.index;
    ssHelper.searchButtonPressed(varname,this.filing,index,this.screenName,this.uwRecordId)
    .then(result=>{
      this.filing = result;
    });
  }
  
  securityFiling(event){
    let varname = event.target.dataset.varname;
    let index = event.target.dataset.index;
    ssHelper.filingButtonPressed(varname,this.filing,index,this.screenName,this.uwRecordId,this.careAccountId)
    .then(result=>{
      this.filing = result;
    });
    
  }


  ///////////////////////////////
  // Formation Document Screen //
  ///////////////////////////////

  saveFormDocChartRows(){
    this.buttonSpinner = true;
    saveFormationDocChartRows({screenName:this.screenName, underwritingId:this.uwRecordId, data:this.formationDocTable})
    .then(result =>{
      this.formationDocTable = result;
      this.isChanged = false;
      this.buttonSpinner = false;
      common.toastNotification("Save Completed",null,"success");
      getScreensImperative({uwCaseOrNDARecId: this.recordId})
      .then(newresult =>{        
        this.populateScreenPropertiesAndLists(this.screenName, this.uwCurrentStage, newresult);
      });
    })
    .catch(error =>{
      common.toastNotification("Save Failure",null,'error');
      this.buttonSpinner = false;
    })
  }
  
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////
  //ADDRESS VERIFICATION SCREEN RELATED METHODS //
  ////////////////////////////////////////////////

  handleselect(event)
    {
     if(this.screenName === common.screenNamesEnum.ADDR_VER)
    {
        //this.selectedRecord = event.detail;
        let selectedRec =event.detail;
      
        if(selectedRec.recordId)
        {
         // if(this.validAccountsLookup.includes(selectedRec.recordId))
          //{
            this.selectedRecord=selectedRec;
            let rowIndex= event.target.dataset.index;
            this.accountsList[rowIndex].recordId = this.selectedRecord.recordId;
            this.accountsList[rowIndex].rowType ='Additional Location';
            this.accountsList.index =rowIndex;
      
            for(let ad of this.addressStandardizationObj.addressStandardization)
            {
              if(ad.rowType ==='Additional Location' && ad.index ===Number(rowIndex))
              {             
                ad.recordId = this.accountsList[rowIndex].recordId;
              }
            }
          /** }
          else
          {
              common.toastNotification('Please select a valid account tied to this care account','Error', 'Error!');
          }*/
        }
      }
      
      else if(this.screenName === common.screenNamesEnum.UNDERWRITING)
      {
        let selectedRec =event.detail;
        if(selectedRec.recordId)
        {
            this.selectedRecord=selectedRec; 
            uwVerif.updateAssignedCreditAnalyst(this.initiatingAccountRecordId,this.selectedRecord.recordId).then(uwres=>{
              if(uwres ==='success')
              {
                  common.toastNotification('Record updated successfully.', 'Success!','success');
              }
              else
              {
                common.toastNotification('Error occured while saving the record.','Error!','error');
              }
            })
        }
        else
        {
          this.selectedRecord={};
        }
        
      }
        
    }

    saveAddress()
    {
      this.buttonSpinnerSaveAddress=true;
      this.buttonSpinnerNewAddress=false;
     //convert all the comboxpicklist to listof strings
      
    // let allList = this.accountsList.concat(this.newAddress);
     let allList =this.accountsList;
     let isAddressVerificationNeedsRefresh =false;

     //added validation for address fields and lookup field.
     let dataIssue =addressVerif.validateAddressInfo(allList)
     if(dataIssue)
     {
      if(dataIssue === 'ADDRESSMISSING')  
      {
        common.toastNotification('One or more address data found missing - country/state/city/street.Please check.','Error!','error');
      }
      else if(dataIssue === 'NAMEMISSING')
      {
        common.toastNotification('Please select the account before saving the record.','Error!','error');
      }
      else if(dataIssue ==='POSTALCODEINVALID')
      {
        common.toastNotification('One or more postal code found missing or invalid.Please check.','Error!','error');
      }
        
      this.buttonSpinnerSaveAddress=false;
      return;
     }

     for(let a of allList)
     {
      for(let d of a.dataList)
       {
         if(d.isPickList)
         {
           d.picklistvalues= [];
         }
         else if(d.isLookup)
         {
          isAddressVerificationNeedsRefresh =true;
         }
       }
     }
   
    addressVerif.UpdateAddressInfo(allList, this.addressStandardizationObj.addressStandardization);
      
      //Update adress on address__c object 
      addressVerif.updateAddress(this.uwRecordId,this.ndaRecordId, allList).then(res =>{
        if(res ==='success')
        {
          
          
          addressVerif.fetchAddressWrapper(this.uwRecordId).then(addressRes=>{
          
            let addressIds=[];
            for(let data of addressRes)
           {
             addressVerif.populateCountryAndStatePickList(data, this.state, this.country);
             this.accountsList =addressRes;
             this.addressStandardizationObj = { addressStandardization:[] };
             this.addressStandardizationObj ={...this.addressStandardizationObj, ...addressVerif.standardizeAddresses(addressRes, addressVerif.addressStandardMap, this.addressStandardizationObj)}
             addressVerif.populateWrapper(this.accountsList, this.addressStandardizationObj);    
             
             if(data.rowType ==='Additional Location')
             {
              let recordIdsList =data.recordId.split(',');
               if(recordIdsList.length >1)
               {
                  addressIds.push(recordIdsList[1]); 
               }
             }
           }
            
              //update additional locations on NDA.
             addressVerif.updateAdditionalLocOnNDA(this.ndaRecordId, this.uwRecordId, addressIds).then(ndaLocUpdate  =>{
              if(ndaLocUpdate !=='success' && ndaLocUpdate !== 'no additional locations to insert or update')
              {
                common.toastNotification('Error!', 'Error occured while updating additional location on NDA. '+e.message,'error');
                this.buttonSpinnerSaveAddress=false;
              }
              else
              {
                this.buttonSpinnerSaveAddress=false;
                common.toastNotification('Success!', 'Record Saved successfully.','success');
    
                if(isAddressVerificationNeedsRefresh)
                {
                   addressVerif.fetchChartRowsForEntityVerification(this.uwRecordId, 'Borrower').then(entityScreenRefresh =>{
                    if(entityScreenRefresh ==='success')
                      {
                        this.getScreenStepsResults(this.screenName);
                        getScreensImperative({uwCaseOrNDARecId: this.recordId})
                        .then(newresult => 
                        {                        
                          this.populateScreenPropertiesAndLists(this.screenName, this.uwCurrentStage, newresult); 
                        })
                        //exception occured while upserting step answer.
                        .catch(e => 
                        {
                          common.toastNotification('Error!', 'Error occured while saving the record. '+e.message,'error');
                        });
                         
                      }
                   });
                }
              }
            }).catch(e => 
              {
                common.toastNotification('Error!', 'Error occured while saving the record. '+JSON.stringify(e),'error');
                this.buttonSpinnerSaveAddress=false;
              });
            //-end 
           
          })
            
        }
        else
        {
          for(let data of allList)
          {
            addressVerif.populateCountryAndStatePickList(data, this.state, this.country);
          } 
          this.buttonSpinnerSaveAddress =false;
          common.toastNotification('Error!','Error occured while saving the record. '+res,'error');
        }
    })
    .catch(e => 
      {
        for(let data of allList)
        {
          addressVerif.populateCountryAndStatePickList(data, this.state, this.country);
        } 
        this.buttonSpinnerSaveAddress=false;
        common.toastNotification('Error!', 'Error occured while saving the record. '+e.message,'error');
      });
    }

    createNewLocation()
    {
      try
      {
        this.buttonSpinnerNewAddress =true;
        this.accountsList.push(addressVerif.createNewAddress(this.accountsList, this.state, this.country));
        this.addressStandardizationObj ={...this.addressStandardizationObj, ...addressVerif.standardizeAddresses(this.accountsList, addressVerif.addressStandardMap, this.addressStandardizationObj)}

        this.buttonSpinnerNewAddress=false;
      }
      catch(e)
      {
        this.buttonSpinnerNewAddress=false;
        common.toastNotification('Error!', 'Error occured while creating new Location. '+JSON.stringify(e),'error');
      }
     
    }

    removeLocation(event)
    {
      var rowIndex = event.target.dataset.index;
      for(let n of this.accountsList)
      {
        if(n.index === Number(rowIndex))
        {
          addressVerif.removeElement(this.accountsList, n);
        }
     }  
    }

    toggleCheckBoxAddressVerification(event)
    {
      var rowIndex = event.target.dataset.index;
      addressVerif.toggleTableCheckbox(this.accountsList[rowIndex]);
    }

    openSelectCarePopup()
    {
      this.openSelectCareModal =true;
    }

    openSelectCareNumberPage()
    {
      window.open(this.selectCareNumberURL);
      this.closeSelectCareModal();
    }
    closeSelectCareModal()
    {
      this.openSelectCareModal =false;
    }

    /////////////////////////////////
    // Reg check case
    ////////////////////////////////
    openLink(event)
    {
      var caseId = event.target.dataset.caseid;
      window.open('/lightning/r/Case/'+caseId+'/view');
    }
    ////////////////////////////

    openWindowNewUnderwritingAudit()
    {
      var scr1 = this.screenName;
      if(scr1 === 'Welcome' || scr1 === common.screenNamesEnum.WELCOME){
        scr1 = '';
      }
      window.open('/flow/Underwriting_Audit_Create?underwritingRecordId='+this.uwRecordId+'&bwScreenName='+scr1+'&isPopupWindow=true&retURL=/lightning/n/Boarding_Wizard?c__id='+this.uwRecordId, '', "width=650,height=750,top=100,left=350"); 
    }
}