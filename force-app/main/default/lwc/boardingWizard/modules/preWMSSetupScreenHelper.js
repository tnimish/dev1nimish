import fetchAllWMSChangeFormCases from '@salesforce/apex/BWAccountSetupStageHelper.fetchAllWMSChangeFormCases';

function constructAllWMSChangeFormCases(underwritingId)
{
    return new Promise( 
        (resolve, reject) =>{
            fetchAllWMSChangeFormCases({underwritingId:underwritingId})
         .then(newResult =>{
            console.log('===  newresult =='+newResult); 
            if(newResult)
             {
                resolve(newResult);
             }
            
         }).catch(e => 
             {
               reject('Error occured while inserting the WMS Change Form case :'+JSON.stringify(e));
             });
        } 
     )
}

export{constructAllWMSChangeFormCases};