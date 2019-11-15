public with sharing class UtilityClass {
    
    public static String getSObjectTypeName(SObject so) 
    {
      return so.getSObjectType().getDescribe().getName();
    }
    
    public static List<string> getPicklistValues(string objectApiName, string fieldApiName)
    {
      List<string> picklistValuesList = new List<string>();

      String[] types = new String[]{objectApiName};

      Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
      for(Schema.DescribeSobjectResult res : results) {
         for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldApiName).getDescribe().getPicklistValues()) {
            if (entry.isActive()) {pickListValuesList.add(entry.getValue());}
         }
      }
              
      return pickListValuesList;
    }

    public static String getMonthNameFromNumber(Integer monthNum, String dateformat)        
    {       
      String monthName;     
            
      if(dateformat == 'US_EN' || dateformat == 'CA_EN' || dateformat == 'AU_EN' || dateformat == 'NZ_EN')      
      {     
        if(monthNum == 1)       
          monthName = 'January';        
        else if(monthNum == 2)      
          monthName = 'February';       
        else if(monthNum == 3)      
          monthName = 'March';      
        else if(monthNum == 4)      
          monthName = 'April';      
        else if(monthNum == 5)      
          monthName = 'May';        
        else if(monthNum == 6)      
          monthName = 'June';       
        else if(monthNum == 7)      
          monthName = 'July';       
        else if(monthNum == 8)      
          monthName = 'August';     
        else if(monthNum == 9)      
          monthName = 'September';      
        else if(monthNum == 10)     
          monthName = 'October';        
        else if(monthNum == 11)     
          monthName = 'November';       
        else if(monthNum == 12)     
          monthName = 'December';       
      }     
      else if(dateformat == 'CA_FR')        
      {     
        if(monthNum == 1)       
          monthName = 'Janvier';        
        else if(monthNum == 2)      
          monthName = 'Février';        
        else if(monthNum == 3)      
          monthName = 'Mars';       
        else if(monthNum == 4)      
          monthName = 'Avril';      
        else if(monthNum == 5)      
          monthName = 'Mai';        
        else if(monthNum == 6)      
          monthName = 'Juin';       
        else if(monthNum == 7)      
          monthName = 'Juillet';        
        else if(monthNum == 8)      
          monthName = 'Août';       
        else if(monthNum == 9)      
          monthName = 'Septembre';      
        else if(monthNum == 10)     
          monthName = 'Octobre';        
        else if(monthNum == 11)     
          monthName = 'Novembre';       
        else if(monthNum == 12)     
          monthName = 'Décembre';       
      }     
                
        return monthName;       
    }
    
    //Method that queries the ContentDocumentLink records associated with the passed records list and creates a record for each doclink record
    //for which a record with the doclink's linkedentityid and contentdocumentid does not already exist in UploadToSharePoint__c object.
    public static void createSharepointDocUploadRecordsForListOfLinkedEntityIds(List<id> linkedEntityIdsList)
    {      
      Map<id, List<id>> linkedEntityIdToContentDocumentIdsListMap = new Map<id, List<id>>();
      Map<id, string> cdocIdToContentTypeMap = new Map<id, string>();
      
       Map<string, boolean> contentTypeToUploadFlagMap = new Map<string, boolean>();
      //Check to see if there is already an existing sharepoint integration record with the same linkedEntityId and DocumentId      
      List<ObjectDocCategoriesAndContentTypes__mdt> oList = [select id, DocType__c, upload_content_to_sharepoint__c from ObjectDocCategoriesAndContentTypes__mdt];
      
      for(ObjectDocCategoriesAndContentTypes__mdt o: oList)
      {
        contentTypeToUploadFlagMap.put(o.DocType__c, o.Upload_Content_to_Sharepoint__c); 
      }
      
      //Create a map of ContentDocumentLink id to ContentDocumentLink record
      Map<string, ContentDocumentLink> cdlIdToCdlRecordMap = new Map<string, ContentDocumentLink>();
      
      List<ContentDocumentLink> cdlList = [select id, LinkedEntityId, ContentDocumentId, ContentDocument.latestpublishedVersion.contentType__c from ContentDocumentLink where linkedEntityId in :linkedEntityIdsList and ContentDocument.FileType != 'SNOTE' and ContentDocument.latestPublishedVersion.ContentType__c != '' and ContentDocument.latestPublishedVersion.ContentType__c != 'Not Uploaded to Sharepoint' and ContentDocument.latestPublishedVersion.Uploaded_to_network_storage__c = null];
      
      if(cdlList != null && cdlList.size() > 0)
      {
        for(ContentDocumentLink c: cdlList)
        {
          cdlIdToCdlRecordMap.put(c.id, c);
        }
      }
      //
      
      for(Id linkedEntityId: linkedEntityIdsList)
      {      
        List<id> contentDocumentIdsList = new List<id>();
        
        //List<ContentDocumentLink> cdlList = [select id, LinkedEntityId, ContentDocumentId, ContentDocument.latestpublishedVersion.contentType__c from ContentDocumentLink where linkedEntityId in :linkedEntityIdsList and ContentDocument.FileType != 'SNOTE' and ContentDocument.latestPublishedVersion.ContentType__c != '' and ContentDocument.latestPublishedVersion.ContentType__c != 'Not Uploaded to Sharepoint' and ContentDocument.latestPublishedVersion.Uploaded_to_network_storage__c = null];
                
        for(ContentDocumentLink cdl: cdlIdToCdlRecordMap.values())
        {
          if(cdl.linkedEntityId == linkedEntityId)
          {
            contentDocumentIdsList.add(cdl.ContentDocumentId);   
            cdocIdToContentTypeMap.put(cdl.ContentDocumentId, cdl.ContentDocument.latestPublishedVersion.ContentType__c);
          }
        }
        
        system.debug(contentDocumentIdsList);
        
        linkedEntityIdToContentDocumentIdsListMap.put(linkedEntityId, contentDocumentIdsList);
      }
      
      Set<string> existingExternalIdsSet = new Set<string>();
  
      for(DocVault_To_Sharepoint_Upload__c dtsu: [select id, linkedEntity__c, ContentDocument__c from DocVault_To_Sharepoint_Upload__c where uploadedtosharepoint__c = false and linkedEntity__c in: linkedEntityIdToContentDocumentIdsListMap.keyset()])
      {
        existingExternalIdsSet.add(dtsu.linkedEntity__c+'-'+dtsu.ContentDocument__c);
      } 
      
      //Create a list of DocVault_To_Sharepoint_Upload__c to insert
      List<DocVault_To_Sharepoint_Upload__c> uploadRecordsList = new List<DocVault_To_Sharepoint_Upload__c>();
      
      for(Id linkedEntityId: linkedEntityIdToContentDocumentIdsListMap.keyset())
      {
        for(Id cDocId: linkedEntityIdToContentDocumentIdsListMap.get(linkedEntityId))
        {
          if(!existingExternalIdsSet.contains(linkedEntityId+'-'+cDocId) && contentTypeToUploadFlagMap.get(cdocIdToContentTypeMap.get(cDocId)) == true)
            uploadRecordsList.add(new DocVault_To_Sharepoint_Upload__c(linkedEntity__c = linkedEntityId, ContentDocument__c = cdocId, ContentType__c = cdocIdToContentTypeMap.get(cdocId)));
        }
      }
      
      if(uploadRecordsList != null && uploadRecordsList.size()>0)
      {
        insert uploadRecordsList;
      }
    }
    
    public static Boolean validateEmail(String email) 
    {
      Boolean res = true;
      String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: <a href="http://www.regular-expressions.info/email.html" target="_blank" rel="nofollow">http://www.regular-expressions.info/email.html</a>
      Pattern MyPattern = Pattern.compile(emailRegex);
      Matcher MyMatcher = MyPattern.matcher(email);
      
      if(!MyMatcher.matches())
        res = false;
      
      return res;
    }
    
    public static string shareFilesWithThisTargetRecord(string sourceRecId, string targetRecId, List<ContentDocumentLink> sourceDocLinksList)
    {
      if(!string.isBlank(targetRecId) && !string.isBlank(sourceRecId) && sourceDocLinksList != null)
      {
        List<ContentDocumentLink> cdlListToInsert = new List<ContentDocumentLink>();

        for(ContentDocumentLink cdl:  sourceDocLinksList)
        { 
          ContentDocumentLink cdl2 = new ContentDocumentLink();
          cdl2.contentDocumentId=cdl.ContentDocumentId;
          cdl2.linkedEntityId = targetRecId;
          cdl2.shareType='V';
          cdl2.visibility='AllUsers';
          cdlListToInsert.add(cdl2);
        }
        
        insert cdlListToInsert;
      }

      

      return null;
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    /**This method is triggered from loanAfterInsertTrigger And DocVault. 
       In LoanAfterInsert - selectedDocLinkIds is passed as null - (targetId,sourceId,null)  //////
       In DocVaultVFC - sourceObjectId is passed as null (targetId,null,selecteddocIds)      */                     
    //////////////////////////////////////////////////////////////////////////////////////////////////
    public static void migrateDocsFromSourceRecordsToTargetRecord(string targetRecordId, string sourceObjectId, Set<Id> selectedDocLinkIds)
 {      
      System.debug('==== targetRecordId ==='+targetRecordId);
      System.debug('==== selectedDocLinkIds==='+selectedDocLinkIds);
      if(!String.isBlank(targetRecordId) )
      { 
             string sourceCDLIds;
             string targetCDLIds;
             String mainQuery='';
             List<ContentDocumentLink> cdlListToInsert = new List<ContentDocumentLink>();
             List<ContentDocumentLink> sourceDocLinks  = new List<ContentDocumentLink>();
 
             String query ='SELECT ContentDocumentId, ContentDocument.LatestPublishedVersion.ContentSize, ContentDocument.LatestPublishedVersion.FileType, ContentDocument.LatestPublishedVersion.PathOnClient, ContentDocument.LatestPublishedVersion.VersionNumber, ContentDocument.LatestPublishedVersion.LastModifiedDate, ContentDocument.LatestPublishedVersionId, ShareType, LinkedEntityId FROM ContentDocumentLink';
 
             if(selectedDocLinkIds!=null && selectedDocLinkIds.size() >0)
             {
                  mainQuery = query+' WHERE ID IN:selectedDocLinkIds';
                   System.debug('==== mainQuery ===='+mainQuery);
                  sourceDocLinks=Database.query(mainQuery);
             }
            else if(!String.isBlank(sourceObjectId) && selectedDocLinkIds==null)
            {
                String sNote='SNOTE'; 
                String notUploaded ='Not Uploaded to Sharepoint';
                String blank='';
                String whereClause= 'and ContentDocument.FileType !=:sNote and ContentDocument.latestPublishedVersion.ContentType__c != null and ContentDocument.latestPublishedVersion.ContentType__c !=:blank and ContentDocument.latestPublishedVersion.ContentType__c !=:notUploaded';
                
                  //determine objectType
                 String objectName=getSObjectNameFromId((Id)sourceObjectId);
                 System.debug('=== objectName ==='+objectName);

                 if(objectName == 'Case')
                 {              
                      List<string> acctIdsList = new List<string>();
                      id careAcctId;
                      Case c =[select id, Care_Number__c from case where id=:sourceObjectId limit 1];
                      System.debug('=== c ==='+c);
                      for(Account a: [select id, care_number__c, care_number__r.name from account where care_number__r.name = :c.care_number__c])
                      {
                          acctIdsList.add(a.id);
                          careAcctId=a.care_number__c;
                      }
                      
                      acctIdsList.add(careAcctId);
                      String caseId= c.id;
                      mainQuery=query+'  WHERE (LinkedEntityId = :caseId or LinkedEntityId in: acctIdsList) '+whereClause;
                      sourceDocLinks=Database.query(mainQuery);
                 }
                 else if(objectName == 'Account')
                 {
                        List<string> acctIdsList = new List<string>();
      
                        for(Account a: [select id from account where care_number__c = :sourceObjectId ])
                        {
                          acctIdsList.add(a.id);
                        }
                        
                        acctIdsList.add(sourceObjectId);
                        
                         mainQuery=query+'  WHERE LinkedEntityId in :acctIdsList '+whereClause;
                         sourceDocLinks=Database.query(mainQuery);
                 }
            
            }
          System.debug('==== mainQuery ===='+mainQuery);
          
          if(sourceDocLinks!=null && sourceDocLinks.size() >0)
          {
               
               System.debug('==== sourceDocLinks ===='+sourceDocLinks);
               
               for(ContentDocumentLink cdl:  sourceDocLinks )
              {
                ContentDocumentLink cdl2 = new ContentDocumentLink();
                cdl2.contentDocumentId=cdl.ContentDocumentId;
                cdl2.linkedEntityId = targetRecordId;
                cdl2.shareType='V';
                cdl2.visibility='AllUsers';
                cdlListToInsert.add(cdl2);
                
                //Create a string of source contentdocumentlink Ids to log error if deletion of those contentdocumentlink records fails
                if(String.isBlank(sourceCDLIds))
                {
                  sourceCDLIds = 'ContentDocumentId = '+ cdl.ContentDocumentId+ ' | LinkedEntityId='+cdl.linkedEntityId;
                }
                else
                {
                  sourceCDLIds = sourceCDLIds + ', \r\nContentDocumentId = '+ cdl.ContentDocumentId+ ' | LinkedEntityId='+cdl.linkedEntityId;
                }
                
                //Create a string of target contentdocumentlink Ids to log error if insertion of those contentdocumentlink records fails
                if(String.isBlank(targetCDLIds))
                {
                  targetCDLIds = 'ContentDocumentId = '+ cdl.ContentDocumentId+ ' | LinkedEntityId='+targetRecordId;
                }
                else
                {
                  targetCDLIds = targetCDLIds + ', \r\nContentDocumentId = '+ cdl.ContentDocumentId+ ' | LinkedEntityId='+targetRecordId;
                }     
              }
                       
              if(cdlListToInsert != null && cdlListToInsert.size()>0)
              {
                try
                {  
                  insert cdlListToInsert;
                }
                catch(Exception e)
                {
                  UtilityClass.logError(e, 'DocVault', '', 'Content Document Link record not inserted for : '+targetCDLIds);
                }
                
                try
                {
                  delete sourceDocLinks;
                }
                catch(Exception e)
                {
                  //WI 3111 - added to ignore insufficient access issue while deleting contentdocumentLinks
                  if(!e.getMessage().contains('INSUFFICIENT_ACCESS'))
                  {
                      UtilityClass.logError(e, 'DocVault', '', 'Content Document Link record not deleted for : '+sourceCDLIds);
                  }
                }
                
              } 
          }
          
      }
    } 
    
  //This method logs exception message to an error__c record  
  public static void logError(Exception excp, string category, string ndaId, string infoStr1)
  {
    try
    {
      Error__c e = new Error__c();
      e.Name = category;
      e.Custom_Message__c = infoStr1;        
      e.Message__c = category;
      if(excp!=null){
          e.Line_Number__c = excp.getLineNumber();
          e.Message__c = (excp.getCause()+': '+excp.getMessage()).left(255);
          e.Stack_Trace_String__c = excp.getStackTraceString();
          e.Type_Name__c = excp.getTypeName();
      }
      
      if(ndaId != null && ndaId != '')
        e.NewDealerApplication__c = ndaId;
      
      System.debug('==== e ==='+e);  
      insert e;
    }
    catch(Exception ex)
    {
      system.debug(ex);
    }
    
    /*if(chatterParentRecordId != null && chatterParentRecordId != '')
    {
      FeedItem post = new FeedItem();
      post.ParentId = chatterParentRecordId;
      post.Body = 'Exception Type: '+excp.getTypeName()+'\r\n Exception Cause: '+excp.getCause()+ '\r\n Exception Line Number: '+excp.getLineNumber()+'\r\n Exception Message: '+excp.getmessage()+'\r\n Exception Stack Trace: '+excp.getStackTraceString();
      insert post;
    }*/
}

//This method returns the error object - if insert/Update/Delete ran from Database class 
  public static error__c createError(Database.Error err, string category, string ndaId, string infoStr1)
  {
  
      Error__c e = new Error__c();
      e.Name = category;
      e.Custom_Message__c = infoStr1;
      
      //Santosh- added for WI 2193
      e.Message__c = category;
      if(err!=null){
          e.Message__c+=' ' +err.getStatusCode();
      }
       
      if(ndaId != null && ndaId != '')
        e.NewDealerApplication__c = ndaId;
        
      return e;
 }

/** Santosh -added for BugFix Wi 0770 - returns a boolean value that determines whether a record is locked. This class is used in 
 ConsolidatedBusinessFinancialsVFC, RelationshipCreditExceptionsVFC, UnderwritingRequestConditionsVFC, URAssetVerificationTableVFC, URBorrowerInfoVFC, URDnBResponsesVFC and URSummaryInfoVFC */
  public Static boolean setrecordLocked(Underwriting__c loan){
        Map<id, boolean> URProfileNamemap = new Map<Id, boolean>(); 
        boolean locked = false;
        User loggedInUser =  [select Profile.Name from User where Id = :Userinfo.getUserId()][0];
        List<UnderwritingProfileAccess__c> URProfileName = UnderwritingProfileAccess__c.getAll().Values();
         
         for(UnderwritingProfileAccess__c  slr: URProfileName){
         
         // Santosh - added for bugFix on consolidated Business financial recordLocked issue -07Mar2017
         /**  if(loggedInUser.Profile.Name == slr.ProfileName__c)
              URProfileNamemap.put(Userinfo.getUserId(), true); */
            
            String loggedInUserProfile = loggedInUser.Profile.Name.deleteWhitespace().toLowerCase();  
            String customSettingProfile = slr.ProfileName__c.deleteWhitespace().toLowerCase(); 
             
              if(loggedInUserProfile.equals(customSettingProfile))
                  URProfileNamemap.put(Userinfo.getUserId(), true);
           //- end
           }
        
          if(Userinfo.getUserId()!= null && URProfileNamemap.get(Userinfo.getUserId())!= null && URProfileNamemap.get(Userinfo.getUserId()))
        {
                  locked =  Constants.URLockedRTIds.contains(loan.RecordTypeId);         
        }                  
        else
        {
         locked = true;
        }
        
        return locked;
    }

    public static String getSObjectNameFromId(Id id)
    {
        return id.getSObjectType().getDescribe().getName();
    }
    
     public static user integrationUser{
     get{
         if(integrationUser == NULL){
           user u = [select id, name from user where profile.Name = 'Integration User' LIMIT 1];
           return u;
         }
          return integrationUser;
     }
     set;
    }
    
  
      public static Map<String, Org_Wide_Email_Address_Data__c> orgEmailCustomMap
    {
        get
        {   
            if(orgEmailCustomMap== NULL)
            {
                orgEmailCustomMap = new Map<String, Org_Wide_Email_Address_Data__c>();
                 
                List<Org_Wide_Email_Address_Data__c> customOrgEmailDataList  = [select id, name, Email_Address__c, Other_Exceptions__c, Profile_Issue__c, Unverified__c, Username__c, Is_Found__c,Exception_Message__c    from Org_Wide_Email_Address_Data__c];
                  
                for(Org_Wide_Email_Address_Data__c orgData: customOrgEmailDataList)
                {   
                    orgEmailCustomMap.put(orgData.Email_Address__c, orgData);
                }            
            }
              
              return orgEmailCustomMap;
        }
        set;
     }
     
     public Project__c p
     {
        get
        {
          if(p == null)
          {
             p = [select id from Project__c where name='Backlog' limit 1];
          }
          return p;
        }
        set;
     }
    
   public user assignWIUser
   {
       get
       {
           if(assignWIUser ==null)
           {
               assignWIUser =[select id from user where email='azielinski@tcfif.com' limit 1];
           }
           
           return assignWIUser;
       }set;
    }
   
  public String projectRecordTypeId
  {
     get
     {
         if(projectRecordTypeId == NULL)
         {
             projectRecordTypeId  =[select id from recordType where sObjectType='Work_Item_projects__c' and DeveloperName='Bug' limit 1].id;
         }
         return projectRecordTypeId; 
     }
     Set;
  }
  
/**
 public class emailValidationClass
    {
        Messaging.SingleEmailMessage mail;
        boolean isValid;
        String errorMessage;
        
        public emailValidationClass( Messaging.SingleEmailMessage msg, boolean isValidData)
        {
           mail =msg;
           isValid = isValidData;
        }
        
    }   
    
public  static List<Messaging.SingleEmailMessage> validateSenderEmailAddressAndLogError(List<Messaging.SingleEmailMessage> emailsToValidate,   List<OrgWideEmailAddress> listAnalystEmails )
{   
    Map<id, String> orgWideMap = new Map<Id, String>();
    List<Messaging.SingleEmailMessage> validEmailMessage = new List<Messaging.SingleEmailMessage>();
    List<Messaging.SingleEmailMessage> inValidEmailMessage = new List<Messaging.SingleEmailMessage>();
    List<error__c> errorList = new List<error__c>();
    List<Work_Item_projects__c> workItemsList = new List<Work_Item_projects__c>();
    
    List<emailValidationClass> wrapperEmailList = new List<emailValidationClass>();
    
   
    for(OrgWideEmailAddress org: listAnalystEmails)
    {
        orgWideMap.put(org.id, org.Address);
    }
    
    System.debug('==== orgWideMap ==='+orgWideMap);
    
    for(Messaging.SingleEmailMessage msg: emailsToValidate)
    {
        System.debug('===== msg.getOrgWideEmailAddressId()=== '+msg.getOrgWideEmailAddressId()+'==== msg ==='+msg);
        
        if(orgWideMap.containsKey(msg.getOrgWideEmailAddressId()))
        {
            String senderEmail =  orgWideMap.get(msg.getOrgWideEmailAddressId());
            System.debug('==== senderEmail ===='+senderEmail);
            
            System.debug('==== orgEmailCustomMap.containsKey(senderEmail) ===='+orgEmailCustomMap.containsKey(senderEmail)+'==== orgEmailCustomMap============='+orgEmailCustomMap);
            if(orgEmailCustomMap.containsKey(senderEmail))
            {
                if(!orgEmailCustomMap.get(senderEmail).Other_Exceptions__c && !orgEmailCustomMap.get(senderEmail).Profile_Issue__c && !orgEmailCustomMap.get(senderEmail).Unverified__c)
                {
                        emailValidationClass wrapper = new emailValidationClass(msg, TRUE);
                        wrapperEmailList.add(wrapper);
                }
                
                else
                {
                   System.debug('=== i am in else part ====');
                   
                   emailValidationClass wrapper = new emailValidationClass(msg, FALSE);
                   
                   System.debug('=== in else wrapper  ===='+wrapper );
                    
                    if(orgEmailCustomMap.get(senderEmail).Other_Exceptions__c)
                    {
                        if(orgEmailCustomMap.get(senderEmail).Exception_Message__c!=NULL)
                            wrapper.errorMessage = orgEmailCustomMap.get(senderEmail).Exception_Message__c;
                    }
                    
                    else if(orgEmailCustomMap.get(senderEmail).Profile_Issue__c)
                    {
                        wrapper.errorMessage = 'Profile Not correctly setup for User '+msg.getToAddresses();
                    }
                    
                    else if(orgEmailCustomMap.get(senderEmail).Unverified__c)
                    {
                        wrapper.errorMessage = 'Email address unverified for the user '+msg.getToAddresses();
                    }
                    
                  /**   else if(!orgEmailCustomMap.get(senderEmail).Is_Found__c)
                    {
                        wrapper.errorMessage = 'Email address was not found/processed in custom org data.Email is no more Valid. '+msg.getToAddresses();
                    }
                    
                   / 
                   wrapperEmailList.add(wrapper);
                   System.debug('==== wrapperEmailList ===='+wrapperEmailList);
                }
            }
            
            else
            {   
                // User found in orgWide Email address list not in our customOrg Setup
                System.debug('===== i am in else condition====');
                emailValidationClass wrapper = new emailValidationClass(msg, FALSE);
                wrapper.errorMessage = 'Email Address setup missing in Custom Org Wide Data object but found in organization-wide Address list '+msg.getToAddresses();
                wrapperEmailList.add(wrapper);
                 System.debug('===== i am in else condition===='+wrapperEmailList);
                
            }
        }
        
   /**     else 
        {
             emailValidationClass wrapper = new emailValidationClass(msg, FALSE);
             wrapper.errorMessage = 'user not found in organization-wide Address. Please set up the user in organization-wide Address list for '+msg.getToAddresses();
             wrapperEmailList.add(wrapper);
             
            // OrgWide Email address is missing and WI should be created and assign to Z
 
            workItemsList.add(createWI(wrapper.errorMessage));
        }    /
        
    }
     
     
     if(wrapperEmailList!=NULL && wrapperEmailList.size() >0)
     {
        for(emailValidationClass w :wrapperEmailList)
        {
            if(w.isValid)
            {
               validEmailMessage.add(w.mail);
            }
            
            else if(!w.isValid)
            {
               inValidEmailMessage.add(w.mail); 
               error__c e= new error__c(message__c = w.errorMessage.left(255), custom_message__c =w.errorMessage);
               errorList.add(e);
            }
            
        }
     }
     
     
   //  if(workItemsList!=NULL && workItemsList.size() >0)
     //   insert workItemsList;
        
     if(errorList!=NULL && errorList.size() > 0)
        insert errorList;
     
     System.debug('====== workItemsList===='+workItemsList);    
     System.debug('====== errorList===='+errorList); 
     System.debug('====== validEmailMessage ===='+validEmailMessage); 
     System.debug('====== inValidEmailMessage ===='+inValidEmailMessage); 
     
     return validEmailMessage;
  }
  */
  
  public static Map<String, boolean> validateSenderEmailAddressAndLogError(Set<String> emailsToValidate)
    {   
        Map<id, String> orgWideMap = new Map<Id, String>();
        List<error__c> errorList = new List<error__c>();
        List<Work_Item_projects__c> workItemsList = new List<Work_Item_projects__c>();
        Map<String, boolean> senderEmailValidationResultMap = new Map<String, boolean>();
        
        for(String senderEmail: emailsToValidate)
        {
                System.debug('==== orgEmailCustomMap.containsKey(senderEmail) ===='+orgEmailCustomMap.containsKey(senderEmail)+'==== orgEmailCustomMap============='+orgEmailCustomMap);
                String message='';
                
                if(orgEmailCustomMap.containsKey(senderEmail))
                {
                    if(!orgEmailCustomMap.get(senderEmail).Other_Exceptions__c && !orgEmailCustomMap.get(senderEmail).Profile_Issue__c && !orgEmailCustomMap.get(senderEmail).Unverified__c)
                    {
                         senderEmailValidationResultMap.put(senderEmail, TRUE);
                    }
                    
                    else
                    {
                       
                        
                        if(orgEmailCustomMap.get(senderEmail).Other_Exceptions__c)
                        {
                            if(orgEmailCustomMap.get(senderEmail).Exception_Message__c!=NULL)
                                message = orgEmailCustomMap.get(senderEmail).Exception_Message__c;
                        }
                        
                        else if(orgEmailCustomMap.get(senderEmail).Profile_Issue__c)
                        {
                            message = 'Profile Not correctly setup for User '+senderEmail;
                        }
                        
                        else if(orgEmailCustomMap.get(senderEmail).Unverified__c)
                        {
                            message = 'Email address unverified for the user '+senderEmail;
                        }
                         senderEmailValidationResultMap.put(senderEmail, FALSE);
                    }
                }
                else
                {   
                    // User found in orgWide Email address list not in our customOrg Setup
                    message = 'Email Address setup missing in Custom Org Wide Data object but found in organization-wide Address list '+senderEmail;
                    senderEmailValidationResultMap.put(senderEmail, FALSE);
                }
                
                 if(!String.isBlank(message))
                 {
                    errorList.add(new error__c(name='Sender Email Invalid', message__c = message.left(255), custom_message__c =message));
                 }
        }
                 
        if(errorList!=NULL && errorList.size() > 0)
        {
            List<Database.SaveResult> dsrList= Database.insert(errorList, false);
            utilityClass.processSaveResult(dsrList, 'Error record in validateSenderEmailAddressAndLogError',errorList);
        }
       
         return senderEmailValidationResultMap;
      }
  
     public Work_Item_projects__c createWI(String message)
     {
         // Work_Item_projects__c wi= new Work_Item_projects__c(Project__c = p.id, Department__c='Portfolio Control', Priority__c= '1', Type_of_Work__c='Configuration', Current_Environment__c ='Production', Enhancement_Description__c = message, Assigned_Tester__c=assignWIUser.Id, recordTypeId=projectRecordTypeId, name__c='Org Wide Email Address Creation');
          Work_Item_projects__c wi= new Work_Item_projects__c( Department__c='Portfolio Control', Priority__c= '1', Type_of_Work__c='Configuration', Current_Environment__c ='Production', Enhancement_Description__c = message, name__c='Org Wide Email Address Creation');
          System.debug('===== wi ===='+wi);
          return wi;
     }
     
     public Static String parseStringReplaceCharacters(String value)
     {
      
         Map<String, String> characterMap = new Map<String, String>{
             '<' =>  '&lt;', 
             '>' =>  '&gt;'
           };
         
         for(String s: characterMap.keySet())
         {
             if(value.contains(s))
             {
                 value = value.replaceAll(s, characterMap.get(s));
             }
            
         }

         return value;
     }
     
     public String missingUsersinOrgWideEmailAddress(Set<String> userIds)
 {
     String userInfoStr = '';
     
    Map<String, user> userIdToUserEmailMap = new Map<String, user>();
    for(user u: [select id, Name, email from user where id IN: userIds])
    {
        userIdToUserEmailMap.put(u.email, u);
    }
    
    for(String s: userIdToUserEmailMap.keySet())
     {
         if(!orgEmailCustomMap.containsKey(s))
              userInfoStr+= (userInfoStr == ''? '': ',') + (userIdToUserEmailMap.get(s).Name + ' - '+ userIdToUserEmailMap.get(s).email); 
     }
     
     return userInfoStr;
 }
 
  public Map<String, List<sObject>> getAllRecordsProcessForThisBatch(AsyncApexJob a, user u, Set<String> Objects, Map<String, Set<String>> RecordTypes, String BatchJobName )
   {
       Map<String, List<sObject>> recordTypeTosObject = new Map<String, List<sObject>>();
       
       try
       {
           String userid =u.id;
           
           for(String s: Objects)
           {
                 
                    String objectType = s.substringAfterLast(',');
                    String operationType= s.contains('isCreated')? 'Insert': s.contains('isUpdated')? 'Update': '';
                    String query ='';
                    
                    DateTime StartTime = a.CreatedDate;
                    DateTime endTime = a.CompletedDate;
                    Date todayDate= Date.Today();
                    
                    if(s.contains('isCreated'))
                    {
                         if(!s.substringAfterLast(',').contains('Error__c'))
                            query = 'SELECT id, RecordTypeId from ' +s.substringAfterLast(',') + ' where createdDate>=:StartTime AND createdDate <=:endTime and createdById=:userid';
                         
                         else if( s.substringAfterLast(',').contains('Error__c'))
                            query = 'SELECT id from ' +s.substringAfterLast(',') + ' where createdDate>=:StartTime AND createdDate <=:endTime and createdById=:userid';
                    }
    
                    else if(s.contains('isUpdated'))
                    {
                           if(!s.substringAfterLast(',').contains('Error__c'))
                               query = 'SELECT id, RecordTypeId from ' +s.substringAfterLast(',') + ' where lastModifiedDate>=:StartTime AND lastModifiedDate<=:endTime and lastModifiedById=:userid and createdDate <:todayDate';
                           
                           else if( s.substringAfterLast(',').contains('Error__c'))
                                query = 'SELECT id from ' +s.substringAfterLast(',') + ' where lastModifiedDate>=:StartTime AND lastModifiedDate<=:endTime and lastModifiedById=:userid and createdDate <:todayDate';
                    }
    
                    if(!String.isBlank(query) && RecordTypes.containsKey(s.substringAfterLast(',')) && RecordTypes.get(s.substringAfterLast(','))!=NULL)
                    {     
                        Set<String> recordTypestoQuery = RecordTypes.get(s.substringAfterLast(','));
                        query = query+ 'AND '+'RecordTypeId IN:recordTypestoQuery';
                    }             
                    
                    System.debug('==== query ==='+query);
                    
                    for (SObject o : database.query(query))  
                    {
                        
                        String recTypeId ='';
                        
                        if(!s.substringAfterLast(',').contains('Error__c'))
                        {
                           recTypeId= String.ValueOf(o.get('RecordTypeId'));
                        }
                        
                        if(recordTypeTosObject.get(objectType+','+recTypeId +','+operationType) == NULL)    
                        {
                            recordTypeTosObject.put(objectType+','+recTypeId +','+operationType, new List<sObject>{o});
                        }
                        
                        else
                            recordTypeTosObject.get(objectType+','+recTypeId +','+operationType).add(o);
                    } 
    
              }
          }
          
          catch(exception e)
          {
              utilityClass.logError(e, 'exception caught in record Processing', '', BatchJobName+'-'+e.getMessage());
          } 
          return recordTypeTosObject;
     }
     
     public void sendEmail(Set<String> allEmails,  Map<String, List<sObject>> recordTypeTosObject, String status, String BatchJobName )
     {  
        try
        {
            messaging.singleEmailMessage mail = new messaging.singleEmailMessage();       
            String[] toAddresses = new String[]{};
            toAddresses.addAll(allEmails);
            mail.setToAddresses(toAddresses);
            mail.setSubject(' Batch Job Status: ' + status);
            string htmlBody = '<div> ';
            
            List<String> splitStr1= new List<String>();
             
            for(String s: recordTypeTosObject.keySet())
             {
                 if(!String.isBlank(s.split(',')[1]))
                     splitStr1.add(s.split(',')[1]);
             }
             
             System.debug('===== splitStr1 ===='+splitStr1);
             
             Map<Id, RecordType> rectypeMap;
             
            if(splitStr1!=NULL && splitStr1.size() > 0)
                  rectypeMap = new Map<Id, RecordType>([select id, Name from RecordType where id IN: splitStr1]);
             
            if(recordTypeTosObject!=NULL && recordTypeTosObject.size() > 0)
            {
                for(String s: recordTypeTosObject.keySet())
                {
                    List<String> splitStr = s.split(',');
                    String operationType= splitStr[2].contains('Insert')? 'Created': splitStr[2].contains('Update')? 'Updated': ''; 
                    String recordTypeName ='';
                    
                    if(!String.isBlank(splitStr[1]) && rectypeMap!=NULL && rectypeMap.containsKey(splitStr[1]))
                    {
                        recordTypeName = rectypeMap.get(splitStr[1]).Name;
                    }
                       
                    htmlBody += '<table style="width:100%;align="left";"><tr>'+recordTypeName+' '+ splitStr[0] + ' have been '+ operationType +' :'+ recordTypeTosObject.get(s).size();
                    htmlBody += '</tr> </table> </div>';
                }
            }
            
            else
            {
                    htmlBody += '<table style="width:100%;align="left";"><tr> No records have been created';
                    htmlBody += '</tr> </table> </div>';
            } 
            
            System.debug('====== htmlBody ====='+htmlBody);
            
            mail.setHtmlBody(htmlBody);
            Messaging.SendEmailResult [] r =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    
       }
       catch(exception e)
       {
           utilityClass.logError(e, 'exception caught in Email Creation', '', BatchJobName+'-'+e.getMessage());
       }
  } 
  
  public static Map<string, string> createStateCodeToStateNameMap(string countryCode)
  {
    Map<string, string> stateCodeToNameMap = new Map<string, string>(); 
    
    if(countryCode == 'US')
    {
      //US STATES 
      stateCodeToNameMap.put('AL','Alabama');
      stateCodeToNameMap.put('AK','Alaska');
      stateCodeToNameMap.put('AZ','Arizona');
      stateCodeToNameMap.put('AR','Arkansas');
      stateCodeToNameMap.put('CA','California');
      stateCodeToNameMap.put('CO','Colorado');
      stateCodeToNameMap.put('CT','Connecticut');
      stateCodeToNameMap.put('DE','Delaware');
      stateCodeToNameMap.put('DC','District of Columbia');
      stateCodeToNameMap.put('FL','Florida');
      stateCodeToNameMap.put('GA','Georgia');
      stateCodeToNameMap.put('HI','Hawaii');
      stateCodeToNameMap.put('ID','Idaho');
      stateCodeToNameMap.put('IL','Illinois');
      stateCodeToNameMap.put('IN','Indiana');
      stateCodeToNameMap.put('IA','Iowa');
      stateCodeToNameMap.put('KS','Kansas');
      stateCodeToNameMap.put('KY','Kentucky');
      stateCodeToNameMap.put('LA','Louisiana');
      stateCodeToNameMap.put('ME','Maine');
      stateCodeToNameMap.put('MD','Maryland');
      stateCodeToNameMap.put('MA','Massachusetts');
      stateCodeToNameMap.put('MI','Michigan');
      stateCodeToNameMap.put('MN','Minnesota');
      stateCodeToNameMap.put('MS','Mississippi');
      stateCodeToNameMap.put('MO','Missouri');
      stateCodeToNameMap.put('MT','Montana');
      stateCodeToNameMap.put('NE','Nebraska');
      stateCodeToNameMap.put('NV','Nevada');
      stateCodeToNameMap.put('NH','New Hampshire');
      stateCodeToNameMap.put('NJ','New Jersey');
      stateCodeToNameMap.put('NM','New Mexico');
      stateCodeToNameMap.put('NY','New York');
      stateCodeToNameMap.put('NC','North Carolina');
      stateCodeToNameMap.put('ND','North Dakota');
      stateCodeToNameMap.put('OH','Ohio');
      stateCodeToNameMap.put('OK','Oklahoma');
      stateCodeToNameMap.put('OR','Oregon');
      stateCodeToNameMap.put('PA','Pennsylvania');
      stateCodeToNameMap.put('TN','Tennessee');
      stateCodeToNameMap.put('RI','Rhode Island');
      stateCodeToNameMap.put('SC','South Carolina');
      stateCodeToNameMap.put('SD','South Dakota');
      //WI 3056 santosh- 01.15.19 Corrected code from TN To TX
      stateCodeToNameMap.put('TX','Texas');
      stateCodeToNameMap.put('UT','Utah');
      stateCodeToNameMap.put('VT','Vermont');
      stateCodeToNameMap.put('VA','Virginia');
      stateCodeToNameMap.put('WA','Washington');
      stateCodeToNameMap.put('WV','West Virginia');
      stateCodeToNameMap.put('WI','Wisconsin');
      stateCodeToNameMap.put('WY','Wyoming');
      stateCodeToNameMap.put('AS','American Samoa');
      //WI 3056 Santosh-  01.15.19 added additional states
      stateCodeToNameMap.put('GU','Guam');
      stateCodeToNameMap.put('MH','Marshall Islands');
      stateCodeToNameMap.put('FM','Micronesia');
      stateCodeToNameMap.put('MP','Northern Marianas');
      stateCodeToNameMap.put('PW','Palau');
      stateCodeToNameMap.put('PR','Puerto Rico');
      stateCodeToNameMap.put('VI','Virgin Islands');
    }
    else if(countryCode == 'CA')    
    {
      //CANADIAN PROVINCES
      stateCodeToNameMap.put('AB','Alberta');
      stateCodeToNameMap.put('BC','British Columbia');
      stateCodeToNameMap.put('MB','Manitoba');
      stateCodeToNameMap.put('NB','New Brunswick');
      stateCodeToNameMap.put('NL','Newfoundland and Labrador');
      stateCodeToNameMap.put('NS','Nova Scotia');
      stateCodeToNameMap.put('ON','Ontario');
      stateCodeToNameMap.put('PE','Prince Edward Island');
      stateCodeToNameMap.put('QC','Quebec');
      stateCodeToNameMap.put('SK','Saskatchewan');
      stateCodeToNameMap.put('NT','Northwest Territories');
      stateCodeToNameMap.put('NU','Nunavat');
      stateCodeToNameMap.put('YT','Yukon');  
    }
    else if(countryCode == 'AU')
    {
      //Australian provinces and territories
      stateCodeToNameMap.put('ACT','Australian Capital Territory');
      stateCodeToNameMap.put('NSW','New South Wales');
      stateCodeToNameMap.put('NT','Northern Territory');
      stateCodeToNameMap.put('QLD','Queensland');
      stateCodeToNameMap.put('SA','South Australia');
      stateCodeToNameMap.put('TAS','Tasmania');
      stateCodeToNameMap.put('VIC','Victoria');
      stateCodeToNameMap.put('WA','Western Australia');
    }
    else if(countryCode == 'NZ')
    {
      //New Zealand provinces and territories
      stateCodeToNameMap.put('AUK', 'Auckland');
      stateCodeToNameMap.put('BOP', 'Bay of Plenty');
      stateCodeToNameMap.put('CAN', 'Canterbury');
      stateCodeToNameMap.put('GIS', 'Gisborne');
      stateCodeToNameMap.put('HKB', 'Hawke\'s Bay');
      stateCodeToNameMap.put('MBH', 'Marlborough');
      stateCodeToNameMap.put('MWT', 'Manawatu-Wanganui');
      stateCodeToNameMap.put('NSN', 'Nelson');
      stateCodeToNameMap.put('NTL', 'Northland');
      stateCodeToNameMap.put('OTA', 'Otago');
      stateCodeToNameMap.put('STL', 'Southland');
      stateCodeToNameMap.put('TAS', 'Tasman');
      stateCodeToNameMap.put('TKI', 'Taranaki');
      stateCodeToNameMap.put('WKO', 'Waikato');
      stateCodeToNameMap.put('WGN', 'Wellington');
      stateCodeToNameMap.put('WTC', 'West Coast');
      stateCodeToNameMap.put('CIT', 'Chatham Islands Territory');
    }
    
    return stateCodeToNameMap;  
  }

  public static Map<string, string> createStateNameToStateCodeMap(string countryCode)
  {
    Map<string, string> stateNameToCodeMap = new Map<string, string>();
    
    if(countryCode == 'US')
    {
      //US STATES 
      stateNameToCodeMap.put('Alabama','AL');
      stateNameToCodeMap.put('Alaska','AK');
      stateNameToCodeMap.put('Arizona','AZ');
      stateNameToCodeMap.put('Arkansas','AR');
      stateNameToCodeMap.put('California','CA');
      stateNameToCodeMap.put('Colorado','CO');
      stateNameToCodeMap.put('Connecticut','CT');
      stateNameToCodeMap.put('Delaware','DE');
      stateNameToCodeMap.put('District of Columbia','DC');
      stateNameToCodeMap.put('Florida','FL');
      stateNameToCodeMap.put('Georgia','GA');
      stateNameToCodeMap.put('Hawaii','HI');
      stateNameToCodeMap.put('Idaho','ID');
      stateNameToCodeMap.put('Illinois','IL');
      stateNameToCodeMap.put('Indiana','IN');
      stateNameToCodeMap.put('Iowa','IA');
      stateNameToCodeMap.put('Kansas','KS');
      stateNameToCodeMap.put('Kentucky','KY');
      stateNameToCodeMap.put('Louisiana','LA');
      stateNameToCodeMap.put('Maine','ME');
      stateNameToCodeMap.put('Maryland','MD');
      stateNameToCodeMap.put('Massachusetts','MA');
      stateNameToCodeMap.put('Michigan','MI');
      stateNameToCodeMap.put('Minnesota','MN');
      stateNameToCodeMap.put('Mississippi','MS');
      stateNameToCodeMap.put('Missouri','MO');
      stateNameToCodeMap.put('Montana','MT');
      stateNameToCodeMap.put('Nebraska','NE');
      stateNameToCodeMap.put('Nevada','NV');
      stateNameToCodeMap.put('New Hampshire','NH');
      stateNameToCodeMap.put('New Jersey','NJ');
      stateNameToCodeMap.put('New Mexico','NM');
      stateNameToCodeMap.put('New York','NY');
      stateNameToCodeMap.put('North Carolina','NC');
      stateNameToCodeMap.put('North Dakota','ND');
      stateNameToCodeMap.put('Ohio','OH');
      stateNameToCodeMap.put('Oklahoma','OK');
      stateNameToCodeMap.put('Oregon','OR');
      stateNameToCodeMap.put('Pennsylvania','PA');
      stateNameToCodeMap.put('Rhode Island','RI');
      stateNameToCodeMap.put('South Carolina','SC');
      stateNameToCodeMap.put('South Dakota','SD');
      stateNameToCodeMap.put('Tennessee','TN');
      stateNameToCodeMap.put('Texas','TX');
      stateNameToCodeMap.put('Utah','UT');
      stateNameToCodeMap.put('Vermont','VT');
      stateNameToCodeMap.put('Virginia','VA');
      stateNameToCodeMap.put('Washington','WA');
      stateNameToCodeMap.put('West Virginia','WV');
      stateNameToCodeMap.put('Wisconsin','WI');
      stateNameToCodeMap.put('Wyoming','WY');
      stateNameToCodeMap.put('American Samoa','AS');
      //WI 3056 Santosh-  01.15.19 added additional states
      stateNameToCodeMap.put('Guam','GU');
      stateNameToCodeMap.put('Marshall Islands','MH');
      stateNameToCodeMap.put('Micronesia','FM');
      stateNameToCodeMap.put('Northern Marianas','MP');
      stateNameToCodeMap.put('Palau','PW');
      stateNameToCodeMap.put('Puerto Rico','PR');
      stateNameToCodeMap.put('Virgin Islands','VI');
    }
    else if(countryCode == 'CA')
    {    
      //CANADIAN PROVINCES
      stateNameToCodeMap.put('Alberta','AB');
      stateNameToCodeMap.put('British Columbia','BC');
      stateNameToCodeMap.put('Manitoba','MB');
      stateNameToCodeMap.put('New Brunswick','NB');
      stateNameToCodeMap.put('Newfoundland and Labrador','NL');
      stateNameToCodeMap.put('Nova Scotia','NS');
      stateNameToCodeMap.put('Ontario','ON');
      stateNameToCodeMap.put('Prince Edward Island','PE');
      stateNameToCodeMap.put('Quebec','QC');
      stateNameToCodeMap.put('Saskatchewan','SK');
      stateNameToCodeMap.put('Northwest Territories','NT');
      stateNameToCodeMap.put('Nunavat','NU');
      stateNameToCodeMap.put('Yukon','YT');
    }
    else if(countryCode == 'AU')
    {
      //Australian provinces and territories
      stateNameToCodeMap.put('Australian Capital Territory','ACT');
      stateNameToCodeMap.put('New South Wales','NSW');
      stateNameToCodeMap.put('Northern Territory','NT');
      stateNameToCodeMap.put('Queensland','QLD');
      stateNameToCodeMap.put('South Australia','SA');
      stateNameToCodeMap.put('Tasmania','TAS');
      stateNameToCodeMap.put('Victoria','VIC');
      stateNameToCodeMap.put('Western Australia', 'WA');
    }
    else if(countryCode == 'NZ')
    {
      //New Zealand provinces and territories
      stateNameToCodeMap.put('Auckland', 'AUK');
      stateNameToCodeMap.put('Bay of Plenty', 'BOP');
      stateNameToCodeMap.put('Canterbury', 'CAN');
      stateNameToCodeMap.put('Gisborne', 'GIS');
      stateNameToCodeMap.put('Hawke\'s Bay','HKB');
      stateNameToCodeMap.put('Marlborough', 'MBH');
      stateNameToCodeMap.put('Manawatu-Wanganui', 'MWT');
      stateNameToCodeMap.put('Nelson', 'NSN');
      stateNameToCodeMap.put('Northland', 'NTL');
      stateNameToCodeMap.put('Otago', 'OTA');
      stateNameToCodeMap.put('Southland', 'STL');
      stateNameToCodeMap.put('Tasman', 'TAS'); 
      stateNameToCodeMap.put('Taranaki', 'TKI');
      stateNameToCodeMap.put('Waikato', 'WKO');
      stateNameToCodeMap.put('Wellington', 'WGN');
      stateNameToCodeMap.put('West Coast','WTC');
      stateNameToCodeMap.put('Chatham Islands Territory','CIT');
    }
    
    return stateNameToCodeMap;   
  }
  
  public static string getStateCodeFromStateName(string stateName, string countryCode)
  {
    return createStateNameToStateCodeMap(countryCode).get(stateName);
  }
  
  public static string getStateNameFromStateCode(string stateCode, string countryCode)
  {
    return createStateCodeToStateNameMap(countryCode).get(stateCode);
  }
  
  
  public static boolean IsLightning(){
        return IsLightning(false);
    }
    
    public static boolean IsLightning(boolean testMode){
        String theme = UserInfo.getUiThemeDisplayed();
        
      /*   !! this will not work if user has 2 tabs open in same session that are different (both lightning and classic at the same time)
          Theme1—Obsolete Salesforce theme
          Theme2—Salesforce Classic 2005 user interface theme
          Theme3—Salesforce Classic 2010 user interface theme
          Theme4d—Modern “Lightning Experience” Salesforce theme
          Theme4t—Salesforce1 mobile Salesforce theme
          PortalDefault—Salesforce Customer Portal theme
          Webstore—Salesforce AppExchange theme
      */
      
       boolean IsLightning=false;
       string currentPageURL = ApexPages.currentPage().getURL();
      
       if((currentPageURL != null && currentPageURL.toLowercase().contains('lightning.')) || theme == 'Theme4d' || testMode)
       {
         IsLightning=true;
       }
       
       return IsLightning;
    }
    
    public static string GetTheme(){    return UserInfo.getUiThemeDisplayed();      }
    
    public static boolean IsNew(string recordId){
        boolean IsNew = false;
        if(recordId == null || recordId == ''){ IsNew=true; }
        return IsNew;
    }
    
    public static boolean IsEdit(string recordId){
        boolean IsNew = IsNew(recordId);
        boolean IsEdit=false;
        if(!IsNew){
            string ur = ApexPages.CurrentPage().getURL();
            if(ur.contains('%2Fe&'))
            { 
                IsEdit=true; 
            }
        }
        return IsEdit;
    }
    
    
    //Method to parse .CSV file, row by row, cell by cell
    public static List<List<String>> parseCSV(String contents, Boolean skipHeaders) 
    {
        List<List<String>> allFields = new List<List<String>>();

        // replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field
        //contents = contents.replaceAll(',"""' , ',"DBLQT').replaceall('""",' , 'DBLQT",');
        contents = contents.replaceAll(',"' , ',DBLQT').replaceall('",' , 'DBLQT,');
        //System.debug('******** CONTENTS = ' +contents);
        // now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote
        //contents = contents.replaceAll('""','DBLQT');
        contents = contents.replaceAll('"','DBLQT');
        //System.debug('******** CONTENTS = ' +contents);
        // we are not attempting to handle fields with a newline inside of them
        // so, split on newline to get the spreadsheet rows
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
           // System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line : lines){
            // check for blank CSV lines (only commas)
            if (line.replaceAll(',','').trim().length() == 0){
                break;
            }
            List<String> fields = line.split(',');  
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('DBLQT') && field.endsWith('DBLQT')) 
                {
                  cleanFields.add(field.replaceAll('DBLQT',''));
                }
                else if (field.startsWith('DBLQT')) 
                {
                  makeCompositeField = true;
                  compositeField = field;
                }
                else if (field.endsWith('DBLQT'))
                {
                  //compositeField += ',' + field;
                  compositeField += field;
                  cleanFields.add(compositeField.replaceAll('DBLQT',''));
                  makeCompositeField = false;
                }
                else if (makeCompositeField) 
                {
                  compositeField += field;
                }
                else 
                {
                  cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            
            allFields.add(cleanFields);
        }
          
        if(skipHeaders && allFields!=null && allFields.size() > 0){
           allFields.remove(0);
        }
                
        return allFields;       
    }
    
    //returns schema information for an sObect 'Account' or 'Contact', etc.
    public static Schema.DescribeSObjectResult getDescribeSObjResultByAPIName(string x){
        Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(x); 
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        return r;
    }
    
   //Creates and inserts a contentVersion record (thereby automatically creating a ContentDocument record) and creates and inserts a ContentDocumentLink record.
   //Returns the id of the contentVersion or an empty string if the insert is not successful
   public static string createAndInsertFile(String linkedEntityId, String title, Blob bodyBlob, String contentType, Date docDate, string libraryName) 
   {
     ContentVersion cv = new ContentVersion();
     
     try
     {
       //Create a new Content Version record  
       cv.title = title;
       cv.pathOnClient = title;
       cv.versionData = bodyBlob;
     
       if(string.isBlank(contentType))
         cv.contentType__c = 'Not Uploaded To SharePoint';
       else
         cv.contentType__c = contentType;
      
       if(docDate != null)
       {
         cv.DocumentDate__c = docDate;
       }
       
       System.debug('=== libraryName ==='+libraryName);
       
       if(!String.isBlank(libraryName))
       {
          ContentWorkspace cw = [select id from ContentWorkspace where name=:libraryName limit 1];
          
          if(cw != null)
           cv.FirstPublishLocationId = cw.id;
       }
      
       insert cv;
       //
       
       //Create a new Content Document Link record         
       ContentDocument cd = [select id from ContentDocument where latestPublishedVersionId =:cv.id limit 1];
       
       if(cd != null)
       {
         ContentDocumentLink cdl = new ContentDocumentLink(); 
         cdl.ContentDocumentId = cd.id; 
         cdl.linkedEntityId = linkedEntityId;
         cdl.ShareType='V';
         cdl.Visibility='AllUsers';
         
         insert cdl;
       }
       //
     }
     catch(exception e)
     {
       logError(e, 'File', null, 'File named '+ title + 'not created on parent recordid: '+linkedEntityId); 
       
       return null; 
     }
        
     return cv.id;
   }
   
   
   public static Set<Id> processSaveResult(List<Database.SaveResult> dsrList, String category, List<sObject> Records)
   { 
         Set<Id> objectIds = new Set<Id>();
         string modifiedCategory = 'Error -';
         try
         {
            integer index =0;
            List<error__c> errorList = new List<error__c>();
            
            for(Database.saveResult dsr: dsrList)
            {
                if(!dsr.isSuccess())
                {
                      Error__c e = new Error__c();
                      
                       for(integer i=0; i<dsr.getErrors().size(); i++) 
                       {
                             modifiedCategory = 'Error -' +category;
                             modifiedCategory = modifiedCategory.subString(0,Math.Min(80,modifiedCategory.length()));
                             errorList.add(UtilityClass.createError(dsr.getErrors()[i], modifiedCategory,'', String.ValueOf(dsr.getErrors()[i])+' Record Information : '+records[index]));
                       }
                }
                
                else if(dsr.isSuccess())
                {
                    objectIds.add(dsr.getId());
                
                }
                
                index++;
            }
            
            if(errorList!=NULL && errorList.size() > 0)
            {
                  try
                  {
                    insert errorList;
                  }
                  
                  catch(exception ex)
                  {
                      try
                      {
                          utilityClass.logError(ex, 'exception caught- inserting error record', '', ex.getMessage());
                      }
                      
                      catch(exception e)
                      {
                      
                      }
                  }
            }
       }
       
       catch(exception exp)
       {
            try
            {
                  utilityClass.logError(exp, 'exception caught'+category, '', exp.getMessage());
            }
            
            catch(exception e)
            {
            
            } 
       }
       
       return objectIds;
   }
   
  public static List<commonWrapperClass.cbrScoreWrapper> getBlendedCBRScore(Set<Id> primaryAcctIds)
{
    List<commonWrapperClass.cbrScoreWrapper> cbrWrapperList = new List<commonWrapperClass.cbrScoreWrapper>();
    
    Set<String> ASSOCIATION_FILTER_TYPES = new Set<String> {'Guarantor', 'Affiliate', 'Guarantor Consent', 'Owner', 'Owner Consent'};
    Set<String> Types= new Set<String>{'Individual'};
    for(account a: [select id, name, care_number__c,recordType.name, wms_customer__c, (select Primary_Relationship__c, Id, name, Ownership_Percentage__c, Secondary_Relationship__c, Secondary_Relationship__r.Current_Month_CBR__c from DealerManufacturer__r where Association_Type__c = :ASSOCIATION_FILTER_TYPES AND Type__c IN:Types) from account where id IN: primaryAcctIds])
    {
        commonWrapperClass.cbrScoreWrapper cw =new commonWrapperClass.cbrScoreWrapper();
        cw.primaryAccount= a;
        cw.errorMessage='';
        
        Decimal percentageTotal = 0;
        Decimal weightedCBRTotal = 0;
        
        if(a.DealerManufacturer__r!= null && a.DealerManufacturer__r.size() >0 )
        {
            for(Associated_Relationships__c asso : a.DealerManufacturer__r)
            {
                if(asso.Ownership_Percentage__c!=null && asso.Secondary_Relationship__c!=null && asso.Secondary_Relationship__r.Current_Month_CBR__c!=null && asso.Ownership_Percentage__c!=0 && asso.Secondary_Relationship__r.Current_Month_CBR__c!=0)
                {
                    percentageTotal += asso.Ownership_Percentage__c; 
                    weightedCBRTotal += asso.Ownership_Percentage__c * asso.Secondary_Relationship__r.Current_Month_CBR__c;
                }
            }
            
            if(percentageTotal> 0 && weightedCBRTotal > 0)
            {
                percentageTotal= percentageTotal==100?Math.round(weightedCBRTotal)/100: Math.round( weightedCBRTotal/percentageTotal);
                cw.cbScore = percentageTotal;
            } 
            else
            {
                map<String, Set<String>> missingDatapoints = validateAssociations(a.DealerManufacturer__r);
                cw.errorMessage='Could not evaluate the CBR score because of the missing data points : ';
                
                if(missingDatapoints!=null)
                {
                    String associationNames = '';
                    
                    if(missingDatapoints.containsKey('ownershipPercentageMissing'))
                    {
                        for(String s:missingDatapoints.get('ownershipPercentageMissing')) 
                        {
                           associationNames += (associationNames==''?'':',')+s;
                        }

                        cw.errorMessage+= 'Ownership data was found missing for following associations '+associationNames+'\n';
                    }
                    if(missingDatapoints.containsKey('secondaryRelationshipCBRScore'))
                    {
                        for(String s:missingDatapoints.get('secondaryRelationshipCBRScore')) 
                        {
                           associationNames += (associationNames==''?'':',')+s;
                        }
                        cw.errorMessage+= 'Current CBR Month data was found missing on secondary relationships for following associations '+associationNames;
                    }
                }
            }
        }
        
        else
        {
            cw.errorMessage='Since there are no individual 1st Level Owners, please enter the Blended CBR directly into the Dealer\'s Relationship Record for '+a.Name+'.';
        } 
        
        cbrWrapperList.add(cw);
    }   
    
    System.debug('====== cbrWrapperList===='+cbrWrapperList);
    
    return cbrWrapperList;
}

public static map<String, Set<String>> validateAssociations(List<Associated_Relationships__c> assocList)
{
    Map<String, Set<String>> missingData = new Map<String, Set<String>>();
    
    for(associated_Relationships__c asso: assocList)
    {
        if(asso.Ownership_Percentage__c == null)
        {
            if(missingData.get('ownershipPercentageMissing') == null)
            {
                missingData.put('ownershipPercentageMissing', new Set<String>{asso.Name});
            }
            else
            {
                missingData.get('ownershipPercentageMissing').add(asso.Name);
            }
        }
        
        if(asso.Secondary_Relationship__c== null || (asso.Secondary_Relationship__c!=null && asso.Secondary_Relationship__r.Current_Month_CBR__c==null ))
        {
            if(missingData.get('secondaryRelationshipCBRScore') == null)
            {
                missingData.put('secondaryRelationshipCBRScore', new Set<String>{asso.Name});
            }
            else
            {
                missingData.get('secondaryRelationshipCBRScore').add(asso.Name);
            }
        }
    }
    
    return missingData;
}
public static Map<Id, String> fetchAndUpdateCBRScores(Set<Id> recordIds)
{
    
    Map<Id, id> accountIdToLoanIdsMap = new map<Id, id>();
    Map<Id, Id> acctIdToNDAIDMap = new Map<id,Id>();
    Set<id> accountIds = new Set<Id>();
    
    Id objId =new List<Id>(recordIds)[0];
    String objectName = getSObjectNameFromId(objId);
    
    if(objectName == 'Account')
    {
        accountIds.addAll(recordIds);      
    }
    
    else if(objectName == 'Underwriting__c')
    {
        for(Underwriting__c  l : [select id, name,Initiating_Account__c, Account__c from Underwriting__c where id IN : recordIds])
        {
            accountIdToLoanIdsMap.put(l.Initiating_Account__c, l.id);
            //accountIdToLoanIdsMap.put(l.Account__c, l.id);
        }
      
        accountIds.addAll(accountIdToLoanIdsMap.keySet());  
    }
    else if(objectName == 'New_Dealer_Application__c')
    {
           for(New_Dealer_Application__c nda: [select id, name, (select id,Primary_Manufacturer__c,Relationship__c,Underwriting__c from Products_LKUP__r) from New_Dealer_Application__c where id IN: recordIds])
          {
                for(Product_Information_For_New_Dealer_App__c junc: nda.Products_LKUP__r)
                {
                    acctIdToNDAIDMap.put(junc.Relationship__c, nda.id);
                    accountIdToLoanIdsMap.put(junc.Relationship__c, junc.Underwriting__c);
                }
         }
         
        accountIds.addAll(acctIdToNDAIDMap.keySet());
    }
    
    // If accounts present fetch the CBR score
    if(accountIds!=null && accountIds.size() >0)
    {
         List<commonWrapperClass.cbrScoreWrapper> cbrScoreList = utilityClass.getBlendedCBRScore(accountIds);
        
        if(cbrScoreList!=null && cbrScoreList.size() >0)
         {
            Map<Id, String> cbrScoreMessage = new Map<Id, String>();
            List<sObject> objectsToUpdateCBRScore = new List<sObject>();
            
             for(commonWrapperClass.cbrScoreWrapper cw: cbrScoreList)
             {
                    System.debug('==== cw ==='+cw);
                        
                     // CBR score exist only if errorMessage is blank
                    if(String.isBlank(cw.errorMessage))
                    {
                            New_Dealer_Application__c nda;
                            Underwriting__c careLoan;
                            
                            account a= new account(id= cw.primaryAccount.id, Blended_CBR__c= cw.cbScore);
                            objectsToUpdateCBRScore.add(a);
                            cbrScoreMessage.put(a.id, 'Success');
                            
                            if(objectName == 'New_Dealer_Application__c')
                            {
                                nda = new New_Dealer_Application__c(id= acctIdToNDAIDMap.get(cw.primaryAccount.id), Blended_CBR_Score__c= cw.cbScore);
                                careLoan = new Underwriting__c(id= accountIdToLoanIdsMap.get(cw.primaryAccount.id), Blended_CBR__c= cw.cbScore);
                                objectsToUpdateCBRScore.add(nda);
                                objectsToUpdateCBRScore.add(careLoan);
                                cbrScoreMessage.put(nda.id, 'Success');
                                cbrScoreMessage.put(careLoan.id, 'Success');
                            }
                            else if(objectName == 'Underwriting__c')
                            {
                                careLoan = new Underwriting__c(id= accountIdToLoanIdsMap.get(cw.primaryAccount.id), Blended_CBR__c= cw.cbScore);
                                objectsToUpdateCBRScore.add(careLoan);
                                cbrScoreMessage.put(careLoan.id, 'Success');
                            }
                            
                    }
                    
                    //if cbr is not determined then throw an error message
                    else
                    {
                         if(objectName == 'New_Dealer_Application__c' && acctIdToNDAIDMap.containsKey(cw.primaryAccount.id))
                         {
                              cbrScoreMessage.put(acctIdToNDAIDMap.get(cw.primaryAccount.id), cw.errorMessage);
                         }
                         else if(objectName == 'Underwriting__c' && accountIdToLoanIdsMap.containsKey(cw.primaryAccount.id))
                        {
                            cbrScoreMessage.put(accountIdToLoanIdsMap.get(cw.primaryAccount.id), cw.errorMessage);
                        }           
                        else if(objectName == 'Account')
                        {
                            cbrScoreMessage.put(cw.primaryAccount.id, cw.errorMessage);
                        }
                    }
             }
             
             // updates the objects with CBR Score and if error is encountered then it updates the with error message.
             
             // if objectName is account then it updates blended CBR score on account with Blended CBR Score.
             // if objectName is Loan then it updates blended CBR score then its updates account and careloan with Blended CBR Score.
             // if object Name is NDA then it updates account, loan and NDA with Blended CBR Score.
             
             if(objectsToUpdateCBRScore!=null && objectsToUpdateCBRScore.size() >0)
             {
                    List<Database.saveResult> dsrList = Database.update(objectsToUpdateCBRScore, false);
                    
                     for(Database.saveResult dsr: dsrList)
                    {
                       if(!dsr.isSuccess() && cbrScoreMessage.containsKey(dsr.getId()))
                       {
                           cbrScoreMessage.put(dsr.getId(), 'Problem encountered while updating the CBR score.');
                       }
                    }
                    
                    utilityClass.processSaveResult(dsrList, 'CBR Score Calculation on loan', objectsToUpdateCBRScore);
            }
            
            return cbrScoreMessage;
                
         }
    }
    
    return null;
}
   
     /**

     This method is triggered from cscDocumentsSearchTrigger, cscFormationDocumentOrder && UCCSecurityFilingsTrigger (Trigger code).
     This process creates a UCC_File_Download__c record
        
     UCC File download complete process:-
     1. When "UCC_Filing_Link__c"/"UCC_Filing_Acknowledgement__c" is updated on Security_Filings__c object 
            OR 
        "CSC_Documents__c"/"Attachments_from_CSC__c" is inserted.
     2. Trigger willl attempt to create a UCC_File_Download__c record
     3. UCCFileDownloadFromURLBatch job will run every 30 mins which attempts to query "UCC_File_Download__c" records and makes a callout and downloads a file and 
     adds to account/underwriting docvault.
     */
    
   public static void createUCCFileDownloadRecord(String url, String linkFileTo, String docName,String contentType, String recordId)
   {
      try
      {
          String objectName=getSObjectNameFromId((Id)recordId); 
          UCC_File_Download__c u =new UCC_File_Download__c(URL_To_Download__c = url, Link_File_To__c= linkFileTo, Document_Name__c=docName, Content_Type__c=contentType, Number_of_Retries__c=0);
          
          if(objectName== 'Security_Filings__c') u.Security_Filing_Id__c=recordId;
          else if(objectName== 'CSC_Documents__c') u.CSC_Search_Document_Id__c=recordId;
          else if(objectName== 'Attachments_from_CSC__c') u.Attachment_From_CSC_Id__c=recordId;
          
          insert u;
       }
       catch(exception e)
       {
           String msg='Exception occured while downloading file operation method - logInfotoCustomObjectForUCCFileDownload'+e.getMessage();
           UtilityClass.logError(e, 'Error occured - while downloading file UCC -logInfotoCustomObjectForUCCFileDownload', '', msg);
       }
   }
   
    public static integer exResponseCode=11111;
    public static integer timeOutResponseCode=99999;
    
    /**
        This method attempts to download the file. This method is used in UCCFileDownloadFromURLBatch job
    */
    public static CommonWrapperClass.downloadURLWrapperClass callout(String downloadURL, String objectId)
    {
 
        CommonWrapperClass.downloadURLWrapperClass wrap = new CommonWrapperClass.downloadURLWrapperClass();
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(downloadURL);
        req.setTimeout(120*1000);
        
        try
        {
            
            if(test.isRunningTest())
            {
                Blob ResponseAsBlob = blob.ValueOf('Test body');
                 wrap.responseAsBlob= ResponseAsblob;
                
                return wrap;
            }
            else
            {
                HttpResponse resp = http.send(req);
                wrap.responseCode = resp.getStatusCode();
                
                if(wrap.responseCode ==200)
                {
                    Blob ResponseAsBlob = resp.getBodyAsBlob();
                    wrap.responseAsBlob= ResponseAsblob;
                }
                else
                {
                    //wrap.responseCode =calloutResponseCode;
                    wrap.responseAsBlob= null;
                    wrap.responseCode =timeOutResponseCode;
                    //wrap.e= new error__c(custom_message__c= ('\n Error occured while downloading file for \n recordId - '+objectId +'\n URL -'+downloadURL+'.'+'\n \n Error details as follows: \n Response status code: - '+resp.getstatusCode()+' res status message :'+resp.getBody()), message__c='Error occured - while downloading file UCC');
                    wrap.e= new error__c(custom_message__c= ( 'Response status code: - '+resp.getstatusCode()+' res status message :'+resp.getBody()), message__c='Error occured - while downloading file UCC -UtilityClass callout Method', name='Error occured while downloading file -UtilityClass callout Method');
                }
                return wrap;
            }
        }
        catch(exception e)
        {
            if(e.getMessage().contains('Read time out'))
            {
                wrap.responseCode =timeOutResponseCode;
            }
            else
            {
                wrap.responseCode=exResponseCode;
            }
            try
            {
                //wrap.e= new error__c(custom_message__c= ('\n Error occured while downloading file for \n recordId - '+objectId +'\n URL -'+downloadURL+'.'+'\n \n Error deatils as follows: - \n'+e.getMessage()), message__c='Error occured - while downloading file UCC');
                 wrap.e= new error__c(custom_message__c= e.getMessage(), message__c='Error occured - while downloading file UCC -UtilityClass callout Method', name='Error occured while downloading file for UCC -UtilityClass callout Method');
            }
            catch(exception ex)
            {
                String msg ='\n Error occured while downloading file for \n recordId - '+objectId +'\n URL -'+downloadURL+'.'+'\n \n Error deatils as follows: - \n'+ex.getMessage()+' -UtilityClass callout Method';
                UtilityClass.logError(ex, 'Error occured - while downloading file UCC', '', msg);
            }
            
            return wrap;
        }


    }
    
    public static String getURlExtension(String URL)
    {
        if(URL.lastIndexOf('.')!=-1)
        {
            String extension = url.substring(url.lastIndexOf('.'));
            return extension;
        }
        return '';
    }

    public static String validateAndModifyDocName(String textString)
    {
        try
        {
            Set<String> specialCharacters = new Set<String>{'"','#', '%', '&', '*', ':','<',  '>', '?', '/', '{', '|', '}', '~'};
            
            for(String sp: specialCharacters)
            {
                if(textString.indexOf(sp)!=-1) textString=textString.replaceAll(sp, '-');
            }
        }
        catch(exception e)
        {
            return textString;
        }
        
        return textString;
    }
    
     // This method triggers when a UW recordtype is changed.
    //This method sets the reviewtype on loan and case.
    public Static String maploanRecordTypesToloanAndcaseReviewtype(String recordTypeName)
    {
        String recordTypeFirst4Chars = recordTypeName.subString(0,4).toLowercase();
        System.debug('=== recordTypeFirst4Chars ==='+recordTypeFirst4Chars);
        Map<String, String> RecordTypesFirst4CharToReviewTypes= new Map<String,String>
        {
            'carv'=> 'Carve Out', 
            'cont' => 'Continuation',
            'cred' => 'Review Extension', 
            'exce' => 'Exception', 
            'fina' => 'Financial Review',
            'incr' => 'Increase', 
            'memo' => 'Memo', 
            'new ' => 'New', 
            'over' => 'Overline', 
            'prod' => 'Product Add', 
            'refi' => 'Refinance', 
            'risk' => 'Risk Rating Change', 
            'silo' => 'Silo', 
            'temp' => 'Temporary'
        };
        
        return (RecordTypesFirst4CharToReviewTypes.containsKey(recordTypeFirst4Chars)?RecordTypesFirst4CharToReviewTypes.get(recordTypeFirst4Chars):'');
    }
    
    // This method triggers when a UW recordtype is changed.
    //This method sets the corresponding recordtype on case.
    public Static String caseReviewTypeTorecordTypeMapping(String reviewType)
    {
        System.debug('==== reviewType ==='+reviewType);
        Map<String,String> caseReviewTypeToRecordTypes = new Map<String,String>
        {
            'Review Extension' =>   'Extension_Review',
            'Risk Rating Change' => 'Risk_Rating_Change_performance',
            'Increase' =>   'Dealer_Increase_Credit_Review_300_000',
            'Carve Out' =>  'Carve_Out',
            'Refinance' =>  'Buyout_Existing_Customer',
            'Continuation'  => 'Dealer_Continuation',
            'Overline'  => 'Credit_Overline',
            'Financial Review'  =>'Interim_Financial_Review_Dealer',
            'Product Add'   => 'Product_Line_Add_Request',
            'Memo'  => 'Memo_Credit_Dept',
            'Exception' => 'Dealer_Exception_Review',
            'Temporary' =>'Temporary_Increase',
            'Interim Financial' => 'Interim_Financial_Review_Dealer',
            'Inventory Buyout' =>   'Buyout_Existing_Customer'
        };
        
        System.debug('=== caseReviewTypeToRecordTypes.containsKey(reviewType) ==='+caseReviewTypeToRecordTypes.containsKey(reviewType));
        //return (caseReviewTypeToRecordTypes.containsKey(reviewType)?(constants.caseRTMap.get(caseReviewTypeToRecordTypes.get(reviewType))):'');
        
        if(caseReviewTypeToRecordTypes.containsKey(reviewType))
        {
            return constants.caseRTMap.get(caseReviewTypeToRecordTypes.get(reviewType));
        }
        return '';
    }

    /* PARAMS:  1) Account acct - that is being inserted or updated
                2) boolean allowSaveIfDuplicate - if TRUE, then this will still save the changes if duplicate matches are found
                3) boolean returnDuplicateIds - if TRUE, the wrapper result will include a set of record ids for the duplicate matches
    */
    public static CommonWrapperClass.accountWithDuplicateSaveResultWrapper saveSingleAccountWithDuplicateResult(Account acct, boolean allowSaveIfDuplicate, boolean returnDuplicateIds){
        CommonWrapperClass.accountWithDuplicateSaveResultWrapper result = new CommonWrapperClass.accountWithDuplicateSaveResultWrapper();
        result.a = acct;
        result.IsSuccess = true;
        result.errorMessage = '';
        result.duplicateMatchIds = new set<id>();
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.AllowSave = allowSaveIfDuplicate;
        Database.SaveResult saveResult;
        system.debug(allowSaveIfDuplicate);
        if(acct.id == null){
            saveResult = Database.insert(acct, dml);
        } else {
            saveResult = Database.update(acct, dml);
        }
    
        if(!saveResult.isSuccess()) {
            for (Database.Error error : saveResult.getErrors()) {
                // If there are duplicates, an error occurs
                
                // Process only duplicates and not other errors  (e.g., validation errors)
                if (error instanceof Database.DuplicateError) {
                    // Handle the duplicate error by first casting it as a DuplicateError class
                    // This lets you use methods of that class (e.g., getDuplicateResult())
                    Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                    Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                    
                    // Display duplicate error message as defined in the duplicate rule
                    ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.WARNING, 'Duplicate Warning: ' + duplicateResult.getErrorMessage()+ ' Please consider using one of the suggested records listed below:');
                    ApexPages.addMessage(errorMessage);
                    result.errorMessage = 'Duplicate Warning: ' + duplicateResult.getErrorMessage();
                    
                    if(returnDuplicateIds){
                        
                        // Return only match results of matching rules that find duplicate records
                        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
    
                        // Just grab first match result (which contains the duplicate record found and other match info)
                        Datacloud.MatchResult matchResult = matchResults[0];
                        Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
    
                        // Add matched record to the duplicate records variable
                        for (Datacloud.MatchRecord matchRecord : matchRecords) {
                            System.debug('MatchRecord: ' + matchRecord.getRecord());
                            result.duplicateMatchIds.add(matchRecord.getRecord().id);
                        }
                    }
                } else { //handle other error types
                    ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage());
                    ApexPages.addMessage(errorMessage);
                    result.errorMessage = error.getMessage();
                }
            }
            
            //If there’s a duplicate record, stay on the page
            result.IsSuccess = false;
        }

        return result;
    }
    
    /**
      Santosh -added for fetching dependent picklist.
      pass the dependent field as argument to fetch the result.
      https://glyntalkssalesforce.blogspot.com/2018/08/dependent-picklist-values-in-apex.html
    */
    public static Map<Object,List<String>> getDependentPicklistValues( Schema.sObjectField dependToken )
    {
        Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
        System.debug('==== dependToken ==='+dependToken);
        try
        {
            if(dependToken ==null) return null;
            
            Schema.DescribeFieldResult depend = dependToken.getDescribe();
            Schema.sObjectField controlToken = depend.getController();
            
            if ( controlToken == null ) return null;
            
            Schema.DescribeFieldResult control = controlToken.getDescribe();
            List<Schema.PicklistEntry> controlEntries =(control.getType() == Schema.DisplayType.Boolean?   null: control.getPicklistValues() );
            String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
           
            
            for ( Schema.PicklistEntry entry : depend.getPicklistValues() ) if ( entry.isActive() )
            {
                /**
                 single statement that does a lot of work.  The Schema.PicklistEntry is serialized and deserialized using the Apex JSON class.  By using JSON.deserializeUntyped, we avoid the need to declare a class to use when deserializing, and the code will continue to work even if Salesforce changes the internals of the Schema.PicklistEntry class — as long as it continues to have a validFor field.
                 After deserializing, the code extracts the validFor field and converts its value to a String. Finally, the code splits the Base64 string into its individual characters.  Each String in base64chars is a single character encoding six columns of the field dependency matrix for this dependent picklist value.
                */
                List<String> base64chars =String.valueOf(((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )).split( '' );
                System.debug('==== base64chars ==='+base64chars);
                for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ )
                {
                    /** 
                    If the controlling field is a picklist, then controlValue will be assigned the label of the active picklist value, or null, if the picklist value is inactive.  If the controlling field is a checkbox, then controlValue will be assigned false (when index is 0) or true (when index is 1).
                    */
                    Object controlValue =
                    (   controlEntries == null
                    ?   (Object) (index == 1)
                    :   (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null)
                    );
                    
                    /**
                    computes the location of this column's bit in the validFor bitmap.  bitIndex identifies which of the Base64 characters contains the bit, and bitShift identifies which of the six bits we want from the decoded character.If the controlling picklist value is inactive or if the decoded bit is a zero, the code skips this column.  The decoding is done using the indexOf method, which converts the Base64 character into the value (0-63) that it represents.
                    */
                    
                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
                    if  (   controlValue == null
                        ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0
                        ) continue;
                    if ( !dependentPicklistValues.containsKey( controlValue ) )
                    {
                        dependentPicklistValues.put( controlValue, new List<String>() );
                    }
                    dependentPicklistValues.get( controlValue ).add( entry.getLabel() );
                }
            }
        }
        catch(exception e)
        {
            UtilityClass.logError(e, 'exception caused while fecthing dependent picklist values for '+dependToken, '', e.getMessage());
        }
        system.debug('==== dependentPicklistValues ===='+dependentPicklistValues);
        return dependentPicklistValues;
    }
    
  /**
  This method is currently called by UBOController class.
  -This method takes caseId or accountId as input
     if account id is the input then it will fetch all the asscoiations(up to 10 levels) tied to the account
     If case id is the input then, it will fetch associations(up to 10 levels) for the case initiating account and any co-borrower account(tied to initiating account) related associations.
     
   BorrowerData and GuarantorData are wrapper class located in commonwrapperclass. 
   FYI. Existing AssociationsVFC class fetches associations based on associations level per selected account
   This method will create a hierarchy of associations and ties all the related associations together based on case id or account id
   
  */ 
    
  public static Map<Id, CommonWrapperClass.UBOBorrowerData> getAllBorrowerAndGuarantorsData(string caseOrAcctId)
  {
    integer i=1;
    Map<Id, CommonWrapperClass.UBOBorrowerData> uboBorrowerMap = new Map<Id, CommonWrapperClass.UBOBorrowerData>();
    Set<Id> accountIds = new Set<id>();
    String baseURL='https://'+String.valueof(System.URL.getSalesforceBaseURL().gethost());
    List<String> ASSOCIATION_FILTER_TYPES_UBO = AssociationsHelper.ASSOCIATION_FILTER_TYPES_UBO ;
    integer OWNERSHIP_THRESHOLD=AssociationsHelper.OWNERSHIP_THRESHOLD;
    Map<String, String> coBorrowerToNAICSCode = new Map<String, String>();
    
    System.debug('=== caseOrAcctId =='+caseOrAcctId);
    if(caseOrAcctId.startsWith('500'))
    {
      case c=[select accountid, account.care_number__c from case where id=:caseOrAcctId];
      accountIds= fetchAllCoBorrowersTiedToThisDealer(c.AccountId);
      accountIds.add(c.accountId);
      String careId = c.account.care_number__c;
      
      if(accountIds.size() >0 && !String.isBlank(careId))
      {
        for(Associated_Relationships__c ar: [select primary_relationship__c, primary_relationship__r.NAICS_Code_Fomula__c, secondary_Relationship__c from Associated_Relationships__c where secondary_Relationship__c IN: accountIds and primary_relationship__r.care_number__c =:careId])
        {
            coBorrowerToNAICSCode.put(ar.secondary_Relationship__c, ar.primary_relationship__r.NAICS_Code_Fomula__c);
        }
      }
    }
    else
    {
        accountIds.add(caseOrAcctId);
    }
    System.debug('==== accountIds.size() ==='+accountIds.size());
    
    for(Account acct: [select id, name, recordtypeId, wms_customer__c, billingStreet, billingCity, billingState, billingPostalCode, billingStateCode, billingCountry, billingCountryCode,legal_entity_name__c, legal_entity__c, publicly_traded__c, government_entity__c, NAICS_Code_Fomula__c, Tax_Identification_Number__c, social_security_number__c, Primary_ID_Number__c, UBO_Tin_Type__c, UBO_Tin_Type_Number__c, UBO_Business_Category_Number__c, (select id from DealerManufacturer__r WHERE Association_Type__c = :ASSOCIATION_FILTER_TYPES_UBO /*and Ownership_Percentage__c >=:OWNERSHIP_THRESHOLD*/ and Authorized_Signer__c=true) from account where id IN:accountIds])
    {
        CommonWrapperClass.UBOBorrowerData uboBorrowerData = new CommonWrapperClass.UBOBorrowerData();
    
        uboBorrowerData.keyValue=i;
        uboBorrowerData.name = acct.name;
        uboBorrowerData.borrowerRelationshipRecordURL = baseURL+'/lightning/r/Account/'+acct.id+'/view';
        uboBorrowerData.borrowerRelationshipRecordId =acct.id;
        uboBorrowerData.borrowerWMSNumber = acct.wms_customer__c;
        uboBorrowerData.addrStreet = acct.billingStreet;
        uboBorrowerData.addrCity = acct.billingCity;
        uboBorrowerData.addrStatecode = acct.billingStateCode;
        uboBorrowerData.addrZip = acct.billingPostalCode;
        uboBorrowerData.addrCountrycode = acct.billingCountryCode;
        if(acct.RecordTypeId== constants.accountRTMap.get('Co_Borrower'))
        {
            if(coBorrowerToNAICSCode.containsKey(acct.id))
            uboBorrowerData.NAICSCode =coBorrowerToNAICSCode.get(acct.id);
        }
        else
        {
            uboBorrowerData.NAICSCode = acct.NAICS_Code_Fomula__c;
        }
        uboBorrowerData.lineOfBusiness = 'TCF Inventory Finance';
        uboBorrowerData.TINType = acct.UBO_Tin_Type__c;
        uboBorrowerData.TINTypeNumber = acct.UBO_Tin_Type_Number__c;
        uboBorrowerData.exemptionCategoryId = acct.UBO_Business_Category_Number__c;

        if(uboBorrowerData.exemptionCategoryId == '')
          uBOBorrowerData.dataErrors = 'Legal Entity Structure cannot be blank for a Borrower / Co-Borrower.';

        if(uboBorrowerData.TINType == 'EIN')
        {
          if(acct.Tax_Identification_Number__c!=null)
          {
              uboBorrowerData.TIN = (acct.Tax_Identification_Number__c.isNumeric()?acct.Tax_Identification_Number__c: StripOutAllNonNumericCharacters(acct.Tax_Identification_Number__c));  
          }
        }
        else if(uboBorrowerData.TINType == 'FOREIGN TAX ID')
        {
            if(acct.Tax_Identification_Number__c!=null)
            {
                uboBorrowerData.TIN = (acct.Tax_Identification_Number__c.isNumeric()?acct.Tax_Identification_Number__c: StripOutAllNonNumericCharacters(acct.Tax_Identification_Number__c));
            } 
        }
        else if(uboBorrowerData.TINType == 'SSN' || uboBorrowerData.TINType == 'ITIN')
        {
          if(acct.social_security_number__c != null)
          {
            uboBorrowerData.TIN = (acct.social_security_number__c.isNumeric()?acct.social_security_number__c: StripOutAllNonNumericCharacters(acct.social_security_number__c));
          }
        }
        
        
        if(acct.DealerManufacturer__r==null || (acct.DealerManufacturer__r!=null && acct.DealerManufacturer__r.size() ==0))
        {
             uboBorrowerData.dataErrors = 'No control prong found for this borrower.';
        }
        
        uboBorrowerData.childrenHaveErrors=false;
        
        uboBorrowerData.ownersList = new List<CommonWrapperClass.UBOOwnerData>();
        
        uboBorrowerData.ownersList = fetchAssociationsForThisDealer(acct.id, uboBorrowerData);
             
        uboBorrowerMap.put(uboBorrowerData.borrowerRelationshipRecordId , uboBorrowerData);

        uboBorrowerData.dataErrors =validateDealerOrCoBorrowerData(uboBorrowerData);

        if(string.isBlank(uboBorrowerData.dataErrors))
            uboBorrowerData.hasDataErrors = false;
        else
            uboBorrowerData.hasDataErrors = true;

        i++;
    }
    return uboBorrowerMap;
  }
  
  /**
      This method takes accountId as input and provides a list of guarantor data.
      This method will fetch all associations tied to account up to 10 levels
  */
  public static List<CommonWrapperClass.UBOOwnerData> fetchAssociationsForThisDealer(Id dealerId, CommonWrapperClass.UBOBorrowerData uboBorrowerData) 
  {
      Integer STARTING_LEVEL = 0;
      Integer MAX_LEVELS = 10;
      
      Map<String, CommonWrapperClass.UBOOwnerData> gurantorAssociationMap = new Map<String, CommonWrapperClass.UBOOwnerData>();
      List<CommonWrapperClass.UBOOwnerData> associationsWrapperList = new List<CommonWrapperClass.UBOOwnerData>();
              
      Set<String> ASSOCIATION_FIELDS = new Set<String>{'name','type__c','Record_type__c', 'association_type__c', 'ownership_percentage__c', 'Authorized_Signer__c', 'Secondary_Relationship__c', 'Secondary_Relationship__r.legal_entity__c', 'Secondary_Relationship__r.social_security_number__c', 'Secondary_Relationship__r.Tax_Identification_Number__c', 'Secondary_Relationship__r.name', 'Secondary_Relationship__r.date_of_birth__c', 'Secondary_Relationship__r.billingStreet', 'Secondary_Relationship__r.billingCity', 'Secondary_Relationship__r.billingState','Secondary_Relationship__r.billingStateCode', 'Secondary_Relationship__r.billingPostalCode', 'Secondary_Relationship__r.billingCountry', 'Secondary_Relationship__r.billingCountryCode', 'secondary_relationship__r.Primary_ID_Number__c', 'secondary_relationship__r.Last_Name__c','secondary_relationship__r.First_Name__c', 'secondary_relationship__r.ubo_tin_type__c', 'secondary_relationship__r.ubo_tin_type_number__c', 'secondary_relationship__r.ubo_business_category__c', 'secondary_relationship__r.ubo_business_category_number__c'};
    
      Set<String> ACCOUNT_FIELDS = new Set<String>{'Name', 'Recordtype.Name', 'Blended_CBR__c', 'accountNumber', 'wms_customer__c', 'recordtypeid'};
               
      Map<Id, List<Associated_Relationships__c>> accountAssociations = AssociationsHelper.GetAccountAssociationsForAccountIdsForUBOs(new Set<Id>{dealerId}, ACCOUNT_FIELDS, ASSOCIATION_FIELDS);
      System.debug('==== accountAssociations ==='+accountAssociations);
      
     
      associationsWrapperList= RecursiveSearch(dealerId, accountAssociations, STARTING_LEVEL, MAX_LEVELS, gurantorAssociationMap, associationsWrapperList,  uboBorrowerData);
      System.debug('==== associationsWrapperList ==='+associationsWrapperList);
      System.debug('====After gurantorAssociationMap==='+gurantorAssociationMap.size());

      return associationsWrapperList;
  } 


  public static List<CommonWrapperClass.UBOOwnerData> RecursiveSearch(Id i, Map<Id, List<Associated_Relationships__c>> accountAssociations, Integer currentLevel, integer maxLevels, Map<String, CommonWrapperClass.UBOOwnerData> gurantorAssociationMap, List<CommonWrapperClass.UBOOwnerData> associationsWrapperList,  CommonWrapperClass.UBOBorrowerData uboBorrowerData)
  {   
     System.debug('====Before gurantorAssociationMap==='+gurantorAssociationMap.size());
    if(currentLevel == 0)
      currentLevel =  1;
    else
      currentLevel = currentLevel + 1; 
    
    boolean IsFirstLevelAccountIdCoBorrower =false;
    
    System.debug('==== currentLevel===='+currentLevel);
    
    if (currentLevel > maxLevels || !accountAssociations.containsKey(i))
    {
        return associationsWrapperList;
    }
    
    if(currentLevel ==1)
    {
        account a =[select id, recordtype.DeveloperName from account where id=:i];
        if(a.recordtype.DeveloperName == 'Co_Borrower')
        {
            IsFirstLevelAccountIdCoBorrower =TRUE;
        }
    }
    
    //System.debug('===  accountAssociations.get(i).DealerManufacturer__r.size()==='+ accountAssociations.get(i).DealerManufacturer__r.size());
    
    integer ownershipPct =0;
    for (Associated_Relationships__c ar : accountAssociations.get(i))
    {      
        ownershipPct+=Integer.valueOf(ar.ownership_percentage__c);
            
          System.debug('=== ar.Primary_relationship__c ==='+ar.Primary_Relationship__c);      
        //  if(ar.Ownership_Percentage__c > 20)
     // {     
            System.debug('==== currentLevel===='+currentLevel);
            if(currentLevel== 1)
            {
                  if(!IsFirstLevelAccountIdCoBorrower && ar.record_type__c!=null && ar.record_type__c.toLowerCase() == 'co-borrower')
                    continue;
            
                  CommonWrapperClass.UBOOwnerData arWrap=  createAssociationWrapper(ar, currentLevel, uboBorrowerData);
                  arWrap.effectiveOwnershipPct  = ar.ownership_percentage__c!=null?String.ValueOf(ar.ownership_percentage__c):'';
                  System.debug('=== arWrap ==='+arWrap);
                  
                  associationsWrapperList.add(arWrap);
                  System.debug('====associationsWrapperList === '+associationsWrapperList);
                  // this map stores the current level associations wrapper
                  // current level association secondary relationship will be the primary on next level.
                  gurantorAssociationMap.put(ar.Secondary_Relationship__c, arWrap);
                 // gurantorAssociationMap.put(ar.primary_Relationship__c, arWrap);
                  System.debug('===gurantorAssociationMap === '+gurantorAssociationMap);
                 
            }
            else if(currentLevel>1 )
            {
                if(ar.record_type__c == 'Dealer' || ar.primary_relationship__r.recordType.Name =='Co-Borrower' || ar.primary_relationship__r.recordType.Name== 'Legal Entity')
                  continue;
                
                System.debug('===  gurantorAssociationMap.containsKey(ar.Primary_Relationship__c) =='+gurantorAssociationMap.containsKey(ar.Primary_Relationship__c));
                if(gurantorAssociationMap.containsKey(ar.Primary_Relationship__c))
                {
                     
                     CommonWrapperClass.UBOOwnerData arWrap= createAssociationWrapper(ar, currentLevel, uboBorrowerData);
                     
                     CommonWrapperClass.UBOOwnerData parentArWrap = gurantorAssociationMap.get(ar.Primary_Relationship__c);
                     try
                     {
                         if(!String.isBlank(parentArWrap.ownershipPct) && ar.ownership_percentage__c!=null)
                         {
                            Decimal effictivePct = ((Decimal.valueOf(parentArWrap.effectiveOwnershipPct))*ar.ownership_percentage__c/100);
                            arWrap.effectiveOwnershipPct  = String.ValueOf(effictivePct.round(System.RoundingMode.HALF_UP));
                          }
                     }
                     catch(exception e)
                     {
                         parentArWrap.effectiveOwnershipPct  ='';
                     }
                     /** gurantorAssociationMap.get(ar.Primary_Relationship__c).goList.add(arWrap);
                         gurantorAssociationMap.put(ar.Secondary_Relationship__c, arWrap);
                         Above two methods are doing the heavy lifting in tieing the current level associations to previous level associations
                     */
                     System.debug('==== before associationsWrapperList ==='+associationsWrapperList+'=== level ==='+currentLevel);
                     gurantorAssociationMap.get(ar.Primary_Relationship__c).hasNextLevel = true;
                     gurantorAssociationMap.get(ar.Primary_Relationship__c).ownersList.add(arWrap);

                     System.debug('=== after associationsWrapperList===='+associationsWrapperList+'=== level ==='+currentLevel);
                     
                      gurantorAssociationMap.put(ar.Secondary_Relationship__c, arWrap);
                     System.debug('===gurantorAssociationMap === '+gurantorAssociationMap);
                     
                }
                
            }
          
          if (String.IsNotBlank(ar.Secondary_Relationship__c))
          {
              system.debug('Recursive search from within recursive search');
              associationsWrapperList= recursiveSearch(ar.Secondary_Relationship__c, accountAssociations, currentLevel, maxLevels, gurantorAssociationMap, associationsWrapperList,uboBorrowerData);
          }
          
       // }
    }
       
    System.debug('====After associationsWrapperList==='+associationsWrapperList.size());

    return associationsWrapperList;
  }
  
   public static CommonWrapperClass.UBOOwnerData createAssociationWrapper(Associated_Relationships__c ar, Integer level, CommonWrapperClass.UBOBorrowerData uboBorrowerData)
   {
        String THRESHOLD_STR ='Under Required Threshold';
        String baseURL='https://'+String.valueof(System.URL.getSalesforceBaseURL().gethost());
        CommonWrapperClass.UBOOwnerData uboOwnerWrapper = new CommonWrapperClass.UBOOwnerData();  
        
        uBOOwnerWrapper.dataErrors = '';

        uboOwnerWrapper.associationId = ar.id;
        uboOwnerWrapper.goPrimaryRelRecordId = ar.Primary_Relationship__c;
        uboOwnerWrapper.goRelationshipRecordId= ar.Secondary_Relationship__c;
        if(ar.secondary_relationship__c!=null)
        {
            if(ar.type__c == 'Entity')
            {
                uboOwnerWrapper.Name=ar.secondary_relationship__r.name;
                uboOwnerWrapper.isIndividual =false;
                uboOwnerWrapper.isEntity=true;
                uboOwnerWrapper.isUnderThreshold=false; 
            }
            else if(ar.type__c=='Individual')
            {
                uboOwnerWrapper.firstname =ar.secondary_relationship__r.First_Name__c;
                uboOwnerWrapper.lastname=ar.secondary_relationship__r.Last_Name__c;
                uboOwnerWrapper.name = uboOwnerWrapper.firstname + ' ' + uboOwnerWrapper.lastname;
                uboOwnerWrapper.isIndividual =true;
                uboOwnerWrapper.isEntity=false;
                uboOwnerWrapper.isUnderThreshold=false;
            }
            else
            {
                uboOwnerWrapper.Name=ar.secondary_relationship__r.name;
                uBOOwnerWrapper.dataErrors = 'Type field cannot be blank on an Association record.';
            }
        }
        else
        {
            uboOwnerWrapper.Name=THRESHOLD_STR;
            uboOwnerWrapper.isIndividual =false;
            uboOwnerWrapper.isEntity=false;
            uboOwnerWrapper.isUnderThreshold=true;
        }   
        
        uboOwnerWrapper.goRelationshipRecordURL =  baseURL+'/lightning/r/Account/'+ar.secondary_relationship__c+'/view';
        uboOwnerWrapper.level =level;
        uboOwnerWrapper.type= ar.type__c;
        uboOwnerWrapper.associationType = ar.association_type__c ;
        
        if( ar.ownership_percentage__c != null)
          uboOwnerWrapper.ownershipPct = string.valueof(ar.ownership_percentage__c);

        if(uboOwnerWrapper.Name==THRESHOLD_STR)
        {
          uboOwnerWrapper.type='Individual';
          return uboOwnerWrapper;
        }

        if(ar.Secondary_Relationship__r.date_of_birth__c != null)
          uboOwnerWrapper.dateOfBirth = ar.secondary_relationship__r.date_of_birth__c.format();

        uboOwnerWrapper.addrStreet = ar.secondary_relationship__r.billingStreet;
        uboOwnerWrapper.addrCity = ar.secondary_relationship__r.billingCity;
        uboOwnerWrapper.addrStateCode = ar.secondary_relationship__r.billingStateCode;
        uboOwnerWrapper.addrZip = ar.secondary_relationship__r.billingPostalCode;
        uboOwnerWrapper.addrCountryCode = ar.secondary_relationship__r.billingCountryCode;

        uboOwnerWrapper.TINType = ar.secondary_relationship__r.UBO_Tin_Type__c;
        uboOwnerWrapper.TINTypeNumber = ar.secondary_relationship__r.UBO_Tin_Type_Number__c;
 
        if(ar.type__c == 'Entity' && ar.secondary_relationship__r.legal_entity__c == null)
          uBOOwnerWrapper.dataErrors = uBOOwnerWrapper.dataErrors + 'Legal Entity Structure cannot be blank for an Entity Owner / Guarantor.';

        if(uBOOwnerWrapper.TINType == 'EIN' || uBOOwnerWrapper.TINType == 'FOREIGN TAX ID')
        {
          if(ar.secondary_relationship__r.Tax_Identification_Number__c!=null)
          {
              uBOOwnerWrapper.TIN = (ar.secondary_relationship__r.Tax_Identification_Number__c.isNumeric()?ar.secondary_relationship__r.Tax_Identification_Number__c: StripOutAllNonNumericCharacters(ar.secondary_relationship__r.Tax_Identification_Number__c));  
          }
        }
        else if(uBOOwnerWrapper.TINType == 'SSN' || uBOOwnerWrapper.TINType == 'ITIN' || uBOOwnerWrapper.TINType == 'NO TIN')
        {
          if(uBOOwnerWrapper.TINType == 'NO TIN')
            uBOOwnerWrapper.isNoTIN = true;
          
          if(ar.secondary_relationship__r.social_security_number__c != null)
          {
            uBOOwnerWrapper.TIN = (ar.secondary_relationship__r.social_security_number__c.isNumeric()?ar.secondary_relationship__r.social_security_number__c: StripOutAllNonNumericCharacters(ar.secondary_relationship__r.social_security_number__c));
          }
        }
        
        if(level == 1 && ar.Authorized_Signer__c == true && ar.type__c=='Individual')
        {
          uboOwnerWrapper.isControlProng = true;
        }
        
        uboOwnerWrapper.hasDataErrors=false;
        
        if(uboOwnerWrapper.name!=THRESHOLD_STR)
        {
            uboOwnerWrapper.dataErrors =validateUBOOwnerData(uboOwnerWrapper);
            
            if(!String.isBlank(uboOwnerWrapper.dataErrors))
            {
                uboOwnerWrapper.hasDataErrors =TRUE;
                
                if(uboBorrowerData!=null && !uboBorrowerData.childrenHaveErrors)
                {
                   uboBorrowerData.childrenHaveErrors=TRUE; 
                }
            }
        }
        if(uboOwnerWrapper.ownersList  ==null)
            uboOwnerWrapper.ownersList  = new List<CommonWrapperClass.UBOOwnerData>();
            
        System.debug('==== uboOwnerWrapper ==='+uboOwnerWrapper);
        return uboOwnerWrapper;
    }
    
    public static Set<Id> fetchAllCoBorrowersTiedToThisDealer(Id accId)
    {
      Set<Id> coBorroweracctIds = new set<Id>();
      
      List<Associated_Relationships__c > coBorrowerassociationList = [select id, Primary_Relationship__c,Secondary_Relationship__c from Associated_Relationships__c where Primary_Relationship__c=:accId and Secondary_Relationship__r.RecordType.DeveloperName='Co_Borrower'];
      
      if(coBorrowerassociationList!=null && coBorrowerassociationList.size() >0)
      {
         for(Associated_Relationships__c ar: coBorrowerassociationList)
         {
            coBorroweracctIds.add(ar.Secondary_Relationship__c);
         }
      }
      
      return coBorroweracctIds;
    }
    
    public static String validateDealerOrCoBorrowerData(CommonWrapperClass.UBOBorrowerData b)
    {
        String errorMsg;
        
        if(!string.isBLank(b.dataErrors))
        {
          errorMsg = b.dataErrors;
        }
        else 
        {
          errorMsg = '';
        }

        if(String.isBlank(b.Name))
        {
          errorMsg+='Customer\'s name cannot be blank.';
        }
        
        if(string.isBlank(b.Naicscode))
        {
          errorMsg += 'Customer\'s NAICS code cannot be blank.';
        }
        
        if(string.isBlank(b.addrStreet))
        {
          errorMsg += 'Customer\'s Primary Street cannot be blank.';
        }
        
        if(string.isBlank(b.addrCity))
        {
          errorMsg += 'Customer\'s Primary City cannot be blank.';
        }
        
        if(string.isBlank(b.addrStateCode))
        {
          errorMsg += 'Customer\'s Primary State cannot be blank.';
        }
        
        if(string.isBlank(b.addrZip))
        {
          errorMsg += 'Customer\'s Primary Zipcode cannot be blank.';
        }
        
        if(string.isBlank(b.addrCountryCode))
        {
          errorMsg += 'Customer\'s Primary Country cannot be blank.';
        }

        if(!string.isBlank(b.addrCountryCode) && b.addrCountryCode == 'US' && string.isBlank(b.TIN))
        {
          errorMsg += 'Customer\'s Tax Identification Number cannot be blank.';
        }
        else if(!string.isBlank(b.addrCountryCode) && b.addrCountryCode == 'CA' && string.isBlank(b.TIN))
        {
          errorMsg += 'Customer\'s Tax Identification Number cannot be blank.';
        }
        
        Boolean IndividualControlProngFoundForThisCustomer = false;

        if(b.ownersList != null && b.ownersList.size() > 0)
        {
          for(CommonWrapperClass.UBOOwnerData o: b.ownersList)
          {
            system.debug(o.Name+o.Firstname+o.isControlProng);

            if(o.isControlProng == true)
            {
              individualControlProngFoundForThisCustomer = true;
            }
          }
        }

        if(IndividualControlProngFoundForThisCustomer == false)
        {
          b.hasdataErrors = true;
          errorMsg += 'Control Prong (Individual - Authorized Signer) not found for this customer.';
        }

        return errorMsg;
    }
    
    public Static String validateUBOOwnerData(CommonWrapperClass.UBOOwnerData uBOOwner)
    {
        String errorMsg;
        
        if(!string.isBLank(uBOOwner.dataErrors))
        {
           errorMsg = uBOOwner.dataErrors;
        }
        else 
          errorMsg = '';
        
        String guarantorName='';
        
         if(uBOOwner.Type == 'Individual' && string.isBlank(uBOOwner.firstname) && string.isBlank(uBOOwner.lastname))
         {
            errorMsg += 'Individual Owner / Guarantor cannot have a blank Firstname or Lastname.';
         }
         else
         {
            guarantorName= uBOOwner.firstname+' '+uBOOwner.lastname;
         }
         
         if(uBOOwner.Type == 'Entity' && string.isBlank(uBOOwner.name))
         {
            errorMsg += 'Entity Owner / Guarantor cannot have a blank name.';
         }
         else
         {
            guarantorName= uBOOwner.name;
         }
         
         if(string.isBlank(uBOOwner.addrStreet))
         {
            //errorMsg += (errorMsg==''?'':'.')+'Owner/Guarantor ' + '('+ guarantorName + ') cannot have a blank Primary Street';
            errorMsg += 'Owner / Guarantor cannot have a blank Primary Street.';
         }
         
         if(string.isBlank(uBOOwner.addrCity))
         {
            errorMsg += 'Owner / Guarantor cannot have a blank Primary City.';
         }
         
         if(string.isBlank(uBOOwner.addrStateCode))
         {
            errorMsg += 'Owner / Guarantor cannot have a blank Primary State.';
         }
         
         if(string.isBlank(uBOOwner.addrZip))
         {
            //errorMsg += (string.isBlank(errorMsg)=true?'':'')+'Owner/Guarantor ' + ' cannot have a blank Primary Zipcode.';
            errorMsg += 'Owner / Guarantor cannot have a blank Primary Zipcode.';
         }
         
         if(string.isBlank(uBOOwner.addrCountryCode))
         {
            errorMsg += 'Owner / Guarantor cannot have a blank Primary Country.';
         }
         
         
         if(string.isBlank(uBOOwner.dataErrors))
         {
           if(uBOOwner.type == 'Individual' && string.isBlank(uBOOwner.DateOfBirth))
           {
              errorMsg += 'Individual Owner / Guarantor cannot have a blank Date of Birth.';
           }
         
           if(uBOOwner.addrCountryCode == 'US' && uBOOwner.Type == 'Individual' && (uBOOwner.TINTypeNumber != '1' || (uBOOwner.TINTypeNumber == '1' && string.isBlank(uBOOwner.TIN))) && !string.isBLank(uBOOwner.dataErrors) && uBOOwner.dataErrors.contains('Legal Entity Structure'))
           {
              errorMsg += 'US Individual Owner / Guarantor cannot have a blank SSN.';
           }
         }
         
         
         if(string.isBlank(uBOOwner.TIN))
         {
            errorMsg += 'Owner/Guarantor has invalid TIN Type / TIN Number.';
         }
         
         return errorMsg;
    }
    
    public Static String StripOutAllNonNumericCharacters(String text)
    {
        String numericStr='';
        String pExp='\\d+';
        Pattern p=Pattern.compile(pExp);
        Matcher m=p.matcher(text);
    
        while (m.find()) 
        {
            numericStr+=text.substring(m.start(), m.end());
        }
        return numericStr;
    }
    
     public Static String removeSpacesAndSpecialChars(String str)
     {
        if(String.isBlank(str))
        {
            return '';
        }
        
        return str.replaceAll( '\\s+', '').replaceAll('[^a-zA-Z0-9\\s+]', '');
     } 
    //-end
    
     /*     data format = 'key=value; key1=A;key2=7;key3=Z; key4=25'  
     *   parseKeyValue(data, 'key3', '=', ';') => returns 'Z'
  */
    public static string parseKeyValue(string bigVal, string key, string mapOperator, string splitChar){
        string result='';
        if(!String.IsBlank(bigVal) && !String.IsBlank(key) && !String.IsBlank(mapOperator) && !String.IsBlank(splitChar))
        {
                for(string chunk: bigVal.split(splitChar)){
                if(chunk.contains(key)){
                    result = chunk.substringAfter(mapOperator);
                    break;
                }   
            }
        }
        system.debug(bigVal+'/'+key+' => '+result);
        return result;
    }
    
    public static void debugStateLimits(string label){
        System.debug('*** Checking Apex Limits For: '+label);
        string pref = ' >>>>>> ';
        System.debug(pref+'SQL QUERIES = '+Limits.getQueries()+' / '+Limits.getLimitQueries());
        System.debug(pref+'SQL ROWS = '+Limits.getQueryRows()+' / '+Limits.getLimitQueryRows());
        System.debug(pref+'CPU TIME = '+Limits.getCpuTime()+' / '+Limits.getLimitCpuTime());
        System.debug(pref+'DML STATEMENTS = '+Limits.getDMLStatements()+' / '+Limits.getLimitDMLStatements());
    }
    
    public static string getUserSourceIPAddress()
    {
      string sourceIP='';
        
      //Get user's source ip address  
      sourceIP=ApexPages.currentPage().getHeaders().get('True-Client-IP');
         
      // X-Salesforce-SIP has the value when no caching integration or via secure URL.
      if (sourceIP == '' || sourceIP == null)
        sourceIP=ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        
      // get IP address when no caching (sandbox, dev, secure URLs)
      if (sourceIP == '' || sourceIP == null)
        sourceIP=ApexPages.currentPage().getHeaders().get('X-Forwarded-For');
      
      system.debug(sourceIP);
      
      return sourceIP;
    }
}