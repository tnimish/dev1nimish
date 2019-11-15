import * as common from './common.js';

import saveDataRowToChartRowEVT from '@salesforce/apex/BWRequestStageHelper.saveDataRowToChartRowEVT';
import fetchEVTTableDataRows from '@salesforce/apex/BWRequestStageHelper.fetchEVTTableDataRows';


//santosh-added address verification - to show none values
let defaultPicklistValue ='(Select One)';
    
  function constructFlags(steps, wrapper)
  {
    let eFlags ={};
    let stepToWrapper = {};

    for(let w of wrapper)
      {
        for(let d of w.dataList)
        {
          if(d.key)
          {
            addValueToKey(stepToWrapper, d.key,d.data);
          }
        }
      }
      for(let s of steps)
      {
        if(s.stepTitle!=='Engine_Location' && s.stepTitle!=='State_Province')
        {
          eFlags[s.stepTitle+'_Verified']=true;

          for(let d of stepToWrapper[s.stepTitle])
          {
            if(d ===defaultPicklistValue) 
            {
              eFlags[s.stepTitle+'_Verified']=false;
            }
            
          }
      }

      }
    return eFlags;
  }

 
    function allFlagsVerified(eFlags)
    {
      console.log('=== eFlags==='+JSON.stringify(eFlags));
      let allFlagsVer=true;
      
      let flags = Object.values(eFlags);
      for(let o of flags)
      {
        if(o===false) 
          return false;
      }
      return allFlagsVer;
    }

    function addValueToKey(stepToWrapper, key, value) 
    {
        stepToWrapper[key] = stepToWrapper[key] || [];
        stepToWrapper[key].push(value);
    } 

  

function updateWrapper(ListName, valueToset,selectedKey)
{
  for(let d of ListName)
  {
   // console.log('== d ==='+d);
    //console.log('=== selectedKey==='+selectedKey);
     if(d.key === selectedKey)
    {
      //console.log('=== i am inside===');
      d.data = valueToset;
    } 
  } 

}

//this method is called when save button is clicked on entity verification table.
function saveWrapperToChartRow(allRows, recordId, steps)
{
  console.log('=== allRows=='+allRows);
  console.log('=== recordId=='+recordId);
  console.log('=== steps=='+steps);
  // eslint-disable-next-line no-console
  return new Promise(
    (resolve, reject) =>{  
      saveDataRowToChartRowEVT({wrapperList:allRows, recordId:recordId, steps:steps})
  .then(res=>{
    if(res)
    {
      resolve(res);
    }
  })
  .catch(e => 
    {
      reject('Error occured while constructing borrower verification :'+JSON.stringify(e));
    });
})
}


  function checkIfThisScreenAlreadyCompleted(screenList)
  {
    for(let s of screenList)
    {
      // eslint-disable-next-line no-console
      if(s.name === common.screenNamesEnum.ENT_VER) return s.isCompleted;
    }
    return false;
  }
  function setEntityScreenResultOnLoad(screenList, actualValue)
  {
    for(let s of screenList)
    {
      // eslint-disable-next-line no-console
      if(s.name === common.screenNamesEnum.ENT_VER) 
        s.isCompleted=actualValue;
    }
    return false;
  }
 
 
  function fetchEVTDataTable(recordId, steps)
  {
        // eslint-disable-next-line no-alert
     return new Promise(
      (resolve, reject) =>{  
        fetchEVTTableDataRows({recordId: recordId, steps:steps }) 
        .then(newresult => 
        {
          // eslint-disable-next-line no-alert
          if(newresult)
          {
              resolve(newresult);
          }
        }).catch(e => 
          {
            reject('Error occured while constructing borrower constructDataRowsForEVT :'+e.message);
          });
        });
  }


  //export functions
export{constructFlags, updateWrapper, saveWrapperToChartRow, checkIfThisScreenAlreadyCompleted, fetchEVTDataTable, allFlagsVerified,setEntityScreenResultOnLoad};