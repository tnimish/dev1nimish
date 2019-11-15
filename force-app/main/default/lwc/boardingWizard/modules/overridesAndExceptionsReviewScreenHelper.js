/**import getILOCIndicator from '@salesforce/apex/BWRequestStageHelper.getILOCIndicator';
import getPoorPerformanceIndicator from '@salesforce/apex/BWRequestStageHelper.getPoorPerformanceIndicator';
import getLimitedRestrictedMfrIndicator from '@salesforce/apex/BWRequestStageHelper.getLimitedRestrictedMfrIndicator';

function getPoorPerfInd(uwCareNum)
{
    let res;

    getPoorPerformanceIndicator({uwCareNumber: uwCareNum})
    .then(result =>
    {
        res = result;
    }).catch(error => 
    {
        this.error = error;
        console.log('Oops'+error);
    });

    return res;
}


function getILOCInd(uwCareNum)
{
    let res;

    getILOCIndicator({uwCareNumber: uwCareNum})
    .then(result =>
    {
        res = result;
    }).catch(error => 
    {
        this.error = error;
        console.log('Oops'+error);
    });

    return res;
}

function getLimitedRestrictedMfrInd(uwRecId)
{
    let res;

    getLimitedRestrictedMfrIndicator({uwRecordId: uwRecId})
    .then(result =>
    {
        res = result;
    }).catch(error => 
    {
        this.error = error;
        console.log('Oops'+error);
    });

    return res;
}

export {getPoorPerfInd, getILOCInd, getLimitedRestrictedMfrInd};*/