/* eslint-disable vars-on-top */
/* eslint-disable no-console */
// eslint-disable-next-line no-unused-vars
import constructAddressWrapper from '@salesforce/apex/BWRequestStageHelper.constructAddressWrapper';
import fetchAddressStandardizationMap from '@salesforce/apex/BWRequestStageHelper.fetchAddressStandardizationMap';
import updateAddressInformation from '@salesforce/apex/BWRequestStageHelper.updateAddressInformation';
import fetchInitAccountAddress from '@salesforce/apex/BWRequestStageHelper.fetchInitAccountAddress';
import fetchValidAccountsForCare from '@salesforce/apex/BWRequestStageHelper.fetchValidAccountsForCare';
import upsertStepResultWithDetail from '@salesforce/apex/BWRequestStageHelper.upsertStepResultWithDetail';
import {validateZipCode} from './common.js';
import refreshEntityVerification from '@salesforce/apex/BWRequestStageHelper.refreshEntityVerification';
import updateNDAAndAdditionalLocations from '@salesforce/apex/BWRequestStageHelper.updateNDAAndAdditionalLocations';

let addressStandardMap =new Map();

//let Headertitle=['Name','First Name','Middle Name','Last Name','Street','City','State','Postal Code','Country','Standardized Address', 'Use Standarized Address'];
//let addressHeaderTitle =['Name','Street','City','State','Postal Code','Country','Standardized Address', 'Use Standarized Address'];
let Headertitle=['Name','Type','First Name','Middle Name','Last Name','Country','State','City','Street','Postal Code','Standardized Address', 'Use Standardized Address'];


function fetchAddressWrapper(recordId)
{
    return new Promise(
        (resolve, reject) =>{  
            constructAddressWrapper({recordId: recordId }) 
          .then(newresult => 
          {
            // eslint-disable-next-line no-alert
            if(newresult)
            {
                resolve(newresult); 
            }
          }).catch(e => 
            {
              reject('Error occured while constructing the address wrapper :'+JSON.stringify(e));
            });
          });
}

function fetchAddressMap()
{
    return new Promise(
        (resolve, reject) =>{  
            fetchAddressStandardizationMap() 
          .then(newresult => 
          {
            // eslint-disable-next-line no-alert
            if(newresult)
            {
                resolve(newresult); 
            }
          }).catch(e => 
            {
              reject('Error occured while constructing the address wrapper :'+JSON.stringify(e));
            });
          });
}

function standardizeAddress(a,addressMap, addressStandardization)
{
    console.log('=== addressMap ==='+addressMap);
    for(let d of a.dataList)
    {  
        let msg='';
        if(d.key.toLowerCase()!=='recordtype.developername' && d.key.toLowerCase()!=='standardized address' && d.key.toLowerCase()!=='name' && d.key.toLowerCase()!=='first_name__c' && d.key.toLowerCase()!=='middle_i__c' && d.key.toLowerCase()!=='last_name__c' && d.key.toLowerCase()!=='type' && d.key.toLowerCase()!=='use standardized address' && d.data)
        {
             console.log('=== d.key ==='+d.key+'=== d.data ==='+d.data);
             for(let st of d.data.split(' '))
            {
                console.log('=== st ==='+st);
                st=st.toLowerCase().replace(',', ' ');
                console.log('===after  st ==='+st);
                if(st)
                {
                    if(addressMap.has(st)) 
                  {
                      msg+=' '+makeFirstLetterCapitalize(addressMap.get(st));
                  }
                  else
                  {
                      msg+=' '+makeFirstLetterCapitalize(st);
                  }
                }
                
            }
        }
        if(d.key) addressStandardization[d.key]=msg; 
    }
    
    // eslint-disable-next-line no-console
    addressStandardization.message='';
    addressStandardization.message=constructStandarizedAddress(addressStandardization);
    return addressStandardization;
}

function constructStandarizedAddress(addressStandardization)
{
  console.log('==== addressStandardization ==='+addressStandardization);
  let standarizedAddress='';
  if(addressStandardization.billingstreet)
  {
    standarizedAddress+=' '+addressStandardization.billingstreet+',\n';
  }
  if(addressStandardization.billingcity)
  {
    standarizedAddress+=' '+addressStandardization.billingcity+',\n';
  }
  if(addressStandardization.billingstate)
  {
    standarizedAddress+=' '+addressStandardization.billingstate+',\n';
  }
  if(addressStandardization.billingpostalcode)
  {
    standarizedAddress+=' '+addressStandardization.billingpostalcode+',\n';
  }
  if( addressStandardization.billingcountry)
  {
    standarizedAddress+=' '+addressStandardization.billingcountry;
  }
  
  console.log('=== standarizedAddress ==='+standarizedAddress);
  return standarizedAddress;
}
function makeFirstLetterCapitalize(st)
{
    let changedStr ='';
    if(st)
    {
      if(st.length ===1)
      {
        changedStr= st[0].toUpperCase();
      }
      else
      {
        // eslint-disable-next-line no-sequences
        changedStr= st[0].toUpperCase()+st.slice(1);
      }  
      
    }
    return changedStr;
}
function standardizeAddresses(List, addressMap, addressStandardizationObj)
{   
    console.log('=== addressMap ===='+addressMap);
    for(let a of List)
    {
        let addressStandardization ={};
       
        addressStandardization.recordId = a.recordId;
        addressStandardization.index= a.index;

        if(a.isNew)
        {
            addressStandardization.rowType ='Additional Location';
        }
        else 
        {
          addressStandardization.rowType =a.rowType;
        } 
        addressStandardizationObj.addressStandardization.push(standardizeAddress(a, addressMap, addressStandardization));
    }
     
        return addressStandardizationObj;
}

function populateWrapper(List,addressStandardizationObj)
{
    for(let a of List)
    {
        updateWrapper(a, addressStandardizationObj);
    }
}

function updateWrapper(a, addressStandardizationObj)
{
    for(let acc of addressStandardizationObj.addressStandardization)
        {
          console.log('=== acc.index ==='+typeof acc.index+'=== a.index ==='+typeof a.index);

          if(/**a.recordId === acc.recordId  &&*/ a.index ===acc.index)
            {
                for(let d of a.dataList)
                {
                    if(d.key === 'Standardized Address')
                    {
                        
                        d.data ='';
                        d.data = acc.message;
                        console.log('=== a.index ==='+a.index+'=== acc.index ==='+acc.index+'=== d.data ==='+d.data);
                    }
                }
            }
        }
}

function UpdateAddressInfo(List, addressStandardization)
{
   
    for(let ad of addressStandardization)
	{
		for(let a of List)
		{
            if(a.recordId === ad.recordId && a.index === ad.index)
          {
                    let useStandardization=false;
                    for(let d of a.dataList)
                    {
                      //santosh-added fix for Address standardization issue.bug#8
                      if(d.key.toLowerCase() ==='use standardized address')
                      {
                        useStandardization=d.booleanData;
                        break;
                      }
                    }
                    if(useStandardization)
                    {
                      if(ad.message)
                      {
                        for(let d of a.dataList)
                        { 
                          //only modifies billingstreet,billingcity,billingstate & billingcountry.
                          if(d.key.toLowerCase() ==='billingstreet' || d.key.toLowerCase() ==='billingcity' || d.key.toLowerCase() === 'billingstate' || d.key.toLowerCase() === 'billingcountry')
                          {
                            d.data = ad[d.key];
                          }
                         
                        }
                      }
                    }
          }
		}
	}
}

function updateAddress(recordId,ndaId, List)
{
    return new Promise(
        (resolve, reject) =>{  
            updateAddressInformation({recordId:recordId,  ndaId:ndaId, wrapperList: List }) 
          .then(res => 
          {
            // eslint-disable-next-line no-alert
            if(res)
            {
                resolve(res); 
            }
          }).catch(e => 
            {
              reject('Error occured while updating the address wrapper :'+JSON.stringify(e));
            });
          });
}

function createNewAddress(List, state, country)
{
   let newRec = {
        index: List.length,
        dataList:[]
     };
   newRec.isNew= true;
   newRec.chartData = {};
   newRec.chartData.Data__c='';

   //let fields =['name', 'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry'];
   // eslint-disable-next-line no-unused-vars
   let fields =['name','firstname, middlename', 'lastname','billingcountry','billingstate','billingbity', 'billingstreet', 'billingpostalcode' ];

   for(let f of Headertitle)
   {
     
      let fArray ={};
      fArray.key =f; 
      if(fArray.key.toLowerCase() ==='name')
      {
        fArray.isLookup =true;
      }
      else if(fArray.key.toLowerCase() ==='type')
      {
        fArray.data ='New Location';
        fArray.key='Recordtype.DeveloperName';
        fArray.isReadOnly =true;
      }
      else if(fArray.key.toLowerCase() ==='first name' ||  fArray.key.toLowerCase() ==='middle name'  || fArray.key.toLowerCase() ==='last name' )
      {
        if(fArray.key.toLowerCase() ==='first name')
        {
          fArray.key ='First_Name__c'; 
        }
        if(fArray.key.toLowerCase() ==='middle name')
        {
          fArray.key ='Middle_I__c'; 
        }
        if(fArray.key.toLowerCase() ==='last name')
        {
          fArray.key='Last_Name__c';
        }
        fArray.isReadOnly =true;
      }
      else if(fArray.key.toLowerCase() ==='street')
      {
        fArray.isTextArea =true;
        fArray.key ='billingstreet'; 
      }
      else if(fArray.key.toLowerCase() ==='city')
      {
        fArray.isTextInput =true;
        fArray.key ='billingcity'; 
      }
      else if(fArray.key.toLowerCase() ==='postal code')
      {
        fArray.isTextInput =true;
        fArray.key ='billingpostalcode'; 
      }
      else if(fArray.key.toLowerCase()==='state')
      {
        fArray.isPickList  =true;
        fArray.picklistvalues =state;
        fArray.key ='billingstate';
      }
     
      else if(fArray.key.toLowerCase()==='country')
      {
        fArray.isPickList  =true;
        fArray.picklistvalues =country;
        fArray.key ='billingcountry';
      }
      else if(fArray.key.toLowerCase() ==='standardized address')
      {
        fArray.isReadOnly =true;
      }
      else if(fArray.key.toLowerCase() ==='use standardized address')
      {
        fArray.isBoolean =true;
        fArray.isBooleanData =false;
      }
      else 
      {
        fArray.isTextInput =true;
      }
        
      newRec.dataList.push(fArray);
      console.log('=== newRec ==='+JSON.stringify(newRec));
    
   }
   /**let fArray={};
   fArray.key= 'Address Standardization';
   fArray.isReadOnly =true;
   newRec.dataList.push(fArray);

   let fArray1={};
   fArray1.key= 'Use this address';
   fArray1.isBoolean =true;
   fArray1.isBooleanData =false;
   newRec.dataList.push(fArray1);
   */
   return newRec;
}

function viewDocumentsOnSharePoint(careNumber)
{
  window.open('https://tcfifsharepoint.sf.tcf.biz/sites/ip/PortalDashboards/CareOnly.aspx?q='+careNumber);
}

function fetchInitiatingAccountAddress(accountId)
{
  return new Promise(
    (resolve, reject) =>{  
        fetchInitAccountAddress({accountId: accountId }) 
      .then(newresult => 
      {
        // eslint-disable-next-line no-alert
        if(newresult)
        {
            resolve(newresult); 
        }
      }).catch(e => 
        {
          reject('Error occured while constructing the address wrapper :'+JSON.stringify(e));
        });
      });
}

function toggleTableCheckbox(List)
{
  for(let d of List.dataList)
  {
    //console.log('=== d.key ==='+d.key); 
    if(d.key === 'Use Standardized Address')
      d.booleanData = !d.booleanData;
    console.log('=== d.booleanData ==='+d.booleanData); 
  }
}

function removeElement(array, elem) {
  var index = array.indexOf(elem);
  if (index > -1) {
      array.splice(index, 1);
  }
}

function populateCountryAndStatePickList(data, state, country)
{
  let key;  
  console.log('=== state ==='+JSON.stringify(state));
  for(let d of data.dataList)
    {
      if(d.picklistvalues)
      {
        if(d.key.toLowerCase() ==='billingcountry') 
        {
          d.picklistvalues =country;
          key = state.controllerValues[d.data];
        }
        if(d.key.toLowerCase() ==='billingstate') 
        {
          d.picklistvalues =state.values;
        }
      }
    } 
    
    for(let d of data.dataList)
    {
      if(d.key.toLowerCase() ==='billingstate') 
      {
        // eslint-disable-next-line no-loop-func
        d.picklistvalues =state.values.filter(opt => opt.validFor.includes(key));
      }
    } 
}

function handleDataChange(event, a, state, country, addressStandardizationObj)
   {
		var selectedCell = event.target.dataset.label;
    //var accountId = event.target.dataset.varname;
    var value=event.target.value;
    var rowIndex = event.target.dataset.index;

		for(let d of a.dataList)
        {
          if(d.key === selectedCell)
          {
            d.data = value;
          }
        }
		
		if(selectedCell.toLowerCase() === 'billingcountry')
		{
      populateCountryAndStatePickList(a, state, country);
      
      for(let d of a.dataList)
      {
        if(d.key.toLowerCase() === 'billingstate')
        {
          d.data = '';
        }
      }
		}
		
		for(let ad of addressStandardizationObj.addressStandardization)
    {
     // if((accountId && ad.recordId === accountId) || (ad.index === Number(rowIndex)))
       if(ad.index === Number(rowIndex))
      {  
        ad.message='';
        // eslint-disable-next-line import/namespace
        ad=standardizeAddress(a, addressStandardMap, ad);
        console.log('**** after ad update ****'+ad);
      }
    }
    updateWrapper(a, addressStandardizationObj);
  }

  function validateAddressInfo(accounts)
  {
      let dataIssue;
      let countriesToValidate = ['united states', 'canada'];

      for(let a of accounts)
      {
        console.log('=== a.recordId ==='+a.recordId);
        let country= '';
        if(!a.recordId)
        {
            dataIssue = 'NAMEMISSING';
            console.log('=== dataissue ==='+dataIssue);
            return dataIssue;
        }
        for(let d of a.dataList)
        {
          
          if(d.key.toLowerCase() ==='billingstreet' || d.key.toLowerCase()==='billingcity' || 
             d.key.toLowerCase() ==='billingcountry')
            {
              if(!d.data) 
              {
                dataIssue = 'ADDRESSMISSING';
                return dataIssue;
              }
              else if(d.key.toLowerCase() ==='billingcountry' && d.data )
              {
                country =d.data;
              }
            }
            else if(d.key.toLowerCase() ==='billingstate')
            {
              console.log('=== countriesToValidate.includes(country.toLowerCase()) ==='+countriesToValidate.includes(country.toLowerCase()));
              console.log('=== d.data ==='+d.data);
              if(countriesToValidate.includes(country.toLowerCase()))
              {
                if(!d.data)
                {
                  dataIssue = 'ADDRESSMISSING';
                  return dataIssue;
                }
              }
            }
              else if(d.key.toLowerCase()==='billingpostalcode')
            {
              
              if(!d.data || (countriesToValidate.includes(country.toLowerCase()) && !validateZipCode(d.data, country))) 
              {
                dataIssue = 'POSTALCODEINVALID';
                return dataIssue;
              }
            } 
        }
      }
      return dataIssue;
  }

  function fetchValidAccountIdsForLookup(recordId)
{
    return new Promise(
        (resolve, reject) =>{  
          fetchValidAccountsForCare({uwId: recordId }) 
          .then(newresult => 
          {
            // eslint-disable-next-line no-alert
            if(newresult)
            {
                resolve(newresult); 
            }
          }).catch(e => 
            {
              reject('Error occured while fetching valid accountIds for lookup :'+JSON.stringify(e));
            });
          });
}

function homeAddressChangeStepResult(event, underwritingId, value, stepArray){
  if(event.target.dataset.steptitle === 'Owner home address match'){
    var longDetail = '';
    var comp = event.target.dataset.stepcompleted;
    if(value === 'Home address does not match DL/CBR'){
      longDetail = 'At least one owner has a home address that does not match their ID (DL) or the address from CBR report.  A utility bill is required.';
      comp = true;
    } else if(value === 'All home addresses match DL/CBR'){
      longDetail = 'All owner home addresses verified to match their DL or CBR report.  No utility bill should be required.';
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

function fetchChartRowsForEntityVerification(uwId, type)
{
  return new Promise(
    (resolve, reject) =>{  
      refreshEntityVerification({recordId: uwId, type:type}) 
      .then(newresult => 
      {
        // eslint-disable-next-line no-alert
        if(newresult)
        {
            resolve(newresult); 
        }
      }).catch(e => 
        {
          reject('Error occured while constructing the address Map :'+JSON.stringify(e));
        });
      });
}

function updateAdditionalLocOnNDA(ndaId, underwritingId, addressIds)
{
    return new Promise(
        (resolve, reject) =>{  
          updateNDAAndAdditionalLocations({ndaId: ndaId, underwritingId:underwritingId, addressIds:addressIds }) 
          .then(newresult => 
          {
            // eslint-disable-next-line no-alert
            if(newresult)
            {
                resolve(newresult); 
            }
          }).catch(e => 
            {
              reject('Error occured while updating additional locations on NDA :'+JSON.stringify(e));
            });
          });
}



export {Headertitle}
export {fetchAddressWrapper, addressStandardMap,fetchAddressMap, standardizeAddresses,populateWrapper, standardizeAddress,updateWrapper,UpdateAddressInfo,
  updateAddress,createNewAddress,viewDocumentsOnSharePoint,fetchInitiatingAccountAddress,toggleTableCheckbox, removeElement,populateCountryAndStatePickList
  ,handleDataChange,validateAddressInfo,fetchValidAccountIdsForLookup, homeAddressChangeStepResult,fetchChartRowsForEntityVerification,updateAdditionalLocOnNDA};