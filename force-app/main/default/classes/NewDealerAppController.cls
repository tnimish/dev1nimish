/******************************************************************************************************************************
* @class name  : NewDealerAppController
* @description : NewDealerAppController serves as the controller of wizard based VF application
                 There could be 7 different applications(based on Country, language and product)

  
* @test class  : NewDealerApplicationControllerTest             
* @author      : Kamran Mahmood
* @date        : 4/22/2015               
                   
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer        Date(MM/DD/YYYY)    Description
  Michael T        2/27/2018           removed deleted field (Legal_Entity_NameOld__c)
  Michael T        3/26/2018           added method checkListForDeleted(), WI 2306
  Michael T        8/ 6/2018           updated for new sobject Underwriting__c
  Michael T        9/25/2018           associations type default = 'Guarantor' (changed from 'Owner') 
  Santosh K        1/ 9/2019           fixed bug that was creating product junction records with null relationship'
  Santosh K        5/ 9/2019           WI 3650. Set Created_Through_App_Site__c to true on account(care, legal entity, guarantor and prospect) insertion
  
******************************************************************************************************************************/

global without sharing class NewDealerAppController
{ 
  //Value for this variable will be set from the NDA AU NZ Support custom metadata in the constructor
  //Only if TRUE, then the AU NZ related code in the NDA controller and NDA pages will get executed.    
  public Boolean AU_NZ_Support {get;set;}
  //
  
  public class ndaException extends Exception {}

  public boolean showErrorMessage {get;set;}
  public final string UNEXPECTED_ERROR_OCCURRED = System.Label.Unexpected_Error_Occurred;

  public string sourceIPAddress {get;set;}
  public string appURL {get;set;}
  public string internalAppNewURL {get;set;} 
  public boolean isInternalApp {get;set;}
  public boolean isSandBox {get;set;}
  public boolean isInternalUser {get;set;}
  public boolean isInternalUserSysAdmin {get;set;}
  public boolean blockAppCreation {get;set;}
  public boolean printNDAAccessVariables {get;set;}
   
  public Map<string, string> stateCodeToNameMap = new Map<string, string>();
  public Map<string, string> stateNameToCodeMap = new Map<string, string>();

  public boolean editProduct {get;set;}
  public string productIdToEditSaveOrDelete  {get;set;}
  public string prodObfToSave {get;set;}
  public string prodObfNameToSave {get;set;}

  public string locationNumToDelete {get; set{locationNumToDelete = value;}}
  public string referenceNumToDelete {get; set{referenceNumToDelete = value;}}

  public string actId {get;set;}
   
  public string dnbUserId; 
  public string dnbPassword;
   
  public boolean loggedInUserIsGuestSiteUser {get;set;}
  public boolean NDAHasMoreThanOneRelationships {get;set;}
  
  public string US_NDACreationDate {get;set;}
  public string CA_NDACreationDate {get;set;}
  public string AU_NZ_NDACreationDate {get;set;}

  public boolean unSubmittedAppFound {get;set;}
  public boolean showRIA {get;set;} 
  public boolean showCanadianEnglish {get;set;}
  public string bankIdToDelete {get;set;}
  public string saveForLater {get;set;}
  public string  showInputsValidationMessageOnMainPage {get;set;}
  public boolean showPasswordFields {get;set;}

   public string             ownerType {get;set;}
   public Integer            saveWhichOwnerNum {get;set;}
   public Integer            entityParentOwnerNum {get;set;}
   public Id                 entityParentOwnerRecordId{get;set;}
   public Id                 editWhichOwnerRecord {get;set;}
   public string             cancelClicked {get;set;}
   public string             agreeClicked {get;set;}
   public string             signerFirstName {get;set;}
   public string             signerLastName {get;set;}
   public Boolean            signerNameDidNotMatchOwnerName {get;set;}
   public Boolean            termsOfUseSigned {get;set;}
   public Id                 deleteWhichOwnerRecord {get;set;}
   public List<selectOption> states {set;}
   public string             pageMessage {get;set;}
   public string             collapsedOrExpandedOwnerType {get;set;}
   public string             collapsedOrExpandedOwnerRelRecId {get;set;}

   public string policyrenewaldate {get;set;}
   public string headerValue {get;set;}
  
   public New_Dealer_Application__c nda {get;set;}
   public static Boolean ndaSubmittedOrWithdrawn {get;set;}
   public NdaPdfWrapper ndaPDF {get;set;}
   public Account existingRelationshipAcct {get; set;} 
   private String ndaId; 
   private String leg; 
   private String ph;
   private String fstate;
   private boolean newApplication  {get; set;}
   public boolean existingRelationship {get; set;}
   public boolean searched {get; set;} 
   private Integer ThisAppNr = 1;
   public Decimal USAmount {get; set;} 
   public Decimal CanadaAmount {get; set;} 
   public List<Id> prospRecTypIds {get; set;}  
   public string currPageURL {get;set;} 

   public Account Downer {get; set;}
   public Contact DummyContact {get; set;}
   public Associated_Relationships__c Dassoc {get; set;}
   public String termsofusetext {get; set;}
   public string consentFN {get;set;}
   public string consentMN {get;set;}
   public string consentLN {get;set;}
   public String entity;
    
   public String country {get; set;}
   public String language {get; set;} 
   public String product {get; set;} 
   public String ApplNr {get; set;} 
   public String pass {get; set;}

   public Boolean thisProductAlreadyExistsForThisNDA {get;set;}
   public string selectedIndustry {get;set;}
   public List<selectOption> industryOptions {get;set;}
  
   public string selectedManufacturer {get;set;}
   public string selectedManufacturerName {get;set;}
   public string selectedOtherManufacturerName {get;set;}

   public List<selectOption> mfrOptions {get;set;}
   // WI 3676 NDA title Limitations
   public List<selectOption> ndatitleOptions {get;set;}

   public List<selectOption> ndaContentTypes
   {
     get
     {
        //Get NDA DocTypes from metadata
        List<selectOption> soList = new List<selectOption>();
        List<ObjectDocCategoriesAndContentTypes__mdt> ctypesList = [select id, DocType__c, Display_on_NDA__c from ObjectDocCategoriesAndContentTypes__mdt where Display_on_NDA__c = true];

        soList.add(new selectOption('','- Select a Document Type -'));

        if(ctypesList != null && ctypesList.size() > 0)
        {
          for(ObjectDocCategoriesAndContentTypes__mdt ct: ctypesList)
          {
            soList.add(new selectOption(ct.DocType__c,ct.DocType__c));
          }
        }
      
        return soList;
     }
     set;
   }

   public string selectedNDAContentType {get;set;}

   public Map<string, string> EnglishToFrenchCAProvinceMap
   {
     get
     {
       if(EnglishToFrenchCAProvinceMap == null)
       {
         EnglishToFrenchCAProvinceMap = new Map<string, string>();
         
         EnglishToFrenchCAProvinceMap.put('Alberta', 'Alberta');
         EnglishToFrenchCAProvinceMap.put('British Columbia','Columbie-Britannique');
         EnglishToFrenchCAProvinceMap.put('Manitoba', 'Manitoba');
         EnglishToFrenchCAProvinceMap.put('New Brunswick', 'Nouveau-Brunswick');
         EnglishToFrenchCAProvinceMap.put('Newfoundland and Labrador','Terre-Neuve-et-Labrador');
         EnglishToFrenchCAProvinceMap.put('Nova Scotia','Nouvelle-Écosse');
         EnglishToFrenchCAProvinceMap.put('Ontario','Ontario');
         EnglishToFrenchCAProvinceMap.put('Prince Edward Island','Île-du-Prince-Édouard');
         EnglishToFrenchCAProvinceMap.put('Quebec','Québec');
         EnglishToFrenchCAProvinceMap.put('Saskatchewan','Saskatchewan');
         EnglishToFrenchCAProvinceMap.put('Northwest Territories','Territoires du nord-ouest');
         EnglishToFrenchCAProvinceMap.put('Nunavat','Nunavat');
         EnglishToFrenchCAProvinceMap.put('Yukon','Yukon');
          
       }
       return EnglishToFrenchCAProvinceMap;
     }
     set;
   }
   
   public Map<string, string> FrenchToEnglishCAProvinceMap
   {
     get
     {
       if(FrenchToEnglishCAProvinceMap == null)
       {
         FrenchToEnglishCAProvinceMap = new Map<string, string>();
         
         FrenchToEnglishCAProvinceMap.put('Alberta', 'Alberta');
         FrenchToEnglishCAProvinceMap.put('Columbie-Britannique','British Columbia');
         FrenchToEnglishCAProvinceMap.put('Manitoba', 'Manitoba');
         FrenchToEnglishCAProvinceMap.put('Nouveau-Brunswick', 'New Brunswick');
         FrenchToEnglishCAProvinceMap.put('Terre-Neuve-et-Labrador','Newfoundland and Labrador');
         FrenchToEnglishCAProvinceMap.put('Nouvelle-Écosse','Nova Scotia');
         FrenchToEnglishCAProvinceMap.put('Ontario','Ontario');
         FrenchToEnglishCAProvinceMap.put('Île-du-Prince-Édouard','Prince Edward Island');
         FrenchToEnglishCAProvinceMap.put('Québec','Quebec');
         FrenchToEnglishCAProvinceMap.put('Saskatchewan','Saskatchewan');
         FrenchToEnglishCAProvinceMap.put('Territoires du nord-ouest','Northwest Territories');
         FrenchToEnglishCAProvinceMap.put('Nunavat','Nunavat');
         FrenchToEnglishCAProvinceMap.put('Yukon','Yukon');
          
       }
       return FrenchToEnglishCAProvinceMap;
     }
     set;
   }
  
   public Map<string, string> EnglishToFrenchIndustryMap
   {
     get
     {
       if(EnglishToFrenchIndustryMap == null)
       {
         EnglishToFrenchIndustryMap = new Map<string, string>();
         
         EnglishToFrenchIndustryMap.put('Lawn & Garden', 'Matériel pour pelouses et jardins');
         EnglishToFrenchIndustryMap.put('Electronics & Appliances','Électronique et électroménager');
         EnglishToFrenchIndustryMap.put('Marine', 'Produits nautiques');
         EnglishToFrenchIndustryMap.put('PowerSports', 'Sports motorisés');
         EnglishToFrenchIndustryMap.put('Recreation Vehicle','Véhicule récréatif');
         EnglishToFrenchIndustryMap.put('Specialty Products','Produits spéciaux'); 
       }
       return EnglishToFrenchIndustryMap;
     }
     set;
   }
  
   public pagereference refreshMfrOptions()
   {
     List<manufacturer__c> mList = new List<manufacturer__c>();
     mfrOptions = new List<selectOption>();
    
     if(nda.language__c == 'English')
     {
       mfrOptions.add(new selectOption('','-Select One-'));
     }
     else if(nda.language__c == 'French Canadian')
     {
       mfrOptions.add(new selectOption('','-Choisir un-'));
     }

     if(!string.isBlank(selectedIndustry))
     {
       if((AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c == 'New Zealand')))
       {
         mList = [select id, name from manufacturer__c where industry__c = :selectedIndustry and (name = 'Toro' or primary_manufacturer__r.name = 'Toro' or name like '%BRP%' or primary_manufacturer__r.name like '%BRP%') order by name asc];
       }
       else if(nda.country__c == 'United States' && nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.startsWith('Toro'))
       {
         mList = [select id, name from manufacturer__c where industry__c = :selectedIndustry and (name = 'Toro' or primary_manufacturer__r.name = 'Toro') order by name asc];
       }
       else
       {
         mList = [select id, name from manufacturer__c where industry__c = :selectedIndustry order by name asc];
       }
        
       for(manufacturer__c m: mList)
       {
         mfrOptions.add(new selectOption(m.id, m.name));
       }
     } 
    
     return null;
  }  
  
  //Remove this later
  public boolean Canada {get;set;}
  
  public string selectedObtainedFrom {get;set;}
  public List<selectOption> obtainedFromOptions {get;set;}
  
  public pagereference refreshObtainedFromOptions()
  {
    obtainedFromOptions = new List<selectOption>();
    
    obtainedFromOptions.add(new SelectOption('Direct', 'Direct'));
    
    List<Manufacturer__c> mList = [select id, name from manufacturer__c where id=:selectedManufacturer];

    string prMfrName;
    
    if(mList != null && mList.size() > 0)
    {
      selectedManufacturerName = mList[0].name;
    }
    
    if((nda.country__c == 'United States' || nda.country__c == 'Canada') && (selectedIndustry == 'Lawn & Garden') && (!string.isBlank(selectedManufacturerName) && (selectedManufacturerName.equalsignorecase('Toro') || selectedManufacturerName.equalsignorecase('Boss Snowplow') || selectedManufacturerName.equalsignorecase('Site Works') || selectedManufacturerName.equalsignorecase('Exmark') || selectedManufacturerName.equalsignorecase('Other'))))
    {
      if(nda.language__c == 'English')
        obtainedFromOptions.add(new SelectOption('Distributor', 'Distributor'));
      else if(nda.language__c == 'French Canadian')
        obtainedFromOptions.add(new SelectOption('Distributor', 'Distributeur'));
    }
    else if((selectedIndustry == 'Electronics & Appliances') && GeneralVersion)
    {
      if(nda.language__c == 'English')
        obtainedFromOptions.add(new SelectOption('Buying Group', 'Buying Group'));
      else if(nda.language__c == 'French Canadian')
        obtainedFromOptions.add(new SelectOption('Buying Group', 'Groupe d\'achat'));  
    }
    else if(selectedIndustry == 'Specialty Products' && GeneralVersion)
    {
      if(nda.language__c == 'English')
        obtainedFromOptions.add(new SelectOption('Distributor', 'Distributor'));
      else if(nda.language__c == 'French Canadian')
        obtainedFromOptions.add(new SelectOption('Distributor', 'Distributeur'));
    }
     
    return null;
  }
   
  public string selectedObtainedFromName {get;set;} 
  public List<selectOption> obtainedFromNameOptions {get;set;}
  
  public pagereference refreshObtainedFromNameOptions()
  {
    obtainedFromNameOptions = new List<selectOption>();
  
    if(nda.language__c == 'English')    
      obtainedFromNameOptions.add(new SelectOption('','-Select One-'));
    else if(nda.language__c == 'French Canadian')  
      obtainedFromNameOptions.add(new SelectOption('','-Choisir un-'));
      
    Schema.DescribeFieldResult fieldResult = Product_Information_For_New_Dealer_App__c.obtained_from_name__c.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
    for( Schema.PicklistEntry f : ple)
    {
      obtainedFromNameOptions.add(new SelectOption(f.getValue(), f.getLabel()));
    }   
  
    return null;
  }

    public list<Product_Information_For_New_Dealer_App__c> ProductsList{get; set;}
    public list<Additional_Location__c> NrofLocationsList {get; set;}
    public List<Bank__c> NrofReferencesList{get; set;} 
    public List<Account> OwnersList{get; set;} 
    public List<Associated_Relationships__c> AssociationList{get; set;}
    public List<Associated_Relationships__c> pdfUniqueAssociationsList {get;set;}
    public Map<Id,list<String>> OwnerAssocMap {get; set;}
    public List<Manufacturer__c>  ManufactList {get; set;} 

    public string industry {get;set;}
    public string primaryManufacturer {get;set;} 
    
    public List<BankPdfWrapper> NrofReferencesListPDF {get;set;}
    
    public string tempPassword {get;set;}
    public string langCode {get;set;}
    public string entityTypeForApp {get;set;}
    
    public static string applicantName {get;set;} 
    public Boolean showOwnerConsent {get;set;}

    public static Account matchedProspect {get;set;}
    public static string matchedProspectId {get;set;}

    public string bankruptcy {get;set;}  
    public string bankruptcyDetails {get;set;}
    public string legalProceedings {get;set;}
    public string legalProceedingsDetails {get;set;}
    public string delinquentTaxes {get;set;}
    public string delinquentTaxesDetails {get;set;}
    public string bankruptcyEtcQuesErrorMessage {get;set;}
        
    public string buttonClicked {get;set;}
    
    public string applicantRepFirstName {get;set;}
    public string applicantRepLastName {get;set;}
    public string applicantRepEmail {get;set;}

  //Location Page Redesign
  public Integer displayNumLocBlocks {get;set;}
  public string  locBlockCorpNum {get;set;}
  
  public string numLocsChanged {get;set;}
  public string locActionStatusString {get;set;}
  public List<Loc> locsList {get;set;}
  public string locationsValidationMsg {get;set;}
  
  public class Loc
  {
    public string  num {get;set;}
    public string  recId {get;set;}
    public string  street {get;set;}
    public string  city {get;set;}
    public string  state {get;set;}
    public string  postalcode {get;set;}
    public List<string>  messages {get;set;}
  }    
  //

  //References Page Redesign
  public Integer displayNumRefBlocks {get;set;}
  public string numRefsChanged {get;set;}
  public string refActionStatusString {get;set;}
  public string referencesValidationMsg {get;set;}
  public List<Ref> refsList {get;set;}
  
  public class Ref 
  {
    public string  num {get;set;}
    public string  recId {get;set;}
    public string  acctType {get;set;}
    public string  bankName {get;set;}
    public string  phoneNumber {get;set;}
    public string  avgBalance {get;set;}
    public string  creditAmt {get;set;} 
    public List<string>  messages {get;set;}
  }

  public List<selectOption> acctTypeOptions 
  {
    get
    {
      List<selectOption> aTOptions = new List<selectOption>();
      
      aTOptions.add(new SelectOption('','-Select One-'));       
  
      Schema.DescribeFieldResult fieldResult;
      
      if(nda.country__c == 'United States' || (AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c == 'New Zealand')))
      {
        fieldResult = Bank__c.type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry f : ple)
        {
          aTOptions.add(new SelectOption(f.getValue(), f.getLabel()));
        }
      }
      else if(nda.country__c == 'Canada')
      {
        fieldResult = Bank__c.Type_of_Established_Canada__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry f : ple)
        {
          aTOptions.add(new SelectOption(f.getValue(), f.getLabel()));
        }  
      }
      
      return aTOptions;
    }   
    set;
  }
  //

  //Owner Page Redesign
  public Integer displayNumIndOwnerBlocks {get;set;}
  public Integer displayNumCorpOwnerBlocks {get;set;}
    
  public Integer displayNumIndEntityOwnerBlocks {get;set;}
  public Integer displayNumCorpEntityOwnerBlocks {get;set;}
   
  public Integer displayIndCorpPanelForCorpNum {get;set;}
    
  public string indBlockCorpNum {get;set;}
  public string corpBlockCorpNum {get;set;}
    
  public string numIndOwnersChanged {get;set;}
  public string numCorpOwnersChanged {get;set;}
  public string numIndEntityOwnersChanged {get;set;}
  public string numCorpEntityOwnersChanged {get;set;}
  public string actionStatusString {get;set;}
  public List<indOwner> indEntityOwners;
  public List<indOwner> indOwnerList {get;set;}
  public List<corpOwner> corpOwnerList {get;set;}  
  public CorpOwnerInfo cOInfo {get;set;}
  public List<corpOwnerInfo> corpEntityOwners {set;}
  public Boolean showNoOwnersMessage {get;set;}
  public Boolean showOwnerNoConsentMessage {get;set;}
     
  public class IndOwner
  {
    public string  num {get;set;}
    public string  ownerType {get;set;}
    public string  firstname {get;set;}
    public string  lastname {get;set;}
    public string  middlename {get;set;}
    public string  suffix {get;set;}
    public string  street {get;set;}
    public string  city {get;set;}
    public string  state {get;set;}
    public string  postalcode {get;set;} 
    public string  phone {get;set;}
    public string  email {get;set;}
    public string  ssn {get;set;}
    public string  driversLicenseNumber {get;set;}
    public string  driversLicenseExpDate {get;set;}
    public string  birthdate {get;set;}
    public string  title {get;set;}
    public string  pctOwnership {get;set;}
    public id      ownerRelationshipRecordId {get;set;}
    public id      ownerRecordId {get;set;}
    public List<id> assocRecordIdsList {get;set;}
    public string  parentCorpOwnerNum {get;set;}
    public string  parentCorpOwnerName {get;set;}
    public id      parentCorpOwnerRelationshipRecordId {get;set;}
    public Boolean showSaveButton {get;set;}
    public Boolean showEditButton {get;set;}
    public Boolean showDeleteButton {get;set;}
    public Boolean showSignButton {get;set;}
    public Boolean termsOfUseSigned {get;set;} 
    public Boolean showIndConsents {get;set;}
    public Boolean showCorpConsents {get;set;}
    public string  consentSigned {get;set;}
    public List<string>  messages {get;set;}
    public Boolean collapsed {get;set;}  
  }
    
  public class CorpOwner
  {
    //Entity Owner of the dealer
    public corpOwnerInfo cOwnerInfo {get;set;}
      
    public Integer  numIndEntityOwners {get;set;}
    public Integer  numCorpEntityOwners {get;set;}
      
    //List of individual owners that are owners of the entity
    public List<indOwner>  indEntityOwnersList {get;set;}
    public List<corpOwnerInfo> corpEntityOwnersList {get;set;} 
      
    public CorpOwner()
    {
      cOwnerInfo = new corpOwnerInfo();
      indEntityOwnersList = new List<IndOwner>();
      corpEntityOwnersList = new List<CorpOwnerInfo>();        
    }     
  }
    
  public class CorpOwnerInfo
  {   
    public string  num {get;set;}
    public string  ownerType {get;set;}
    public string  legalEntityName {get;set;}
    public string  street {get;set;}
    public string  city {get;set;}
    public string  state {get;set;}
    public string  postalcode {get;set;} 
    public string  taxID {get;set;}
    public string  formationState {get;set;}
    public string  pctOwnership {get;set;}
    public string  authorizedSignerFirstname {get;set;}
    public string  authorizedSignerMiddlename {get;set;}
    public string  authorizedSignerLastname {get;set;}
    public string  entityOwnerTitle {get;set;}
    public id      ownerRelationshipRecordId {get;set;}
    public id      ownerRecordId {get;set;}
    public List<id> assocRecordIdsList {get;set;}
    public string  parentCorpOwnerNum {get;set;}
    public string  parentCorpOwnerName {get;set;}
    public id      parentCorpOwnerRelationshipRecordId {get;set;}
    public Boolean showSaveButton {get;set;}
    public Boolean showEditButton {get;set;}
    public Boolean showDeleteButton {get;set;}
    public Boolean showSignButton {get;set;}
    public Boolean termsOfUseSigned {get;set;} 
    public Boolean showIndConsents {get;set;}
    public Boolean showCorpConsents {get;set;}
    public string  consentSigned {get;set;}
    public List<string>  messages {get;set;}
    public Boolean collapsed {get;set;}
  }

  public Boolean GeneralVersion {get{if(GeneralVersion != true){GeneralVersion = false;} return GeneralVersion;}set;}
  public Boolean RIAVersion     {get{if(RIAVersion != true){RIAVersion = false;}return RIAVersion;}set;}
  public Boolean BRPVersion     {get{if(BRPVersion != true){BRPVersion = false;} return BRPVersion;}set;}
  public Boolean MTDVersion     {get{if(MTDVersion != true){MTDVersion = false;} return MTDVersion;}set;} 
  public Boolean TCFCFVersion   {get{if(TCFCFVersion != true){TCFCFVersion = false;}return TCFCFVersion;}set;}
  public Boolean TCFAUVersion   {get{if(TCFAUVersion != true){TCFAUVersion = false;}return TCFAUVersion;}set;}
  public Boolean TCFNZVersion   {get{if(TCFNZVersion != true){TCFNZVersion = false;}return TCFNZVersion;}set;}

  public Id CanadianRecordTypeID{get{if(CanadianRecordTypeID == null){CanadianRecordTypeID = Constants.NewDealerAppRTMap.get('Canadian');}return CanadianRecordTypeID;}set;}

  public string colorScheme 
  {
    get
    {    
      if(colorScheme == null)
      {
        if(GeneralVersion || TCFAUVersion || TCFNZVersion)
        {
          colorScheme = 'default';
          system.debug('1');
        }
        else if(BRPVersion)
        {
          colorScheme = 'BRP';
          system.debug('2');
        }
        else if(MTDVersion)
          colorScheme = 'MTD';
        else if(RIAVersion)
          colorScheme = 'RIA';
      }
        
      return colorScheme;   
    }
    set;
  }

  public List<SelectOption> getCountires() 
  {
    List<SelectOption> options = new List<SelectOption>(); 
    options.add(new SelectOption('United States','United States')); 
    options.add(new SelectOption('Canada','Canada'));
    
    if(AU_NZ_Support)
    {
      options.add(new SelectOption('Australia','Australia'));
      options.add(new SelectOption('New Zealand','New Zealand'));
    }
     
    return options; 
  }
        
  public List<SelectOption> getLanguages() 
  {
    List<SelectOption> options = new List<SelectOption>(); 
    options.add(new SelectOption('English','English')); 
    options.add(new SelectOption('French Canadian','French Canadian')); 
    return options; 
  }

   public Id GauranotrRecType 
   {
     get
     {
       if(GauranotrRecType == null)
       {
         GauranotrRecType = Constants.AccountRTGuarantor;
       }
       
       return GauranotrRecType; 
     } 
     set;
   }
  
   public List<selectOption> ManufactOptionsList 
   {
     get
     {
        Set<string> uniqueMfgNames = new Set<string>();  
        manufactOptionsList = new List<SelectOption>();
       
        if(nda.language__c == 'English')
        {
          manufactOptionsList.add(new selectOption('','-Select One-'));
          
          /*
          if(GeneralVersion || TCFCFVersion || TCFAUVersion || TCFNZVersion)
            manufactOptionsList.add(new SelectOption('Other','Other'));  
            */
        }
        else if(nda.language__c == 'French Canadian')
        {
          manufactOptionsList.add(new selectOption('','-Choisir un-'));
          /*manufactOptionsList.add(new SelectOption('Autre','Autre'));*/
        }
       
       if(ManufactList != null)
       {
         for(Manufacturer__c mfg: ManufactList)
         {
           uniqueMfgNames.add(mfg.name);
         }
            
         for(string mfgName: uniqueMfgNames)
         {
           //if(mfgName != 'Other')
            manufactOptionsList.add(new SelectOption(mfgName, mfgName));
         }
       }
       return manufactOptionsList;
     }
     set;
   }
    
   public List<corpOwnerInfo> corpOwnerInfoList 
   {
      get
      {
        List<CorpOwnerInfo> cList = new List<CorpOwnerInfo>();
        
        if(corpOwnerList != null)
        {
          for(CorpOwner c: corpOwnerList)
          {
            cList.add(c.cOwnerInfo);
          }
        }
        
        return cList;
      }
   }
    
   public List<corpOwnerInfo> getCorpEntityOwners()
   {
      if(corpOwnerList != null)
      {
        for(CorpOwner co : corpOwnerList)
        {
          if(co.cOwnerInfo.num == corpBlockCorpNum)
          {
            return co.corpEntityOwnersList;
          }  
        }
      }
      return null;
   }
   
   public List<indOwner> getIndEntityOwners()
   {
       system.debug(corpOwnerList);
       
       List<indOwner> tempIndEntityOwnersList = new List<indOwner>();   
        
      if((indBlockCorpNum == null || indBlockCorpNum == '') && collapsedOrExpandedOwnerRelRecId != null && collapsedOrExpandedOwnerRelRecId != '')
      {
        for(CorpOwner co: corpOwnerList)
        {
          if(co.cOwnerInfo.ownerRelationshipRecordId == collapsedOrExpandedOwnerRelRecId)
            tempIndEntityOwnersList = co.indEntityOwnersList;  
        }
      }
      else
      {
        tempIndEntityOwnersList = corpOwnerList[Integer.valueof(indBlockCorpNum)-1].indEntityOwnersList;
      }
      
      return tempIndEntityOwnersList;
   }

  //CONSTRUCTOR
  public NewDealerAppController(ApexPages.StandardController controller) 
  {        
    try
    { 
      //Set AU NZ support in the NDA code
      NDA_AU_NZ_Support__mdt aUNZMdt = [select enabled__c from NDA_AU_NZ_Support__mdt limit 1];
      AU_NZ_Support = aUNZMdt.enabled__c;
      //
        
      BRPVersion = false;
      RIAVersion = false;
      MTDVersion = false;
      TCFCFVersion = false;
      TCFAUVersion = false;
      TCFNZVersion = false;
      GeneralVersion = false;
        
      //colorscheme = 'default';
      headerValue = '';
      
      value = 10;
      showInputsValidationMessageOnMainPage = '';
        
      currPageURL = Apexpages.currentPage().getUrl().toLowercase();

      //Read custom setting to get USA and Canada credit amount limits
      List<CreditAmountThreshold__c> ca = CreditAmountThreshold__c.getall().values();
        
      if(ca.size() > 0)
      {
        USAmount = ca[0].USA__c;
        CanadaAmount = ca[0].Canada__c;
      }

      //-------------------------------------------------------------------------------------------------//
      //BLOCK EXTERNAL APP FOR INTERNAL USERS
      //-------------------------------------------------------------------------------------------------//
      //Block external app creation for internal users while allowing them to create the app through internal site URL.
      //Sys admins should be allowed to create apps through external app in sandbox even if they are creating the app while on TCF network. 
      printNDAAccessVariables = false;
        
      if(ApexPages.currentPage().getParameters().get('printNDAAccessVariables') == 'yes')
        printNDAAccessVariables = true;
      
      blockAppCreation = shouldAppCreationBeBlocked();
      //-------------------------------------------------------------------------------------------------//


      //-------------------------------------------------------------------------------------------------//
      //GET PAGE PARAMETERS AND SET NDA VARIABLES
      //-------------------------------------------------------------------------------------------------//
      this.nda = (New_Dealer_Application__c)controller.getRecord();
      
      // nda is set to null in  products page after v45.0 change. Causing the products page to break.
      // querying the nda fixed the issue.
      if(this.nda!=null && nda.id!=null)
      {
             nda = [select Applicant_Representative_Signature_Date__c, Legal_Business_Name__c, Customer_DBA_Name__c, What_is_your_business_entity_type__c, Federal_Tax__c, Tax_Id_For_Use_By_NDA_Guest_User__c, Date_of_signature__c,
                       Dealer_Phone_Number__c, Fax_Number__c, Location_Contact_First_Name__c,  Email_Address__c, Nr_of_Owners__c, Annual_Gross_Revenue__c,
                       What_year_was_your_business_founded__c, of_years_under_current_ownership__c, Financial_Year_End__c, Address__c,
                       City__c, Zipcode__c, Name, Id, How_many_locations__c, How_many_references_do_you_have__c, State__c, Line_of_Credit_Amount__c, Formation_State_US__c,
                       Industry__c, What_type_of_program_are_you_requesting__c, What_is_your_requested_line_of_credit__c, Primary_Brand_Requested__c,
                       Provide_Explanation_of_Bankrucptcy__c,  Provide_Explanation_unpaid_taxes__c, Provide_Explanation_of_Legal_Proceedings__c, 
                       Electronic_Communication_Consent__c, Password__c, IP_Address__c, Manufacturer__c, Manufacturer__r.name,
                       Name_of_authorized_signer__c, Title_of_authorized_signer__c, Bankruptcy_Filed__c, Delinquent_Taxes__c, Pending_Legal_Proceedings__c, Country__c, Dealer_Submitted__c,  Withdrawn__c, Account__c,
                       Applicant_Representative_s_Email__c, Applicant_Representative_s_First_Name__c, Applicant_Representative_s_Last_Name__c, RecordTypeId,
                       Formation_Jurisdiction__c, application_submitted__c, Type_of_Established_Canada__c, Province__c, Language__c,State_Province_Code__c, Formation_Jurisdiction_Code__c, Interested_in_Retail_Financing__c,
                       inventory_insurance_carrier__c, inventory_insurance_coverage_amount__c, policy_number__c, policy_renewal_date__c, agent_first_name__c, agent_last_name__c, agent_phone_number__c,
                       Existing_TCFIF_or_RIA_customer__c, AD_Eligible__c, AD_Result__c, AD_Model_Used__c 
                       from New_Dealer_Application__c
                       where Id = :nda.id];
      }
      // WI 3676 NDA title Limitations
      if(!String.isBlank(currPageURL) && currPageURL.contains('owner'))
      {
          if(ndatitleOptions==null && !String.isBlank(nda.What_is_your_business_entity_type__c))
          { 
               ndatitleOptions = new List<Selectoption>();
               Schema.DescribeFieldResult ownerTitle = New_Dealer_Application__c.NDA_Owner_Title_Options__c.getDescribe();
               Schema.sObjectField ownerTitleField = ownerTitle.getSObjectField();
               Map<Object,List<String>> controlValueToDependPickValsMap=utilityClass.getDependentPicklistValues(ownerTitleField);
               
               if(controlValueToDependPickValsMap!=null && controlValueToDependPickValsMap.size() >0)
               {
                   if(controlValueToDependPickValsMap.containsKey(nda.What_is_your_business_entity_type__c))
                   {
                       for(String depValues: controlValueToDependPickValsMap.get(nda.What_is_your_business_entity_type__c))
                       {
                            ndatitleOptions.add(new selectOption(depValues, depValues));
                       }
                   }
               }
               
          }
      }
      else
      {
          ndatitleOptions=null;
      }
      //-end
      
      ndaId = ApexPages.currentPage().getParameters().get('id');
      actId = ApexPages.currentPage().getParameters().get('accntId');
        
      leg = ApexPages.currentPage().getParameters().get('legalnm');
      ph = ApexPages.currentPage().getParameters().get('fone');
      entity = ApexPages.currentPage().getParameters().get('entity');
      fstate= ApexPages.currentPage().getParameters().get('state');

      langCode = ApexPages.currentPage().getParameters().get('lang');
      country = ApexPages.currentPage().getParameters().get('country');
      nda.country__c = ApexPages.currentPage().getParameters().get('country');

      product = ApexPages.currentPage().getParameters().get('prod');
      
      if(product == 'MTD')
      {
        nda.primary_brand_requested__c = 'General';
      }
      else
      {
        nda.primary_brand_requested__c = ApexPages.currentPage().getParameters().get('prod');
      }
      
      if(nda != null && nda.manufacturer__c != null)
        primaryManufacturer = nda.manufacturer__r.name;
      else  
        primaryManufacturer = ApexPages.currentPage().getParameters().get('prMfr');
      
      system.debug(primaryManufacturer);

      if(langCode == 'fr')
        nda.language__c = 'French Canadian';
      else if(langCode == 'en')
        nda.language__c = 'English';

      string countryCode;

      if(nda.country__c == 'United States')
        countryCode = 'US';
      else if(nda.country__c == 'Canada')
        countryCode = 'CA';
      else if(AU_NZ_Support && nda.country__c == 'Australia')
        countryCode = 'AU';
      else if(AU_NZ_Support && nda.country__c == 'New Zealand')
        countryCode = 'NZ';  
           
      if(nda.country__c != null)
      {
        stateCodeToNameMap = UtilityClass.createStateCodeToStateNameMap(countryCode);
        stateNameToCodeMap = UtilityClass.createStateNameToStateCodeMap(countryCode);
      }

      if(nda.country__c == 'Canada' && nda.language__c == 'French Canadian')
      {
        Blob blb = [Select body, name from StaticResource where Name = 'NDATermsOfUseFrench'].body;
        termsofusetext = blb.toString();
        langCode = 'fr';
      }
      else if(nda.country__c == 'United States')
      {
        langCode = 'en';
        Blob blb = [Select body, name from StaticResource where Name = 'NDATermsOfUse'].body;
        termsofusetext = blb.toString();
      }
      else if(nda.country__c == 'Canada' && nda.language__c == 'English')
      {
        langCode = 'en';
        Blob blb = [Select body, name from StaticResource where Name = 'NDATermsOfUse'].body;
        termsofusetext = blb.toString();
        showCanadianEnglish = true;
      }
      else if(AU_NZ_Support && nda.country__c == 'Australia')
      {
        langCode = 'en';
        //Update the following for AU when NDA terms of use are created for AU
        Blob blb = [Select body, name from StaticResource where Name = 'NDATermsOfUse'].body;
        termsofusetext = blb.toString();
      }
      else if(AU_NZ_Support && nda.country__c == 'New Zealand')
      {
        langCode = 'en';
        
        //Update the following for AU when NDA terms of use are created for NZ
        Blob blb = [Select body, name from StaticResource where Name = 'NDATermsOfUse'].body;
        termsofusetext = blb.toString();
      }
      else
      {
        langCode = 'en';
        Blob blb = [Select body, name from StaticResource where Name = 'NDATermsOfUse'].body;
        termsofusetext = blb.toString();
      }
      //---------------------------------------------------------------------------------------------------//

      retrieveAllManufacturers();
      showOrHideMfgList();
      //----------------------------------------------------------------------------------------------------//
      //RETRIEVE NDA FIELD VALUES
      //----------------------------------------------------------------------------------------------------//     
      newApplication = true;
      entityTypeForApp = entity;         
      addattachments = false;
      addContentVersions=false;
      existingRelationship = false;  
                

      //EXISTING APPLICATION //
      if(ndaId != null && ndaId != '')
      { 
        newApplication = false;

        nda = [select Applicant_Representative_Signature_Date__c, Legal_Business_Name__c, Customer_DBA_Name__c, What_is_your_business_entity_type__c, Federal_Tax__c, Tax_Id_For_Use_By_NDA_Guest_User__c, Date_of_signature__c,
               Dealer_Phone_Number__c, Fax_Number__c, Location_Contact_First_Name__c,  Email_Address__c, Nr_of_Owners__c, Annual_Gross_Revenue__c,
               What_year_was_your_business_founded__c, of_years_under_current_ownership__c, Financial_Year_End__c, Address__c,
               City__c, Zipcode__c, Name, Id, How_many_locations__c, How_many_references_do_you_have__c, State__c, Line_of_Credit_Amount__c, Formation_State_US__c,
               Industry__c, What_type_of_program_are_you_requesting__c, What_is_your_requested_line_of_credit__c, Primary_Brand_Requested__c,
               Provide_Explanation_of_Bankrucptcy__c,  Provide_Explanation_unpaid_taxes__c, Provide_Explanation_of_Legal_Proceedings__c, 
               Electronic_Communication_Consent__c, Password__c, IP_Address__c, Manufacturer__c, Manufacturer__r.name,
               Name_of_authorized_signer__c, Title_of_authorized_signer__c, Bankruptcy_Filed__c, Delinquent_Taxes__c, Pending_Legal_Proceedings__c, Country__c, Dealer_Submitted__c,  Withdrawn__c, Account__c,
               Applicant_Representative_s_Email__c, Applicant_Representative_s_First_Name__c, Applicant_Representative_s_Last_Name__c, RecordTypeId,
               Formation_Jurisdiction__c, application_submitted__c, Type_of_Established_Canada__c, Province__c, Language__c,State_Province_Code__c, Formation_Jurisdiction_Code__c, Interested_in_Retail_Financing__c,
               inventory_insurance_carrier__c, inventory_insurance_coverage_amount__c, policy_number__c, policy_renewal_date__c, agent_first_name__c, agent_last_name__c, agent_phone_number__c,
               Existing_TCFIF_or_RIA_customer__c, AD_Eligible__c, AD_Result__c, AD_Model_Used__c 
               from New_Dealer_Application__c
               where Id = :ndaId];
                          
        primaryManufacturer = nda.Manufacturer__r.name;

        ProductsList = [select id, relationship__c, new_dealer_application2__c, Industry__c, Manufacturer__c, Manufacturer__r.Name, Manufacturer__r.Industry__c, Obtained_From__c, Obtained_From_Name__c from Product_Information_For_New_Dealer_App__c where new_dealer_application2__c = :ndaId];
            
        if(ProductsList != null && ProductsList.size() > 1)
          NDAHasMoreThanOneRelationships = true; 
            
        if(string.isBlank(actId))
          actId = ProductsList[0].relationship__c;
            
        nda.IP_Address__c = sourceIPAddress;
        policyrenewaldate=nda.policy_renewal_date__c;
          
        if(currPageURL.contains('main'))
          {
            prospRecTypIds = new List<Id>();       
            prospRecTypIds.add(Constants.accountRTMap.get('Prospect_Dealer'));
            prospRecTypIds.add(Constants.accountRTMap.get('Prospect_Buying_Group'));
            prospRecTypIds.add(Constants.accountRTMap.get('Prospect_Distributor'));               
            prospRecTypIds.add(Constants.accountRTMap.get('Prospect_Manufacturer')); 
            
            if(string.isBlank(nda.password__c))
              showPasswordFields = true;  
          }
          
          if(currPageURL.contains('submit') || currPageURL.contains('pdf'))
          {
            if(bankruptcyEtcQuesErrorMessage != '')
            {
              applicantRepFirstName=nda.Applicant_Representative_s_First_Name__c;
              applicantRepLastName=nda.Applicant_Representative_s_Last_Name__c;
              applicantRepEmail=nda.Applicant_Representative_s_Email__c;
              bankruptcy=nda.Bankruptcy_Filed__c;
              bankruptcyDetails=nda.Provide_Explanation_of_Bankrucptcy__c;
              legalProceedings=nda.Pending_Legal_Proceedings__c;
              legalProceedingsDetails=nda.Provide_Explanation_of_Legal_Proceedings__c;
              delinquentTaxes=nda.Delinquent_Taxes__c;
              delinquentTaxesDetails=nda.Provide_Explanation_unpaid_taxes__c;
            }
          }
                        
          if(nda.Dealer_Submitted__c == TRUE || nda.application_submitted__c == TRUE || nda.Withdrawn__c == TRUE)
          {
            ndaSubmittedOrWithdrawn = TRUE;
            system.debug(ndaSubmittedOrWithdrawn); 
          }
                                      
          applicantName = nda.Applicant_Representative_s_First_Name__c + ' ' + nda.Applicant_Representative_s_Last_Name__c;
            
          //Added by Nimish
          List<Underwriting__c> careUnderwritingList = [select id, createddate from Underwriting__c where Underwriting_Request_Level__c = 'CARE Level' and Connected_Request__c = :nda.id];
          Date careUnderwritingCreatedDate;
            
          if(careUnderwritingList != null && careUnderwritingList.size()>0) 
            careUnderwritingCreatedDate =  careUnderWritingList[0].createddate.Date();
          
          if(currPageURL.contains('owners') || currPageURL.contains('pdf')) 
          {       
            if(nda.Applicant_Representative_Signature_Date__c != null)
            {
              if(nda.language__c == 'English' && nda.Country__c == 'United States')
                US_NDACreationDate = getMonthNameFromNumber(nda.Applicant_Representative_Signature_Date__c.Date().month(), 'US_EN') + ' ' + nda.Applicant_Representative_Signature_Date__c.Date().day() + ', ' + nda.Applicant_Representative_Signature_Date__c.Date().year();
              else if(nda.language__c == 'French Canadian' && nda.Country__c == 'Canada')
                CA_NDACreationDate = getMonthNameFromNumber(nda.Applicant_Representative_Signature_Date__c.Date().month(), 'CA_FR') + ' ' + nda.Applicant_Representative_Signature_Date__c.Date().day() + ', ' + nda.Applicant_Representative_Signature_Date__c.Date().year();
              else if(nda.language__c == 'English' && nda.Country__c == 'Canada')
                CA_NDACreationDate = getMonthNameFromNumber(nda.Applicant_Representative_Signature_Date__c.Date().month(), 'CA_EN') + ' ' + nda.Applicant_Representative_Signature_Date__c.Date().day() + ', ' + nda.Applicant_Representative_Signature_Date__c.Date().year();
              else if(AU_NZ_Support && nda.language__c == 'English' && (nda.Country__c == 'Australia' || nda.Country__c == 'New Zealand'))
                AU_NZ_NDACreationDate = getMonthNameFromNumber(nda.Applicant_Representative_Signature_Date__c.Date().month(), 'AU_EN') + ' ' + nda.Applicant_Representative_Signature_Date__c.Date().day() + ', ' + nda.Applicant_Representative_Signature_Date__c.Date().year();  
            }
            else if(careUnderwritingCreatedDate != null)
            {
              if(nda.language__c == 'English' && nda.Country__c == 'United States')
                US_NDACreationDate = getMonthNameFromNumber(careUnderwritingCreatedDate.month(), 'US_EN') + ' ' + careUnderwritingCreatedDate.day() + ', ' + careUnderwritingCreatedDate.year();
              else if(nda.language__c == 'French Canadian' && nda.Country__c == 'Canada')
                CA_NDACreationDate = getMonthNameFromNumber(careUnderwritingCreatedDate.month(), 'CA_FR') + ' ' + careUnderwritingCreatedDate.day() + ', ' + careUnderwritingCreatedDate.year();
              else if(nda.language__c == 'English' && nda.Country__c == 'Canada')
                CA_NDACreationDate = getMonthNameFromNumber(careUnderwritingCreatedDate.month(), 'CA_EN') + ' ' + careUnderwritingCreatedDate.day() + ', ' + careUnderwritingCreatedDate.year();
              else if(AU_NZ_Support && nda.language__c == 'English' && (nda.Country__c == 'Australia' || nda.Country__c == 'New Zealand'))
                AU_NZ_NDACreationDate = getMonthNameFromNumber(careUnderwritingCreatedDate.month(), 'AU_EN') + ' ' + careUnderwritingCreatedDate.day() + ', ' + careUnderwritingCreatedDate.year();  
            }
          }    
            
          if(currPageURL.contains('pdf'))
          {
            ndaPdf = new NdaPdfWrapper(nda, langCode == 'fr' ? false : true, AU_NZ_Support);
            
            AssociationList = new List<Associated_Relationships__c>();
                        
            OwnersList = setOwnerInfoSection();
          }
            
          if(currPageURL.contains('documents') || currPageURL.contains('pdf'))
          {
            showExistingContentVersions();          
          }  
            
          if(currPageURL.contains('products') || currPageURL.contains('pdf'))
          {
            displayProdsToAddTable=false;
            editProduct=false;
        
            ProductsList = PrepareProductsList();
            
            //Create options list for Add products table
            List<manufacturer__c> mfrsList = new List<manufacturer__c>();
            
            if(AU_NZ_Support && nda.country__c == 'Australia' || nda.country__c == 'New Zealand')
            {
              mfrsList = [select id, name, industry__c from manufacturer__c where name = 'Toro' or primary_manufacturer__r.name = 'Toro' or name like '%BRP%' or primary_manufacturer__r.name like '%BRP%'];
            }
            else if(nda.country__c == 'United States' && nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.startsWith('Toro'))
            {
              mfrsList = [select id, name, industry__c from manufacturer__c where name = 'Toro' or primary_manufacturer__r.name = 'Toro'];
            }
            else
            {
              mfrsList = [select id, name, industry__c from manufacturer__c];
            }
             
            Set<string> indSet = new Set<string>();
                        
            for(manufacturer__c mfr: mfrsList)
            {
              indSet.add(mfr.industry__c);  
            } 
            
            industryOptions = new List<selectOption>();
            
            if(nda.language__c == 'English')
            {
              industryOptions.add(new selectOption('','-Select One-'));
            
              for(string ind: indSet)
              {
                industryOptions.add(new selectOption(ind, ind));
              }
            }
            else if(nda.language__c == 'French Canadian')
            {
              industryOptions.add(new selectOption('','-Choisir un-'));
            
              for(string ind: indSet)
              {
                if(EnglishToFrenchIndustryMap.get(ind) != null)
                  industryOptions.add(new selectOption(ind, EnglishToFrenchIndustryMap.get(ind)));
                else
                  industryOptions.add(new selectOption(ind, ind));  
              }
            }
            //
          }
            
          if(currPageURL.contains('locations') || currPageURL.contains('pdf'))
          {  
            NrofLocationsList = setAdditionalLocations();
            
            if(currPageURL.contains('locations'))
              displayLocPanels();
          }  

          if(currPageURL.contains('referenceinfo') || currPageURL.contains('pdf'))
          {  
            NrofReferencesList = setBankingInfoSection();
            
            if(currPageURL.contains('referenceinfo'))
              displayRefPanels();
                  
            if(currPageURL.contains('pdf'))
            {   
              NrofReferencesListPDF = setBankingInfoSectionForPDf();  
                
              for(BankPDfWrapper wrapper : NrofReferencesListPDF)
              {    
                if(wrapper.b.Name == (string)wrapper.b.id)
                  wrapper.b.Name = '';
              }
            }
          }
          
          //----------------------------------------------------------------------------------------------------//
          //OWNERS
          //----------------------------------------------------------------------------------------------------//
          if(currPageURL.contains('owners'))
          {         
            indOwnerList = new List<IndOwner>();
            corpOwnerList = new List<CorpOwner>();
        
            pageMessage = '';
        
            showNoOwnersMessage = FALSE;
            showOwnerNoConsentMessage = FALSE;

            AssociationList = new List<Associated_Relationships__c>();
                        
            OwnersList = setOwnerInfoSection();
            
            displayIndOwnerPanels();
            displayCorpOwnerPanels();
          }
          
            
          //---------------------------------------------------------------------------------------------------//
          //AUTO DECISION
          //---------------------------------------------------------------------------------------------------//
          if(currPageURL.contains('submit') || currPageURL.contains('appinternalreview'))
          {
            ndaDealerNameMatchesDnBBussName = false;
            stopPollingForAutoSelectedDUNS = false;
            stopPollingForSelectedDUNS = true;
            showSection = 'confirmation';
            showAutoReviewMsg='Performing an automated review of your application.  This may take a minute. Please wait ';
            
            if(userinfo.getusername().startswith('application@'))
              loggedInUserIsGuestSiteUser = TRUE;
            else
              loggedInUserIsGuestSiteUser = FALSE;  
        
        
            autoDecHelper = new AutoDecisionHelper();
        
            if(nda.country__c == 'United States') 
            { 
              dnbUserId   = Constants.dnbUSUserId; 
              dnbPassword = Constants.getDecryptedPassword(Constants.dnbUSEncryptedHexStringPassword); 
                    
              if(ApexPages.currentPage().getParameters().get('AD') == 'Yes')
              {
                continueWithAutoDecisioning = true;
              }
              //If app is not eligible for auto decisioning, show the submission confirmation screen right away on the internal review page
              else
              {           
                continueWithAutoDecisioning = false;
              }
            }   
          }
          //----------------------------------------------------------------------------------------------------//
        }
        //NEW APP BUT LINK TO AN EXISTING ACCOUNT
        else if(actId != '' && actId!= null) 
        {   
            existingRelationshipAcct = [select Id, Name, Phone, Primary_Contact_Name__c, Customer_DBA_Name__c, State_of_Incorporation__c,
                                        Primary_Contact_Email_Address__c, Fax,Year_Business_Was_Established__c, Years_Under_the_Present_Ownership__c, 
                                        Financial_Year_End__c, Tax_Identification_Number__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                                        Primary_Contact_Phone_Number__c, WMS_Customer__c, billingstatecode, billingCountryCode, State_of_Incorporation_Code__c,
                                        Legal_Entity__c, ShippingStateCode, AnnualRevenue
                                        from Account
                                        where Id = :actId
                                        limit 1];
                                                        
            existingRelationship = true; 
            nda.IP_Address__c = sourceIPAddress; 
            nda.Legal_Business_Name__c = existingRelationshipAcct.Name;
            nda.Dealer_Phone_Number__c = existingRelationshipAcct.Phone;
            nda.What_is_your_business_entity_type__c = existingRelationshipAcct.Legal_Entity__c;
            nda.Location_Contact_First_Name__c = existingRelationshipAcct.Primary_Contact_Name__c;  
            nda.Fax_Number__c = existingRelationshipAcct.Fax;
            nda.What_year_was_your_business_founded__c = existingRelationshipAcct.Year_Business_Was_Established__c; 
            nda.of_years_under_current_ownership__c = existingRelationshipAcct.Years_Under_the_Present_Ownership__c;
            nda.Financial_Year_End__c = existingRelationshipAcct.Financial_Year_End__c; 
            nda.Address__c = existingRelationshipAcct.BillingStreet;
            nda.City__c = existingRelationshipAcct.BillingCity; 
            nda.state__c = existingRelationshipAcct.BillingState;
            nda.Formation_State_US__c = existingRelationshipAcct.State_Of_Incorporation__c;
            nda.Zipcode__c = existingRelationshipAcct.BillingPostalCode;
            nda.Email_Address__c = existingRelationshipAcct.Primary_Contact_Email_Address__c;   
            //nda.Customer_DBA_Name__c = existingRelationshipAcct.Customer_DBA_Name__c;

            nda.customer_dba_name__c = '';

            for(dba_name__c dba: [select id, dba_name__c from dba_name__c where relationship__c =: existingRelationshipAcct.id])
            {
              nda.Customer_DBA_Name__c = nda.Customer_DBA_Name__c + dba.dba_name__c+';';
            }

            nda.Federal_Tax__c = existingRelationshipAcct.Tax_Identification_Number__c;
            nda.Tax_Id_For_Use_By_NDA_Guest_User__c = existingRelationshipAcct.Tax_Identification_Number__c;
            nda.Annual_Gross_Revenue__c = existingRelationshipAcct.AnnualRevenue;                                       
       }
       //NEW APP NOT LINKED TO EXISTING (MATCHING) ACCOUNT
       else
       { 
         //Copy values from prev page      
         if(nda!= null)
         {
           nda.IP_Address__c = sourceIPAddress;
           nda.Legal_Business_Name__c = leg;
           nda.Dealer_Phone_Number__c = ph;
           nda.What_is_your_business_entity_type__c = entity;
         } 
       }
      }
      catch(Exception e)
      {
        system.debug(e);
      }
   }


  public PageReference showOrHideMfgList()
  {
    PageReference nextPage = Page.NewDealerAppMain;
      
    if(AU_NZ_Support && nda.country__c == 'Australia')
    {
      TCFAUVersion = true;  
      headerValue = System.Label.NDA_Main_Header;
      colorScheme = 'default';        
      langCode = 'en';
      nextPage.getParameters().put('version','TCFAU');
    }
    else if(AU_NZ_Support && nda.country__c == 'New Zealand')
    {
      TCFNZVersion = true;  
      headerValue = System.Label.NDA_Main_Header;
      colorScheme = 'default';        
      langCode = 'en';
      nextPage.getParameters().put('version','TCFNZ');
    }
    else if(nda.country__c== 'Canada') 
    {
      if(nda.primary_brand_requested__c != null && (nda.primary_brand_requested__c == 'General' || nda.primary_brand_requested__c.startsWith('Toro')))
      {
        TCFCFVersion = true;
        headerValue = System.Label.NDA_Main_Header_Canada;
        colorScheme = 'default';
        nextPage.getParameters().put('version','TCFCF');
      }
      else if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.contains('Bombardier Recreational Products'))
      {
        BRPVersion = true;  
        headerValue = System.Label.NDA_Main_Header_BRP;
        colorScheme = 'BRP';
        nextPage.getParameters().put('version','BRP');
      }
        
      if(nda.language__c == 'English')
        langCode = 'en';
      else if(nda.language__c == 'French Canadian')
        langCode = 'fr';
    }
    else if(nda.country__c== 'United States')
    {         
      langCode = 'en';
      
      system.debug(nda.primary_brand_requested__c);
      
      if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.contains('Bombardier Recreational Products'))
      {
        BRPVersion = true;  
        headerValue = System.Label.NDA_Main_Header_BRP;
        colorScheme = 'BRP';
        nextPage.getParameters().put('version','BRP');
      }
      else if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.startsWith('Toro'))
      {
        RIAVersion = true; 
        headerValue = System.Label.NDA_Main_Header_RIA;
        colorScheme = 'RIA';
        nextPage.getParameters().put('version','RIA');
      }
      else if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.contains('General') && (product == 'MTD' || primaryManufacturer == 'MTD' || primaryManufacturer == 'Cub Cadet'))
      {
        MTDVersion = true;
        colorscheme = 'MTD';
        headerValue = System.Label.NDA_Main_Header_MTD;
        nextPage.getParameters().put('version','MTD');                                                              
        }
        else
        {
          GeneralVersion = true;  
          headerValue = System.Label.NDA_Main_Header;
          colorScheme = 'default';
          nextPage.getParameters().put('version','General');
        }                     
      }
      else
      {
        GeneralVersion = true;  
        headerValue = System.Label.NDA_Main_Header;
        colorScheme = 'default';
        nextPage.getParameters().put('version','General');
      }
                  
      nextPage.getParameters().put('country', nda.country__c);
      nextPage.getParameters().put('lang',langCode);
      
      if(nda.primary_brand_requested__c != null)
        nextPage.getParameters().put('prod',nda.primary_brand_requested__c);
      
      if(nda.manufacturer__c != null)
        nextPage.getParameters().put('prMfr', nda.manufacturer__r.name);  
      else
        nextPage.getParameters().put('prMfr', primaryManufacturer);  
      
      if(!string.isBlank(nda.password__c ))
        nextPage.getparameters().put('p','yes');
      else
        nextPage.getparameters().put('p','no'); 
        
      system.debug(BRPVersion+','+colorScheme);         
      
      nextPage.setRedirect(true);
      
      return nextPage;
   } 

   public PageReference toggleCollapsed()
   {
      if(collapsedOrExpandedOwnerType == 'Individual')
      {       
        for(IndOwner io: indOwnerList)
        {
          if(io.ownerRelationshipRecordId == collapsedOrExpandedOwnerRelRecId)
          {
            io.collapsed = !io.collapsed;
          }
        }
        
      }
      else if(collapsedOrExpandedownerType == 'Corporate')
      {
        for(CorpOwner co: corpOwnerList)
        {
          if(co.cOwnerInfo.ownerRelationshipRecordId == collapsedOrExpandedOwnerRelRecId)
          {
            co.cOwnerInfo.collapsed = !co.cOwnerInfo.collapsed;
          }
        }
      }
      
      return null;
   }

    public void setButtonsVisibility(IndOwner io, corpOwnerInfo coi, Boolean saveBtn, Boolean editBtn, Boolean deleteBtn, Boolean signBtn, Boolean showIndConsents, Boolean showCorpConsents)
    {
      if(io != null)
      {
        io.showSaveButton   = saveBtn;
        io.showEditButton   = editBtn;
        io.showDeleteButton = deleteBtn;
        io.showSignButton   = signBtn;
        io.showIndConsents  = showIndConsents;
        io.showCorpConsents = showCorpConsents;
      }
      else if(coi != null)
      {
        coi.showSaveButton   = saveBtn;
        coi.showEditButton   = editBtn;
        coi.showDeleteButton = deleteBtn;
        coi.showSignButton   = signBtn;
        coi.showIndConsents  = showIndConsents;
        coi.showCorpConsents = showCorpConsents; 
      }
          
    }
    
   public PageReference MTDRefresh()
   {
     TCFAUVersion   = false;
     TCFNZVersion   = false;  
     TCFCFVersion   = false;
     GeneralVersion = false;
     RIAVersion     = false;
     BRPVersion     = false;
     MTDVersion     = false;  
       
     if(AU_NZ_Support && nda.country__c == 'Australia')
     {
       TCFAUVersion = true;  
       headerValue = System.Label.NDA_Main_Header;
       colorScheme = 'default';        
       langCode = 'en';
     }
     else if(AU_NZ_Support && nda.country__c == 'New Zealand')
     {
       TCFNZVersion = true;  
       headerValue = System.Label.NDA_Main_Header;
       colorScheme = 'default';        
       langCode = 'en';
     }
     else if(nda.country__c== 'Canada') 
     {
       if(nda.primary_brand_requested__c != null && (nda.primary_brand_requested__c == 'General' || nda.primary_brand_requested__c.startsWith('Toro')))
       {
         TCFCFVersion = true;
         headerValue = System.Label.NDA_Main_Header_Canada;
         colorScheme = 'default';
       }
       else if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.contains('Bombardier Recreational Products'))
       {
         BRPVersion = true;  
         headerValue = System.Label.NDA_Main_Header_BRP;
         colorScheme = 'BRP';
      }
        
      if(nda.language__c == 'English')
        langCode = 'en';
      else if(nda.language__c == 'French Canadian')
        langCode = 'fr';
    }
    else if(nda.country__c== 'United States')
    {         
      langCode = 'en';
      
      if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.contains('Bombardier Recreational Products'))
      {
        BRPVersion = true;  
        headerValue = System.Label.NDA_Main_Header_BRP;
        colorScheme = 'BRP';
      }
      else if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.startsWith('Toro'))
      {
        RIAVersion = true; 
        headerValue = System.Label.NDA_Main_Header_RIA;
        colorScheme = 'RIA';
      }
      else if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.contains('General') && (primaryManufacturer == 'MTD' || primaryManufacturer == 'Cub Cadet'))
      {
        MTDVersion = true;
        colorscheme = 'MTD';
        headerValue = System.Label.NDA_Main_Header_MTD;
      }
      else
      {
        GeneralVersion = true;  
        headerValue = System.Label.NDA_Main_Header;
        colorScheme = 'default';
      }                     
    }
    else
    {
      GeneralVersion = true;  
      headerValue = System.Label.NDA_Main_Header;
      colorScheme = 'default';
    }
     
     return null;
   } 
    
   public PageReference pageRefresh()
   {
     return null;
   }

   public Boolean doesTotalOwnershipPctNotExceed100pct()
   {
      Integer totalOwnershipPct = 0;
    
      for(Indowner i: indOwnerList)
      {
        if(i.pctOwnership != null && i.pctOwnership != '')
          totalOwnershipPct = totalOwnershipPct + Integer.valueof(i.pctOwnership);
      }  
    
      for(corpOwner c: corpOwnerList)
      {
        if(c.cOwnerInfo.pctOwnership != null && c.cOwnerInfo.pctOwnership != '')
          totalOwnershipPct = totalOwnershipPct + Integer.valueof(c.cOwnerInfo.pctOwnership);
      }
    
      if(totalOwnershipPct > 100)
        return true;
      else 
        return false;  
   }

   public void validateIndOwnerData(IndOwner io)
   {
      try
      {
        if(io.firstname == '' || (!(io.firstname == '' || io.firstname.isAlphaSpace() == TRUE || io.firstname.contains('\''))))
          io.messages.add(System.Label.first_name_invalid_error);
      
        if(io.lastname == '' || (!(io.lastname == '' || io.lastname.isAlphaSpace() == TRUE || io.lastname.contains('\''))))
          io.messages.add(System.Label.Last_name_invalid_error);
      
        if(io.street == '' || (!(io.street.isAlphaNumeric() || io.street.contains(' ') || io.street.contains(',') || io.street.contains('.') || io.street.contains('#') || io.street.contains('-') || io.street.contains('/')  || io.street.contains('\'')|| io.street.contains('(') || io.street.contains(')') )))
          io.messages.add(System.Label.Street_validation_error);
        
        if(io.city == '' || (io.city != ' ' && !(io.city.isAlphaNumeric() || io.city.contains(' ') || io.city.contains(',') || io.city.contains('.') || io.city.contains('#') || io.city.contains('-') || io.city.contains('/')  || io.city.contains('\'') )))
          io.messages.add(System.Label.City_invalid_error);
      
        if(io.state == '' || (io.state == null))
          io.messages.add(System.Label.State_validation_error);
          
        if(io.email == '' || (io.email != '' && !UtilityClass.validateEmail(io.email)))   
          io.messages.add(System.Label.Email_validation_error);   

        if(io.title == 'None')
          io.messages.add(System.Label.Title_validation_error);        
        
        if(string.isBlank(io.pctOwnership) || (io.pctOwnership != '' && !(io.pctOwnership.isNumeric())))
          io.messages.add(System.Label.Ownership_percentage_validation_error);
        
        if(!string.isBlank(io.pctOwnership) && io.pctOwnership.isNumeric())
        {
          try
          {
            if(doesTotalOwnershipPctNotExceed100pct() == true)
            {
              io.messages.add(System.Label.Total_Ownership_validation_error);
            }
          }
          catch(Exception e)
          {
            io.messages.add(System.Label.Unable_to_validate_total_ownership);
          }
        }
        
        Pattern MyPattern;
        Matcher MyMatcher;
        ////////////////////////////////////////
        // United States specific validations //
        //////////////////////////////////////// 
        if(nda.country__c== 'United States')
        {
          ////////////////////////
          //Zip code must be xxxxx
          ////////////////////////
          Boolean match=false;
          
          String zipRegex2 = '\\d{5}';
          
          MyPattern = Pattern.compile(zipRegex2);         
          MyMatcher = MyPattern.matcher(io.postalcode);
         
          if(MyMatcher.matches())
          { 
            match = true;
          }      
         
          if(match == false) 
            io.messages.add(System.Label.Postal_code_required);
          
          
          if(string.isBlank(io.phone))
          {
            io.messages.add(System.Label.Phone_validation_error);  
          }
          else
          {
            io.phone = io.phone.remove('(').remove(')').remove('-').remove(' ');
            
            if(!io.phone.isNumeric() || io.phone.length() != 10)
            {
              io.messages.add(System.Label.Phone_validation_error);
            }    
          }
          
          if(io.birthdate == '' || io.birthdate == null)
          {
            io.messages.add(System.Label.US_birthdate_validation_error);   
          }
          else if(io.birthdate != '' && io.birthdate != null)
          {
            //Prepend a leading zero if missing in the date and month since sfdc does not store leading zero in date day and month in date field on the record
            if(io.birthdate.countMatches('/') == 2)
            {
              string[] bDateParts = io.birthdate.split('/');
          
              if(bDateParts[0] != null && bDateParts[0] != '' && bDateParts[1] != null && bDateParts[1] != '' && bDateParts[2] != null && bDateParts[2] != '')
              {
                if(bDateParts[0].length()<2)
                  bDateParts[0] = '0'+bDateParts[0];
              
                if(bDateParts[1].length()<2)
                  bDateParts[1] = '0'+bDateParts[1];
              
                String bdateRegex1 = '((01|03|05|07|08|10|12)[/](01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)[/](1|2)[0-9][0-9][0-9])|((04|06|09|11)[/](01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30)[/](1|2)[0-9][0-9][0-9])|((02)[/](01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29)[/](1|2)[0-9][0-9][0-9])';
                MyPattern = Pattern.compile(bdateRegex1);         
                MyMatcher = MyPattern.matcher(bDateParts[0]+'/'+bDateParts[1]+'/'+bDateParts[2]);
            
                if(!MyMatcher.matches()) 
                  io.messages.add(System.Label.US_birthdate_validation_error);
              }
            }
            else
            {
              io.messages.add(System.Label.US_birthdate_validation_error);
            }    
          }
          
          if(io.ssn == '' || (io.ssn != '' && ( !io.ssn.isNumeric() || io.ssn.length() != 9 )))
          {  
            io.messages.add(System.Label.SSN_validation_error);
          }
        }
        /////////////////////////////////
        // Canada specific validations //
        ///////////////////////////////// 
        else if(nda.country__c== 'Canada')
        {
          String zipRegex = '[A-Z]\\d[A-Z]\\s\\d[A-Z]\\d';
          MyPattern = Pattern.compile(zipRegex);         
          MyMatcher = MyPattern.matcher(io.postalcode);
            
          if(!MyMatcher.matches()) 
            io.messages.add(System.Label.Canada_postal_code_validation_error);
        
          if(string.isBlank(io.phone))
          {
            io.messages.add(System.Label.Phone_validation_error);  
          }
          else
          {
            io.phone = io.phone.remove('(').remove(')').remove('-').remove(' ');
            
            if(!io.phone.isNumeric() || io.phone.length() != 10)
            {
              io.messages.add(System.Label.Phone_validation_error);
            }    
          }
          
          if(io.birthdate == '' || io.birthdate == null)
          {
            io.messages.add(System.Label.Canada_birthdate_validation_error);
          }
          else if(io.birthdate != '' && io.birthdate != null)
          {
            //Prepend a leading zero if missing in the date and month since sfdc does not store leading zero in date day and month in date field on the record
            if(io.birthdate.countMatches('/') == 2)
            {
              string[] bDateParts = io.birthdate.split('/');
          
              if(bDateParts[0] != null && bDateParts[0] != '' && bDateParts[1] != null && bDateParts[1] != '' && bDateParts[2] != null && bDateParts[2] != '')
              {
                if(bDateParts[0].length()<2)
                  bDateParts[0] = '0'+bDateParts[0];
                if(bDateParts[1].length()<2)
                  bDateParts[1] = '0'+bDateParts[1];
                  
                String bdateRegex1 = '((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)[/](01|03|05|07|08|10|12)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30)[/](04|06|09|11)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29)[/](02)[/](1|2)[0-9][0-9][0-9])';
                MyPattern = Pattern.compile(bdateRegex1);         
                MyMatcher = MyPattern.matcher(bDateParts[0]+'/'+bDateParts[1]+'/'+bDateParts[2]);
        
                if(!MyMatcher.matches()) 
                  io.messages.add(System.Label.Canada_birthdate_validation_error);
              }
            }
            else
            {
              io.messages.add(System.Label.Canada_birthdate_validation_error);
            }
          } 
          
          if(io.ssn != '' && (!io.ssn.isNumeric() || io.ssn.length() != 9 ))
          {
            io.messages.add(System.Label.Canada_SIN_validation_error);
          }
        }
        ////////////////////////////////////
        // Australia specific validations //
        //////////////////////////////////// 
        else if(AU_NZ_Support && nda.country__c== 'Australia')
        {
          String zipRegex = '\\d{4}';
          MyPattern = Pattern.compile(zipRegex);         
          MyMatcher = MyPattern.matcher(io.postalcode);
          
          if(!MyMatcher.matches()) 
            io.messages.add('Postal code is a required field and must be exactly 4 numerical digits.');
          
          if(string.isBlank(io.phone))
          {
            io.messages.add('10 digit phone number is required.');  
          }
          else
          {
            io.phone = io.phone.remove('(').remove(')').remove('-').remove(' ');
            
            system.debug(io.phone);
            
            if(!io.phone.isNumeric() || (io.phone.isNumeric() && io.phone.length() != 10))
            {
              io.messages.add('10 digit phone number is required.');
            }    
          }
          
          if(io.birthdate == '' || io.birthdate == null)
          {
            io.messages.add(System.Label.Canada_birthdate_validation_error);
          }
          else if(io.birthdate != '' && io.birthdate != null)
          {
            //Prepend a leading zero if missing in the date and month since sfdc does not store leading zero in date day and month in date field on the record
            if(io.birthdate.countMatches('/') == 2)
            {
              string[] bDateParts = io.birthdate.split('/');
          
              if(bDateParts[0] != null && bDateParts[0] != '' && bDateParts[1] != null && bDateParts[1] != '' && bDateParts[2] != null && bDateParts[2] != '')
              {
                if(bDateParts[0].length()<2)
                  bDateParts[0] = '0'+bDateParts[0];
                if(bDateParts[1].length()<2)
                  bDateParts[1] = '0'+bDateParts[1];
                  
                String bdateRegex1 = '((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)[/](01|03|05|07|08|10|12)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30)[/](04|06|09|11)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29)[/](02)[/](1|2)[0-9][0-9][0-9])';
                MyPattern = Pattern.compile(bdateRegex1);         
                MyMatcher = MyPattern.matcher(bDateParts[0]+'/'+bDateParts[1]+'/'+bDateParts[2]);
        
                if(!MyMatcher.matches()) 
                  io.messages.add(System.Label.Canada_birthdate_validation_error);
              }
            }
            else
            {
              io.messages.add(System.Label.Canada_birthdate_validation_error);
            }
          }
          
          if(string.isBlank(io.driversLicenseNumber))// || (string.isBlank(io.driversLicenseNumber) && io.driversLicenseNumber.length() > 10))
          {
          
            io.messages.add('Driver\'s License # is a required field.' );
          }
          
          if(string.isBlank(io.driversLicenseExpDate))// || (string.isBlank(io.driversLicenseNumber) && io.driversLicenseNumber.length() > 10))
          {
          
            io.messages.add('Driver\'s License Expiration Date is a required field.' );
          }
          else
          {
            //Prepend a leading zero if missing in the date and month since sfdc does not store leading zero in date day and month in date field on the record
            if(io.driversLicenseExpDate.countMatches('/') == 2)
            {
              string[] bDateParts = io.driversLicenseExpDate.split('/');
          
              if(bDateParts[0] != null && bDateParts[0] != '' && bDateParts[1] != null && bDateParts[1] != '' && bDateParts[2] != null && bDateParts[2] != '')
              {
                if(bDateParts[0].length()<2)
                  bDateParts[0] = '0'+bDateParts[0];
                if(bDateParts[1].length()<2)
                  bDateParts[1] = '0'+bDateParts[1];
                  
                String bdateRegex1 = '((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)[/](01|03|05|07|08|10|12)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30)[/](04|06|09|11)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29)[/](02)[/](1|2)[0-9][0-9][0-9])';
                MyPattern = Pattern.compile(bdateRegex1);         
                MyMatcher = MyPattern.matcher(bDateParts[0]+'/'+bDateParts[1]+'/'+bDateParts[2]);
        
                if(!MyMatcher.matches()) 
                  io.messages.add('Driver\'s License Expiration Date must be in dd/mm/yyyy format.');
              }
            }
            else
            {
              io.messages.add('Driver\'s License Expiration Date must be in dd/mm/yyyy format.');
            }
          } 
        }
        //////////////////////////////////////
        // New Zealand specific validations //
        ////////////////////////////////////// 
        else if(AU_NZ_Support && nda.country__c== 'New Zealand')
        {
          String zipRegex = '\\d{4}';
          MyPattern = Pattern.compile(zipRegex);         
          MyMatcher = MyPattern.matcher(io.postalcode);
          
          if(!MyMatcher.matches()) 
            io.messages.add('Postal code is a required field and must be exactly 4 numerical digits.');
          
          if(string.isBlank(io.phone))
          {
            io.messages.add('Phone number is a required field.');  
          }
          else
          {
            io.phone = io.phone.remove('(').remove(')').remove('-').remove(' ');
            
            if(!io.phone.isNumeric() || (io.phone.length() != 8 && io.phone.length() != 9))
            {
              io.messages.add('Phone number is a required field and cannot be more than 10 digits long.');
            }    
          }
          
          if(io.birthdate == '' || io.birthdate == null)
          {
            io.messages.add(System.Label.Canada_birthdate_validation_error);
          }
          else if(io.birthdate != '' && io.birthdate != null)
          {
            //Prepend a leading zero if missing in the date and month since sfdc does not store leading zero in date day and month in date field on the record
            if(io.birthdate.countMatches('/') == 2)
            {
              string[] bDateParts = io.birthdate.split('/');
          
              if(bDateParts[0] != null && bDateParts[0] != '' && bDateParts[1] != null && bDateParts[1] != '' && bDateParts[2] != null && bDateParts[2] != '')
              {
                if(bDateParts[0].length()<2)
                  bDateParts[0] = '0'+bDateParts[0];
                if(bDateParts[1].length()<2)
                  bDateParts[1] = '0'+bDateParts[1];
                  
                String bdateRegex1 = '((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)[/](01|03|05|07|08|10|12)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30)[/](04|06|09|11)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29)[/](02)[/](1|2)[0-9][0-9][0-9])';
                MyPattern = Pattern.compile(bdateRegex1);         
                MyMatcher = MyPattern.matcher(bDateParts[0]+'/'+bDateParts[1]+'/'+bDateParts[2]);
        
                if(!MyMatcher.matches()) 
                  io.messages.add(System.Label.Canada_birthdate_validation_error);
              }
            }
            else
            {
              io.messages.add(System.Label.Canada_birthdate_validation_error);
            }
          } 
          
          if(string.isBlank(io.driversLicenseNumber))// || (string.isBlank(io.driversLicenseNumber) && io.driversLicenseNumber.length() > 10))
          {
          
            io.messages.add('Driver\'s License # is a required field.' );
          }
          else
          {
            if(io.driversLicenseNumber.length() > 9)
              io.messages.add('Driver\'s License # must be 9 or less characters long.' );
          }
          
          if(string.isBlank(io.driversLicenseExpDate))// || (string.isBlank(io.driversLicenseNumber) && io.driversLicenseNumber.length() > 10))
          {
          
            io.messages.add('Driver\'s License Expiration Date is a required field.' );
          }
          else
          {
            if(io.driversLicenseExpDate.countMatches('/') == 2)
            {
              string[] bDateParts = io.driversLicenseExpDate.split('/');
          
              if(bDateParts[0] != null && bDateParts[0] != '' && bDateParts[1] != null && bDateParts[1] != '' && bDateParts[2] != null && bDateParts[2] != '')
              {
                if(bDateParts[0].length()<2)
                  bDateParts[0] = '0'+bDateParts[0];
                if(bDateParts[1].length()<2)
                  bDateParts[1] = '0'+bDateParts[1];
                  
                String bdateRegex1 = '((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)[/](01|03|05|07|08|10|12)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30)[/](04|06|09|11)[/](1|2)[0-9][0-9][0-9])|((01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29)[/](02)[/](1|2)[0-9][0-9][0-9])';
                MyPattern = Pattern.compile(bdateRegex1);         
                MyMatcher = MyPattern.matcher(bDateParts[0]+'/'+bDateParts[1]+'/'+bDateParts[2]);
        
                if(!MyMatcher.matches()) 
                  io.messages.add('Driver\'s License Expiration Date must be in dd/mm/yyyy format.' );
              }
            }
            else
            {
              io.messages.add('Driver\'s License Expiration Date must be in dd/mm/yyyy format.' );
            }
          }
        }
      }
      catch(Exception excp)
      { 
        UtilityClass.logError(excp,'NDA', ndaId, 'Firstname: '+io.firstname+', Lastname: '+io.lastname+', Street: '+io.street+', City: '+io.city+', State: '+io.state+', Postal Code: '+io.postalcode+', Birth Date:'+io.birthdate+', Email: '+io.email+', SSN: '+io.ssn+', DL#: '+io.driversLicenseNumber+', Exp Date:'+io.driversLicenseExpDate+', Ownership Pct: '+io.pctOwnership+', Title: '+io.title); 
        showErrorMessage = true;
      }  
   }
    
   public void validateCorpOwnerData(CorpOwnerInfo coi) 
   {
      try
      {
        if(coi.street == '' || (coi.street != ' ' && coi.street != '' && !(coi.street.isAlphaNumeric()  || coi.street.contains(' ') || coi.street.contains(',') || coi.street.contains('.') || coi.street.contains('#') || coi.street.contains('-') || coi.street.contains('/')  || coi.street.contains('\'')|| coi.street.contains('(') || coi.street.contains(')') )))
          coi.messages.add(System.Label.Street_validation_error);
        
        if(coi.city == '' || (coi.city != '' && !(coi.city.isAlphaNumeric() || coi.city.contains(' ') || coi.city.contains(',') || coi.city.contains('.') || coi.city.contains('#') || coi.city.contains('-') || coi.city.contains('/')  || coi.city.contains('\'') )))
          coi.messages.add(System.Label.City_invalid_error);
      
        if(coi.state == '' || (coi.state == null))
          coi.messages.add(System.Label.State_validation_error);
        
        if(coi.formationstate == '' || (coi.formationstate == null))
          coi.messages.add(System.Label.Formation_state_validation_error);
          
        if(coi.pctOwnership == '' || (coi.pctOwnership != '' && !(coi.pctOwnership.isNumeric())))
          coi.messages.add(System.Label.Ownership_percentage_validation_error);  
        
        if(coi.authorizedSignerFirstname == '' || (coi.authorizedSignerFirstname != '' && coi.authorizedSignerFirstname.isAlphaSpace() != TRUE))
          coi.messages.add(System.Label.Authorized_signer_first_name_validation_error);
      
        if(coi.authorizedSignerLastname == '' || (coi.authorizedSignerLastname != '' && coi.authorizedSignerLastname.isAlphaSpace() != TRUE))
          coi.messages.add(System.Label.Authorized_signer_last_name_validation_error);
        
        if(coi.entityOwnerTitle == 'None')
          coi.messages.add(System.Label.Title_validation_error);
        
        if(!(coi.pctOwnership == '' || (coi.pctOwnership != '' && !(coi.pctOwnership.isNumeric()))) && doesTotalOwnershipPctNotExceed100pct() == true)
          coi.messages.add(System.Label.Total_Ownership_validation_error);
        
        if(nda.country__c == 'United States')
        {  
          if(coi.postalcode == '' || (coi.postalcode != '' && !(coi.postalcode.isNumeric() || coi.postalcode.contains('-'))))
            coi.messages.add(System.Label.Postal_code_required);
        }
        else if(nda.country__c == 'Canada')
        {
          if(coi.postalcode == '' || (coi.postalcode != '' && !(coi.postalcode.isAlphaNumeric() || coi.postalcode.contains(' '))))
            coi.messages.add(System.Label.Canada_postal_code_validation_error);
        }
        else if(AU_NZ_Support && nda.country__c == 'Australia')
        {
          if(coi.postalcode == '' || (coi.postalcode != '' && !coi.postalcode.isNumeric()) || (coi.postalcode != '' && coi.postalcode.isNumeric() &&  coi.postalcode.length() != 4))
          {
            coi.messages.add('4 digit postal code is required.');
          }
        }
        else if(AU_NZ_Support && nda.country__c == 'New Zealand')
        {
          if(coi.postalcode == '' || (coi.postalcode != '' && !coi.postalcode.isNumeric()) || (coi.postalcode != '' && coi.postalcode.isNumeric() &&  coi.postalcode.length() != 4))
          {
            coi.messages.add('4 digit postal code is required.');
          }
        }  
      }
      catch(Exception excp)
      { 
        //UtilityClass.logError(excp,'NDA', ndaId, 'Street: '+coi.street+', City: '+coi.city+', State: '+coi.state+', Formation State: '+coi.formationState+', Postal Code: '+coi.postalcode+', Authorized Signer Firstname: '+coi.authorizedSignerFirstname+', Authorized Signer Lastname: '+coi.authorizedSignerLastname+', Entity Owner Title: '+coi.entityOwnerTitle+', Ownership Pct: '+coi.pctOwnership);  
        showErrorMessage = true;
      }
   }

    @RemoteAction
    global static String getNDAIdFromAccountId(String acctId)
    {
      Id returnNDAId='';
      List<account> AccountsList = [select New_Dealer_Application__c from account where id = :acctId];
      
      if(AccountsList != null && AccountsList.size()>0)
      {
        returnNDAId = AccountsList[0].New_Dealer_Application__c;
      }
            
      return returnNDAId; 
    }
    
    @RemoteAction
    global static Boolean getNDAPassword(String nId, String acctId)
    {
      Account a;
      New_Dealer_Application__c tempNDA = new New_dealer_Application__c();
      Boolean NDAPasswordFound=FALSE;
      
      if(nId != '' && nId != null)
      {
        List<New_Dealer_Application__c> tempNDAList = [select id, password__c from New_Dealer_Application__c where id = :nId order by createdDate desc];
        
        if(tempNDAList != null && tempNDAList.size()>0 && tempNDAList[0].password__c != null && tempNDAList[0].password__c != '')
          NDAPasswordFound=TRUE;  
      }
      
      return NDAPasswordFound;
    }
    
    @RemoteAction
    global static String findMatchingProspect(string legalName, string statecode, string phoneNumber, string priMfg, string ndaId)
    {    
      try
      {
        Boolean priMfgExclusive = false;
        string priMfgIndustry;
        string priMfgParentName;
         
        List<Manufacturer__c>  mfgList = [select id, name, exclusive__c, industry__c, primary_manufacturer__r.name from manufacturer__c where name =: priMfg or primary_manufacturer__r.name = :priMfg];
            
        if(mfgList != null && mfgList.size()>0)
        {
          priMfgExclusive = mfgList[0].exclusive__c;
          priMfgIndustry = mfgList[0].industry__c;
          
          if(mfgList[0].primary_manufacturer__r.name != null && mfgList[0].primary_manufacturer__r.name != '')
            priMfgParentName = mfgList[0].primary_manufacturer__r.name;
          else
            priMfgParentName = mfgList[0].name;
        }
                
        String normalizedLegalName;
        String normalizedPhoneNumber;
      
        if(legalName != null && legalName != '')
          normalizedLegalName = legalName.remove('.').remove('INC').remove('inc').remove('Inc').remove('Incorporated').remove('incorporated').remove('LLC').remove('Llc').remove('llc').remove('\'').remove(',').remove('&').remove(' ');
     
        if(phoneNumber != null && phoneNumber != '')
          normalizedPhoneNumber = phoneNumber.remove('(').remove(')').remove('-').remove(' ').left(10);
 
        List<Account> phoneMatchingProspectDealers = [select id, Name, billingStateCode, Phone from account where recordtypeid = :Constants.AccountRTProspectDealer and phoneProsMatching__c =:normalizedPhoneNumber order by LastModifiedDate desc];
            
        List<Account> StateMatchingProspectDealers = [select id, Name, billingStateCode, Phone from account where recordtypeid = :Constants.AccountRTProspectDealer and billingStateCode = :statecode]; 

        String normalizedAccountName;
        String normalizedAccountPhone;
        
        //Check to see if there is a match based on phone number
        if(phoneMatchingProspectDealers!= null && phoneMatchingProspectDealers.size() > 0)
        { 
          List<id> phoneMatchingProspectIdsList = new List<id>();
          
          for(Account a: phoneMatchingProspectDealers)
            phoneMatchingProspectIdsList.add(a.id);
                         
          List<Product_Information_For_New_Dealer_App__c> pjsList = new List<Product_Information_For_New_Dealer_App__c>();
          
          Map<id,List<Product_Information_For_New_Dealer_App__c>> phoneMatchingProspectIdToProdsListMap = new Map<id,List<Product_Information_For_New_Dealer_App__c>>();
          
          if(priMfgExclusive == true)
          {
            pjsList = [select id, manufacturer__c, manufacturer__r.name, manufacturer__r.primary_manufacturer__r.name, relationship__c, industry__c from Product_Information_For_New_Dealer_App__c where relationship__c in :phoneMatchingProspectIdsList and manufacturer__c != null and (manufacturer__r.name =: priMfg or manufacturer__r.primary_manufacturer__r.name =:priMfg or manufacturer__r.name =: priMfgParentName or manufacturer__r.primary_manufacturer__r.name =:priMfgParentName)];
          }
          else if(priMfgExclusive == false)
          {
            pjsList = [select id, manufacturer__c, manufacturer__r.name, manufacturer__r.primary_manufacturer__r.name, relationship__c, industry__c from Product_Information_For_New_Dealer_App__c where relationship__c in :phoneMatchingProspectIdsList and manufacturer__c != null and industry__c =:priMfgIndustry];   
          }  
              
          for(Account a: phoneMatchingProspectDealers)
          { 
            List<Product_Information_For_New_Dealer_App__c> ptempList = new List<Product_Information_For_New_Dealer_App__c>();
 
            for(Product_Information_For_New_Dealer_App__c p: pjsList)
            {
              if(a.id == p.relationship__c)
                pTempList.add(p);
            }
            
            phoneMatchingProspectIdToProdsListMap.put(a.id, pTempList);
         }    
         
         for(Account a: phoneMatchingProspectDealers)
         {               
           normalizedAccountName = a.name.remove('.').remove('INC').remove('inc').remove('Inc').remove('Incorporated').remove('incorporated').remove('LLC').remove('Llc').remove('llc').remove('\'').remove(',').remove('&').remove(' ');   
            
           if(normalizedLegalName.equalsIgnoreCase(normalizedAccountName))
           {
             if(priMfgExclusive == true)
             {
               for(Product_Information_For_New_Dealer_App__c p :phoneMatchingProspectIdToProdsListMap.get(a.id))
               {                  
                 if(p.manufacturer__r.name == priMfg || p.manufacturer__r.name == priMfgParentName || p.manufacturer__r.primary_manufacturer__r.name == priMfg || p.manufacturer__r.primary_manufacturer__r.name == priMfgParentName)
                 {
                   matchedProspect = a;
                   matchedProspectId = a.id;
            
                   return matchedProspectId;
                 }
               }
             }
             else if(priMfgExclusive == false)
             {
               for(Product_Information_For_New_Dealer_App__c p :phoneMatchingProspectIdToProdsListMap.get(a.id))
               {       
                 if(p.industry__c == priMfgIndustry)
                 {                
                   matchedProspect = a;
                   matchedProspectId = a.id;
                   return matchedProspectId;
                 } 
               }
             }
           }
         }   
       }
       //Check to see if there is a match based on state code and name
       else if(StateMatchingProspectDealers != null && StateMatchingProspectDealers.size()>0)
       {    
         List<id> stateMatchingProspectIdsList = new List<id>();
          
         for(Account a: StateMatchingProspectDealers)
           stateMatchingProspectIdsList.add(a.id);
            
         List<Product_Information_For_New_Dealer_App__c> stateMatchingProspectPJsList = new List<Product_Information_For_New_Dealer_App__c>();
          
         Map<id,List<Product_Information_For_New_Dealer_App__c>> prospectIdToProdsListMap = new Map<id,List<Product_Information_For_New_Dealer_App__c>>();
          
         if(priMfgExclusive == true)
         {
           stateMatchingProspectPJsList = [select id, manufacturer__c, manufacturer__r.name, manufacturer__r.primary_manufacturer__r.name, relationship__c, industry__c from Product_Information_For_New_Dealer_App__c where relationship__c in :stateMatchingProspectIdsList and manufacturer__c != null and (manufacturer__r.name =: priMfg or manufacturer__r.primary_manufacturer__r.name =:priMfg or manufacturer__r.name =: priMfgParentName or manufacturer__r.primary_manufacturer__r.name =: priMfgParentName)];  
         }
         else if(priMfgExclusive == false)
         {
           stateMatchingProspectPJsList = [select id, manufacturer__c, manufacturer__r.name, manufacturer__r.primary_manufacturer__r.name, relationship__c, industry__c from Product_Information_For_New_Dealer_App__c where relationship__c in :stateMatchingProspectIdsList and manufacturer__c != null and industry__c =:priMfgIndustry];   
         }  
              
         for(Account a: StateMatchingProspectDealers)
         {
           List<Product_Information_For_New_Dealer_App__c> ptempList = new List<Product_Information_For_New_Dealer_App__c>();
 
           for(Product_Information_For_New_Dealer_App__c p: stateMatchingProspectPJsList)
           {
             if(a.id == p.relationship__c)
               pTempList.add(p);
           }
            
           prospectIdToProdsListMap.put(a.id, pTempList);
         }           
                            
         for(Account a: StateMatchingProspectDealers)
         { 
           normalizedAccountName = a.Name.remove('.').remove('inc').remove('Inc').remove('INC').remove('Incorporated').remove('incorporated').remove('LLC').remove('Llc').remove('llc').remove('\'').remove(',').remove('&').remove(' ');

           if((normalizedLegalName.equalsignorecase(normalizedAccountName) && statecode.contains(a.billingStateCode)))
           {   
             if(prospectIdToProdsListMap.get(a.id) != null)
             {
               for(Product_Information_For_New_Dealer_App__c p: prospectIdToProdsListMap.get(a.id))
               {
                 if(priMfgExclusive == true)
                 {
                   if(p.manufacturer__r.name == priMfg || p.manufacturer__r.name == priMfgParentName || p.manufacturer__r.primary_manufacturer__r.name == priMfg || p.manufacturer__r.primary_manufacturer__r.name == priMfgParentName)
                   {
                     matchedProspect = a;
                     matchedProspectId = a.id;
             
                     return matchedProspectId;
                   }
                 }
                 else if(priMfgExclusive == false)
                 {
                   if(p.industry__c == priMfgIndustry)
                   {
                     matchedProspect = a;
                     matchedProspectId = a.id;
             
                     return matchedProspectId; 
                   }  
                 }   
               }
             }
           }
         }
       }          
       return matchedProspectId;  
     }
     catch(Exception excp)
     { 
       UtilityClass.logError(excp,'NDA', ndaId, 'Legal name: '+legalName + ', Phone number: '+phoneNumber + ', Primary Mfg: '+priMfg);
       throw excp;
        
     //  return null;
     } 
   }
   //
    
    public class OwnerSignatureDate
    {
      public string ownerName {get;set;}
      public string signatureDate {get;set;}
    } 
    
    public List<OwnerSignatureDate> ownerSignaturesList {get;set;}
    
    public integer value {get;set;}
        
    public PageReference incrementValue() 
    {
          if(value == 90)
            value = 10;
          else  
            value = value+10;  
         
        return null; 
    } 
    //
    
   public account populateIndividualGuarantorRelationship(Account a, IndOwner io)
   {  
     system.debug(io);

      if(io != null) 
      {
        a.recordtypeid= Constants.AccountRTMap.get('Guarantors');
        a.BillingStreet = io.street;
        a.BillingCity = io.city;
      
        system.debug(nda.country__c);
        
        if(nda.Country__c == 'United States')
          a.BillingCountryCode = 'US';
        else if(nda.Country__c == 'Canada')
          a.BillingCountryCode = 'CA';
        else if(AU_NZ_Support && nda.Country__c == 'Australia')
          a.BillingCountryCode = 'AU';
        else if(AU_NZ_Support && nda.Country__c == 'New Zealand')
          a.BillingCountryCode = 'NZ';    
        
        if(nda.language__c == 'English')
        {
          a.BillingState = io.state;
          a.BillingStateCode = stateNameToCodeMap.get(io.state);
        } 
        else if(nda.language__c == 'French Canadian')       
        {
          a.BillingState = FrenchToEnglishCAProvinceMap.get(io.state);
          a.BillingStateCode = stateNameToCodeMap.get(a.BillingState);  
        }  
        
        
        a.BillingPostalCode = io.postalcode; 
      
        a.first_name__c = io.firstname;
        a.last_name__c = io.lastname;
      
        if(io.suffix != null && io.suffix != '')
          a.Suffix__c = io.suffix;
          
        if(io.middlename != null && io.middlename != '')  
          a.Middle_I__c = io.middlename;
         
        a.Name = io.firstname  + ' ' + io.middlename + ' ' + io.lastname + ' ' + io.suffix;
        
        if(a.Name != null && a.Name != '' && a.Name.containsIgnoreCase('null'))
        {
          a.Name = a.Name.remove('null');
          a.Name = a.Name.normalizeSpace();
        }
              
        a.Phone = io.phone;
        a.Guarantor_Email__c = io.email;
        a.Title__c = io.Title;  
        
        //US application
        if(nda.country__c == 'United States')
        {
          a.Date_of_Birth__c  = Date.parse(io.birthdate);  
        }
        //Canada / Australia / New Zealand application        
        else if(nda.country__c == 'Canada' || (AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c == 'New Zealand')))
        {
          Date tempDate = date.newInstance(Integer.valueof(io.birthdate.substring(6,10)), Integer.valueof(io.birthdate.substring(3,5)), Integer.valueof(io.birthdate.substring(0,2)));
        
          a.Date_of_Birth__c  = tempdate;
        }
           
        if(io.ssn != null && io.ssn != '' && !io.ssn.contains('*'))
        {
          a.Social_Security_number__c = io.ssn;
        }
        
        a.Primary_ID_Type__c = 'Driver\'s License';
        a.Primary_ID_Number__c = io.driversLicenseNumber;
        
        if(AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c == 'New Zealand'))
          a.Government_ID_Expiration_Date__c = date.newInstance(Integer.valueof(io.driversLicenseExpDate.substring(6,10)), Integer.valueof(io.driversLicenseExpDate.substring(3,5)), Integer.valueof(io.driversLicenseExpDate.substring(0,2)));  
      
      
       //santosh -added for WI 3650
        if(a.id==null)
           a.Created_Through_App_Site__c=true;

      }
            
      system.debug(a);
      
      return a;          
    }

    public account populateEntityGuarantorRelationship(Account a, CorpOwnerInfo coInfo)
    {  
      if(coInfo != null) 
      {
        a.recordtypeid= Constants.AccountRTMap.get('Guarantors');
        a.Name = coInfo.legalEntityName;
        a.BillingStreet = coInfo.street;
        a.BillingCity = coInfo.city;
      
        if(nda.Country__c == 'United States')
        {
          a.BillingCountryCode = 'US';
        }
        else if(nda.Country__c == 'Canada')
        {
          a.BillingCountryCode = 'CA';
        }
        else if(AU_NZ_Support && nda.Country__c == 'Australia')
        {
          a.BillingCountryCode = 'AU';
        }
        else if(AU_NZ_Support && nda.Country__c == 'New Zealand')
        {
          a.BillingCountryCode = 'NZ';
        }
        
        //a.BillingState = coInfo.state;
        //a.BillingStateCode = stateNameToCodeMap.get(coInfo.state);
       
        if(nda.language__c == 'English')
        {
          a.BillingState = coInfo.state;
          a.BillingStateCode = stateNameToCodeMap.get(coInfo.state);
          a.State_of_Incorporation__c = coInfo.formationState;
        } 
        else if(nda.language__c == 'French Canadian')       
        {
          a.BillingState = FrenchToEnglishCAProvinceMap.get(coInfo.state);
          a.BillingStateCode = stateNameToCodeMap.get(a.BillingState);
          a.State_of_Incorporation__c = FrenchToEnglishCAProvinceMap.get(coInfo.formationState);    
        } 
        
        a.BillingPostalCode = coInfo.postalcode;
        //a.State_of_Incorporation__c = stateCodeToNameMap.get(coInfo.formationState);
        
        a.Tax_Identification_Number__c = coInfo.taxId;
        a.Name_of_Authorized_Signer__c = coInfo.authorizedSignerFirstname+' '+coInfo.authorizedSignerMiddlename+' '+coInfo.authorizedSignerLastName;
        a.Title_of_Authorized_Signer__c = coInfo.entityOwnerTitle;
        
        //santosh-added for WI 3650
        if(a.id==null)
            a.Created_Through_App_Site__c=true;  
      }
      
      return a;
               
    }

    public IndOwner populateIndOwner(IndOwner io, Owner__c o, Associated_Relationships__c assoc)
    {  
      if(o != null)   
      { 
        io.firstname = o.relationship__r.first_name__c;
        io.lastname =  o.relationship__r.last_name__c;
        io.middlename = o.relationship__r.middle_i__c;
        io.suffix = o.relationship__r.suffix__c;
        io.street = o.relationship__r.billingstreet;
        io.city = o.relationship__r.billingcity;
        io.state = o.relationship__r.billingstate;
        io.postalcode = o.relationship__r.billingpostalcode;
        io.phone = o.relationship__r.phone;
        io.email = o.relationship__r.Guarantor_Email__c;
        io.ssn = o.relationship__r.social_security_number__c;
        io.driversLicenseNumber = o.relationship__r.primary_id_number__c;
        
        system.debug(io.state);
        
        if(nda.language__c == 'French Canadian')
          io.state = EnglishToFrenchCAProvinceMap.get(io.state);
          
        //Birth date   
        if(o.relationship__r.date_of_birth__c != null)
        {
          string month;
          string day;
            
          if(o.relationship__r.date_of_birth__c.month() < 10)
          {
            month='0'+o.relationship__r.date_of_birth__c.month();
          }
          else
          {
            month = string.valueof(o.relationship__r.date_of_birth__c.month()); 
          }
          
          if(o.relationship__r.date_of_birth__c.day() < 10)
          {
            day='0'+o.relationship__r.date_of_birth__c.day();
          }
          else
          {
            day = string.valueof(o.relationship__r.date_of_birth__c.day());
          }  
        
          if(nda.country__c == 'United States')
          {
            io.birthdate=month+'/'+day+'/'+o.relationship__r.date_of_birth__c.year();
          }
          else
          {
            io.birthdate=day+'/'+month+'/'+o.relationship__r.date_of_birth__c.year();
          }
        }
        
        //Driver's license exp date
        if(o.relationship__r.Government_ID_Expiration_Date__c != null)
        {
          string month;
          string day;
            
          if(o.relationship__r.Government_ID_Expiration_Date__c.month() < 10)
          {
            month='0'+o.relationship__r.Government_ID_Expiration_Date__c.month();
          }
          else
          {
            month = string.valueof(o.relationship__r.Government_ID_Expiration_Date__c.month()); 
          }
          
          if(o.relationship__r.Government_ID_Expiration_Date__c.day() < 10)
          {
            day='0'+o.relationship__r.Government_ID_Expiration_Date__c.day();
          }
          else
          {
            day = string.valueof(o.relationship__r.Government_ID_Expiration_Date__c.day());
          }  
        
          if(nda.country__c == 'United States')
          {
            io.driversLicenseExpDate=month+'/'+day+'/'+o.relationship__r.Government_ID_Expiration_Date__c.year();
          }
          else
          {
            io.driversLicenseExpDate=day+'/'+month+'/'+o.relationship__r.Government_ID_Expiration_Date__c.year();
          }
        }
           
        //Need to fetch related association record for these data
        io.title = assoc.title__c;
        io.pctOwnership = String.valueof(assoc.Ownership_Percentage__c);
        io.ownerRelationshipRecordId = o.relationship__c;
        
        io.assocRecordIdsList = new List<id>();
        io.assocRecordIdsList.add(assoc.id);
       
        if(o.date_of_signature__c != null)
        { 
          if(nda.language__c == 'English' && nda.Country__c == 'United States')
            io.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'US_EN') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();
          else if(nda.language__c == 'French Canadian' && nda.Country__c == 'Canada')
            io.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'CA_FR') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();
          else if(nda.language__c == 'English' && nda.Country__c == 'Canada')
            io.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'CA_EN') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();
          else if(AU_NZ_Support && nda.language__c == 'English' && nda.Country__c == 'Australia')
            io.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'AU_EN') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();
          else if(AU_NZ_Support && nda.language__c == 'English' && nda.Country__c == 'New Zealand')
            io.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'NZ_EN') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();  
        }      
        
        if(io.consentSigned != null && io.consentSigned != '')
        {
          setButtonsVisibility(io,null,FALSE,FALSE,TRUE,FALSE,FALSE,FALSE);
        }
        else
        {
          setButtonsVisibility(io,null,FALSE,TRUE,TRUE,TRUE,FALSE,FALSE);
        }
      }
      //Create a blank new indOwner record 
      else
      {
        setButtonsVisibility(io,null,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
      }
         
      return io;  
    }

    public CorpOwner populateCorpOwner(CorpOwner co, Owner__c o, Associated_Relationships__c assoc)
    {  
      if(o != null)   
      { 
        //co.cOwnerInfo = new CorpOwnerInfo();
        co.indEntityOwnersList = new List<indOwner>();
        co.corpEntityOwnersList = new List<corpOwnerInfo>();
        co.cOwnerInfo.legalEntityName = o.relationship__r.Name;                
        co.cOwnerInfo.street = o.relationship__r.billingstreet;
        co.cOwnerInfo.city = o.relationship__r.billingcity;
        co.cOwnerInfo.state = o.relationship__r.billingstate;
        co.cOwnerInfo.formationState = o.relationship__r.State_of_Incorporation__c;
        
        if(nda.language__c == 'French Canadian')
        {
          co.cOwnerInfo.state = EnglishToFrenchCAProvinceMap.get(co.cOwnerInfo.state);
          co.cOwnerInfo.formationState = EnglishToFrenchCAProvinceMap.get(o.relationship__r.State_of_Incorporation__c);
        }
        
        system.debug(co.cOwnerInfo.legalEntityName+','+co.cOwnerInfo.formationState);
        
        co.cOwnerInfo.postalcode = o.relationship__r.billingpostalcode;
        co.cOwnerInfo.taxId = o.relationship__r.Tax_Identification_Number__c;
        
        if(o.relationship__r.name_of_authorized_signer__c != null && o.relationship__r.name_of_authorized_signer__c != '')
        {
          co.cOwnerInfo.authorizedSignerFirstName=o.relationship__r.name_of_authorized_signer__c.split(' ')[0];
          co.cOwnerInfo.authorizedSignerMiddleName=o.relationship__r.name_of_authorized_signer__c.split(' ')[1];
          co.cOwnerInfo.authorizedSignerLastName=o.relationship__r.name_of_authorized_signer__c.split(' ')[2];
        }
        
        //Need to fetch related association record for these data
        co.cOwnerInfo.entityOwnertitle = assoc.title__c;
        co.cOwnerInfo.pctOwnership = String.valueof(assoc.Ownership_Percentage__c);
        co.cOwnerInfo.ownerRelationshipRecordId = o.relationship__c;
        
        co.cOwnerInfo.assocRecordIdsList = new List<id>();
        co.cOwnerInfo.assocRecordIdsList.add(assoc.id);
                       
        if(o.date_of_signature__c != null)
        { 
          if(nda.language__c == 'English' && nda.Country__c == 'United States')
            co.cOwnerInfo.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'US_EN') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();
          else if(nda.language__c == 'French Canadian' && nda.Country__c == 'Canada')
            co.cOwnerInfo.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'CA_FR') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();
          else if(nda.language__c == 'English' && nda.Country__c == 'Canada')
            co.cOwnerInfo.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'CA_EN') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();
          else if(AU_NZ_Support && nda.language__c == 'English' && nda.Country__c == 'Australia')
            co.cOwnerInfo.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'AU_EN') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();
          else if(AU_NZ_Support && nda.language__c == 'English' && nda.Country__c == 'New Zealand')
            co.cOwnerInfo.consentSigned = getMonthNameFromNumber(o.date_of_signature__c.month(), 'NZ_EN') + ' ' + o.date_of_signature__c.day() + ', ' + o.date_of_signature__c.year();            
                  
        }
        
        if(co.cOwnerInfo.consentSigned != null && co.cOwnerInfo.consentSigned != '')
        {
          setButtonsVisibility(null,co.cOwnerInfo,FALSE,FALSE,TRUE,FALSE,FALSE,FALSE);
        }
        else
        {
          setButtonsVisibility(null,co.cOwnerInfo,FALSE,TRUE,TRUE,TRUE,FALSE,FALSE);
        }  
             
        for(Integer j=0; j<Integer.valueof(co.numIndEntityOwners); j++)
        {
          IndOwner ieo = new IndOwner();
                
          ieo.num = String.valueof(j+1);
          
          setButtonsVisibility(ieo, null,TRUE,FALSE,FALSE,TRUE,FALSE,FALSE);
               
          co.indEntityOwnersList.add(ieo);
        }
             
        for(Integer k=0; k<Integer.valueof(co.numCorpEntityOwners); k++)
        {
          CorpOwnerInfo ceoi = new CorpOwnerInfo();
               
          ceoi.num = String.valueof(k+1);
          
          setButtonsVisibility(null,ceoi,TRUE,FALSE,FALSE,TRUE,FALSE,FALSE);
             
          co.corpEntityOwnersList.add(ceoi);
        }           
      }
      //Create a blank new corpOwner record 
      else
      {
        setButtonsVisibility(null,co.cOwnerInfo,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
      }
         
      return co;  
    }
    
    public void saveIndividualOwnerInformation()
    {
      indOwner indOwner;
            
      try
      {
        indOwner = (indOwner)indOwnerList[saveWhichOwnerNum-1];
        indOwner.messages.clear();
        
        //Validate form data
        validateIndOwnerData(indOwner);
        
        ///////////////////////////////////////////////////////////////////////////////
        //If owner data has error(s), display error(s) and show buttons accordingly  //
        ///////////////////////////////////////////////////////////////////////////////
        if(indOwner.messages != null && indOwner.messages.size() > 0)
        {       
          setButtonsVisibility(indOwner,null,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
        }
        //////////////////////////////////////////////////////////////////////
        //Update matched, existing individual guarantor relationship record //
        //////////////////////////////////////////////////////////////////////
        else
        {     
          if(indOwner.ownerRelationshipRecordId != null)
          {       
            if(indOwner.messages != null && indOwner.messages.size() > 0)
            { 
              setButtonsVisibility(indOwner,null,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
            }
            else
            {
              //Update guarantor/owner relationship record
              Account acct = new Account(id=indOwner.ownerRelationshipRecordId);
              acct = populateIndividualGuarantorRelationship(acct, indOwner);
              system.debug(indOwner);
              system.debug(acct);
              update acct;
              
              //Update associations
              List<Associated_Relationships__c> aList = new List<Associated_Relationships__c>();
              aList = [select id from Associated_Relationships__c where id in :indOwner.assocRecordIdsList];
              
              system.debug(aList);
              
              for(Associated_Relationships__c assoc: aList)
              {
                updateAssociation(assoc.id, 'Individual', indOwner, null);
              }
                
              setButtonsVisibility(indOwner,null,FALSE,TRUE,TRUE,TRUE,FALSE,FALSE);
            }
          }
          ////////////////////////////////////////////////////////////////////////////////
          //Create new individual guarantor relationship, owner and association records //
          ////////////////////////////////////////////////////////////////////////////////
          else
          {
            Account acct = new Account();
            if(indOwner.messages != null && indOwner.messages.size() > 0)
            {
              setButtonsVisibility(indOwner,null,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
            }
            else
            {   
              //Create new guarantor/owner relationship record
              acct = populateIndividualGuarantorRelationship(acct, indOwner);           
              insert acct;
              indOwner.ownerRelationshipRecordId = acct.id;

              setButtonsVisibility(indOwner,null,FALSE,TRUE,TRUE,TRUE,FALSE,FALSE);
            }
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //Create guarantor's owner record and guarantor-prospect dealer association records for each of the prospect dealer relationship records created (depending on exclusive, non-exclusive manufacturers for this NDA) //
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            if(ndaId != null)
            { 
              List<Product_Information_For_New_Dealer_App__c> productsList = new List<Product_Information_For_New_Dealer_App__c>();
        
              productsList = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c
                                                                            where New_Dealer_Application2__c = : ndaId];
                                                                            
              createOwner(ndaId, acct.id, 'Individual', indOwner, null);
              indOwner.assocRecordIdsList = new List<id>();

              Set<id> ndaDealerRecIds = new Set<id>();
              
              for(Product_Information_For_New_Dealer_App__c prodJunc: productsList)
              {
                 ndaDealerRecIds.add(prodJunc.relationship__c);
              }

              for(id ndaDealerRelId :ndaDealerRecIds)
              {
                createAssociation(ndaId, ndaDealerRelId, acct.id, 'Individual', indOwner, null);
              }
            } 
          } 
        }
            
        if(indOwner.messages != null && indOwner.messages.size()==0)
          indOwner.collapsed = TRUE;      
          
        showNoOwnersMessage=FALSE;  
      }
      catch(Exception excp)
      {
         UtilityClass.logError(excp,'NDA', ndaId, 'Owner Name: '+indOwner.firstname+' '+indOwner.lastName);
         indOwner.messages.add(UNEXPECTED_ERROR_OCCURRED);
      }
    }
    
    public void saveCorporateOwnerInformation()
    {
        corpOwner corpOwner;
        
        pageMessage = '';
        
        try
        {
        
        corpOwner = (corpOwner)corpOwnerList[saveWhichOwnerNum-1];
        corpOwner.cOwnerInfo.messages.clear();
        
        //Validate form data
        validateCorpOwnerData(corpOwner.cOwnerInfo);
        
        ///////////////////////////////////////////////////////////////////////////////
        //If owner data has error(s), display error(s) and show buttons accordingly  //
        ///////////////////////////////////////////////////////////////////////////////
        if(corpOwner.cOwnerInfo.messages != null && corpOwner.cOwnerInfo.messages.size() > 0)
        {       
          setButtonsVisibility(null,corpOwner.cOwnerInfo,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
        }
        //////////////////////////////////////////////////////////////////////
        //Update matched, existing individual guarantor relationship record // 
        //////////////////////////////////////////////////////////////////////
        else
        {
          //Update matched, existing entity guarantor relationship record
          if(corpOwner.cOwnerInfo.ownerRelationshipRecordId != null)
          {
            
            if(corpOwner.cOwnerInfo.messages != null && corpOwner.cOwnerInfo.messages.size() > 0)
            { 
              setButtonsVisibility(null,corpOwner.cOwnerInfo,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
            }
            else
            {
              Account acct = new Account(id=corpOwner.cOwnerInfo.ownerRelationshipRecordId);
              acct = populateEntityGuarantorRelationship(acct, corpOwner.cOwnerInfo);
              update acct;
              
              //Update associations
              List<Associated_Relationships__c> aList = new List<Associated_Relationships__c>();
              aList = [select id from Associated_Relationships__c where id in :corpOwner.cOwnerInfo.assocRecordIdsList];
              
              for(Associated_Relationships__c assoc: aList)
              {
                updateAssociation(assoc.id, 'Corporate', null, corpOwner.cOwnerInfo);
              }
          
              setButtonsVisibility(null,corpOwner.cOwnerInfo,FALSE,TRUE,TRUE,TRUE,FALSE,FALSE);
            }
         }
         ////////////////////////////////////////////////////////////////////////////////
         //Create new individual guarantor relationship, owner and association records //
         ////////////////////////////////////////////////////////////////////////////////
         else
         {
           Account acct = new Account();
           acct = populateEntityGuarantorRelationship(acct, corpOwner.cOwnerInfo);
                        
           if(corpOwner.cOwnerInfo.messages != null && corpOwner.cOwnerInfo.messages.size() > 0)
           {
             setButtonsVisibility(null,corpOwner.cOwnerInfo,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
           }
           else
           {    
             insert acct; 

             corpOwner.cOwnerInfo.ownerRelationshipRecordId = acct.id;
          
             setButtonsVisibility(null,corpOwner.cOwnerInfo,FALSE,TRUE,TRUE,TRUE,FALSE,FALSE);
           }
           //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
           //Create guarantor's owner record and guurantor-prospect dealer association records for each of the prospect dealer relationship records created (depending on exclusive, non-exclusive manufacturers for this NDA) //
           //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
           
           system.debug(corpOwner.cOwnerInfo);
           
           if(ndaId != null)
           { 
              List<Product_Information_For_New_Dealer_App__c> productsList = new List<Product_Information_For_New_Dealer_App__c>();
        
              productsList = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c
                                                                            where New_Dealer_Application2__c = : ndaId];
                                                                            
              createOwner(ndaId, acct.id,  'Corporate', null, corpOwner.cOwnerInfo);
              corpOwner.cOwnerInfo.assocRecordIdsList = new List<id>();
              
              Set<id> ndaDealerRecIds = new Set<id>();
              
              for(Product_Information_For_New_Dealer_App__c prodJunc: productsList)
              {
                 ndaDealerRecIds.add(prodJunc.relationship__c);
              }

              for(id ndaDealerRelId :ndaDealerRecIds)
              {
                createAssociation(ndaId, ndaDealerRelId, acct.id, 'Corporate', null, corpOwner.cOwnerInfo);
              }
           } 
         }
       }  
            
       if(corpOwner.cOwnerInfo.messages != null && corpOwner.cOwnerInfo.messages.size()==0)
          corpOwner.cOwnerInfo.collapsed = TRUE;
          
       showNoOwnersMessage=FALSE;
       }
       catch(Exception excp) 
       {
          UtilityClass.logError(excp,'NDA',ndaId, 'Owner Name: '+corpOwner.cOwnerInfo.legalEntityName);
          corpOwner.cOwnerInfo.messages.add(UNEXPECTED_ERROR_OCCURRED);
          
          pageMessage = System.Label.Something_Went_Wrong;
       }
    }
    
    
    public void createOwner(string ndaId, string guarantorRelationshipRecordId, string ownerType, IndOwner io, corpOwnerInfo coi)
    {
      /////////////////////////////////////
      // Create guarantor's owner record //
      /////////////////////////////////////   
      Owner__c owner = new Owner__c(); 
      owner.New_Dealer_Application__c = ndaId;
      owner.Relationship__c = guarantorRelationshipRecordId;
       
      insert owner;
       
      if(ownerType=='Individual')
      {
        io.ownerRecordId = owner.id;
      }
      else if(ownerType=='Corporate')
      {
        coi.ownerRecordId = owner.id;
      }
    }

    //Modified by Nimish to accomodate potentially multiple prospect dealer records related to an NDA
    public void createAssociation(string ndaId, string prospectDealerRelationshipRecordId, string guarantorRelationshipRecordId, string typeOfOwner, IndOwner io, corpOwnerInfo coi)
    {
      try   
      {
        /////////////////////////////////////////////////
        //Create guarantor-prospect association record //
        /////////////////////////////////////////////////
        Associated_Relationships__c ar = new Associated_Relationships__c();
     
        ar.Association_Type__c = 'Guarantor';
        ar.Primary_Relationship__c   = prospectDealerRelationshipRecordId;
        ar.Secondary_Relationship__c = guarantorRelationshipRecordId;
     
        if(typeOfOwner == 'Individual')    
        {
          ar.Title__c = io.Title;
       
          if(typeOfOwner=='Individual')
          {
            ar.Type__c = 'Individual';
          }
       
          if(io != null && io.pctOwnership != '')
          {
            ar.Ownership_Percentage__c = Decimal.valueof(io.pctOwnership);
          }
        }
        else if(typeOfOwner == 'Corporate')
        {
          ar.Title__c = coi.entityOwnerTitle;
      
          if(typeOfOwner=='Corporate')
          {
            ar.Type__c = 'Entity';
          }
       
          if(coi != null && coi.pctOwnership != '')
          {
            ar.Ownership_Percentage__c = Decimal.valueof(coi.pctOwnership); 
          } 
        }
     
        insert ar;
          
        if(typeOfOwner == 'Individual')
        {
          io.assocRecordIdsList.add(ar.id);
        }
        else if(typeOfOwner == 'Corporate')
        {
          coi.assocRecordIdsList.add(ar.id);
        }
      }
      catch(Exception excp)
      {
        UtilityClass.logError(excp,'NDA', ndaId, 'Prospect Dealer Rec. Id: '+prospectDealerRelationshipRecordId + ', Guarantor Record Id: '+guarantorRelationshipRecordId); 
        
        if(typeOfOwner == 'Individual')
          io.messages.add(UNEXPECTED_ERROR_OCCURRED);
        else if(typeOfOwner == 'Corporate')  
          coi.messages.add(UNEXPECTED_ERROR_OCCURRED);
          
        pageMessage = System.Label.Something_Went_Wrong;  
     }     
   }

    //Modified by Nimish to accomodate potentially multiple prospect dealer records related to an NDA 
    public void updateAssociation(Id assocId, string typeOfOwner, IndOwner io, corpOwnerInfo coi)
    {       
      try
      { 
        /////////////////////////////////////////////////
        //Update guarantor-prospect association record //
        /////////////////////////////////////////////////
        Associated_Relationships__c ar = new Associated_Relationships__c(id=assocId);
     
        if(typeOfOwner == 'Individual')    
        {
          ar.Title__c = io.Title;
       
          if(io != null && io.pctOwnership != '')
          {
            ar.Ownership_Percentage__c = Decimal.valueof(io.pctOwnership);
          }
        }
        else if(typeOfOwner == 'Corporate')
        {
          ar.Title__c = coi.entityOwnerTitle;
      
          if(coi != null && coi.pctOwnership != '')
          {
            ar.Ownership_Percentage__c = Decimal.valueof(coi.pctOwnership); 
          } 
        }
     
        update ar;
      }
      catch(Exception excp)
      {
        UtilityClass.logError(excp,'NDA', ndaId, 'Association Rec. Id: '+assocId + ', Owner Type: '+typeOfOwner); 
        showErrorMessage = true;
        
        pageMessage = System.Label.Something_Went_Wrong; 
      }
    }

    public pageReference saveOwnerInformation()
    {      
      /////////////////////
      //INDIVIDUAL OWNER //
      /////////////////////
      if(ownerType == 'Individual')
      {
        saveIndividualOwnerInformation();
      }
      else if(ownerType == 'Corporate')
      {
        saveCorporateOwnerInformation();
      }
      
      return null;
   }
    
    
    public pageReference updateOwnerInformation()
    {    
      indOwner indOwner;
      corpOwner corpOwner;
      
      if(ownerType == 'Individual')// || ownerType == 'Individual-Indirect')
      {
        for(indOwner owner: indOwnerList)
        {
          system.debug(owner.ownerRelationshipRecordId+','+editWhichOwnerRecord);
          if(owner.ownerRelationshipRecordId == editWhichOwnerRecord)
          {
            indOwner = Owner;
            indOwner.collapsed = FALSE;
            
            setButtonsVisibility(indOwner,null,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
            
            break;
          }
        }
      }
      else if (ownerType == 'Corporate')// || ownerType == 'Corporate-Indirect')
      {
        for(corpOwner owner: corpOwnerList)
        {
          if(owner.cOwnerInfo.ownerRelationshipRecordId == editWhichOwnerRecord)
          {
            corpOwner = Owner;            
            corpOwner.cOwnerInfo.collapsed = FALSE;
                        
            setButtonsVisibility(null,corpOwner.cOwnerInfo,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE);
            
            break;
          }
        }
      }  

      return null;
    }
    
    public pageReference deleteOwnerInformation() 
    {
      indOwner indOw;
      corpOwnerInfo corpOwIn;
      Account a;
        
      try
      {
        pageMessage = '';
        
        showOwnerNoConsentMessage = FALSE;
        showNoOwnersMessage =  FALSE;
      
        if(ownerType == 'Individual')
        {
          for(indOwner owner: indOwnerList)
          {
            if(owner.ownerRelationshipRecordId == deleteWhichOwnerRecord)
            {
              a = new Account(id=owner.ownerRelationshipRecordId);
              indOw = owner;
            
              //Delete association records for this owner record
              deleteOwnerAssociations(owner.ownerRelationshipRecordId);
            
              //Delete owner relationship record which inturn also deletes the corresponding Owner__c record since Owner__c has a master-detail relationship with owner relationship (account)  
              delete a;
                  
              displayNumIndOwnerBlocks = displayNumIndOwnerBlocks - 1;
              indOwnerList.remove(Integer.valueof(indOw.Num)-1);
            
              break;
            }
          }
        }
        else if(ownerType == 'Corporate')
        {
          for(corpOwner owner: corpOwnerList)
          {
            if(owner.cOwnerInfo.ownerRelationshipRecordId == deleteWhichOwnerRecord)
            {
              a = new Account(id=owner.cOwnerInfo.ownerRelationshipRecordId);
              corpOwIn = owner.cOwnerInfo;
            
              //Delete association records for this owner record
              deleteOwnerAssociations(owner.cOwnerInfo.ownerRelationshipRecordId);
              //Delete owner relationship record which inturn also deletes the corresponding Owner__c record since Owner__c has a master-detail relationship with owner relationship (account)  
              delete a;
            
              corpOwnerList.remove(Integer.valueof(corpOwIn.Num)-1);
              displayNumCorpOwnerBlocks = displayNumCorpOwnerBlocks - 1; 
            
              break;
            }
          }
        }
      }
      catch(Exception excp) 
      {
        if(ownerType == 'Individual')
        {
           UtilityClass.logError(excp,'NDA',ndaId, 'Owner Type: '+ownerType + ', Owner Relationship Rec. Id: '+indOw.ownerRelationshipRecordId);
           showErrorMessage = true;
           
           pageMessage = System.Label.Something_Went_Wrong; 
        }
        else if(ownerType == 'Corporate')
        {
           UtilityClass.logError(excp,'NDA',ndaId, 'Owner Type: '+ownerType + ', Owner Relationshio Rec. Id: '+corpOwIn.ownerRelationshipRecordId);
           showErrorMessage = true;
           
           pageMessage = System.Label.Something_Went_Wrong; 
        } 
      }
      
      return null;
    } 
     
    //Delete association records from the Dealer relationship for an owner
    public void deleteOwnerAssociations(id ownerRelationshipId) 
    {
      try
      {
        List<Owner__c> oList = [select id, relationship__c, new_dealer_application__c from Owner__c where relationship__c = :ownerRelationshipId];
      
        List<Product_Information_For_New_Dealer_App__c> pList = [select id, relationship__c from Product_Information_For_New_Dealer_App__c where new_dealer_application2__c = :oList[0].new_dealer_application__c];
      
        List<Associated_Relationships__c> ownerAssocsList = [select id from Associated_Relationships__c where primary_relationship__c =: pList[0].relationship__c and secondary_relationship__c = :oList[0].relationship__c];
      
        if(ownerAssocsList != null && ownerAssocsList.size()>0) 
          delete ownerAssocsList;
      }
      catch(Exception excp)
      {
         UtilityClass.logError(excp,'NDA',ndaId, 'Owner Relationship Rec. Id: '+ownerRelationshipId);
         showErrorMessage = true;
         
         pageMessage = System.Label.Something_Went_Wrong;
      }  
    }


    public pageReference signOwnerConsents()
    {    
      indOwner indOwner;
      corpOwner corpOwner;
      
      showNoOwnersMessage = FALSE;
      showOwnerNoConsentMessage = FALSE;
      
      if(ownerType == 'Individual') 
      {
        for(indOwner owner: indOwnerList)
        {
          system.debug(owner.ownerRelationshipRecordId);
          if(owner.ownerRelationshipRecordId == editWhichOwnerRecord)
          {
            indOwner = Owner;
            
            indOwner.consentSigned = '';
            indOwner.showIndConsents = FALSE;
            indOwner.collapsed=FALSE;
            
            setButtonsVisibility(indOwner,null,FALSE,FALSE,FALSE,FALSE,TRUE,FALSE);
            
            break;
          }
        }
      }
      else if (ownerType == 'Corporate')
      {
        for(corpOwner owner: corpOwnerList)
        {
          if(owner.cOwnerInfo.ownerRelationshipRecordId == editWhichOwnerRecord)
          {
            corpOwner = owner;
            corpOwner.cOwnerInfo.consentSigned = '';
            corpOwner.cOwnerInfo.showCorpConsents = FALSE;
            corpOwner.cOwnerInfo.collapsed=FALSE;
            
            setButtonsVisibility(null,corpOwner.cOwnerInfo,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE);
            
            break;
          }
        }
      }  
      
      return null;
    }
    
    public pagereference saveOwnerSignature()
    {   
      indOwner indOwner;
      corpOwner corpOwner;
      
      signerNameDidNotMatchOwnerName = FALSE;
      showNoOwnersMessage = FALSE;
      showOwnerNoConsentMessage = FALSE;
      
      if(ownerType == 'Individual')
      {
        for(indOwner owner: indOwnerList)
        {
          system.debug(owner.ownerRelationshipRecordId);
          if(owner.ownerRelationshipRecordId == editWhichOwnerRecord)
          {
            indOwner = Owner;
            break;
          }
        }
      
        if(cancelClicked == 'yes')
        {
          cancelClicked = 'no';
          indOwner.showIndConsents = FALSE;
          setButtonsVisibility(indOwner,null,FALSE,TRUE,TRUE,TRUE,indOwner.showIndConsents,FALSE);
        }
        else if(agreeClicked == 'yes')
        {
          indOwner.termsOfUseSigned = termsOfUseSigned;
          
          if(termsOfUseSigned == FALSE)
          {
            indOwner.collapsed=FALSE;
            indOwner.showIndConsents = TRUE;
            
            setButtonsVisibility(indOwner,null,FALSE,FALSE,FALSE,FALSE,indOwner.showIndConsents,FALSE);
            return null;
          } 
           
          if(signerFirstName!= '' && signerFirstName.toUppercase() == indOwner.firstname.toUpperCase() && signerLastName != '' && signerLastName.toUpperCase() == indOwner.lastname.toUpperCase())
          {
            agreeClicked='no';
            List<Owner__c> ownerList = [select id, date_of_signature__c from Owner__c where New_Dealer_Application__c = :ndaId and relationship__c =: indOwner.ownerRelationshipRecordId];
      
            if(ownerList != null)
            {
              ownerList[0].Date_of_signature__c = System.today();
              update ownerList[0];
      
              indOwner.consentSigned = ownerList[0].date_of_signature__c.format();
            }
            
            indOwner.collapsed=TRUE;
            indOwner.showIndConsents = FALSE;
            
            setButtonsVisibility(indOwner,null,FALSE,FALSE,TRUE,FALSE,indOwner.showIndConsents,FALSE);
          }
          else
          {
            signerNameDidNotMatchOwnerName = TRUE;
            indOwner.collapsed=FALSE;
            indOwner.showIndConsents = TRUE;
            
            setButtonsVisibility(indOwner,null,FALSE,FALSE,FALSE,FALSE,indOwner.showIndConsents,FALSE);
          }
        }
      }
      else if (ownerType == 'Corporate')
      {
        for(corpOwner owner: corpOwnerList)
        {
          if(owner.cOwnerInfo.ownerRelationshipRecordId == editWhichOwnerRecord)
          {
            corpOwner = Owner;
            break;
          }
        }
        
        if(cancelClicked == 'yes')
        {
          cancelClicked = 'no';
          corpOwner.cOwnerInfo.showCorpConsents = FALSE;
          setButtonsVisibility(null,corpOwner.cOwnerInfo,FALSE,TRUE,TRUE,TRUE,FALSE,corpOwner.cOwnerInfo.showCorpConsents);
        }
        else if(agreeClicked == 'yes')
        {
          corpOwner.cOwnerInfo.termsOfUseSigned = termsOfUseSigned; 
          
          if(termsOfUseSigned == FALSE)
          {
            corpOwner.cOwnerInfo.collapsed=FALSE;
            corpOwner.cOwnerInfo.showIndConsents = TRUE;
            
            setButtonsVisibility(null,corpOwner.cOwnerInfo,FALSE,FALSE,FALSE,FALSE,FALSE,corpOwner.cOwnerInfo.showCorpConsents);
            return null;
          }
          
          if(signerFirstName != '' && signerFirstName.toUppercase() == corpOwner.cOwnerInfo.authorizedSignerFirstname.toUpperCase() && signerLastName != '' && signerLastName.toUpperCase() == corpOwner.cOwnerInfo.authorizedSignerLastname.toUpperCase())
          {
            agreeClicked='no';
            List<Owner__c> ownerList = [select id, date_of_signature__c from Owner__c where New_Dealer_Application__c = :ndaId and relationship__c =: corpOwner.cOwnerInfo.ownerRelationshipRecordId];
      
            if(ownerList != null)
            {
              ownerList[0].Date_of_signature__c = System.today();
              update ownerList[0];
        
              corpOwner.cOwnerInfo.consentSigned = ownerList[0].date_of_signature__c.format();
            }
            
            corpOwner.cOwnerInfo.termsOfUseSigned = TRUE;
            corpOwner.cOwnerInfo.collapsed=TRUE;
            corpOwner.cOwnerInfo.showCorpConsents=FALSE;
            setButtonsVisibility(null,corpOwner.cOwnerInfo,FALSE,FALSE,TRUE,FALSE,FALSE,corpOwner.cOwnerInfo.showCorpConsents);
          }
          else
          {
            signerNameDidNotMatchOwnerName = TRUE;
            corpOwner.cOwnerInfo.collapsed=FALSE;
            corpOwner.cOwnerInfo.showIndConsents = TRUE;
            
            setButtonsVisibility(null,corpOwner.cOwnerInfo,FALSE,FALSE,FALSE,FALSE,FALSE,corpOwner.cOwnerInfo.showCorpConsents);
          }
        }
        
      }
      
      signerFirstName='';
      signerLastName='';  
      
      return null;
    }
    
    public PageReference saveApplicationInformation()
    {
      showNoOwnersMessage = FALSE;
      showOwnerNoConsentMessage = FALSE;
      
      //Check to see if there is at least one owner saved
      Boolean atLeastOneIndOwner = FALSE;
      Boolean atLeastOneCorpOwner = FALSE;
      Boolean atLeastOneOwnerDoesNotHaveConsentSigned = FALSE;
        
      for(IndOwner io:  indOwnerList)
      {
        if(io.ownerRelationshipRecordId != null && io.consentSigned != '')
        {
          atLeastOneIndOwner=TRUE;
          break;
        }
      }
        
      for(corpOwner co:  corpOwnerList)
      {
        if(co.cOwnerInfo.ownerRelationshipRecordId != null && co.cOwnerInfo.consentSigned != '')
        {
          atLeastOneCorpOwner=TRUE;
          break;
        }
      } 
      //
      
      for(IndOwner io:  indOwnerList)
      {
        if(io.consentSigned == '' || io.consentSigned == null)
        {
          atLeastOneOwnerDoesNotHaveConsentSigned=TRUE;
          break;
        }
      }
        
      for(corpOwner co:  corpOwnerList)
      {
        if(co.cOwnerInfo.consentSigned == '' || co.cOwnerInfo.consentSigned == null)
        {
          atLeastOneOwnerDoesNotHaveConsentSigned=TRUE;
          break;
        }
      }
      
      system.debug(buttonClicked+','+atLeastOneIndOwner+','+atLeastOneCorpOwner+','+atLeastOneOwnerDoesNotHaveConsentSigned+','+showNoOwnersMessage+','+showOwnerNoConsentMessage);
            
      if(buttonClicked == 'Next' && (atLeastOneIndOwner == FALSE && atLeastOneCorpOwner == FALSE))
      {
        showNoOwnersMessage = TRUE;
      }
      else if(buttonClicked == 'Next' && atLeastOneOwnerDoesNotHaveConsentSigned == TRUE)
      {
        showOwnerNoConsentMessage = TRUE;
      }
      
      if(buttonClicked == 'Next' && showNoOwnersMessage == FALSE && showOwnerNoConsentMessage ==  FALSE)
      {
        PageReference nextPage = Page.NewDealerAppDocuments;

        //if(nda.id != null)
            //nextPage.getParameters().put('Id', nda.Id);
        
        //nextPage.getParameters().put('country', ApexPages.currentPage().getParameters().get('country'));
        //nextPage.getParameters().put('prod',ApexPages.currentPage().getParameters().get('prod'));
        
        //nextPage.setRedirect(true);  
        
        if(ndaId != null && ndaId !='')
          nextPage.getParameters().put('Id', ndaId);
                          
         nextPage.getParameters().put('country',nda.country__c);
         nextPage.getParameters().put('prod',nda.primary_brand_requested__c);
         nextPage.getParameters().put('prMfr',nda.Manufacturer__r.name);
        
         if(nda.language__c == 'French Canadian')
           nextPage.getParameters().put('lang', 'fr');
         else if(nda.language__c == 'English')
           nextPage.getParameters().put('lang', 'en');  
                         
        nextPage.setRedirect(true);
        
        return nextPage;
        
      }
      else if(buttonClicked == 'SaveAndClose' && showNoOwnersMessage == FALSE && showOwnerNoConsentMessage ==  FALSE)
      {
        PageReference nextPage = Page.NewDealerAppSaved;
        
        if(nda.id != null)
            nextPage.getParameters().put('Id', nda.Id);
        
        nextPage.getParameters().put('country', ApexPages.currentPage().getParameters().get('country'));
        nextPage.getParameters().put('prod',ApexPages.currentPage().getParameters().get('prod'));
        
        nextPage.setRedirect(true);
        
        return nextPage;
      } 
      else
      {       
        return null;
      }
    }

   
    public Loc populateLoc(Loc l, Additional_location__c al)
    {  
      if(al != null)   
      { 
        l.recId = al.id;
        l.street = al.street__c;
        l.city   =  al.city__c;
        
        system.debug(al.state__c);
        
        /*
        if(nda.language__c == 'French Canadian')
        {
          l.state = EnglishToFrenchCAProvinceMap.get(al.state__c);
        }  
        else if(nda.language__c == 'English')
        {
          l.state = al.state__c;
        }
        */
        
        system.debug(l.state);
        
        l.state = al.state__c;
        l.postalcode    = al.zip__c;
      }
             
      return l;  
    }
    
    public PageReference displayLocPanels()
    {  
       try
       {
       locationsValidationMsg = '';
       pageMessage = '';
        
       List<additional_location__c> additionalLocsList = new List<additional_location__c>();
       
       additionalLocsList = [select id, name, street__c, city__c, state__c, province__c, zip__c from additional_location__c where new_dealer_application__c =: nda.id];
       
       //If the number of additional locations value is changed in the picklist        
       if(numLocsChanged == 'TRUE')
       { 
         //If selected additional location number is 0 and no saved additional location exists for the NDA
         if(displayNumLocBlocks == 0 && additionalLocsList.size() == 0) 
         {
           locsList = new List<loc>(); 
         }
         //If selected location number in the picklist is less than the number of existing, saved additional locations for this NDA, display a message asking the user to delete the desired additional location record on the screen instead. 
         else if(displayNumLocBlocks < additionalLocsList.size()) 
         {
           if((additionalLocsList.size()-displayNumLocBlocks) == 1)
             pageMessage = System.Label.please_delete + ' ' + (additionalLocsList.size()-displayNumLocBlocks) + ' ' + System.Label.location_by_clicking_link;
           else if((additionalLocsList.size()-displayNumLocBlocks) > 1)
             pageMessage = System.Label.please_delete + ' ' + (additionalLocsList.size()-displayNumLocBlocks) + ' ' + System.Label.locations_by_clicking_link;
             
             
           //Clear the locsList
           locsList = new List<Loc>();
           
           for(Integer i=0; i<additionalLocsList.size(); i++)
           {
             Loc l = new Loc();
             l.messages = new List<string>();
           
             l.num = String.valueof(i+1);
                          
             l = populateLoc(l,additionalLocsList[i]);  
           
             locsList.add(l);
           }
           
           displayNumLocBlocks = locsList.size();
           
           system.debug(pageMessage); 
           
           return null; 
         }
         //If saved additional location records for this NDA exist
         else if(additionalLocsList.size() > 0 && displayNumLocBlocks == additionalLocsList.size())
         {          
           //Clear the indOwnerList
           locsList.clear();
            
           for(Integer i=0; i<additionalLocsList.size(); i++)
           {
             Loc l = new Loc();
             l.messages = new List<string>();
             l.num = String.valueof(i+1);
             
             l = populateLoc(l,additionalLocsList[i]);  
           
             locsList.add(l);
           }      
         }
         //If selected location count is > number of existing, saved additional locations on the NDA then display one more location section on the screen 
         else if(displayNumLocBlocks > additionalLocsList.size()) 
         {
           locsList = new List<Loc>();
            
           //Retrieve Loc for already created additional location records   
           for(Integer i=0; i<additionalLocsList.size(); i++)
           {
             Loc l = new Loc();
             l.messages = new List<string>();             
             l.num = String.valueof(i+1);
             
             l = populateLoc(l,additionalLocsList[i]);  
           
             locsList.add(l);
           }
           
           //Create additional blank Loc records
           for(Integer i=additionalLocsList.size(); i<displayNumLocBlocks; i++)
           {
             Loc l = new Loc();
             l.messages = new List<string>();
           
             l.num = String.valueof(i+1);
             
             l = populateLoc(l,null);  
           
             locsList.add(l);
           }
         }
         
       }
       //If the number of additional locations picklist value has not changed, then simply obtain the saved additional locations records for this NDA and display them on the screen 
       else
       {
         //Clear the additionalLocsList
         locsList = new List<loc>();
         
         displayNumLocBlocks = additionalLocsList.size();
                    
         for(Integer i=0; i<additionalLocsList.size(); i++)
         {
           Loc l = new Loc();
           l.messages = new List<string>();           
           l.num = String.valueof(i+1);
                       
           l = populateLoc(l, additionalLocsList[i]); 
           
           system.debug(l); 
           
           locsList.add(l); 
         }          
        }
       }
       catch(Exception e)
       {
         pageMessage = System.Label.Something_Went_Wrong;  
       }
       
       return null;
    }
    
    public Ref populateRef(Ref r, Bank__c b)
    {  
      if(b != null)   
      { 
        r.recId         = b.id;
        r.acctType      = b.Type__c;
        r.bankName      = b.Name;
        r.phoneNumber   = b.Phone__c;
        
        /*
        if(nda.country__c == 'United States')
        {
          r.avgBalance = formatCurrency(b.Average_Balance__c, true);
          r.creditAmt  = formatCurrency(b.Credit_Amount__c, true);
        }
        else if(nda.country__c == 'Canada' && nda.language__c == 'French Canadian')
        {
          r.avgBalance = formatCurrency(String.valueof(b.Average_Balance__c), false, true);
          r.creditAmt = formatCurrency(String.valueof(b.Credit_Amount__c), false, true);
        }
        */
        
        r.avgBalance = String.valueof(b.Average_Balance__c);
        r.creditAmt  = String.valueof(b.Credit_Amount__c);
      }
             
      return r;  
    }
    
    public PageReference displayRefPanels()
    {  
       try
       {
       referencesValidationMsg = '';
       pageMessage = '';
        
       List<Bank__c> banksList = new List<Bank__c>();
       
       banksList = [select id, type__c, name, phone__c, credit_amount__c, average_balance__c from Bank__c where new_dealer_application__c =: nda.id];
       
       //If the number of References value is changed in the picklist        
       if(numRefsChanged == 'TRUE')
       { 
         //If selected References number is 0 and no saved References exists for the NDA
         if(displayNumRefBlocks == 0 && banksList.size() == 0) 
         {
           refsList = new List<Ref>(); 
         }
         //If selected reference number in the picklist is less than the number of existing, saved references for this NDA, display a message asking the user to delete the desired reference record on the screen instead. 
         else if(displayNumRefBlocks < banksList.size()) 
         {
           if((banksList.size()-displayNumRefBlocks) == 1)
             pageMessage = System.Label.please_delete + ' ' + (banksList.size()-displayNumRefBlocks)+ ' ' + System.Label.reference_by_clicking_link;
           else if((banksList.size()-displayNumRefBlocks) > 1)
             pageMessage = System.Label.please_delete + ' ' + (banksList.size()-displayNumRefBlocks)+ ' ' + System.Label.references_by_clicking_link;
             
           //Clear the refsList
           refsList.clear();
           
           for(Integer i=0; i<banksList.size(); i++)
           {
             Ref r = new Ref(); 
             r.messages = new List<string>();
             r.num = String.valueof(i+1);
                          
             r = populateRef(r,banksList[i]);  
             refsList.add(r);
           }
           
           displayNumRefBlocks = refsList.size();
           
           system.debug(pageMessage); 
           
           return null; 
         }
         //If saved reference records for this NDA exist
         else if(banksList.size() > 0 && displayNumRefBlocks == banksList.size())
         {          
           //Clear the refsList
           refsList = new List<Ref>();
            
           for(Integer i=0; i<banksList.size(); i++)
           {
             Ref r = new Ref();
             r.messages = new List<string>();
             r.num = String.valueof(i+1);
             
             r = populateRef(r,banksList[i]);  
             refsList.add(r);
           }      
         }
         //If selected reference count is > number of existing, saved reference on the NDA then display one more location section on the screen 
         else if(displayNumRefBlocks > banksList.size()) 
         {
           refsList = new List<ref>();
            
           //Retrieve ref for already created reference records   
           for(Integer i=0; i<banksList.size(); i++)
           {
             Ref r = new Ref();
             r.messages = new List<string>();             
             r.num = String.valueof(i+1);
             
             r = populateRef(r,banksList[i]);    
           
             refsList.add(r);
           }
           
           //Create blank Ref records
           for(Integer i=banksList.size(); i<displayNumRefBlocks; i++)
           {
             Ref r = new Ref();
             r.messages = new List<string>();
             r.num = String.valueof(i+1);
             r = populateRef(r,null);  
             refsList.add(r);
           }
         }
       }
       //If the number of refs picklist value has not changed, then simply obtain the saved owner and associated records for this NDA and display them on the screen 
       else
       {
         //Clear the refList
         refsList = new List<Ref>();
         
         displayNumRefBlocks = banksList.size();
                    
         for(Integer i=0; i<banksList.size(); i++)
         {
           Ref r = new Ref();
           r.messages = new List<string>();           
           r.num = String.valueof(i+1);         
           r = populateRef(r, banksList[i]); 
           refsList.add(r); 
         }      
       }
       }
       catch(Exception e)
       {
         pageMessage = System.Label.Something_Went_Wrong;
       }
       
       return null;
    }

    public PageReference displayIndOwnerPanels()
    {  
       try
       {
       showNoOwnersMessage=FALSE;
       pageMessage = '';
        
       //Check to see if saved owner and association records exist for this NDA 
       List<id>  accountIdsList = new List<id>(); 
       List<Product_Information_For_New_Dealer_App__c> productsList = new List<Product_Information_For_New_Dealer_App__c>();
        
       productsList = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c
                                                                            where New_Dealer_Application2__c = : ndaId];
                                                                            
       for(Product_Information_For_New_Dealer_App__c prodJunc: productsList)
       {
         accountIdsList.add(prodJunc.relationship__c);  
       }                                                                     
        
       List<account> ndaAccounts = [select id from account where id in :accountIdsList];
       
       List<id> indOwnerAccounts = new List<id>();
             
       List<associated_relationships__c>  indOwnerAssociations = [select id, primary_relationship__c, primary_relationship__r.name, title__c, ownership_percentage__c, secondary_relationship__c from associated_relationships__c where primary_relationship__c in: ndaAccounts and type__c = 'Individual'];
       
       for(Associated_relationships__c ia: indOwnerAssociations)
       {
         indOwnerAccounts.add(ia.secondary_relationship__c); 
       }         
     
       List<owner__c> ndaIndOwners = [select id, date_of_signature__c, relationship__c, relationship__r.recordtypeid, relationship__r.Primary_ID_Number__c, relationship__r.Government_ID_Expiration_Date__c, relationship__r.BillingStreet, relationship__r.BillingCity, relationship__r.BillingCountryCode, relationship__r.BillingState,  relationship__r.BillingStateCode, relationship__r.BillingPostalCode, relationship__r.Suffix__c, relationship__r.First_Name__c, relationship__r.Last_Name__c, relationship__r.Middle_I__c, relationship__r.Name, relationship__r.phone, relationship__r.Guarantor_Email__c, relationship__r.date_of_birth__c, relationship__r.social_security_number__c from Owner__c where New_Dealer_Application__c =: nda.id and relationship__c in : indOwnerAccounts];
  
       //Create a map of ownerrecordid to association record
       Map<id, Associated_relationships__c> ownerIdToAssociationRecMap = new Map<id, Associated_relationships__c>();
     
       for(Associated_relationships__c ia: indOwnerAssociations)
       {
         for(Owner__c ow: ndaIndOwners)
         {
           if(ia.secondary_relationship__c == ow.relationship__c && ia.primary_relationship__r.name == nda.legal_business_name__c)
             ownerIdToAssociationRecMap.put(ow.id, ia);  
         }  
       }
              
       //If the number of Individual owners value is changed in the picklist        
       if(numIndOwnersChanged == 'TRUE')
       { 
         system.debug(displayNumIndOwnerBlocks+','+ndaIndOwners.size());
         
         //If selected owner number is 0 and no saved individual owners exists for the NDA
         if(displayNumIndOwnerBlocks == 0 && ndaIndOwners.size() == 0) 
         {
           indOwnerList.clear(); 
         }
         //If selected owner number in the picklist is less than the number of existing, saved owners for this NDA, display a message asking the user to delete the desired owner record on the screen instead. 
         else if(displayNumIndOwnerBlocks < ndaIndOwners.size()) 
         {
           pageMessage = System.Label.please_delete + ' ' + (ndaIndOwners.size()-displayNumIndOwnerBlocks) + ' ' + System.Label.individual_owners_by_clicking_link;
           
           //Clear the indOwnerList
           indOwnerList.clear();
           
           for(Integer i=0; i<ndaIndOwners.size(); i++)
           {
             indOwner indOwner = new indOwner();
             indOwner.messages = new List<string>();
           
             indOwner.num = String.valueof(i+1);
             indOwner.collapsed=FALSE;
             
             indOwner = populateIndOwner(indOwner,ndaIndOwners[i], ownerIdToAssociationRecMap.get(ndaIndOwners[i].id));  
           
             indOwnerList.add(indOwner);
           }
           
           displayNumIndOwnerBlocks = indOwnerList.size();
                      
           return null; 
         }
         //If saved owners and association records for this NDA exist
         else if(ndaIndOwners.size() > 0 && displayNumIndOwnerBlocks == ndaIndOwners.size())
         {          
           //Clear the indOwnerList
           indOwnerList.clear();
            
           for(Integer i=0; i<ndaIndOwners.size(); i++)
           {
             indOwner indOwner = new indOwner();
             indOwner.messages = new List<string>();
           
             indOwner.num = String.valueof(i+1);
             indOwner.collapsed=FALSE;
             
             indOwner = populateIndOwner(indOwner,ndaIndOwners[i], ownerIdToAssociationRecMap.get(ndaIndOwners[i].id));  
           
             indOwnerList.add(indOwner);
           }
                                 
         }
         //If selected owner count is > number of existing, saved owners on the NDA then display one more individual owner section on the screen 
         else if(displayNumIndOwnerBlocks > ndaIndOwners.size()) 
         {
            //Clear the indOwnerList
            indOwnerList.clear();
            
           //Retrieve ownerinfo for already created owner records   
           for(Integer i=0; i<ndaIndOwners.size(); i++)
           {
             indOwner indOwner = new indOwner();
             indOwner.messages = new List<string>();             
           
             indOwner.num = String.valueof(i+1);
             
             system.debug(indOwner);
             system.debug(ndaIndOwners[i]);
             system.debug(ownerIdToAssociationRecMap);
             
             indOwner.collapsed=FALSE;
             indOwner = populateIndOwner(indOwner,ndaIndOwners[i], ownerIdToAssociationRecMap.get(ndaIndOwners[i].id));  
           
             indOwnerList.add(indOwner);
           }
           
           //Create additional blank ownerinfo records
           for(Integer i=ndaIndOwners.size(); i<displayNumIndOwnerBlocks; i++)
           {
             indOwner indOwner = new indOwner();
             indOwner.messages = new List<string>();
           
             indOwner.num = String.valueof(i+1);
             indOwner.collapsed=FALSE;
             
             indOwner = populateIndOwner(indOwner,null, null);  
           
             indOwnerList.add(indOwner);
           }
         }
         
       }
       //If the number of individual owners picklist value has not changed, then simply obtain the saved owner and associated records for this NDa and display them on the screen 
       else
       {
         //Clear the indOwnerList
         indOwnerList.clear();
         
         displayNumIndOwnerBlocks = ndaIndOwners.size();
                    
         for(Integer i=0; i<ndaIndOwners.size(); i++)
         {
           indOwner indOwner = new indOwner();
           indOwner.messages = new List<string>();           
           
           indOwner.num = String.valueof(i+1);
           indOwner.collapsed=FALSE;
                       
           indOwner = populateIndOwner(indOwner, ndaIndOwners[i], ownerIdToAssociationRecMap.get(ndaIndOwners[i].id));  
           
           indOwnerList.add(indOwner); 
         }
                  
       }
       }
       catch(Exception e)
       {
         pageMessage = System.Label.Something_Went_Wrong;        
       }
       
       return null;
    }
 
 
    //Remove this later
    public PageReference LandingPageNext()
    {
      return null;
    }
    //

    public PageReference displayCorpOwnerPanels()
    {  
       try
       {
       showNoOwnersMessage=FALSE;
       pageMessage = '';
       
       //Check to see if saved owner and association records exist for this NDA 
       List<Product_Information_For_New_Dealer_App__c> productsList = new List<Product_Information_For_New_Dealer_App__c>();
        
       productsList = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c
                                                                            where New_Dealer_Application2__c = : ndaId];

       List<id>  accountIdsList = new List<id>(); 
                                                                            
       for(Product_Information_For_New_Dealer_App__c prodJunc: productsList)
       {
         accountIdsList.add(prodJunc.relationship__c);  
       }
        
       List<account> ndaAccounts = [select id from account where id in :accountIdsList];
       
       List<id> CorpOwnerAccounts = new List<id>();
             
       List<associated_relationships__c>  corpOwnerAssociations = [select id, primary_relationship__c, primary_relationship__r.name, secondary_relationship__c, title__c, ownership_percentage__c from associated_relationships__c where primary_relationship__c in: ndaAccounts and type__c = 'Entity'];
       system.debug(CorpOwnerAssociations);
       
       for(Associated_relationships__c ia: corpOwnerAssociations)
       {
         corpOwnerAccounts.add(ia.secondary_relationship__c); 
       }         
     
       List<owner__c> ndaCorpOwners = [select id, date_of_signature__c, relationship__c, relationship__r.recordtypeid, relationship__r.Tax_Identification_Number__c, relationship__r.Name_of_Authorized_Signer__c, relationship__r.BillingStreet, relationship__r.BillingCity, relationship__r.BillingCountryCode, relationship__r.BillingState, relationship__r.BillingStateCode, relationship__r.State_of_Incorporation__c, relationship__r.BillingPostalCode, relationship__r.Suffix__c, relationship__r.First_Name__c, relationship__r.Last_Name__c, relationship__r.Middle_I__c, relationship__r.Name, relationship__r.phone, relationship__r.Guarantor_Email__c, relationship__r.date_of_birth__c, relationship__r.social_security_number__c from Owner__c where New_Dealer_Application__c =: nda.id and relationship__c in : CorpOwnerAccounts];
     
       //Create a map of ownerrecordid to association record
       Map<id, Associated_relationships__c> ownerIdToAssociationRecMap = new Map<id, Associated_relationships__c>();
     
       for(Associated_relationships__c ia: corpOwnerAssociations)
       {
         for(Owner__c ow: ndaCorpOwners)
         {
           if(ia.secondary_relationship__c == ow.relationship__c && ia.primary_relationship__r.name == nda.legal_business_name__c)
             ownerIdToAssociationRecMap.put(ow.id, ia);  
         }  
       }
     
       //Clear the CorpOwnerList
       corpOwnerList.clear();
            
       if(numCorpOwnersChanged == 'TRUE')
       {
         numCorpOwnersChanged = 'FALSE'; 
        
         //If selected owner number is 0 and no saved individual owners exists for the NDA
         if(displayNumCorpOwnerBlocks == 0 && ndaCorpOwners.size() == 0) 
         {
           CorpOwnerList.clear(); 
         }
         //If selected corp owner number in the picklist is less than the number of existing, saved owners for this NDA, display a message asking the user to delete the desired owner record on the screen instead. 
         else if(displayNumCorpOwnerBlocks < ndaCorpOwners.size()) 
         {           
           pageMessage = System.Label.please_delete + ' ' + (ndaCorpOwners.size()-displayNumCorpOwnerBlocks)+ ' ' + System.Label.entity_owners_by_clicking_on_link;
           
           //Clear the indOwnerList
           CorpOwnerList.clear();
           
           for(Integer i=0; i<ndaCorpOwners.size(); i++)
           {
             CorpOwner cOwner = new CorpOwner();
             cOwner.cOwnerInfo = new CorpOwnerInfo();
             cOwner.cOwnerInfo.messages = new List<string>(); 
           
             cOwner.indEntityOwnersList = new List<indOwner>();
             cOwner.corpEntityOwnersList = new List<corpOwnerInfo>();
         
             cOwner.cOwnerInfo.num = String.valueof(i+1);
             cOwner.cOwnerInfo.collapsed=FALSE;
             
             cOwner = populateCorpOwner(cOwner, ndaCorpOwners[i], ownerIdToAssociationRecMap.get(ndaCorpOwners[i].id));
            
             corpOwnerList.add(cOwner);
           }

           displayNumCorpOwnerBlocks = corpOwnerList.size();
                      
           return null; 
         }
         //If selected number of corp owners is greater than saved corp owners for this NDA
         else if(ndaCorpOwners.size() > 0 && displayNumCorpOwnerBlocks == ndaCorpOwners.size())
         {          
           for(Integer i=0; i<ndaCorpOwners.size(); i++)
           {
             CorpOwner cOwner = new CorpOwner();
             cOwner.cOwnerInfo = new CorpOwnerInfo();
             cOwner.cOwnerInfo.messages = new List<string>();             
             cOwner.indEntityOwnersList = new List<indOwner>();
             cOwner.corpEntityOwnersList = new List<corpOwnerInfo>();
         
             cOwner.cOwnerInfo.num = String.valueof(i+1);
             cOwner.cOwnerInfo.collapsed=FALSE;

             cOwner = populateCorpOwner(cOwner, ndaCorpOwners[i], ownerIdToAssociationRecMap.get(ndaCorpOwners[i].id));
            
             CorpOwnerList.add(cOwner);
           }
         }
         else if(displayNumCorpOwnerBlocks > ndaCorpOwners.size()) 
         {          
           //Retrieve ownerinfo for already created owner records   
           for(Integer i=0; i<ndaCorpOwners.size(); i++)
           {
             CorpOwner cOwner = new CorpOwner();
             cOwner.cOwnerInfo = new CorpOwnerInfo();
             cOwner.cOwnerInfo.messages = new List<string>();
             cOwner.indEntityOwnersList = new List<indOwner>();
             cOwner.corpEntityOwnersList = new List<corpOwnerInfo>();
           
             cOwner.cOwnerInfo.num = String.valueof(i+1);
             cOwner.cOwnerInfo.collapsed=FALSE;
             
             cOwner = populateCorpOwner(cOwner, ndaCorpOwners[i], ownerIdToAssociationRecMap.get(ndaCorpOwners[i].id));
            
             CorpOwnerList.add(cOwner);
           }
           
           //Create additional blank ownerinfo records
           for(Integer i=ndaCorpOwners.size(); i<displayNumCorpOwnerBlocks; i++)
           {
             CorpOwner cOwner = new CorpOwner();
             cOwner.cOwnerInfo = new CorpOwnerInfo();
             cOwner.cOwnerInfo.messages = new List<string>();
             cOwner.indEntityOwnersList = new List<indOwner>();
             cOwner.corpEntityOwnersList = new List<corpOwnerInfo>();
                                     
             cOwner.cOwnerInfo.num = String.valueof(i+1);
             cOwner.cOwnerInfo.collapsed=FALSE;
             
             cOwner = populateCorpOwner(cOwner, null, null);
            
             CorpOwnerList.add(cOwner);
           }
         }
       }
       else
       {
         displayNumCorpOwnerBlocks = ndaCorpOwners.size();
                    
         for(Integer i=0; i<ndaCorpOwners.size(); i++)
         {
           CorpOwner cOwner = new CorpOwner();
           cOwner.cOwnerInfo = new CorpOwnerInfo();
           cOwner.cOwnerInfo.messages = new List<string>();           
           cOwner.indEntityOwnersList = new List<indOwner>();
           cOwner.corpEntityOwnersList = new List<corpOwnerInfo>();
           
           cOwner.cOwnerInfo.num = String.valueof(i+1);
           cOwner.cOwnerInfo.collapsed=FALSE;
                      
           cOwner = populateCorpOwner(cOwner, ndaCorpOwners[i], ownerIdToAssociationRecMap.get(ndaCorpOwners[i].id));
            
           corpOwnerList.add(cOwner);  
         }
       }
       }
       catch(Exception e)
       {
         pageMessage = System.Label.Something_Went_Wrong;         
       }
              
       return null;
    }

    public List<SelectOption> getStates()
    {
      List<SelectOption> options = new List<SelectOption>();
      
      if(nda.language__c == 'French Canadian')
        options.add(new SelectOption('','--Aucun--'));
      else if(nda.language__c == 'English')
        options.add(new SelectOption('', '--None--'));  
      
      Id nId = ApexPages.currentPage().getParameters().get('Id');
        
      New_Dealer_Application__c n = [select country__c from New_Dealer_Application__c where id=:nId];
        
      string ndaCountryCode;
        
      if(n.country__c == 'United States')
        ndaCountryCode = 'US';
      else if(n.country__c == 'Canada')
        ndaCountryCode = 'CA';
      else if(AU_NZ_Support && n.country__c == 'Australia')
        ndaCountryCode = 'AU';
      else if(AU_NZ_Support && n.country__c == 'New Zealand')
        ndaCountryCode = 'NZ';
     
      Map<string, string> stCodeToNameMap = new Map<string, string>();
      stCodeToNameMap = UtilityClass.createStateCodeToStateNameMap(ndaCountryCode);
        
      for(string stateCode: stCodeToNameMap.keyset())
      {
        if(!string.isBlank(stateCode))
        {
          if(nda.language__c == 'French Canadian')
          {
            //options.add(new SelectOption(stCodeToNameMap.get(stateCode),EnglishToFrenchCAProvinceMap.get(stCodeToNameMap.get(stateCode))));
            options.add(new SelectOption(EnglishToFrenchCAProvinceMap.get(stCodeToNameMap.get(stateCode)),EnglishToFrenchCAProvinceMap.get(stCodeToNameMap.get(stateCode))));
            
          }
          else if(nda.language__c == 'English')
          {
            options.add(new SelectOption(stCodeToNameMap.get(stateCode),stCodeToNameMap.get(stateCode)));
          }
        }
      }
      
      return options;  
    }

    
    private Set<string> retrieveTCFProxyIPAddresses()
    {
      List<TCF_Proxy_IP_Addresses__c> TCFProxyIPAddresses = TCF_Proxy_IP_Addresses__c.getall().values();
      Set<string> ipaddressSet = new Set<string>();
      
      if(TCFProxyIPAddresses != null && TCFProxyIPAddresses.size()>0)
      {
        string[] sList = TCFProxyIPAddresses[0].name.normalizeSpace().split(',');
        
        ipaddressSet.addAll(sList); 
        
        system.debug(ipaddressSet);
      }
      
      return ipaddressSet;
    }

    public string getUserSourceIPAddress()
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

    private boolean shouldAppCreationBeBlocked()
    {
      string blockAppParam;
      boolean blockApplicationCreation=FALSE;
      
      appURL = URL.getSalesforceBaseUrl().toExternalForm();
      
      //Check to see if the app is initiated from external site address and an internal TCFIF user.  If so, block it. (WI 1490)
      isInternalApp = FALSE;
      if(appURL != null && appURL != '' && appURL.contains('visual'))
        isInternalApp = TRUE;
      
      List<Organization> orgList = [Select IsSandbox from Organization limit 1];            
      isSandBox = FALSE;
      if(orgList != null && orgList.size()>0 && orgList[0].isSandbox == TRUE) 
        isSandBox = TRUE;
      
      sourceIPAddress = getUserSourceIPAddress();

      isInternalUser = FALSE;
      if(retrieveTCFProxyIPAddresses().contains(sourceIPAddress))
        isInternalUser = TRUE;
        
      blockAppParam = ApexPages.currentPage().getParameters().get('blockapp');
      
      //Block access to external NDA site if user is signed in from TCF network.  If a sys admins wants to test the external app in a sandbox however, they should append the default external site url with ?blockapp=no 
      if( (isSandbox == FALSE && isInternalUser == TRUE && isInternalApp == FALSE))// || (isSandbox == TRUE && isInternalApp == FALSE && (blockAppParam == null || blockAppParam == '' || (blockAppParam != null && blockAppParam != '' && !blockAppParam.equalsignorecase('no'))) ) )
      {
        blockApplicationCreation = TRUE;
      } 
      
     // santosh replaced na54.visual.force with visualforce as part of critical update WI 2926
      //internalAppNewURL = 'https://inventoryengine--c.na54.visual.force.com/apex/NewDealerAppMain';  
      internalAppNewURL = 'https://inventoryengine--c.visualforce.com/apex/NewDealerAppMain';
      
      System.debug('=== internalAppNewURL  ===='+internalAppNewURL );
      return blockApplicationCreation;
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
    
    public void SetVersionTypes(Boolean newApp)
    {    
      if(nda.country__c== 'Canada')
      {
        TCFCFVersion = true;
        headerValue = System.Label.NDA_Main_Header_Canada;
        colorscheme = 'default';
      }
      else if(AU_NZ_Support && nda.Country__c == 'Australia')
      {
        TCFAUVersion = true;  
        headerValue = System.Label.NDA_Main_Header;
        colorscheme = 'default';  
      }
      else if(AU_NZ_Support && nda.Country__c == 'New Zealand')
      {
        TCFNZVersion = true;  
        headerValue = System.Label.NDA_Main_Header;
        colorscheme = 'default';  
      }
      else if(nda.Country__c == 'United States' && nda.primary_brand_requested__c == 'Bombardier Recreational Products')
      { 
        BRPVersion = true;  
        headerValue = System.Label.NDA_Main_Header_BRP;
        colorscheme = 'BRP';                     
      }
      else if(nda.Country__c == 'United States' && nda.primary_brand_requested__c.startsWith('Toro') && nda.country__c == 'United States')
      {
        RIAVersion = true;
        headerValue = System.Label.NDA_Main_Header_RIA;
        colorscheme = 'RIA';
      }
      else if(nda.Country__c == 'United States' && nda.primary_brand_requested__c == 'General' && (primaryManufacturer == 'MTD' || primaryManufacturer == 'Cub Cadet'))
      {
        MTDVersion = true;
        headerValue = System.Label.NDA_Main_Header_MTD;
        colorscheme = 'MTD';                                                                     
      }
      else if(!string.isBlank(nda.country__c) && !string.isBlank(nda.primary_brand_requested__c))
      {
        GeneralVersion = true;  
        headerValue = System.Label.NDA_Main_Header;
        colorscheme = 'default';                                                                             
      } 
    }
    
    // Manufacturer List 
    public void retrieveAllManufacturers()
    {    
      if(AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c == 'New Zealand'))
      {
        if(nda.Primary_Brand_Requested__c != null && nda.Primary_Brand_Requested__c.startsWith('Toro'))
          ManufactList = [select Id, Name, primary_manufacturer__r.name, Industry__c from Manufacturer__c where (name = 'Toro' or primary_manufacturer__r.name = 'Toro') and active__c = true order BY Name];
        else if(nda.Primary_Brand_Requested__c != null && nda.Primary_Brand_Requested__c == 'Bombardier Recreational Products')
          ManufactList = [select Id, Name, primary_manufacturer__r.name, Industry__c from Manufacturer__c where (name = 'Bombardier Recreational Products (BRP)' or primary_manufacturer__r.name = 'Bombardier Recreational Products (BRP)') and active__c = true order BY Name];     
      }
      else if(nda.Primary_Brand_Requested__c != null && nda.Primary_Brand_Requested__c == 'Bombardier Recreational Products')
      {
        ManufactList = [select Id, Name, primary_manufacturer__r.name, Industry__c from Manufacturer__c where (name like 'Bombardier Recreational Products (BRP)' or primary_manufacturer__r.name like 'Bombardier Recreational Products (BRP)') and active__c = true order BY Name]; 
      }
      else if(nda != null && nda.Primary_Brand_Requested__c != null && nda.Primary_Brand_Requested__c.startsWith('Toro'))
      { 
        ManufactList = [select Id, Name, primary_manufacturer__r.name, Industry__c from Manufacturer__c where (name = 'Toro' or primary_manufacturer__r.name = 'Toro') and active__c = true order BY Name];          
      }
      else if(nda != null && nda.Primary_Brand_Requested__c != null && nda.Primary_Brand_Requested__c == 'General' && product == 'MTD')
      {
        ManufactList = [select Id, Name, primary_manufacturer__r.name, Industry__c from Manufacturer__c where (name = 'MTD' or primary_manufacturer__r.name = 'MTD') and active__c = true order BY Name];          
      }
      else if(nda != null && nda.Primary_Brand_Requested__c != null && nda.Primary_Brand_Requested__c == 'General')
      {
        ManufactList = [select Id, Name, primary_manufacturer__r.name, Industry__c from Manufacturer__c where active__c = true order BY Name];   
      }
    } 
     
    // Owner Details
    public List<Account> setOwnerInfoSection(){ 
        
        ownerSignaturesList = new List<OwnerSignatureDate>();
        
        if(nda.Nr_of_Owners__c != null && nda.Nr_of_Owners__c > 0)
        {
          //Modified by Nimish
          List<Owner__c> owners = [select Date_of_signature__c, Relationship__c, Relationship__r.Name, Relationship__r.Name_of_Authorized_Signer__c, Relationship__r.Middle_I__c, Relationship__r.Last_Name__c, Relationship__r.Primary_ID_Number__c, Relationship__r.Government_ID_Expiration_Date__c, New_Dealer_Application__c, First_Name__c, Middle_Initial__c, Last_Name__c, Name_of_authorized_signer__c 
                                   from Owner__c
                                   where New_Dealer_Application__c = : nda.Id];
          //
          
          //Santosh - added fro WI 2278  
          Set<id> primaryRelIds = new Set<Id>();
          
          for(Product_Information_For_New_Dealer_App__c p:[select id, Relationship__c from Product_Information_For_New_Dealer_App__c where New_Dealer_Application2__c=:ndaId])
          {
            primaryRelIds.add(p.Relationship__c);
          }     
          //-end
                            
          if(!owners.isempty())
          {
            //Added by Nimish
            showOwnerConsent = TRUE;
            //
                
            Set<Id> resultIds = new Set<Id>();
            
            for(Owner__c o : owners)
            {
                  resultIds.add(o.Relationship__c);
                  //Added by Nimish
                  OwnerSignatureDate ows = new OwnerSignatureDate();

                  if(o.Relationship__r.Name_of_Authorized_Signer__c != null && o.Relationship__r.Name_of_Authorized_Signer__c != '')
                  {
                     ows.ownerName = o.Relationship__r.Name_of_authorized_signer__c;
                  }
                  else
                  {
                    ows.ownerName = o.Relationship__r.Name;
                  }
                    
                  //Added by Nimish  
                  if(nda.language__c == 'English' && nda.Country__c == 'United States' && o.Date_of_signature__c != null)
                    ows.signatureDate = getMonthNameFromNumber(o.Date_of_signature__c.month(), 'US_EN') + ' ' + o.Date_of_signature__c.day() + ', ' + o.Date_of_signature__c.year();
                  else if(nda.language__c == 'French Canadian' && nda.Country__c == 'Canada' && o.Date_of_signature__c != null)
                    ows.signatureDate = getMonthNameFromNumber(o.Date_of_signature__c.month(), 'CA_FR') + ' ' + o.Date_of_signature__c.day() + ', ' + o.Date_of_signature__c.year();
                  else if(nda.language__c == 'English' && nda.Country__c == 'Canada' && o.Date_of_signature__c != null)
                    ows.signatureDate = getMonthNameFromNumber(o.Date_of_signature__c.month(), 'CA_EN') + ' ' + o.Date_of_signature__c.day() + ', ' + o.Date_of_signature__c.year();
                  else if(AU_NZ_Support && nda.language__c == 'English' && nda.Country__c == 'Australia' && o.Date_of_signature__c != null)
                    ows.signatureDate = getMonthNameFromNumber(o.Date_of_signature__c.month(), 'AU_EN') + ' ' + o.Date_of_signature__c.day() + ', ' + o.Date_of_signature__c.year();
                  else if(AU_NZ_Support && nda.language__c == 'English' && nda.Country__c == 'New Zealand' && o.Date_of_signature__c != null)
                      ows.signatureDate = getMonthNameFromNumber(o.Date_of_signature__c.month(), 'NZ_EN') + ' ' + o.Date_of_signature__c.day() + ', ' + o.Date_of_signature__c.year();
                    
                    ownerSignaturesList.add(ows);                     
                    //
             }
             
             List<Account>  OList = [select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, Tax_Identification_Number__c, State_of_Incorporation__c, First_Name__c, 
                                     Middle_I__c, Last_Name__c, Phone, Guarantor_Email__c, Date_of_Birth__c, Social_Security_Number__c, Suffix__c, Primary_ID_Number__c, Government_ID_Expiration_Date__c, createdDate
                                     from Account
                                     where Id  in :resultIds
                                     order by createdDate desc];
                
              //Modified by Nimish to accomodate association records of the same owner being created for each prospect dealer record instead of single set of association records previously 
              List<Associated_Relationships__c> tempAssociationList = new List<Associated_Relationships__c>();
              Set <Id> AssociationSecondaryIdsSet = new Set<Id>(); 
                
              //added AND primary_Relationship__c IN: primaryRelIds condition
              tempAssociationList = [select Id, Primary_Relationship__r.Name, Association_Type__c, Ownership_Percentage__c, Secondary_Relationship__c, Title__c, Type__c,createdDate,   
                                            Secondary_Relationship__r.Name, Secondary_Relationship__r.BillingStreet, Secondary_Relationship__r.BillingCity, 
                                            Secondary_Relationship__r.BillingState, Secondary_Relationship__r.BillingPostalCode, Secondary_Relationship__r.BillingStateCode, Secondary_Relationship__r.BillingCountryCode,
                                            Secondary_Relationship__r.Tax_Identification_Number__c, Secondary_Relationship__r.State_of_Incorporation__c, Secondary_Relationship__r.First_Name__c, 
                                            Secondary_Relationship__r.Middle_I__c, Secondary_Relationship__r.Last_Name__c, Secondary_Relationship__r.Phone, Secondary_Relationship__r.Guarantor_Email__c, 
                                            Secondary_Relationship__r.Date_of_Birth__c, Secondary_Relationship__r.Primary_ID_Number__c, Secondary_Relationship__r.Government_ID_Expiration_Date__c, 
                                            Secondary_Relationship__r.Social_Security_Number__c, Secondary_Relationship__r.Suffix__c, Secondary_Relationship__r.createdDate,
                                            Secondary_Relationship__r.Name_of_Authorized_Signer__c, Secondary_Relationship__r.Title_of_Authorized_Signer__c                                           
                                            from Associated_Relationships__c
                                            where Secondary_Relationship__c in :resultIds   AND primary_Relationship__c IN: primaryRelIds
                                            order by createdDate desc];
                           
              for(Associated_Relationships__c ar: tempAssociationList)
              {
                  if(!AssociationSecondaryIdsSet.contains(ar.Secondary_Relationship__c))
                  {
                    AssociationList.add(ar);
                    AssociationSecondaryIdsSet.add(ar.Secondary_Relationship__c);
                  }
              }                              
              //
                                             
              OwnerAssocMap = new Map<Id,list<String>>();                                                                 
              return  OList; 
           }                                              
        } 
        return  null;       
    }

    //Added by Nimish
    public date PDFOwnerDateOfSignature(id associationSecondaryRelationshipRecordId, id ndaRecordId) 
    {
      List<Owner__c> ownerList = [select id, date_of_signature__c from Owner__c where new_dealer_application__c = : ndaRecordId and relationship__c = :associationSecondaryRelationshipRecordId];

      if(ownerList != null && ownerList.size()>0)
      {
        return ownerList[0].date_of_signature__c;
      }
      else 
        return null;
    } 


    public boolean displayProdsToAddTable {get;set;}

    public pagereference displayProductsToAdd()
    {
      selectedIndustry='';
      selectedManufacturer=null;
      selectedObtainedFrom='';
      selectedObtainedFromName='';
      
      displayProdsToAddTable = true;
      
      return null;
    }


    // Product Details
    public list<Product_Information_For_New_Dealer_App__c> PrepareProductsList()
    {
      List<Product_Information_For_New_Dealer_App__c>  ProdList; 
      
      
      ProdList = [select Id, Name, New_Dealer_Application2__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                   from Product_Information_For_New_Dealer_App__c
                                                                   where New_Dealer_Application2__c = : nda.Id and Manufacturer__c != null];
                                                                
      return  ProdList;
    }


    public void QueryProducts(){          
          ProductsList = PrepareProductsList();
    }   
    
    public void EditProd()
    {
      editProduct = true;
    }
    
    public void saveProd()
    {
      editProduct = false;
      
      system.debug(productIdToEditSaveOrDelete);
      
      Product_Information_For_New_Dealer_App__c p = [select Id, Name, New_Dealer_Application2__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                     from Product_Information_For_New_Dealer_App__c where id=:productIdToEditSaveOrDelete limit 1];                                               
      
      system.debug(prodObfToSave+','+prodObfNameToSave);
      
      p.obtained_from__c = prodObfToSave;
      p.obtained_from_name__c = prodObfNameToSave;
      
      update p;                                                   
    }


    public PageReference DeleteProd()
    {
      try
      { 
        pageMessage = '';
        Product_Information_For_New_Dealer_App__c p = new Product_Information_For_New_Dealer_App__c(Id=productIdToEditSaveOrDelete);
        
        //WI 0672 - Added by Nimish so that if the user tries to delete the product through NDA VF page
        //and only one product record exists on the NDA then instead of deleting the product record, it will retain it and just update the manufacturer field to blank instead of deleting the record. 
        if(ProductsList.size()>1)
        {
          //Added by Nimish
          DeleteProspectDealerRecordIfNeeded(p.id);
          //
          delete p;
        }
        else if(ProductsList.size() == 1)
        {
          p.manufacturer__c = null;
          p.Primary_Manufacturer__c = null;
          p.Obtained_From__c = '';
          p.Obtained_From_Name__c = '';
          update p;
          
          DeleteProspectDealerRecordIfNeeded(p.id);
        }
        
        ProductsList = PrepareProductsList(); 
        
        selectedIndustry='';
        selectedManufacturer=null;
        selectedObtainedFrom='';
        selectedObtainedFromName='';
       
        if(mfrOptions != null)
          mfrOptions.clear();
       
        if(obtainedFromOptions != null)
          obtainedFromOptions.clear();
       
        if(obtainedFromNameOptions != null)
          obtainedFromNameOptions.clear();
        
        displayProdsToAddTable=false;
        
        return null;
      }
      catch(Exception excp)
      {
        UtilityClass.logError(excp,'NDA', ndaId, 'Product Junction Rec. Id: '+productIdToEditSaveOrDelete); 
        showErrorMessage = true;
         
        pageMessage = System.Label.Something_Went_Wrong;                
      }
      
      return null;
       
    }

    //Added by Nimish
    //Delete prospect record if this product record is tied to a non-exclusive manufacturer and no other non-exclusive mfg exists in the product list for this NDA
    //Or if prospect record is tied to a product record that is tied to an exclusive manufacturer and no other product record for the same manufacturer / its sub manufacturer (e.g. Toro BossSnow, Toro) exists     
    public void DeleteProspectDealerRecordIfNeeded(Id currentProductId)
    {
       Account deleteAcct;
       pageMessage = '';
        
       try
       {
         Product_Information_For_New_Dealer_App__c currentProduct = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c where id =: currentProductId][0];
         //Santosh -added for WI 3033.                                                                   
         if(currentProduct!=null && !String.isBlank(currentProduct.New_Dealer_Application2__c) && !String.isBlank(currentProduct.relationship__c))
         {
         New_Dealer_Application__c n = [select id from New_Dealer_Application__c where id = :currentProduct.New_Dealer_Application2__c][0];
    
         List<Product_Information_For_New_Dealer_App__c> productsList = new List<Product_Information_For_New_Dealer_App__c>();
        
         productsList = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c
                                                                            where New_Dealer_Application2__c = : n.id];
            
         Boolean deleteAccount = TRUE;
         
         List<account> NDAAccounts = new List<account>();
         //Wi 3033, Account to Product_Information_For_New_Dealer_App__c direct relationship doesnt exist.
         //NDAAccounts = [select id from account where New_Dealer_Application__c = : n.id]; 
         Set<Id> accountIds = new Set<Id>();
         for(Product_Information_For_New_Dealer_App__c junc: productsList)
         {
             accountIds.add(junc.relationship__c);
         }
         NDAAccounts = [select id from account where Id IN : accountIds]; 
            
          //Only attempt to delete the prospect dealer account record if number of existing product records is > 1
          if(productsList.size()>1)
          {
            //Santosh-added for Wi 3033, Check for prospect record type.
            try
            {
                deleteAcct = [select id from account where id =: currentProduct.relationship__c AND recordTypeId=:constants.accountRTMap.get('Prospect_Dealer') limit 1];
            }
            catch(exception e)
            {
                deleteAcct = new account();
            }
            if(deleteAcct!=null && !String.isBlank(deleteAcct.id))
            {
                for(Product_Information_For_New_Dealer_App__c prd: productsList)
                {
                  if((prd.Id != currentProductId && prd.Relationship__c == deleteAcct.Id) || NDAAccounts.size() == 1)
                  {
                    deleteAccount = FALSE;
                  }
                }
              
                if(deleteAccount == TRUE)
                {
                  delete deleteAcct;
                }
            }
            /**else
            {
                showErrorMessage = true;
                pageMessage = System.Label.Something_Went_Wrong; 
            } */
          }
        
         }//end
          //
       }
       catch(Exception excp)
       {
         UtilityClass.logError(excp,'NDA', ndaId, 'Product Junction Rec. Id: '+currentProductId + ', Deletion Account Rec Id: '+deleteAcct.id);
         showErrorMessage = true;
         
         pageMessage = System.Label.Something_Went_Wrong;                
       }
    }

    public void DeleteAdditionalLocation()
    {
      pageMessage = ''; 
        
      try
      {   
        integer i = 0;
        integer locListIndexToRemove;
         
        for(Loc l: locsList)
        {
          if(l.num == locationNumToDelete)
          {
            locListIndexToRemove = i;
            
            if(l.recId != null)
            {
              delete [select id from additional_location__c where id=:l.recId];
             
              New_Dealer_Application__c n = [select id, How_many_locations__c from new_dealer_application__c where id=:nda.Id limit 1];
            
              if(n.how_many_locations__c != null && integer.valueof(n.How_many_locations__c) > 1)
                n.How_many_locations__c = string.valueof(integer.valueof(n.How_many_locations__c) - 1);
              else
                n.How_many_locations__c = '0';
                  
              update n;
            }   
          }
          
          i= i +1;
        }
        
        locsList.remove(locListIndexToRemove);
        
        if(displayNumLocBlocks > 0)
          displayNumLocBlocks = displayNumLocBlocks - 1;
        else
          displayNumLocBlocks = 0;
          
        pageMessage = '';    
      }
      catch(Exception excp)
      {
        UtilityClass.logError(excp,'NDA', ndaId, 'Deletion Location Rec Id: '+locationNumToDelete);
        showErrorMessage = true;
         
        pageMessage = System.Label.Something_Went_Wrong;        
      }   
    }

    public void DeleteReference()
    {
      try
      {   
        integer i = 0;
        integer refListIndexToRemove;
        
        pageMessage = ''; 
         
        for(Ref r: refsList)
        {
          if(r.num == referenceNumToDelete)
          {
            refListIndexToRemove = i;
            
            if(r.recId != null)
            {
              delete [select id from bank__c where id=:r.recId];
             
              New_Dealer_Application__c n = [select id, How_many_references_do_you_have__c from new_dealer_application__c where id=:nda.Id limit 1];
            
              if(integer.valueof(n.How_many_references_do_you_have__c) > 1)
                n.How_many_references_do_you_have__c = string.valueof(integer.valueof(n.How_many_references_do_you_have__c) - 1);
              else
                n.How_many_references_do_you_have__c = '0';
              
              update n;
            }   
          }
          
          i= i +1;
        }
        
        refsList.remove(refListIndexToRemove);
        
        if(displayNumRefBlocks > 0)
          displayNumRefBlocks = displayNumRefBlocks - 1;
        else
          displayNumRefBlocks = 0;
          
      }
      catch(Exception excp)
      {
        UtilityClass.logError(excp,'NDA', ndaId, 'Reference Rec Id: '+referenceNumToDelete);
        showErrorMessage = true;
                
        pageMessage = System.Label.Something_Went_Wrong;
      }   
    }

    // Bank Details
    public List<Bank__c> setBankingInfoSection(){
        
        return [select Id, Name, New_Dealer_Application__c, Credit_Amount__c, Type__c, Phone__c, Average_Balance__c, Type_of_Established_Canada__c
                                                            from Bank__c
                                                            where New_Dealer_Application__c = :nda.Id];
    }
    
    public List<BankPdfWrapper> setBankingInfoSectionForPDf(){
        Boolean isUS = langCode == 'fr' ? false : true;
        List<BankPdfWrapper> banksPdf = new List<BankPdfWrapper>();
        List<Bank__c> banks = [select Id, Name, City__c, New_Dealer_Application__c, Credit_Amount__c, Type__c, Phone__c, Average_Balance__c, Type_of_Established_Canada__c
                                                            from Bank__c
                                                            where New_Dealer_Application__c = :nda.Id];
         
             
        for(Bank__c b : banks){
            banksPdf.add(new BankPdfWrapper(b, isUS));
        }
        
        return banksPdf;
    }

    public List<Additional_Location__c> setAdditionalLocations(){
            
            system.debug(nda.id);
            
            List<Additional_Location__c> alLocsList = [select Id, Name, City__c, New_Dealer_Application__c, State__c, Street__c, Zip__c, Province__c
                                                        from Additional_Location__c
                                                        where New_Dealer_Application__c = :nda.Id];  
            
            system.debug(alLocsList);
            return alLocsList;     
    }

    public PageReference saveLocationInformation()
    {
      try
      {
        locationsValidationMsg = '';
        pageMessage = '';
 
        for(Loc l: locsList)
        {
          l.messages = new List<string>();
 
          validateLocationInformation(l);
 
          if(l.messages != null && l.messages.size() > 0)
          {
            locationsValidationMsg = System.Label.Please_provide_valid_data_in_all_required_fields_for_all_additional_locations;
          }
       
          if(l.messages == null || (l.messages != null && l.messages.size() == 0))
          {
            if(string.isBlank(l.recId))
            {
              Additional_location__c al = new Additional_Location__c();
           
              al.street__c = l.street;
              al.city__c   = l.city;
              al.state__c = l.state;
              al.zip__c    = l.postalCode;
              al.new_dealer_application__c = nda.Id;
            
              Id CArecordId = Constants.AdditionalLocationRTMap.get('Canadian'); 
              Id USrecordId = Constants.AdditionalLocationRTMap.get('United_States');
              Id AUrecordId;
              Id NZrecordId;
             
              if(AU_NZ_Support)
              {
                AUrecordId = Constants.AdditionalLocationRTMap.get('Australia');
                NZrecordId = Constants.AdditionalLocationRTMap.get('New_Zealand');
              }
            
              Id rtypeId;
              
              if(nda.country__c == 'United States')
              {
                rtypeId = USrecordId;
              }
              else if(nda.country__c == 'Canada')
              {
                rtypeId = CArecordId;
              }
              else if(AU_NZ_Support && nda.country__c == 'Australia')
              {
                rtypeId = AUrecordId;
              }
              else if(AU_NZ_Support && nda.country__c == 'New Zealand')
              {
                rtypeId = NZrecordId;
              }
              
              al.recordTypeId = rtypeId;
             
              insert al;
                        
              l.recId = al.id;
            }
            else
            {
              Additional_location__c al = new Additional_Location__c(id=l.recId);
             
              al.street__c = l.street;
              al.city__c   = l.city;
              al.state__c = l.state;
              al.zip__c    = l.postalCode;
         
              update al;           
            }  
          }
        }
       
        if(string.isBlank(locationsValidationMsg))
        {  
          Integer locNum = 0;
       
          for(Loc l: locsList)
          {
            l.num = string.valueof(locNum);
            locNum++;
          }
       
          New_Dealer_Application__c n = new New_Dealer_Application__c(id = ndaId);
       
          if(locsList != null)
          {
            n.How_many_locations__c = string.valueof(locsList.size());
          }
          else
          {
            n.How_many_locations__c = '0';  
          } 
                   
          update n;
        
          PageReference nextPage;
       
          if(saveForLater=='true')
            nextPage = page.NewDealerAppSaved;
          else
            nextPage = Page.NewDealerAppReferenceInfo;
            
          if(ndaId != null && ndaId !='')
           nextPage.getParameters().put('Id', ndaId);
                          
          nextPage.getParameters().put('country',nda.country__c);
          nextPage.getParameters().put('prod',nda.primary_brand_requested__c);
          nextPage.getParameters().put('prMfr',nda.manufacturer__r.name);
        
          if(nda.language__c == 'French Canadian')
            nextPage.getParameters().put('lang', 'fr');
          else if(nda.language__c == 'English')
            nextPage.getParameters().put('lang', 'en');  
                         
          nextPage.setRedirect(true);
       
          return nextPage;
        }
        else
        {
          return null;
        }
      }
      catch(Exception excp)
      {
        UtilityClass.logError(excp,'NDA', ndaId, 'Save Location failed.');
       
        pageMessage = System.Label.Something_Went_Wrong;
       
        throw excp;
       
        //return null;
     }
   }

   public PageReference DirectToMainPage(){
       PageReference pg = Page.NewDealerAppMain;
       pg.setRedirect(true);
       return pg;   
   }

    //Retrieve existing application
   public PageReference RetrieveApp()
   {
     try
     {
       showPasswordFields = false;

       retrieveAllManufacturers();
   
       PageReference savedapp = Page.NewDealerAppMain;
     
       List<New_dealer_application__c> unsubmittedAppList; 
       List<New_dealer_application__c> submittedAppList;
     
       if(ApplNr != null && ApplNr != '' && pass != null && pass != '')
       {      
         unsubmittedAppList = [select id, Applicant_Representative_Signature_Date__c, Legal_Business_Name__c, Customer_DBA_Name__c, What_is_your_business_entity_type__c, Federal_Tax__c, Tax_Id_For_Use_By_NDA_Guest_User__c, Date_of_signature__c,
               withdrawn__c, language__c, country__c, primary_brand_requested__c, Manufacturer__c, manufacturer__r.name, Electronic_Communication_Consent__c, existing_tcfif_or_ria_customer__c,
               Dealer_Phone_Number__c, Fax_Number__c, Location_Contact_First_Name__c,  Email_Address__c, Nr_of_Owners__c, Annual_Gross_Revenue__c,
               What_year_was_your_business_founded__c, of_years_under_current_ownership__c, Financial_Year_End__c, Address__c,
               City__c, Zipcode__c, How_many_locations__c, How_many_references_do_you_have__c, State__c, Line_of_Credit_Amount__c, Formation_State_US__c,
               Industry__c, What_type_of_program_are_you_requesting__c, What_is_your_requested_line_of_credit__c,
               Provide_Explanation_of_Bankrucptcy__c,  Provide_Explanation_unpaid_taxes__c, Provide_Explanation_of_Legal_Proceedings__c, 
               Password__c, IP_Address__c, 
               Name_of_authorized_signer__c, Title_of_authorized_signer__c, Bankruptcy_Filed__c, Delinquent_Taxes__c, Pending_Legal_Proceedings__c, Dealer_Submitted__c, Account__c,
               Applicant_Representative_s_Email__c, Applicant_Representative_s_First_Name__c, Applicant_Representative_s_Last_Name__c, RecordTypeId,
               Formation_Jurisdiction__c, application_submitted__c, Type_of_Established_Canada__c, Province__c,State_Province_Code__c, Formation_Jurisdiction_Code__c, Interested_in_Retail_Financing__c,
               inventory_insurance_carrier__c, inventory_insurance_coverage_amount__c, policy_number__c, policy_renewal_date__c, agent_first_name__c, agent_last_name__c, agent_phone_number__c,
               AD_Eligible__c, AD_Result__c, AD_Model_Used__c
               from New_Dealer_Application__c
               where name = :ApplNr and Dealer_Submitted__c = false]; 
       
         //Found an unsubmitted, not withdrawn app with the number provided, still need to check for password match                       
         if(unsubmittedAppList != null && unsubmittedAppList.size() > 0)
         {
           this.nda =  unsubmittedAppList[0];
         
           //If password matches and the unsubmitted app was not withdrawn, then show Main page with appropriate parameters
           if(nda.Id != null && nda.password__c != null && nda.password__c != '' && nda.password__c.equals(pass) && nda.withdrawn__c == false)
           {
             savedapp.getParameters().put('Id', nda.Id);
       
             if(nda.password__c != null && nda.password__c != '')
               savedapp.getParameters().put('p','yes');
             else
               savedapp.getParameters().put('p','no');
           
             if(nda.country__c == 'United States')
               savedapp.getParameters().put('country','United States');
             else if(nda.country__c == 'Canada')
               savedapp.getParameters().put('country','Canada');
             else if(AU_NZ_Support && nda.country__c == 'Australia')
               savedapp.getParameters().put('country','Australia');
             else if(AU_NZ_Support && nda.country__c == 'New Zealand')
               savedapp.getParameters().put('country','New Zealand');     
                  
             if(nda.language__c == 'French Canadian')
               savedapp.getParameters().put('lang', 'fr');
             else if(nda.language__c == 'English')
               savedapp.getParameters().put('lang', 'en');
             
             savedapp.getParameters().put('prod', nda.primary_brand_requested__c);
           
             primaryManufacturer = nda.manufacturer__r.name; 
           
             savedapp.getParameters().put('prMfr', nda.manufacturer__r.name);   
             
             savedapp.setRedirect(true);    
             return savedapp;
           }
           //else if password matches but the unsubmitted app was withdrawn, then show the submitted or withdrawn page
           else if(nda.Id != null  && nda.password__c != null && nda.password__c != '' && nda.password__c.equals(pass) && nda.withdrawn__c == true)
           {           
             savedapp.getParameters().put('Id', nda.Id);
           
             if(nda.password__c != null && nda.password__c != '')
               savedapp.getParameters().put('p','yes');
             else
               savedapp.getParameters().put('p','no');
                  
             savedapp.getParameters().put('country',nda.country__c);       
             savedapp.getParameters().put('lang', langCode);
           
             savedapp.setRedirect(true);    
             return savedapp;
           }
           //else if the password did not match, then show an error message
           else
           {
             pageMessage = 'No application was found with the provided application number and password. Please make sure you are entering the 12 character application number in this format: NDA-xxxxxxxx and the correct password.';
             nda = null;
             //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'No application found with the provided application number and password. Please make sure you are entering the 12 character application number in this format: NDA-xxxxxxxx and the correct password.'));
             return null; 
           }
         }
         //If an unsubmitted, unwithdrawn app with the provideed app number is not found, see if there is a submitted app with that app number
         else
         {
          submittedAppList  = [select id, name, withdrawn__c, password__c, Customer_DBA_Name__c, language__c, primary_brand_requested__c, country__c, Electronic_Communication_Consent__c, existing_tcfif_or_ria_customer__c from New_Dealer_Application__c 
                               where name = :ApplNr and Dealer_Submitted__c = true];
          
          //If a submitted app is found                  
          if(submittedAppList != null && submittedAppList.size() > 0)
          {
            this.nda = submittedAppList[0];
            
            //If password matches and the submitted app was not withdrawn, then show BasicInfoB page with appropriate parameters
            if(nda.Id != null  && nda.password__c != null && nda.password__c != '' && nda.password__c.equals(pass))
            {
              savedapp.getParameters().put('Id', nda.Id);
              
              if(nda.password__c != null && nda.password__c != '')
                savedapp.getParameters().put('p','yes');
              else
                savedapp.getParameters().put('p','no');
                  
              savedapp.getParameters().put('country',country);
              savedapp.getParameters().put('lang', langCode);
                     
              savedapp.setRedirect(true);    
            
              return savedapp;
            }
            //else if the password did not match, then show an error message
            
        }
        else
            {
              pageMessage = 'No application was found with the provided application number and password. Please make sure you are entering the 12 character application number in this format: NDA-xxxxxxxx and the correct password.';
              nda = null;
              //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'No application found with the provided application number and password. Please make sure you are entering the 12 character application number in this format: NDA-xxxxxxxx and the correct password.'));
              return null;  
            }
      }
    }
    else
            {
              pageMessage = 'No application was found with the provided application number and password. Please make sure you are entering the 12 character application number in this format: NDA-xxxxxxxx and the correct password.';
              //nda = null;
              //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'No application found with the provided application number and password. Please make sure you are entering the 12 character application number in this format: NDA-xxxxxxxx and the correct password.'));
              return null;  
            }
 }
 catch(Exception e)
 {
   pageMessage = System.Label.Something_Went_Wrong;
 }
   
    return null;
  }

public Pagereference saveBasicInformation()
  {
    try
    {
      pageMessage = '';
  
      string countryCode;
      PageReference ref;
  
      if(nda.Id != null)
      { 
        if(nda.country__c == 'United States')
          countryCode = 'US';
        else if(nda.country__c == 'Canada')
          countryCode = 'CA';
        else if(AU_NZ_Support && nda.country__c == 'Australia')
          countryCode = 'AU';    
        else if(AU_NZ_Support && nda.country__c == 'New Zealand')
          countryCode = 'NZ';
    
        New_dealer_application__c n = [select id, name, withdrawn__c, dealer_submitted__c, manufacturer__c, manufacturer__r.name from New_Dealer_Application__c where id=:nda.id limit 1];
                  
        if(n != null && n.withdrawn__c == false && n.dealer_submitted__c == false)
        {
          List<Product_Information_For_New_Dealer_App__c> prodJunc = new List<Product_Information_For_New_Dealer_App__c>();
          prodJunc =[select id, name, New_Dealer_Application2__c, Relationship__c, Manufacturer__c, manufacturer__r.name, manufacturer__r.industry__c, Underwriting__c from Product_Information_For_New_Dealer_App__c where New_Dealer_Application2__c=:n.id and manufacturer__r.name = :n.manufacturer__r.name order by createdDate desc LIMIT 1];

        List<Manufacturer__c> mfrList = new List<Manufacturer__c>();

        mfrList = [select id, name, industry__c from Manufacturer__c where name = :primaryManufacturer];
        
        system.debug(mfrList);
        
        if(mfrList != null && mfrList.size() > 0)
        {
          nda.industry__c = mfrList[0].industry__c;
          nda.manufacturer__c = mfrList[0].id;
        }
        
        nda.Federal_Tax__c = nda.Tax_Id_for_use_by_NDA_Guest_User__c;
        
        update nda;
        
        if(prodJunc.size() == 1)
        {
          prodJunc[0].new_dealer_application2__c  = nda.id;
             
          if(mfrList != null && mfrList.size() > 0)
            prodJunc[0].manufacturer__c = mfrList[0].id;
             
          upsert prodJunc[0];
        }
        
        system.debug(prodJunc);
            
        //Added by Nimish - Update all prospect and client dealer record info with the updated info
        List<Account> updateAccountsList = new List<account>();
                     
        List<id> pListAcctIds = new List<id>();
            
        for(Product_Information_For_New_Dealer_App__c p: [select id, relationship__c, Manufacturer__c, new_dealer_application2__c from Product_Information_For_New_Dealer_App__c where new_dealer_application2__c =: nda.id and (relationship__r.recordtypeid =: Constants.AccountRTProspectDealer or relationship__r.recordtypeid = :Constants.AccountRTClientDealer)])
        {
          pListAcctIds.add(p.relationship__c);
        }
            
        List<account> NDAAccountsList = [select name, AssignedBoardingSpecialist__c, Primary_Contact_Name__c,Phone, Fax, Customer_DBA_Name__c, Year_Business_Was_Established__c,Years_Under_the_Present_Ownership__c, Financial_Year_End__c, 
        BillingStreet,BillingCity, BillingStateCode, BillingPostalCode, shippingstatecode, Primary_Contact_Email_Address__c, Tax_Identification_Number__c, State_of_Incorporation__c, Legal_Entity__c
        from account where id in: pListAcctIds];
            
        for(Account acct: NDAAccountsList)
        { 
          acct.Name = nda.Legal_Business_Name__c;
          acct.Primary_Contact_Name__c = nda.Location_Contact_First_Name__c;// + ' ' + nda.Location_Contact_Last_Name__c;   
          acct.Phone = nda.Dealer_Phone_Number__c;  
              
          if(nda.fax_number__c != null)
            acct.Fax = nda.fax_number__c;

          ////////////////////////////////////////////////////////////////////////////////
          //Logic to sync relationship dba names with what's on the nda dba names field //
          ////////////////////////////////////////////////////////////////////////////////

          //Retrieve all dbaName records associated with this relationship
          List<DBA_Name__c> existingDBANameRecordsList = AccountManager.getDBARecordsForThisRealtionship(acct.id);
          List<string> existingRelDBANamesList = new List<string>();

          for(DBA_Name__c d: existingDBANameRecordsList)
          {
            existingRelDBANamesList.add(d.dba_Name__c);
          }
          ////

          //Retrieve and clean up all dbaName from the nda dba names field
          List<string> unTrimmedNDADBANamesList = new List<string>();
          List<string> ndaDBANamesList=new List<string>();
          
          //Execute the DBA Name sync logic only if NDA dbaNames field is not blank
          if(!string.isBlank(nda.customer_dba_name__c))
          {
            unTrimmedNDADBANamesList = nda.customer_dba_name__c.replace(';;',';').split(';');

            if(unTrimmedNDADBANamesList.size() == 0)
              unTrimmedNDADBANamesList.add(nda.customer_dba_name__c);

            for(integer i=0; i<unTrimmedNDADBANamesList.size(); i++)
            {
              ndaDBANamesList.add(unTrimmedNDADBANamesList[i].trim());
            }
            ////
          
            //Check to see if any dbaName on the NDA  dbaNames field is missing as a dba_Name__c record on the relationship
            //If so create that DBA_Name__C record for that relationship
            List<string> newDBARecordsToBeInsertedList = new List<string>();

            for(string nDBAName: ndaDBANamesList)
            {
              if(!existingRelDBANamesList.contains(nDBAName))
              {
                newDBARecordsToBeInsertedList.add(nDBAName);
              }
            } 
            /////// 


            if(newDBARecordsToBeInsertedList.size() > 0)
            {
              //Handle synching nda dba name field (; delimited values) with acct dba name field (first dba name on the nda dba name field) and dba name records
              string firstNDACustDBAName;

              if(!string.isBlank(nda.customer_dba_name__c))     
              { 
                /*
                //Take the first dba name in customer_dba_name__C field and assign it to acct.Customer_DBA_Name__c
                if(ndaDBANamesList != null)
                  firstNDACustDBAName = ndaDBANamesList[0];
                else
                  firstNDACustDBAName = nda.customer_dba_name__c.trim();

                acct.Customer_DBA_Name__c = firstNDACustDBAName;
                */

                //Create new dbaNAme records for this relationship based on the semicolon separated values on the customer_db_name__c field on this NDA
                List<DBA_Name__c> dbaNamesList = new List<DBA_Name__c>();

                for(string dbaName : newDBARecordsToBeInsertedList)
                {
                  dbaNamesList.add(new DBA_Name__c(DBA_Name__c = dbaName.trim(), relationship__c = acct.id));
                }

                if(dbaNamesList.size() > 0)
                {
                  insert dbaNamesList;
                }
              }
            }
          }
          ///////////////////////////////////////////////////////////
              
          acct.Year_Business_Was_Established__c = nda.What_year_was_your_business_founded__c; 
          acct.Years_Under_the_Present_Ownership__c = nda.of_years_under_current_ownership__c;
          acct.Financial_Year_End__c = nda.Financial_Year_End__c;  
          acct.BillingStreet = nda.address__c;
          acct.BillingCity = nda.city__c;
          acct.BillingCountryCode=countryCode;   
          acct.BillingStateCode = UtilityClass.createStateNameToStateCodeMap(countryCode).get(nda.state__c);
          acct.BillingPostalCode = nda.Zipcode__c;
          acct.Primary_Contact_Email_Address__c = nda.Email_Address__c; 
          acct.Tax_Identification_Number__c = nda.Tax_Id_For_Use_By_NDA_Guest_User__c;
          acct.shippingCountryCode=countryCode; 
          acct.shippingstatecode=UtilityClass.createStateNameToStateCodeMap(countryCode).get(nda.state__c);
          
          if(nda.country__c == 'United States')
            acct.State_of_Incorporation__c = nda.formation_state_us__c;
          else if(nda.country__c == 'Canada' || AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c == 'New Zealand'))  
            acct.State_of_Incorporation__c = nda.formation_jurisdiction__c;
                        
          acct.Legal_Entity__c = nda.What_is_your_business_entity_type__c;

          updateAccountsList.add(acct);
        }
            
        update updateAccountsList;
        
        if(saveForLater == 'true')
          ref = Page.NewDealerAppSaved;
        else
          ref = Page.NewDealerAppProducts;  
    
        ref.getParameters().put('Id', nda.id);
        ref.getParameters().put('country', nda.country__c);
         
        if(!string.isBlank(nda.password__c))  
        {
          ref.getParameters().put('p', 'yes');
        }
        else
        {
          ref.getParameters().put('p', 'no'); 
        } 
            
        ref.getParameters().put('prod',nda.primary_brand_requested__c);
        
        if(nda.manufacturer__c != null)
          ref.getParameters().put('prMfr', nda.manufacturer__r.name);
        else
          ref.getParameters().put('prMfr', primaryManufacturer);
        
        system.debug(primaryManufacturer);  
          
        if(nda.language__c == 'French Canadian')
          ref.getParameters().put('lang', 'fr');
        else if(nda.language__c == 'English')
          ref.getParameters().put('lang', 'en');
      }
    }
    else
    { 
      if(nda.country__c == 'United States')
      {
        countryCode = 'US';
        nda.RecordTypeId  = Constants.NewDealerAppRTMap.get('United_States');
      }
      else if(nda.country__c == 'Canada')
      {
        countryCode = 'CA';
        nda.RecordTypeId = Constants.NewDealerAppRTMap.get('Canadian');
      }
      else if(AU_NZ_Support && nda.country__c == 'Australia')
      {
        countryCode = 'AU';
        nda.RecordTypeId  = Constants.NewDealerAppRTMap.get('Australia');    
      }
      else if(AU_NZ_Support && nda.country__c == 'New Zealand')
      {
        countryCode = 'NZ';
        nda.RecordTypeId  = Constants.NewDealerAppRTMap.get('New Zealand');
      }
           
      nda.State_Province_Code__c = UtilityClass.createStateNameToStateCodeMap(countryCode).get(nda.state__c);
      
      if(nda.country__c == 'United States')
        nda.Formation_Jurisdiction_Code__c = UtilityClass.createStateNameToStateCodeMap(countryCode).get(nda.Formation_State_US__c);
      else if(nda.country__c == 'Canada' || AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c == 'New Zealand')) 
        nda.Formation_Jurisdiction_Code__c = UtilityClass.createStateNameToStateCodeMap(countryCode).get(nda.Formation_Jurisdiction__c);
              
          
      if(nda.primary_brand_requested__c != null && nda.primary_brand_requested__c.startsWith('Toro') && nda.language__c == 'English' && nda.country__c== 'United States')
        nda.RIA__c = true;
                    
      List<Manufacturer__c> ml = new List<Manufacturer__c>();
           
      if(!string.isBlank(nda.manufacturer__r.name))
        ml = [select id, name, industry__c from Manufacturer__c where name = :nda.manufacturer__r.name];
      else
        ml = [select id, name, industry__c from Manufacturer__c where name = :primaryManufacturer];
        
      system.debug(primaryManufacturer+ml);
            
      if(ml != null && ml.size() > 0)
      {
        nda.industry__c = ml[0].industry__c;
        nda.manufacturer__c = ml[0].id;
      }
      
      nda.Federal_Tax__c = nda.Tax_Id_for_use_by_NDA_Guest_User__c;
          
      insert nda;   
          
      ////////////////////////////////////////
      // Insert New Prospect Dealer Account //
      ////////////////////////////////////////
      Account a = new Account();
         
      if(!string.isBlank(actId))
      {
        a = new Account(Id = actId);
      }  
      else
      {
        Id ProspectDealerRecTypeId = Constants.accountRTMap.get('Prospect_Dealer');
                 
        a = new Account(recordTypeId=ProspectDealerRecTypeId);  
        
        //santosh -added for WI 3650. Set Created_Through_App_Site__c to true only on account insertion
        a.Created_Through_App_Site__c=true;
      }              
          
      a.Name = nda.Legal_Business_Name__c;
      a.Primary_Contact_Name__c = nda.Location_Contact_First_Name__c;// + ' ' + nda.Location_Contact_Last_Name__c;   
      a.Phone = nda.Dealer_Phone_Number__c;  
              
      if(nda.fax_number__c != null)
        a.Fax = nda.fax_number__c;

      //Handle synching nda dba name field (; delimited values) with acct dba name field (first dba name on the nda dba name field) and dba name records
      string firstNDACustDBAName;

      List<string> ndaDBANamesList = new List<string>();

      if(!string.isBlank(nda.customer_dba_name__c))     
      {
        if(nda.customer_dba_name__c.contains(';'))
          ndaDBANamesList = nda.customer_dba_name__c.split(';');
        else
          ndaDBANamesList.add(nda.customer_dba_name__c);  

        system.debug('------------'+ndaDBANamesList);

        if(ndaDBANamesList != null && ndaDBANamesList.size()>0)
        {
          //Remove spaces around ';' in user entered customer_dba_name__c field
          nda.customer_dba_name__c = '';

          for(string s: ndaDBANamesList)
          {
            system.debug('------------>'+nda.customer_dba_name__c);
            nda.customer_dba_name__c = nda.customer_dba_name__c + s.trim() + ';';
          }
            
          system.debug('------------>>>>>>'+nda.customer_dba_name__c);

          //nda.customer_dba_name__c = nda.customer_dba_name__c.substring(0,nda.customer_dba_name__c.length()-1);
        }
        //

        //Take the first dba name in customer_dba_name__C field and assign it to acct.Customer_DBA_Name__c
        if(ndaDBANamesList != null)
          firstNDACustDBAName = ndaDBANamesList[0].trim();
        else
          firstNDACustDBAName = nda.customer_dba_name__c.trim();

        a.Customer_DBA_Name__c = firstNDACustDBAName;
      }
              
      a.Year_Business_Was_Established__c = nda.What_year_was_your_business_founded__c; 
      a.Years_Under_the_Present_Ownership__c = nda.of_years_under_current_ownership__c;
      a.Financial_Year_End__c = nda.Financial_Year_End__c;  
      a.BillingStreet = nda.address__c;
      a.BillingCity = nda.city__c;  
      a.BillingCountryCode=countryCode; 
      a.BillingStateCode = UtilityClass.createStateNameToStateCodeMap(countryCode).get(nda.state__c);
      a.BillingPostalCode = nda.Zipcode__c;
      a.Primary_Contact_Email_Address__c = nda.Email_Address__c; 
      a.Tax_Identification_Number__c = nda.Tax_Id_For_Use_By_NDA_Guest_User__c;
      a.shippingCountryCode=countryCode; 
      a.shippingstatecode=UtilityClass.createStateNameToStateCodeMap(countryCode).get(nda.state__c);
          
      if(nda.country__c == 'United States')
        a.State_of_Incorporation__c = nda.formation_state_us__c;
      else if(nda.country__c == 'Canada' || AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c == 'New Zealand'))  
        a.State_of_Incorporation__c = nda.formation_jurisdiction__c;
                        
      a.Legal_Entity__c = nda.What_is_your_business_entity_type__c;
    
      a.AnnualRevenue = nda.Annual_Gross_Revenue__c;
       
      upsert a; 

      //Create and link the DBA Name record to the relationship after it is upserted
      List<DBA_Name__c> dbaNamesList = new List<DBA_Name__c>();

      for(string dbaName : ndaDBANamesList)
      {
        dbaNamesList.add(new DBA_Name__c(DBA_Name__c = dbaName.trim(), relationship__c = a.id));
      }

      if(dbaNamesList.size() > 0)
      {
        insert dbaNamesList;
      }
      //

          
      List<Product_Information_For_New_Dealer_App__c> pj1 = new List<Product_Information_For_New_Dealer_App__c>();
      pj1 =[select id, New_Dealer_Application2__c, Relationship__c, Manufacturer__c, manufacturer__r.name, manufacturer__r.industry__c, Underwriting__c from Product_Information_For_New_Dealer_App__c where Relationship__c=:a.id AND New_Dealer_Application2__c=NULL order by createdDate desc LIMIT 1];

      List<Manufacturer__c> ml1 = new List<Manufacturer__c>();
           
      if(!string.isBlank(nda.manufacturer__r.name))
        ml1 = [select id, name, industry__c from Manufacturer__c where name = :nda.manufacturer__r.name];

      if(pj1.size() == 1)
      {
        pj1[0].new_dealer_application2__c  = nda.id;
         
        if(ml1 != null && ml1.size() > 0)
          pj1[0].manufacturer__c = ml1[0].id;
             
        upsert pj1[0];
      }
      else if(pj1.size() == 0)
      {
        Product_Information_For_New_Dealer_App__c p = new Product_Information_For_New_Dealer_App__c();
        p.new_dealer_application2__c = nda.id;
        p.Relationship__c = a.id;
             
        if(ml1 != null && ml1.size() > 0)
        {
          p.manufacturer__c = ml1[0].id;
        }
             
        insert p;
      } 
      //end      

      //Added by Nimish 
      //Send NDA application number and password email to the Dealer provided email address if the Dealer nda.country__cis United States
      New_Dealer_Application__c insertedNDA = [select id, name, password__c, email_address__c, country__c, primary_brand_requested__c, Location_Contact_First_Name__c from New_Dealer_Application__c where id =: nda.id][0];            
                
      if(insertedNDA != null && insertedNDA.country__c == 'United States' && insertedNDA.email_address__c != null)
        sendAppNumAndPasswordEmail(insertedNDA.country__c, insertedNDA.primary_brand_requested__c, insertedNDA.Location_Contact_First_Name__c, insertedNDA.name, insertedNDA.password__c, insertedNDA.email_address__c, nda.Id);
      //End
      
      if(saveForLater == 'true')
        ref = Page.NewDealerAppSaved;
      else
        ref = Page.NewDealerAppProducts;  
    
      ref.getParameters().put('Id', nda.Id);
      ref.getParameters().put('country', nda.country__c);
         
      if(!string.isBlank(nda.password__c))  
      {
        ref.getParameters().put('p', 'yes');
      }
      else
      {
        ref.getParameters().put('p', 'no'); 
      } 
            
      ref.getParameters().put('Id', nda.Id);
      ref.getParameters().put('prod',nda.primary_brand_requested__c);
      //ref.getParameters().put('prMfr', nda.Manufacturer__r.name);
      ref.getParameters().put('prMfr', primaryManufacturer); 
          
      if(nda.language__c == 'French Canadian')
        ref.getParameters().put('lang', 'fr');
      else if(nda.language__c == 'English')
        ref.getParameters().put('lang', 'en');     
    }
          
    ref.setRedirect(true);
    return ref;
    }
    catch(Exception e)
    {
      showInputsValidationMessageOnMainPage = System.Label.Please_enter_all_required_fields_with_valid_values;
      pageMessage = System.Label.Something_Went_Wrong+ '  ' + e;
    }
    
    return null;         
  }
     
    
   
   //Added by Nimish
   //Send email notification with NDA app number and password at the provided email address
   public static void sendAppNumAndPasswordEmail(string country, string primaryBrandRequested, string contactName, string appNumber, string appPassword, string dealerEmailAddress, string ndaId)
   {        
      try
      { 
        String SFDCBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        String NDAURL;
        
        String ToroAppSupportPhone = '877.223.7131';
        String GeneralAndBRPSAppSupportPhone = '877.872.8234, option #2';
        
        if(SFDCBaseURL.contains('.cs'))
          NDAURL = URL.getSalesforceBaseUrl().toExternalForm()+'/Application/newdealerappmain';
        else
          NDAURL = 'http://tcfif.force.com/Application';   
      
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<string> toAddresses = new List<string>();
      
        toAddresses.add(dealerEmailAddress);
        email.setToAddresses(toAddresses);
        email.setSubject('Your New Dealer Application number and access link');
      
        String htmlBody;
        htmlBody = '<HTML><Body>';
        htmlBody = htmlBody + '<table style=\"width:525pt\">'; 
      
        if(country == 'United States' && primaryBrandRequested == 'Bombardier Recreational Products' || primaryBrandRequested == 'General')
        {
           //santosh replaced  na16.content.force with documentforce as part of critical update WI 2926
           // htmlBody = htmlBody + '<tr><td align=\"center\"><img src=\"https://inventoryengine--c.na16.content.force.com/servlet/servlet.ImageServer?id=015j0000000qPI3&oid=00Dj00000027uOr\"></td></tr>';
           htmlBody = htmlBody + '<tr><td align=\"center\"><img src=\"https://inventoryengine--c.documentforce.com/servlet/servlet.ImageServer?id=015j0000000qPI3&oid=00Dj00000027uOr\"></td></tr>';     
        }
        else if(country == 'United States' && !string.isBlank(primaryBrandRequested) && primaryBrandRequested.startsWith('Toro'))
        {
           //santosh replaced  na16.content.force with documentforce as part of critical update WI 2926
           // htmlBody = htmlBody + '<tr><td align=\"center\"><img src=\"https://inventoryengine--c.na16.content.force.com/servlet/servlet.ImageServer?id=015j0000000rX3T&oid=00Dj00000027uOr\"></td></tr>';
            htmlBody = htmlBody + '<tr><td align=\"center\"><img src=\"https://inventoryengine--c.documentforce.com/servlet/servlet.ImageServer?id=015j0000000rX3T&oid=00Dj00000027uOr\"></td></tr>';
        }
        htmlBody = htmlBody + '<tr style=\"background: #8A8A90; height:\'5pt\'\"><td><p style=\"font-family:Arial; font-size:4pt;\">&nbsp;</p></td></tr><tr height=\"200\"><td valign = \"top\" align=\"left\">';
        htmlBody = htmlBody + '<p style=\"font-family:Arial\">';
        htmlBody = htmlBody + '<br>'+contactName+',</br>';
    
        if(country == 'United States' && primaryBrandRequested == 'Bombardier Recreational Products' || primaryBrandRequested == 'General')
            htmlBody = htmlBody +'<br>Thank you for starting an application with TCF Inventory Finance, Inc.</br>';
        else if(country == 'United States' && !string.isBlank(primaryBrandRequested) && primaryBrandRequested.startsWith('Toro'))
            htmlBody = htmlBody +'<br>Thank you for starting an application with Red Iron Acceptance LLC.</br>';
    
        htmlBody = htmlBody +'<br><br>Please use the following information to continue your application process:</br></br>';
        htmlBody = htmlBody +'<br><b>Application Number: </b>'+appNumber+'</br>';
        htmlBody = htmlBody +'<br><a href=\"'+NDAURL+'\">Click here to access the application</a></br>';
        htmlBody = htmlBody +'<br><br>Questions regarding your application process? Please contact us at ';
        
        if(country == 'United States' && primaryBrandRequested == 'Bombardier Recreational Products' || primaryBrandRequested == 'General')
            htmlBody = htmlBody + GeneralAndBRPSAppSupportPhone;
        else if(country == 'United States' && !string.isBlank(primaryBrandRequested) && primaryBrandRequested.startsWith('Toro'))
            htmlBody = htmlBody + ToroAppSupportPhone;

        htmlBody = htmlBody +'.</br></br></p></td></tr>';
        htmlBody = htmlBody +'<tr style=\"background:#8A8A90; height: \'5pt\';\"><td><p style=\"font-family:Arial; font-size:4pt;\">&nbsp;</p></td></tr>';
        htmlBody = htmlBody +'</table></Body></HTML>';
        
        email.setHTMLBody(htmlBody);
      
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
     }
     catch(Exception excp)
     { 
       UtilityClass.logError(excp,'NDA', ndaId, 'Dealer Email Address: '+dealerEmailAddress);
       throw excp;  
     }
   } 
   //End
   
   public void RefreshNda(){
        nda = null;
   }
   
   //Added by Nimish
   //Delete all association records tied to the owner record on tha NDA that is being deleted
   @RemoteAction
   global static void deleteOwnerAndRelatedAssociations(Id ndaId, Id associationId)
   {       
     try
     {
      List<Associated_Relationships__c> arList = [select id, secondary_relationship__c, secondary_relationship__r.name from associated_relationships__c where id = : associationId];
      List<Associated_Relationships__c> allARsForThisOwnerList =  [select id, secondary_relationship__c, secondary_relationship__r.name from associated_relationships__c where secondary_relationship__c = :arList[0].secondary_relationship__c];
      
      if(arList != null && arList.size()>0)
      { 
        List<Owner__c> delOwnersList = [select id from Owner__c where new_dealer_application__c = : ndaId and relationship__c = :arList[0].secondary_relationship__c];
        
        if(delOwnersList != null && delOwnersList.size()>0)
          delete delOwnersList[0];
      }
       
      if(allARsForThisOwnerList != null && allARsForThisOwnerList.size()>0)
        delete allARsForThisOwnerList;
     }
     catch(Exception excp)
     {
       UtilityClass.logError(excp,'NDA', ndaId, 'Association Id: '+ associationId);
       throw excp;
     }
   }
    
   public PageReference addProduct()
   {      
     try
     {
       pageMessage = '';
       
       if(selectedManufacturerName == 'Other' && string.isBlank(selectedOtherManufacturerName))
       {
         pageMessage = 'Please enter a name in the Other Manufacturer Name field.';
         return null;
       }  
       
       List<Manufacturer__c> manuList = [select id, primary_manufacturer__c from Manufacturer__c where id = :selectedManufacturer];
       List<Product_Information_For_New_Dealer_App__c> pList = [select id, manufacturer__r.name, Other_Manufacturer_Name__c, manufacturer__r.industry__c, obtained_from__c, obtained_from_name__c from Product_Information_For_New_Dealer_App__c where manufacturer__c = null and New_Dealer_Application2__c = :nda.Id];
     
       Product_Information_For_New_Dealer_App__c p;
     
       if(pList.size() == 0)
       {                  
         p = new Product_Information_For_New_Dealer_App__c();
       
         p.new_dealer_application2__c = nda.Id;
         p.Manufacturer__c = selectedManufacturer;
         p.Other_Manufacturer_Name__c = selectedOtherManufacturerName;
         p.Obtained_From__c = selectedObtainedFrom;
         p.Obtained_From_Name__c = selectedObtainedFromName;
        
         if(manuList != null && manuList.size()>0)
         {
           //e.g: If Boss Snow Plow is selected as a product, Toro will be the Primary Manufacturer 
           if(manuList[0].primary_manufacturer__c != null)
           {
             p.Primary_Manufacturer__c = manuList[0].primary_manufacturer__c;
           }
           else
           {
             //e.g: If Toro is selected as the product, Toro will be the Primary Manufacturer
             if(manuList != null && manuList.size()>0)
               p.Primary_Manufacturer__c = manuList[0].id; 
            
             //leave primary manufacturer field blank for non-exclusive products     
           }   
         }
         // WI 3033 01.09.19 -Santosh -products(Junction records) have missing relationshipId. 
        // insert p; 
         createAdditionalProspectDealerRecordsIfNeeded(p);
         
         New_Dealer_Application__c n = new New_Dealer_Application__c (id=ndaId);
         n.Industry__c = selectedIndustry;
         n.Manufacturer__c = selectedManufacturer;
         update n;
       }
       if(pList.size()==1)   
       {
         p=new Product_Information_For_New_Dealer_App__c(id=pList[0].id);
       
         p.Manufacturer__c = selectedManufacturer;
         p.Other_Manufacturer_Name__c = selectedOtherManufacturerName;
         p.Obtained_From__c = selectedObtainedFrom;
         p.Obtained_From_Name__c = selectedObtainedFromName;
         
         system.debug(p.Manufacturer__c+','+p.Obtained_From__c+','+p.Obtained_From_Name__c);
         
         if(string.isBlank(p.obtained_from__c))
         {
           pageMessage = 'Please provide a valid Obtained From value.';
           return null; 
         }
         
         if(nda.country__c == 'United States' && selectedIndustry == 'Lawn & Garden')
         {
           if(p.obtained_from__c == 'Distributor' && string.isBlank(p.obtained_from_name__c)) 
           {
             pageMessage = 'Please provide valid Obtained From and Obtained From Name values for Lawn & Garden manufacturers.';
             return null;
           }
         }
       
         if(manuList != null && manuList.size()>0)
         {
           //e.g: If Boss Snow Plow is selected as a product, Toro will be the Primary Manufacturer 
           if(manuList[0].primary_manufacturer__c != null)
           {
             p.Primary_Manufacturer__c = manuList[0].primary_manufacturer__c;
           }
           else
           {
             //e.g: If Toro is selected as the product, Toro will be the Primary Manufacturer
             if(manuList != null && manuList.size()>0)
               p.Primary_Manufacturer__c = manuList[0].id; 
              
             //leave primary manufacturer field blank for non-exclusive products     
           }
         }
       
         update p;
       
         //if(!string.isBlank(ndaId) && updateIndustry == 'true')
         {
           New_Dealer_Application__c n = new New_Dealer_Application__c (id=nda.Id);
           n.Industry__c = selectedIndustry;
           n.Manufacturer__c = selectedManufacturer;
           update n;
         }       
       }   
       else
       {
         thisProductAlreadyExistsForThisNDA = false;
         
         List<Product_Information_For_New_Dealer_App__c> pList2 = [select id, manufacturer__c, manufacturer__r.name, Other_Manufacturer_Name__c, manufacturer__r.industry__c, obtained_from__c, obtained_from_name__c from Product_Information_For_New_Dealer_App__c where New_Dealer_Application2__c = :nda.Id];
         
         system.debug(nda.id);
       
         for(Product_Information_For_New_Dealer_App__c prod: pList2)
         {
           if(prod.manufacturer__c == selectedManufacturer)
           {
             thisProductAlreadyExistsForThisNDA = true;          
           }  
         }    
         
         system.debug(pList2);
         system.debug(thisProductAlreadyExistsForThisNDA);
     
         if(thisProductAlreadyExistsForThisNDA == false)
         { 
           p = new Product_Information_For_New_Dealer_App__c();
       
           p.new_dealer_application2__c = nda.Id;
           p.Manufacturer__c = selectedManufacturer;
           p.Other_Manufacturer_Name__c = selectedOtherManufacturerName;
           p.Obtained_From__c = selectedObtainedFrom;
           p.Obtained_From_Name__c = selectedObtainedFromName;
        
           if(manuList != null && manuList.size()>0)
           {
             //e.g: If Boss Snow Plow is selected as a product, Toro will be the Primary Manufacturer 
             if(manuList[0].primary_manufacturer__c != null)
             {
               p.Primary_Manufacturer__c = manuList[0].primary_manufacturer__c;
             }
             else
             {
               //e.g: If Toro is selected as the product, Toro will be the Primary Manufacturer
               if(manuList != null && manuList.size()>0)
                 p.Primary_Manufacturer__c = manuList[0].id; 
              
               //leave primary manufacturer field blank for non-exclusive products     
             }   
           } 
       
           //if(!string.isBlank(ndaId) && updateIndustry == 'true')
           {
             New_Dealer_Application__c n = new New_Dealer_Application__c (id=ndaId);
             n.Industry__c = selectedIndustry;
             n.Manufacturer__c = selectedManufacturer;
             update n; 
           }
           
           createAdditionalProspectDealerRecordsIfNeeded(p);
         }
      
       }
       
       productsList = [select id, name, manufacturer__c, manufacturer__r.name, manufacturer__r.industry__c, Other_Manufacturer_Name__c, obtained_from__c, obtained_from_name__c from Product_Information_For_New_Dealer_App__c where New_Dealer_Application2__c = :nda.Id]; 
       
       selectedIndustry='';
       selectedManufacturer=null;
       selectedManufacturerName='';
       selectedOtherManufacturerName='';
       selectedObtainedFrom='';
       selectedObtainedFromName='';
       
       if(mfrOptions != null)
         mfrOptions.clear();
       
       if(obtainedFromOptions != null)
         obtainedFromOptions.clear();
       
       if(obtainedFromNameOptions != null)
         obtainedFromNameOptions.clear();
       
       displayProdsToAddTable=false;
       
       return null;
     } 
     catch(Exception excp)
     {
       UtilityClass.logError(excp,'NDA', nda.Id, 'Manufacturer: '+selectedManufacturer +', Obtained From:'+selectedObtainedFrom+', Obtained From Name: '+ selectedObtainedFromName+', Industry: '+selectedIndustry);
       
       pageMessage = System.Label.Something_Went_Wrong;
       
       throw excp;
     }
     
     //return null;    
   }
    
   
   global static Manufacturer__c getManufacturer(Id mfgId)
   {
     List<Manufacturer__c> mfgList = new List<Manufacturer__c>();
     mfgList = [select id, primary_manufacturer__c, exclusive__c from manufacturer__c where id = :mfgid];
     
     if(mfgList.size()>0)
       return mfgList[0];
     else 
       return null;
   }
   
   
   //Added by Nimish
   //Create additional prospect records depending on the products added - one prospect record for each non-exclusive product if it does not exist and one record for each exclusive product manufacturer if it does not exist
   //e.g. Toro and MTD products should result in 2 prospect records total; Toro and BossSnow should only result in 1 prospect record total; 1 or more non-exclusive products (manufacturers) like Briggs Straton and Dixie Chooper should only result in 1 prospect record total
   global static void createAdditionalProspectDealerRecordsIfNeeded(Product_Information_For_New_Dealer_App__c currentProduct)
   {    
     New_Dealer_Application__c n = [select id, Account__c from New_Dealer_Application__c where id = :currentProduct.New_Dealer_Application2__c][0];
     
     try
     {                                                                
        List<Product_Information_For_New_Dealer_App__c> productsList = new List<Product_Information_For_New_Dealer_App__c>();
        
        productsList = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c
                                                                            where New_Dealer_Application2__c = : n.id order by createddate desc];                                                                             
        
        system.debug(productsList);
        
        if(productsList.size()>0)
        { 
          system.debug('productsListsize > 0');
          Id existingProspectDealerId;
          Boolean nonExclusiveProspectAlreadyCreated = false;
          Boolean exclusiveProspectAlreadyCreated = false;
                    
          //Check to see if a prospect record for a non-exclusive product manufacturer is already created for this NDA previously (since only one prospect record in total is to be created for non-exclusive products/manufacturers)
          for(Product_Information_For_New_Dealer_App__c prd1: productsList)
          {
            if(prd1.manufacturer__c != currentProduct.Manufacturer__c && prd1.manufacturer__c != null && prd1.manufacturer__r.exclusive__c == false )
            {
              nonExclusiveProspectAlreadyCreated = true;
              existingProspectDealerId = prd1.relationship__c;
              break;
            }
          }
          
          
          //Check to see if a prospect record has already been created previously for this exclusive manufacturer for this NDA
          for(Product_Information_For_New_Dealer_App__c prd2: productsList)
          {
            if(prd2.manufacturer__c != currentProduct.manufacturer__c)
            {
              if((getManufacturer(currentProduct.manufacturer__c).primary_manufacturer__c == prd2.manufacturer__c && prd2.manufacturer__r.exclusive__c == true) || (getManufacturer(currentProduct.manufacturer__c).primary_manufacturer__c == prd2.manufacturer__r.primary_manufacturer__c && prd2.manufacturer__r.primary_manufacturer__r.exclusive__c == true) || (getManufacturer(currentProduct.manufacturer__c).primary_manufacturer__c == null && currentProduct.manufacturer__c == prd2.manufacturer__r.primary_manufacturer__c && prd2.manufacturer__r.primary_manufacturer__r.exclusive__c == true))
              {
                exclusiveProspectAlreadyCreated = true;
                existingProspectDealerId = prd2.relationship__c;
                break;
              }
            }            
          }
                   
          //Create a prospect record for exclusive or non-exclusive product/manufacturer based on the checks above         
          if((getManufacturer(currentProduct.Manufacturer__c).Exclusive__c == true && exclusiveProspectAlreadyCreated == false) || (getManufacturer(currentProduct.Manufacturer__c).Exclusive__c == false && nonExclusiveProspectAlreadyCreated == false))
          {
            Account newProspectDealer;
            Account existingProspectDealerToClone = [select id, Name, New_Dealer_Application__c, New_Dealer_Application__r.Account__c, recordtypeid, billingCountryCode, Primary_Contact_Name__c, Phone, fax, Customer_DBA_Name__c, Year_Business_Was_Established__c, Years_Under_the_Present_Ownership__c, Financial_Year_End__c,
            BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, Primary_Contact_Email_Address__c, Tax_Identification_Number__c, State_of_Incorporation__c, Legal_Entity__c from account where id = :productsList[0].Relationship__c][0];
          
            newProspectDealer = existingProspectDealerToClone.clone(false, true, false, false);
           // newProspectDealer.new_dealer_application__c = currentProduct.new_dealer_application2__c;
           
            //santosh-added fro WI 3650.
            newProspectDealer.Created_Through_App_Site__c =true;
            insert newProspectDealer;
            
            
            //Tie the current product with the new prospect dealer record that is created
            currentProduct.relationship__c = newProspectDealer.Id;
            insert currentProduct;
          }
          //If a new prospect dealer record is not being inserted, find the existing prospect dealer record for this NDA to tie the product to that existing prospect dealer record
          else
          {
            currentProduct.relationship__c = existingProspectDealerId;
            insert currentProduct;
            system.debug(currentProduct);
          }
        }
        //Don't forget to delete related prospect records if a product is deleted in DeleteProduct method
        //Don't forget to replicate all account related list records (i.e. associations etc.) on all prospect dealer records that were persent on the original one
     }
     catch(Exception excp)
     {
       UtilityClass.logError(excp,'NDA', n.Id, 'Product Junction Record Id: '+currentProduct);
       throw excp; 
     } 
   }
   
   public pagereference saveProducts()
   {
     try
     {
       pageMessage = '';
       
       productsList = prepareProductsList();
       
       
       if(productsList == null || (productsList != null && productsList.size() == 0))
       {
         pageMessage = System.Label.Please_add_at_least_one_product_line;
         return null;
       }  
       
       for(Product_Information_For_New_Dealer_App__c p: productsList)
       {
         if(string.isBlank(p.obtained_from__c))
         {
           pageMessage = System.Label.Please_provide_Obtained_From_value_for_Lawn_Garden_product_lines;
           return null;
         }
         else if(nda.country__c == 'United States' && p.manufacturer__r.industry__c == 'Lawn & Garden')
         {
           if(p.obtained_from__c == 'Distributor' && string.isBlank(p.obtained_from_name__c)) 
           {
             pageMessage = System.Label.Please_provide_Obtained_From_value_for_Lawn_Garden_product_lines;
             return null;
           }
         }
       }
              
       update nda; 
       
       PageReference nextPage;
    
       if(saveForLater == 'true')
       {
         nextPage = Page.NewDealerAppSaved; 
       }  
       else
       {
         nextPage = Page.NewDealerAppLocations;
       }
     
       if(ndaId != null && ndaId !='')
       {
         nextPage.getParameters().put('Id', ndaId);
       }
        
       nextPage.getParameters().put('prod', nda.primary_brand_requested__c);  
       
       if(nda.language__c == 'French Canadian')
         nextPage.getParameters().put('lang', 'fr');
       else if(nda.language__c == 'English')
         nextPage.getParameters().put('lang', 'en');
             
       nextPage.getParameters().put('country',nda.country__c);
       
       if(nda.manufacturer__c != null)
         nextPage.getParameters().put('prMfr',nda.manufacturer__r.name);
       else
         nextPage.getParameters().put('prMfr',primaryManufacturer);  
         
       nextPage.setRedirect(true);
       return nextPage;
     }
     catch(Exception excp)
     {
       UtilityClass.logError(excp,'NDA', ndaId, 'Credit Line Requested: '+ nda.What_is_your_requested_line_of_credit__c +', Insurance Carrier: '+nda.inventory_insurance_carrier__c +', Inventory Insurance Coverage Amount: '+nda.inventory_insurance_coverage_amount__c +', Policy Number: '+nda.policy_number__c+', Agent Phone Number: '+nda.agent_phone_number__c + ', RenewalDate: '+ nda.policy_renewal_date__c + ', Agent Firstname: '+nda.agent_first_name__c+', Agent Lastname: '+nda.agent_last_name__c); 
       
       pageMessage = System.Label.Something_Went_Wrong;
       
       throw excp;
       
       //return null;
     }
   }

        
   public void validateLocationInformation(Loc l)
   {
     if(string.isBlank(l.street))
       l.messages.add(System.Label.Street_validation_error);
     if(string.isBlank(l.city))
       l.messages.add(System.Label.City_invalid_error);  
     if(string.isBlank(l.state))
       l.messages.add(System.Label.State_validation_error);
       
     Pattern MyPattern;
     Matcher MyMatcher;
     
     ////////////////////////////////////////
     // United States specific validations //
     //////////////////////////////////////// 
     if(nda.country__c== 'United States')
     {
       ///////////////////////////////////////////
       //Zip code must be xxxxx-xxxx or xxxxx
       ///////////////////////////////////////////
       Boolean match=false;
          
       String zipRegex2 = '\\d{5}';
       MyPattern = Pattern.compile(zipRegex2);         
       MyMatcher = MyPattern.matcher(l.postalcode);
         
       if(MyMatcher.matches())
       { 
         match = true;
         system.debug(match);
       }      
         
       if(match == false) 
         l.messages.add(System.Label.Postal_code_required);  
     }
     else if(nda.country__c == 'Canada')
     {
       String zipRegex = '[A-Z]\\d[A-Z]\\s\\d[A-Z]\\d';
       MyPattern = Pattern.compile(zipRegex);         
       MyMatcher = MyPattern.matcher(l.postalcode);
         
       if(!MyMatcher.matches()) 
         l.messages.add(System.Label.Canada_postal_code_validation_error);
     }
     else if(AU_NZ_Support && (nda.country__c == 'Australia' || nda.country__c== 'New Zealand'))
     {
       String zipRegex = '\\d{4}';
       MyPattern = Pattern.compile(zipRegex);         
       MyMatcher = MyPattern.matcher(l.postalcode);
          
       if(!MyMatcher.matches()) 
         l.messages.add(System.Label.AU_NZ_Postal_Code_Required); 
     }
   }     
        
    
   public void validateReferenceInformation(Ref r)
   { 
     if(string.isBlank(r.acctType))
       r.messages.add(System.Label.Account_Type_is_a_required_field);
     if(string.isBlank(r.bankName))
       r.messages.add(System.Label.Bank_Name_is_a_required_field);   
   }
   
  public PageReference saveReferenceInformation()
   {
     try
     {
       referencesValidationMsg='';
       pageMessage = '';
 
       for(Ref r: refsList)
       {
         r.messages = new List<string>();
 
         validateReferenceInformation(r);
 
         if(r.messages != null && r.messages.size() > 0)
         {
           referencesValidationMsg = System.Label.Please_provide_valid_data_in_all_required_fields_for_all_references;
         }

         if(r.messages == null || (r.messages != null && r.messages.size() == 0))
         {
           if(string.isBlank(r.recId))
           {
             Bank__c b  = new Bank__c();
             b.type__c  = r.acctType;
             b.name     = r.bankName;
             b.phone__c = r.phoneNumber;
           
             if(!string.isBlank(r.avgBalance))
             {
               b.average_balance__c = Decimal.valueof(r.avgBalance.remove(',').remove('$'));
             }
           
             if(!string.isBlank(r.creditAmt))
             {
               b.credit_amount__c = Decimal.valueof(r.creditAmt.remove(',').remove('$'));
             }
             
             b.new_dealer_application__c = nda.Id;
           
             Id CArecordId = Constants.BankRTMap.get('Canadian'); 
             Id USrecordId = Constants.BankRTMap.get('United_States');
             Id AUrecordId;
             Id NZrecordId;
             
             if(AU_NZ_Support)
             {
               AUrecordId = Constants.BankRTMap.get('Australia');
               NZrecordId = Constants.BankRTMap.get('New_Zealand');
             }
           
             Id rtypeId;
              
             if(nda.country__c == 'United States')
             {
               rtypeId = USrecordId;
             }
             else if(nda.country__c == 'Canada')
             {
               rtypeId = CArecordId;
             }
             else if(AU_NZ_Support && nda.country__c == 'Australia')
             {
               rtypeId = AUrecordId;
             }
             else if(AU_NZ_Support && nda.country__c == 'New Zealand')
             {
               rtypeId = NZrecordId;
             }
           
             b.recordTypeId = rtypeId;
           
             insert b;
                      
             r.recId = b.id;
           }
           else
           {
             if(r.messages != null && r.messages.size() > 0)
             {
               referencesValidationMsg = System.Label.Please_provide_valid_data_in_all_required_fields_for_all_references;
             }
             else
             {
               Bank__c b  = new Bank__c(id=r.recId);
               b.type__c  = r.acctType;
               b.name     = r.bankName;
               b.phone__c = r.phoneNumber;
           
               if(!string.isBlank(r.avgBalance))
               {
                 b.average_balance__c = Decimal.valueof(r.avgBalance.remove(',').remove('$'));
               }
           
               if(!string.isBlank(r.creditAmt))
               {
                 b.credit_amount__c = Decimal.valueof(r.creditAmt.remove(',').remove('$'));
               }
 
               update b;
             }           
           }  
         }
       }
       
       if(string.isBlank(referencesValidationMsg))
       { 
         Integer refNum = 0;
       
         for(Ref r: refsList)
         {
           r.num = string.valueof(refNum);
           refNum++;
         }
       
         New_Dealer_Application__c n = new New_Dealer_Application__c(id = ndaId);
       
         if(refsList != null)
         {
           n.How_many_references_do_you_have__c = string.valueof(refsList.size());
         }
         else
         {
           n.How_many_references_do_you_have__c = '0';
         }
                   
         update n;
        
         PageReference nextPage;
       
         if(saveForLater=='true')
           nextPage = page.NewDealerAppSaved;
         else
           nextPage = Page.NewDealerAppOwners;
            
         if(ndaId != null && ndaId !='')
          nextPage.getParameters().put('Id', ndaId);
                          
         nextPage.getParameters().put('country',nda.country__c);
         nextPage.getParameters().put('prod',nda.primary_brand_requested__c);
         nextPage.getParameters().put('prMfr',nda.manufacturer__r.name);
        
         if(nda.language__c == 'French Canadian')
           nextPage.getParameters().put('lang', 'fr');
         else if(nda.language__c == 'English')
           nextPage.getParameters().put('lang', 'en');  
                         
         nextPage.setRedirect(true);
       
         return nextPage;
       }
       else
       {
         return null;
       } 
       
     }
     catch(Exception excp)
     {
       UtilityClass.logError(excp,'NDA', ndaId, 'Save reference failed.');
       
       pageMessage = System.Label.Something_Went_Wrong;
       throw excp;
       
       //return null;
     }
   }

   // TCFIF Step10 button
   public PageReference DirectToSaveAppForLaterPage(){
        PageReference nextPage = Page.NewDealerAppSaved; // Representative
        
        if(ndaId != null && ndaId !='')
        {
          nextPage.getParameters().put('Id', ndaId);
          nextPage.getParameters().put('country',nda.country__c);
          nextPage.getParameters().put('prod',nda.primary_brand_requested__c);
          nextPage.getParameters().put('prMfr',nda.manufacturer__r.name);
        
          if(nda.language__c == 'French Canadian')
            nextPage.getParameters().put('lang', 'fr');
          else if(nda.language__c == 'English')
           nextPage.getParameters().put('lang', 'en');  
        }
        
        nextPage.setRedirect(true);
        return nextPage;
   }
 
   
   
   public PageReference DirectToSubmitPage() 
   {     
        PageReference nextPage = Page.NewDealerAppSubmit; // Representative
        
        if(ndaId != null && ndaId !='')
        {
          nextPage.getParameters().put('Id', ndaId);
          nextPage.getParameters().put('country',nda.country__c);
          nextPage.getParameters().put('prod',nda.primary_brand_requested__c);
          nextPage.getParameters().put('prMfr',nda.manufacturer__r.name);
        
          if(nda.language__c == 'French Canadian')
            nextPage.getParameters().put('lang', 'fr');
          else if(nda.language__c == 'English')
           nextPage.getParameters().put('lang', 'en');  
        }
        
        nextPage.setRedirect(true);
        return nextPage;
   }
      


   public PageReference SubmitApplicationInformation()
   {        
     try
     {
       bankruptcyEtcQuesErrorMessage = '';
       
       if(buttonClicked == 'SubmitApp')
       {
         boolean prodValidationPassed=false;
         
         //Check to make sure at least one product (prod jn record with manufacturer) exists on this NDA
         productsList = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c
                                                                            where New_Dealer_Application2__c = : ndaId];
           
         if(productsList == null || (productsList != null && productsList.size() == 0))
         {
           prodValidationPassed=false;
           bankruptcyEtcQuesErrorMessage = System.Label.At_least_one_product_required_on_NDA;   
         }
         else if(productsList != null && productsList.size() > 0)
         {
           for(Product_Information_For_New_Dealer_App__c p: productsList)
           {
             //If the following condition is met for at least one product junction record
             //then product check is fine
             if(p.Manufacturer__c != null)
             {
               prodValidationPassed = true;
               bankruptcyEtcQuesErrorMessage = '';
               break;
             }
           }
           
           if(prodValidationPassed == false)
              bankruptcyEtcQuesErrorMessage = System.Label.At_least_one_product_required_on_NDA;  
               
         }
         
         //Cannot submit without at least 1 owner      
         if(buttonClicked == 'SubmitApp' && nda.Nr_of_Owners__c == 0) 
         {
           bankruptcyEtcQuesErrorMessage = System.Label.Provide_info_for_at_least_one_owner;
         } 
        //
       }
       
       //Make sure all questions on the submit page are answered        
       if((buttonClicked == 'SubmitApp' || buttonClicked == 'SaveAndCloseDontSubmitApp') 
           && (
                  (bankruptcy == '-') 
               || (bankruptcy == 'Yes'  && (bankruptcyDetails == null || bankruptcyDetails == ''))
               || (legalProceedings == '-') 
               || (legalProceedings == 'Yes' && (legalProceedingsDetails == null || legalProceedingsDetails == ''))
               || (delinquentTaxes == '-')
               || (delinquentTaxes == 'Yes'  && (delinquentTaxesDetails == null  || delinquentTaxesDetails == ''))
               || (applicantRepFirstName == null || applicantRepFirstName == '' || applicantRepLastName == null || applicantRepLastName == '' || applicantRepEmail == null || applicantRepEmail == '')
              )
          )
       { 
         bankruptcyEtcQuesErrorMessage = System.Label.Provide_all_requested_information;       
       }
       
       
       //If any data validation above failed, then show corresponding error message and block app submission
       if(buttonClicked == 'SubmitApp' && bankruptcyEtcQuesErrorMessage != '')
       {
         return null;
       }
       //If all data validations above passed, continue with app submission
       else if(buttonClicked == 'SubmitApp' && bankruptcyEtcQuesErrorMessage=='')
       {
          nda = [select Applicant_Representative_Signature_Date__c, Legal_Business_Name__c, Customer_DBA_Name__c, What_is_your_business_entity_type__c, Federal_Tax__c, Tax_Id_For_Use_By_NDA_Guest_User__c, Date_of_signature__c,
               Dealer_Phone_Number__c, Fax_Number__c, Location_Contact_First_Name__c,  Email_Address__c, Nr_of_Owners__c, Annual_Gross_Revenue__c,
               What_year_was_your_business_founded__c, of_years_under_current_ownership__c, Financial_Year_End__c, Address__c,
               City__c, Zipcode__c, Name, Id, How_many_locations__c, How_many_references_do_you_have__c, State__c, Line_of_Credit_Amount__c, Formation_State_US__c,
               Industry__c, What_type_of_program_are_you_requesting__c, What_is_your_requested_line_of_credit__c, Primary_Brand_Requested__c,
               Provide_Explanation_of_Bankrucptcy__c,  Provide_Explanation_unpaid_taxes__c, Provide_Explanation_of_Legal_Proceedings__c, 
               Electronic_Communication_Consent__c, Password__c, IP_Address__c, Manufacturer__c, Manufacturer__r.name,
               Name_of_authorized_signer__c, Title_of_authorized_signer__c, Bankruptcy_Filed__c, Delinquent_Taxes__c, Pending_Legal_Proceedings__c, Country__c, Dealer_Submitted__c,  Withdrawn__c, Account__c,
               Applicant_Representative_s_Email__c, Applicant_Representative_s_First_Name__c, Applicant_Representative_s_Last_Name__c, RecordTypeId,
               Formation_Jurisdiction__c, application_submitted__c, Type_of_Established_Canada__c, Province__c, Language__c,State_Province_Code__c, Formation_Jurisdiction_Code__c, Interested_in_Retail_Financing__c,
               inventory_insurance_carrier__c, inventory_insurance_coverage_amount__c, policy_number__c, policy_renewal_date__c, agent_first_name__c, agent_last_name__c, agent_phone_number__c,
               Existing_TCFIF_or_RIA_customer__c, AD_Eligible__c, AD_Result__c, AD_Model_Used__c 
               from New_Dealer_Application__c
               where Id = :ndaId];
               
          //New_Dealer_Application__c nda = new New_Dealer_Application__c(id = ndaId); 
        
          nda.Dealer_Submitted__c = true; // flag as submitted
          
          // Santosh- added for WI 1670
          nda.Application_Submitted__c = true;
          
          //Santosh - changes made to reference developerNames instead of label WI 1535
          //nda.RecordTypeId = Constants.NewDealerAppRTs.get('Locked').getRecordTypeId();            
          nda.RecordTypeId = Constants.NewDealerAppRTMap.get('Locked');  
          
          nda.Applicant_Representative_s_First_Name__c =  applicantRepFirstName;
          nda.Applicant_Representative_s_Last_Name__c = applicantRepLastName;
          nda.Applicant_Representative_s_Email__c = applicantRepEmail;
          nda.Applicant_Representative_Signature_Date__c = system.now();
          
          nda.Bankruptcy_Filed__c = bankruptcy;
          if(bankruptcy == 'Yes')
            nda.Provide_Explanation_of_Bankrucptcy__c=bankruptcyDetails;
          
          nda.Pending_Legal_Proceedings__c=legalProceedings;
          if(legalProceedings == 'Yes')
            nda.Provide_Explanation_of_Legal_Proceedings__c=legalProceedingsDetails;
          
          nda.Delinquent_Taxes__c=delinquentTaxes;
          if(delinquentTaxes == 'Yes')
            nda.Provide_Explanation_unpaid_taxes__c=delinquentTaxesDetails;
          
          try
          {
            system.debug('update nda');
            update nda;
          }
          catch(Exception excp)
          {
            system.debug('exception');
            UtilityClass.logError(excp,'NDA', ndaId, 'Firstname: '+applicantRepFirstName+', Lastname: '+applicantRepLastName+', Rep Email: '+applicantRepEmail+', Bankruptcy: '+bankruptcy+', Bankruptcy Details: '+bankruptcyDetails+', Legal Proceedings: '+legalProceedings+', Legal Proceedings Details: '+legalProceedingsDetails+', Delinquent Taxes: '+delinquentTaxes+', Delinquent Taxes Details: '+delinquentTaxesDetails);
            
            bankruptcyEtcQuesErrorMessage = System.Label.Unexpected_Error_Occurred;
            return null;
          }
        
          //WI 0360 - Send incentive email to prospect dealer upon NDA app submission
        
          String manufacturer;
        
          //Retrieve value of custom setting that determines if prospect dealer incentive email should be sent
          Boolean sendIncentiveEmail;
          List<Send_Incentive_Email_Upon_App_Submission__c> sList = Send_Incentive_Email_Upon_App_Submission__c.getAll().values();
        
          if(sList != null && sList.size()>0)
          {
            sendIncentiveEmail = sList[0].Send_Email__c; 
          }
        
          //If sendIncentiveEmail is true then determine the manufacturer and the related template to use for sending the email to the prospect dealer email address
          if(sendIncentiveEmail)
          {
            for(Product_Information_For_New_Dealer_App__c p: [select id, Manufacturer__r.name, Manufacturer__r.primary_manufacturer__r.name from Product_Information_For_New_Dealer_App__c where New_Dealer_Application2__c = :nda.id])
            {
              if((p.Manufacturer__r.name != null && p.Manufacturer__r.name.contains('E-Z-GO')) || (p.Manufacturer__r.primary_manufacturer__r.name != null && p.Manufacturer__r.primary_manufacturer__r.name.contains('E-Z-GO')))
              {
                manufacturer = 'E-Z-GO';
              }
            }
          
            if(manufacturer != 'E-Z-GO')
            {
              for(Product_Information_For_New_Dealer_App__c p: [select id, Manufacturer__r.name, Manufacturer__r.primary_manufacturer__r.name from Product_Information_For_New_Dealer_App__c where New_Dealer_Application2__c = :nda.id])
              {
                if((p.Manufacturer__r.name != null && p.Manufacturer__r.name.contains('Toro')) || (p.Manufacturer__r.primary_manufacturer__r.name != null && p.Manufacturer__r.primary_manufacturer__r.name.contains('Toro')))
                {
                  manufacturer = 'Toro';
                }
              }
            }
          
            //if(manufacturer != 'E-Z-GO' && nda.Applicant_Representative_s_Email__c != null && nda.Applicant_Representative_s_Email__c != '')
            if(nda.Applicant_Representative_s_Email__c != null && nda.Applicant_Representative_s_Email__c != '')
            {
              //Create a temporary contact record to be able to send out an email using an email template
              Contact c = new Contact();
          
              c.lastname = applicantRepLastName;
              c.firstname = applicantRepFirstName;
              c.Email = applicantRepEmail;
                              
              system.debug(ndaId);
              system.debug([select id, New_Dealer_Application__c from account where New_Dealer_Application__c =: ndaId]);
              c.Accountid = [select Id, Name, New_Dealer_Application2__c, Relationship__c, New_dealer_application2__r.Account__c, Manufacturer__c, Primary_Manufacturer__c, Manufacturer__r.Primary_Manufacturer__c, Manufacturer__r.Exclusive__c, Manufacturer__r.Primary_Manufacturer__r.Exclusive__c, Manufacturer__r.Industry__c, Industry__c, Manufacturer__r.Name, Obtained_From__c, Obtained_From_Name__c
                                                                            from Product_Information_For_New_Dealer_App__c
                                                                            where New_Dealer_Application2__c = : ndaId][0].relationship__c;
          
              insert c;
          
              //Query to retrieve the Email template
              EmailTemplate et;
          
              New_Dealer_Application__c n = new New_Dealer_Application__c();
              n = [select id, assignedboardingspecialist__c, country__c, language__c from New_Dealer_Application__c where id =:ndaId][0];
          
              if(manufacturer == 'E-Z-GO')
              {
                et=[select id from EmailTemplate where name = 'Application is submitted - External EZGO'];
              }
              else if(manufacturer == 'Toro' && n.country__c == 'United States')
              {
                et=[Select id from EmailTemplate where name ='Application is submitted - External_RIA'];
              }
              else 
              {
                if(n.country__c == 'United States')
                  et=[Select id from EmailTemplate where name='Application is submitted - External TCFIF'];
                else if(n.country__c == 'Canada' && n.language__c == 'English')
                  et=[Select id from EmailTemplate where name='Application is submitted - External_CAN'];
                else if(n.country__c == 'Canada' && n.language__c == 'French Canadian')
                  et=[Select id from EmailTemplate where name='Application is submitted - External_CAN_FR'];
              }
          
              if(et != null)
              {
                //list of emails
                List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
                Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
 
                singleMail.setTargetObjectId(c.Id);
                singleMail.setTemplateId(et.Id);
                //flag to false to stop inserting activity history
                singleMail.setSaveAsActivity(false);
            
                List<User> uList = [select name, email from user where id = :n.assignedboardingspecialist__c];
                User u;
            
                if(uList != null && uList.size()>0)
                  u = uList[0];

                List<OrgWideEmailAddress> emailFromAddressList = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :u.email];
          
                List<OrgwideEmailAddress> defaultFromAddressList = [select id, address from orgwideemailaddress where address = 'enginesupport@tcfif.com'];
            
                if(emailFromAddressList != null && emailFromAddressList.size()>0)
                  singleMail.setOrgWideEmailAddressId(emailFromAddressList[0].id); 
            
                //add mail
                emails.add(singleMail);
 
                //send mail
                try
                {
                  Messaging.sendEmail(emails);
                }
                //if ISR orgwideemailaddress record is not verified etc.
                catch(Exception e)
                {
                  system.debug(e.getMessage());
                
                  if(defaultFromAddressList != null && defaultFromAddressList.size()>0)
                    singleMail.setOrgWideEmailAddressId(defaultFromAddressList[0].id);
                  
                  try
                  {
                    Messaging.sendEmail(emails);   
                  }
                  catch(Exception excp)
                  {
                    UtilityClass.logError(excp,'NDA', ndaId, 'Submission email not sent | Firstname: '+applicantRepFirstName+', Lastname: '+applicantRepLastName+', Rep Email: '+applicantRepEmail+', Bankruptcy: '+bankruptcy+', Bankruptcy Details: '+bankruptcyDetails+', Legal Proceedings: '+legalProceedings+', Legal Proceedings Details: '+legalProceedingsDetails+', Delinquent Taxes: '+delinquentTaxes+', Delinquent Taxes Details: '+delinquentTaxesDetails);  
                  }
                }
          
                //Delete the temporary contact record created just to be able to send out the email using an email template
                //WI 1030 (Remove deletion of contact so the contact is retained unlike before)
                //delete c;
              }
            }
          }
          //WI 0360 end
        
          //Added by Nimish
          applicantName = nda.Applicant_Representative_s_First_Name__c + ',' + nda.Applicant_Representative_s_Last_Name__c; 
          //
         
          //Check to see if the NDA can be Auto Decisioned         
          continueWithAutoDecisioning = autoDecHelper.isEligibleForAutoDecisioning(loggedInUserIsGuestSiteUser, nda.Id, actId);
          
          system.debug(continueWithAutoDecisioning);
          
          //showOrHideMfgList();
          
          PageReference p = Page.NewDealerAppInternalReview;
          
          p.getParameters().put('Id', nda.Id);
          p.getParameters().put('accntId', actId);
          p.getParameters().put('country',country);
          
          p.getParameters().put('prod',nda.primary_brand_requested__c);
          p.getParameters().put('prMfr',nda.manufacturer__r.name);
        
          if(nda.language__c == 'French Canadian')
            p.getParameters().put('lang', 'fr');
          else if(nda.language__c == 'English')
           p.getParameters().put('lang', 'en');
          
          if(continueWithAutoDecisioning == true)
          {
            p.getParameters().put('AD','Yes');
            stopPollingForAutoSelectedDUNS = false;
            stopPollingForSelectedDUNS = true;
          }
          else
          {
            p.getParameters().put('AD','No');
            stopPollingForAutoSelectedDUNS = true;
            stopPollingForSelectedDUNS = true;
          }   
          
          p.setredirect(true);
              
          return p; 
        }
        else if(buttonClicked == 'SaveAndCloseDontSubmitApp' && bankruptcyEtcQuesErrorMessage == '')
        {           
           New_Dealer_Application__c nda = new New_Dealer_Application__c(id = ndaId); 
        
           nda.Applicant_Representative_s_First_Name__c =  applicantRepFirstName;
           nda.Applicant_Representative_s_Last_Name__c = applicantRepLastName;
           nda.Applicant_Representative_s_Email__c = applicantRepEmail;
           nda.Bankruptcy_Filed__c = bankruptcy;
           nda.Provide_Explanation_of_Bankrucptcy__c=bankruptcyDetails;
           nda.Pending_Legal_Proceedings__c=legalProceedings;
           nda.Provide_Explanation_of_Legal_Proceedings__c=legalProceedingsDetails;
           nda.Delinquent_Taxes__c=delinquentTaxes;
           nda.Provide_Explanation_unpaid_taxes__c=delinquentTaxesDetails;
        
           update nda;
          
           PageReference finalPage = Page.NewDealerAppSaved; 
           
           if(ndaId != null && ndaId !='')
            finalPage.getParameters().put('Id', ndaId);
             
           system.debug(bankruptcyEtcQuesErrorMessage);
             
           return finalPage;   
        }
        else
        {
          system.debug(bankruptcyEtcQuesErrorMessage);
          return null;
        } 
        
        //return null;
     }
     catch(Exception excp)
     {
       system.debug('exception');
       UtilityClass.logError(excp,'NDA', ndaId, 'Firstname: '+applicantRepFirstName+', Lastname: '+applicantRepLastName+', Rep Email: '+applicantRepEmail+', Bankruptcy: '+bankruptcy+', Bankruptcy Details: '+bankruptcyDetails+', Legal Proceedings: '+legalProceedings+', Legal Proceedings Details: '+legalProceedingsDetails+', Delinquent Taxes: '+delinquentTaxes+', Delinquent Taxes Details: '+delinquentTaxesDetails);
            
       showErrorMessage = true;
       
       return null;
     }          
   }
   
   
   ///////////////////////////////////////////////////////////
   // VARIABLES AND METHODS RELATED TO NDA AUTO DECISIONING //
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
   public static final decimal pdPctThreshold = 5.13;
   public static final decimal blendedCBRThreshold = 640;
   
   public AutoDecisionHelper autoDecHelper  {get;set;}    
   public boolean continueWithAutoDecisioning {get;set;}
      
   public string selectedDUNSNumber {get;set;}
   public string autoSelectedDUNSNumber {get;set;}
   public string  dnbSelectedBusinessName {get;set;}
   
   public boolean stopPollingForAutoSelectedDUNS {get;set;}
   public boolean stopPollingForSelectedDUNS {get;set;}
   public string  showSection {get;set;}
   public string  autoDecision {get;set;}
   public string  showAutoReviewMsg {get;set;}
   public string  reasonForBusinessNameMismatchWithDnB {get;set;}
  
   public string  Name {get;set;} 
   public decimal requestedCL {get;set;}
   public decimal blendedCBR {get;set;}
   
   public integer autoSelectedDUNSCounter {get;set;}
   public integer selectedDUNSCounter {get;set;}
   public boolean numDnBMatchesGreaterThanOne {get;set;}
   public boolean ndaDealerNameMatchesDnBBussName {get;set;}  
     
   public boolean dnbLookupRequestInitiated {get;set;}
   public boolean dnbLookupResponseReceived {get;set;}
   public boolean dnbOMInputsRequestInitiated {get;set;}
   public boolean dnbOMInputsResponseReceived {get;set;}
   
  /////////////////////////////////////////////////////////////////////////////
  // END - VARIABLES AND METHODS RELATED TO NDA AUTO DECISIONING //
  /////////////////////////////////////////////////////////////////////////////
   //If all owner relationship records have a CBR Score value populated then we are ready to calculate blended CBR
   public PageReference calculateBlendedCBRAndPDForAutoSelectedDUNS()
   { 
     if(stopPollingForAutoSelectedDUNS == true)
       return null;
    
     if(nda.country__c != 'United States' || continueWithAutoDecisioning == false)
     {  
       autoDecision = 'UNDERWRITE';
       continueWithAutoDecisioning = false;
       stopPollingForAutoSelectedDUNS = true;
       showSection = 'confirmation';
       
       nda.AD_Result__c = 'Not Passed';
       setNDAADEligibilityAndModelUsed();
       update nda;
        
       return null;
     }
      
     //If none of the above conditions match, then continue with this method execution
     if(stopPollingForAutoSelectedDUNS == false)
     {
       //Set the autoSelectedDUNS counter
       if(autoSelectedDUNSCounter == null)// && showAutoReviewMsg != '')
         autoSelectedDUNSCounter = 1;
       else if(autoSelectedDUNSCounter != null)
         autoSelectedDUNSCounter++;
      
       //If PD% data not recieved after 5 polling iterations of this method, set autodecision to 'UNDERWRITE'
       if(autoSelectedDUNSCounter == 2)
       {
         autoDecision = 'UNDERWRITE';
         //showAutoReviewMsg = '';
         continueWithAutoDecisioning = false;
         stopPollingForAutoSelectedDUNS = true;
         showSection = 'confirmation';
      
         nda.AD_Result__c = 'Not Passed';
         setNDAADEligibilityAndModelUsed();
         update nda;
     
         return null;
       }
       //
       
        //Calculate Blended CBR if a valid cbr score for all owners with SSN has been retrieved from TransUnion 
        if(blendedCBR == null)
        {
          system.debug(blendedCBR);
          system.debug(autoDecHelper.getNDAOwnerIdToOwnershipPctMap(ndaId, actId));
          system.debug(autoDecHelper.getOwnerIdToCBRScoreMap(ndaId, actId));
        
          if(autoDecHelper.getOwnerIdToCBRScoreMap(ndaId, actId) != null)
          {
            blendedCBR = autoDecHelper.calculateBlendedCBRForDealer(autoDecHelper.getNDAOwnerIdToOwnershipPctMap(ndaId, actId), autoDecHelper.getOwnerIdToCBRScoreMap(ndaId, actId));

            system.debug('Just completed calculcateBlendedCBRForDealer');

            system.debug(blendedCBR);
        
            autoDecHelper.dnbHelper.blendedCBR = blendedCBR;
          }
        }
      
        //Perform DnB lookup when executing this method for the NDA only the very first time
        if(blendedCBR == null)
        {
          return null;
        }
        else 
        {   
          if(blendedCBR == -1)
          {
            autoDecision = 'UNDERWRITE';
            nda.AD_Result__c = 'Not Passed';
                        
            setNDAADEligibilityAndModelUsed();
            update nda;
            
            continueWithAutoDecisioning = false;
            stopPollingForAutoSelectedDUNS = true;
            showSection = 'confirmation';
            return null;
          }
          else if(blendedCBR != -1 && blendedCBR > blendedCBRThreshold)
          { 
          
            nda.blended_cbr_score__c = blendedCBR;
          
            //If blendedCBR is calculated successfully, do a DNB Lookup to inititate the steps to gather DnB variables to input to OM
            if(dnbLookupRequestInitiated != true)
            {
              dnbLookupRequestInitiated = true;
              autoDecHelper.dnbHelper.dnbLookup(actId);
              dnbLookupResponseReceived = true;
        
              //If more than one business matches are returned by DnB, exit this method and ask user to fisrt select a DUNS number  
              if(dnbLookupResponseReceived && autoDecHelper.dnbHelper.lookupResponseWrapperList != null && autoDecHelper.dnbHelper.lookupResponseWrapperList.size() > 1)
              {     
                numDnBMatchesGreaterThanOne = true;
          
                stopPollingForAutoSelectedDUNS = true;
                return null;
              }
              //If exactly one business matches are returned by DnB, check to see if the NDA Account name matches the business name returned by DnB 
              else if(dnbLookupResponseReceived && autoDecHelper.dnbHelper.lookupResponseWrapperList != null && autoDecHelper.dnbHelper.lookupResponseWrapperList.size() == 1)
              {
                autoSelectedDUNSNumber = autoDecHelper.dnbHelper.lookupResponseWrapperList[0].DUNSNumber;
            
                numDnBMatchesGreaterThanOne = false;
              
                if(dnbOMInputsRequestInitiated != true)
                {
                  requestedCL=nda.What_is_your_requested_line_of_credit__c;
                    
                  //Get PD And Pkt46 info. for this DUNSNumber if the DnB business name matches NDA Account Name
                  dnbOMInputsRequestInitiated = true;
                  autoDecHelper.getDnBDataComputePDAndGetPkt46(actId, autoSelectedDUNSNumber);
                  
                  dnbOMInputsResponseReceived = true;
              
                  ndaDealerNameMatchesDnBBussName = ndaDealerEntityNameMatchesDnBSelectedBusinessName(autoSelectedDUNSNumber);
                }
              
                //If NDA account name does not match with autoSelected DnB business name, set auto decision to 'UNDERWRITE'
                if(ndaDealerNameMatchesDnBBussName == false)
                {
                  autoDecision = 'UNDERWRITE';
      
                  continueWithAutoDecisioning = false;
                
                  stopPollingForAutoSelectedDUNS = true;
                  showSection = 'businessNameMismatch';
          
                  nda.AD_Result__c = 'Not Passed';
                  setNDAADEligibilityAndModelUsed();
                  update nda;
          
                  return null;
                }
                else
                {
                  if(autoDecHelper.dnbHelper.omPkt46Wrapper != null && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs != null && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.twelveMonthPDPct != null)
                  { 
                    if(autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.twelveMonthPDPct <= pdPctThreshold)
                    {
                      autoDecision = 'APPROVED';
            
                      if(autoDecHelper.ndaHasOverrides(nda.Id) == true) 
                      {
                        nda.AD_Result__c = 'Approved w/Override';
                      }
                      else
                      {
                        nda.AD_Result__c = 'Approved';
                      }
            
                      setNDAADEligibilityAndModelUsed();
                      update nda;
 
                      continueWithAutoDecisioning = false;
                      stopPollingForAutoSelectedDUNS = true;
                      showSection = 'confirmation';
            
                      //Update overrides info on the relationship as appropriate
                      Account a = [select id, X1_Year_In_Business__c, Known_Material_Liens_Suits_Judgements__c, Current_Bankruptcy__c, Prior_Bankruptcy__c from account where id=:actId LIMIT 1];
         
                      if((system.today().year() - Integer.valueof(nda.What_year_was_your_business_founded__c)) < 1)
                      {
                        a.X1_Year_In_Business__c = true;    
                      }
         
                      if(nda.Bankruptcy_Filed__c.equalsignorecase('Yes'))
                      { 
                        a.Current_Bankruptcy__c = true;
                        a.Prior_Bankruptcy__c = true;
                      }
         
                      if(nda.Delinquent_Taxes__c.equalsignorecase('Yes') || nda.Pending_Legal_Proceedings__c.equalsignorecase('Yes'))
                      {
                        a.Known_Material_Liens_Suits_Judgements__c = true;
                      }
         
                      update a;
                                      
                      /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
                      //Create a dnb junction record and mark it as used for decision, if one does not exist and if CARE Underwriting and OM Record already exists.  //
                      //Also update the WMS Underwriting Lookup field on the OM Record                                                                               //
                      /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                      //createDnBJunctionRecordAndUpdateOMRecord();
                    } 
                    else if(autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.twelveMonthPDPct > pdPctThreshold)
                    {
                      autoDecision = 'UNDERWRITE';
                      nda.AD_Result__c = 'Not Passed';
                      setNDAADEligibilityAndModelUsed();                      
          
                      update nda;
            
                      continueWithAutoDecisioning = false;
                      stopPollingForAutoSelectedDUNS = true;
                      showSection = 'confirmation';
                    }
                  }
                }
              }
            }
          }
        }
      }
             
      return null;
   }
   
   //If all owner relationship records have a CBR Score value populated then we are ready to calculate blended CBR
   public PageReference calculateBlendedCBRAndPDForSelectedDUNS()
   { 
      numDnBMatchesGreaterThanOne = true;

      if(nda.country__c != 'United States' || continueWithAutoDecisioning == false)
      {  
       autoDecision = 'UNDERWRITE';
       continueWithAutoDecisioning = false;
       stopPollingForSelectedDUNS = true;
       showSection = 'confirmation';
       
       nda.AD_Result__c = 'Not Passed';
       setNDAADEligibilityAndModelUsed();
       update nda;
        
       return null;
      }
      
     //If none of the above conditions match, then continue with this method execution
     if(stopPollingForSelectedDUNS == false)
     {
       //Set the autoSelectedDUNS counter
       if(selectedDUNSCounter == null)// && showAutoReviewMsg != '')
       {
         selectedDUNSCounter = 1;
         dnbLookupRequestInitiated = false;
       }
       else if(selectedDUNSCounter != null)
       {
         selectedDUNSCounter ++;
       }
       
       //If PD% data not recieved after 5 polling iterations of this method, set autodecision to 'UNDERWRITE'
       if(selectedDUNSCounter == 2)
       {
         autoDecision = 'UNDERWRITE';
         //showAutoReviewMsg = '';
         continueWithAutoDecisioning = false;
         stopPollingForSelectedDUNS = true;
         showSection = 'confirmation';
      
         nda.AD_Result__c = 'Not Passed';
         setNDAADEligibilityAndModelUsed();
         update nda;
     
         return null;
       }
       //
       
        //Calculate Blended CBR if a valid cbr score for all owners with SSN has been retrieved from TransUnion 
        if(blendedCBR == null)
        {
          system.debug(blendedCBR);
          system.debug(autoDecHelper.getNDAOwnerIdToOwnershipPctMap(ndaId, actId));
          system.debug(autoDecHelper.getOwnerIdToCBRScoreMap(ndaId, actId));
        
          if(autoDecHelper.getOwnerIdToCBRScoreMap(ndaId, actId) != null)
          {
            blendedCBR = autoDecHelper.calculateBlendedCBRForDealer(autoDecHelper.getNDAOwnerIdToOwnershipPctMap(ndaId, actId), autoDecHelper.getOwnerIdToCBRScoreMap(ndaId, actId));

            system.debug('Just completed calculcateBlendedCBRForDealer');

            system.debug(blendedCBR);
        
            autoDecHelper.dnbHelper.blendedCBR = blendedCBR;
          }
        }
      
        //Perform DnB lookup when executing this method for the NDA only the very first time
        if(blendedCBR == null)
        {
          return null;
        }
        else 
        {   
          if(blendedCBR == -1)
          {
            autoDecision = 'UNDERWRITE';
            nda.AD_Result__c = 'Not Passed';
                        
            setNDAADEligibilityAndModelUsed();
            update nda;
            
            continueWithAutoDecisioning = false;
            stopPollingForSelectedDUNS = true;
            showSection = 'confirmation';
            return null;
          }
          else if(blendedCBR != -1 && blendedCBR > blendedCBRThreshold)
          { 
            nda.blended_cbr_score__c = blendedCBR;
            
            //If blendedCBR is calculated successfully, do a DNB Lookup to inititate the steps to gather DnB variables to input to OM
            if(dnbLookupRequestInitiated != true)
            {
              dnbLookupRequestInitiated = true;
              //autoDecHelper.dnbHelper.dnbLookup(actId);
              dnbLookupResponseReceived = true;
        
              //If more than one business matches are returned by DnB, exit this method and ask user to fisrt select a DUNS number  
              //if(dnbLookupResponseReceived && autoDecHelper.dnbHelper.lookupResponseWrapperList != null && autoDecHelper.dnbHelper.lookupResponseWrapperList.size() > 1)
              //{     
                //numDnBMatchesGreaterThanOne = true;
          
                //stopPollingForSelectedDUNS = true;
                //return null;
              //}
              //If exactly one business matches are returned by DnB, check to see if the NDA Account name matches the business name returned by DnB 
              /*else */
              if(selectedDUNSNumber != '' && selectedDUNSNumber != null)// && dnbLookupResponseReceived && autoDecHelper.dnbHelper.lookupResponseWrapperList != null && autoDecHelper.dnbHelper.lookupResponseWrapperList.size() == 1)
              {
                numDnBMatchesGreaterThanOne = false;
              
                if(dnbOMInputsRequestInitiated != true)
                {
                  requestedCL=nda.What_is_your_requested_line_of_credit__c;
                    
                  //Get PD And Pkt46 info. for this DUNSNumber if the DnB business name matches NDA Account Name
                  dnbOMInputsRequestInitiated = true;
                  autoDecHelper.getDnBDataComputePDAndGetPkt46(actId, selectedDUNSNumber);
                  dnbOMInputsResponseReceived = true;
              
                  ndaDealerNameMatchesDnBBussName = ndaDealerEntityNameMatchesDnBSelectedBusinessName(selectedDUNSNumber);
                }
              
                //If NDA account name does not match with autoSelected DnB business name, set auto decision to 'UNDERWRITE'
                if(ndaDealerNameMatchesDnBBussName == false)
                {
                  autoDecision = 'UNDERWRITE';
      
                  continueWithAutoDecisioning = false;
                
                  stopPollingForSelectedDUNS = true;
                  showSection = 'businessNameMismatch';
          
                  nda.AD_Result__c = 'Not Passed';
                  setNDAADEligibilityAndModelUsed();
                  update nda;
          
                  return null;
                }
                else
                {
                  if(autoDecHelper.dnbHelper.omPkt46Wrapper != null && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs != null && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.twelveMonthPDPct != null)
                  { 
                    if(autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.twelveMonthPDPct <= pdPctThreshold)
                    {
                      autoDecision = 'APPROVED';
            
                      if(autoDecHelper.ndaHasOverrides(nda.Id) == true) 
                      {
                        nda.AD_Result__c = 'Approved w/Override';
                      }
                      else
                      {
                        nda.AD_Result__c = 'Approved';
                      }
            
                      setNDAADEligibilityAndModelUsed();
                      update nda;
 
                      continueWithAutoDecisioning = false;
                      stopPollingForSelectedDUNS = true;
                      showSection = 'confirmation';
            
                      //Update overrides info on the relationship as appropriate
                      Account a = [select id, X1_Year_In_Business__c, Known_Material_Liens_Suits_Judgements__c, Current_Bankruptcy__c, Prior_Bankruptcy__c from account where id=:actId LIMIT 1];
         
                      if((system.today().year() - Integer.valueof(nda.What_year_was_your_business_founded__c)) < 1)
                      {
                        a.X1_Year_In_Business__c = true;    
                      }
         
                      if(nda.Bankruptcy_Filed__c.equalsignorecase('Yes'))
                      { 
                        a.Current_Bankruptcy__c = true;
                        a.Prior_Bankruptcy__c = true;
                      }
         
                      if(nda.Delinquent_Taxes__c.equalsignorecase('Yes') || nda.Pending_Legal_Proceedings__c.equalsignorecase('Yes'))
                      {
                        a.Known_Material_Liens_Suits_Judgements__c = true;
                      }
         
                      update a;
                                      
                      /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
                      //Create a dnb junction record and mark it as used for decision, if one does not exist and if CARE Underwriting and OM Record already exists.  //
                      //Also update the WMS Underwriting Lookup field on the OM Record                                                                               //
                      /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                      //createDnBJunctionRecordAndUpdateOMRecord();
                    } 
                    else if(autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.twelveMonthPDPct > pdPctThreshold)
                    {
                      autoDecision = 'UNDERWRITE';
                      nda.AD_Result__c = 'Not Passed';
                      setNDAADEligibilityAndModelUsed();                      
          
                      update nda;
            
                      continueWithAutoDecisioning = false;
                      stopPollingForSelectedDUNS = true;
                      showSection = 'confirmation';
                    }
                  }
                }
              }
            }
          }
        }
      }
             
      return null;
      
      
   }
   
   //Set one of the DnB variables to null, so simulate the fact that the OM model cannot run
   private void setDnBOMInputVariableNullForTestingPurposes()
   {
     autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.delScoreAggrFromDnB = null;
   }
   
   
   //If requested credit amount <= 750k and the OM model can be run (Blended CBR Score > 0 and the 3 DnB variables are have valid values for OM Input), 
   //then AD Eligible = true, else false
   private void setNDAADEligibilityAndModelUsed()
   {
     //setDnBOMInputVariableNullForTestingPurposes();
    
     //New_Dealer_Application__c n = new New_Dealer_Application__c(id=nda.Id);
     
     if(nda.what_is_your_requested_line_of_credit__c <= 750000)             
     {
       //The following conditions would have had to be true for the NDA to show Internal Review page (to run the OM).
       //So if the credit line <= 750000 && additional following conditions were true then the application was ADEligible, else not.
       if(
             blendedCBR > 0
          && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs != null 
          && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.delScoreAggrUsedForPDCalc != null 
          //&& autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.numSatisfactoryPmtsUsedForPDCalc != null 
          //&& autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.num120DaysOverdueUsedForPDCalc != null
       )
       {
         nda.AD_Eligible__c = 'Yes';
         nda.AD_Model_Used__c = 'OM';  
       }
       else
       {
         nda.AD_Eligible__c = 'No';
         nda.AD_Model_Used__c = 'OM-NA';
       }
     }
     else
     {
       nda.AD_Eligible__c = 'No';
       //AD Model Used will be left blank 
     }
   }
   
   //Initiate retrieval of PD% for selectedDUNS
   public void getPDForSelectedDUNS()
   {
      stopPollingForSelectedDUNS = false;
            
      ndaDealerNameMatchesDnBBussName = ndaDealerEntityNameMatchesDnBSelectedBusinessName(selectedDUNSNumber);
   } 
   
   public boolean ndaDealerEntityNameMatchesDnBSelectedBusinessName(string DUNSNumber)
   {
     boolean businessesMatch = false;
     system.debug(DUNSNumber);
     
     system.debug(autoDecHelper.dnbHelper.lookupResponseWrapperList);
      
     if(autoDecHelper.dnbHelper.lookupResponseWrapperList != null && autoDecHelper.dnbHelper.lookupResponseWrapperList.size() > 0)
     {      
       for(CommonWrapperClass.DnBLookupIOWrapper dnbLkup: autoDecHelper.dnbHelper.lookupResponseWrapperList)
       {
         system.debug(dnbLkup);
         
         if(DUNSNumber.equals(dnbLkup.DUNSNumber))
         {
           dnbSelectedBusinessName = dnbLkup.name;
           system.debug(dnbSelectedBusinessName);
           
           break;
         }  
      }
       
       system.debug(nda.Legal_Business_Name__c);
       
       New_Dealer_Application__c n = [select id, legal_business_name__c from New_Dealer_Application__C where id=:ndaId LIMIT 1];
       
       system.debug(n.legal_business_name__c);
     
     
       if(nda.Legal_Business_Name__c.toUpperCase().remove('LLC').remove('INC').remove('INCORPORATED').remove('CORPORATION').remove('CORP').remove('AND').normalizeSpace().trim().remove('.').remove(',').remove('&').replaceAll('\\s+','').
       equalsignorecase(dnbSelectedBusinessName.toUpperCase().remove('LLC').remove('INC').remove('INCORPORATED').remove('CORPORATION').remove('CORP').remove('AND').normalizeSpace().trim().remove('.').remove(',').remove('&').replaceAll('\\s+','')))
       {
         businessesMatch=true;
       }
     }
     
     return businessesMatch;
   }
   
   public PageReference getPDAndPkt46ForSelectedDUNS()
   {  
       system.debug(actId+','+selectedDUNSNumber);
    
       autoDecHelper.getDnBDataComputePDAndGetPkt46(actId, selectedDUNSNumber);
       
       if(autoDecHelper.dnbHelper.omPkt46Wrapper != null && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs != null && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.twelveMonthPDPct <= pdPctThreshold)
       {
         autoDecision = 'APPROVED';
         showAutoReviewMsg = '';
         continueWithAutoDecisioning = false;
       } 
       else if(autoDecHelper.dnbHelper.omPkt46Wrapper != null && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs != null && autoDecHelper.dnbHelper.omPkt46Wrapper.omInputsOutputs.twelveMonthPDPct > pdPctThreshold)
       {
         autoDecision = 'UNDERWRITE';
         showAutoReviewMsg = '';
         continueWithAutoDecisioning = false;
       }
       
       system.debug(autoDecision);
       
       return null;  
   }
   
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
   //Create a dnb junction record and mark it as used for decision, if one does not exist and if CARE Underwriting and OM Record already exists  //
   //Also update the WMS Underwriting Lookup field on the OM Record                                                                              //
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   
   ///////////////////////////////////////////////////////////////////////////////
   //Prepare the list of DnB lookup results returned by DnB for the NDA Account //
   ///////////////////////////////////////////////////////////////////////////////   
   public List<selectOption> DUNSNbrOptionsList 
   {
      get
      {          
        List<selectOption> sList = new List<selectOption>();
   
        integer count=1; 
      
       if(autoDecHelper.dnBHelper.lookupResponseWrapperList != null)
       {
         for(CommonWrapperClass.DnBLookupIOWrapper l: autoDecHelper.dnBHelper.lookupResponseWrapperList)
         {      
           sList.add(new SelectOption(l.DUNSNumber, '('+count+'-'+l.DUNSNumber+') ' +l.Name+': '+l.streetAddress+', '+l.city+', '+l.state+', '+l.zipCode+', '+'US'+', PHONE: '+l.phoneNumber));
           count++;
         }
         
         if(autoDecHelper.dnBHelper.lookupResponseWrapperList.size() > 1)
         {
           sList.add(new SelectOption('None', 'None of the above'));
         } 
       }
       
       return sList;
     }
     set;
   }
   
   public PageReference updateNDAWithBusinessNameMismatchReason()
   {
     New_Dealer_Application__c n = [select id, reasonForBusNameMismatchWithDnB__c from New_Dealer_Application__c where id=:ndaId LIMIT 1];
     n.reasonForBusNameMismatchWithDnB__c = reasonForBusinessNameMismatchWithDnB;
     update n;
     
     showSection = 'confirmation';
     
     return null;
      
   }   
   
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // END - VARIABLES AND METHODS RELATED TO NDA AUTO DECISIONING //
  /////////////////////////////////////////////////////////////////
   
    // Attachments upload
    public boolean addattachments {get; set;}
    public Attachment attachment {
    get {
          if (attachment == null)
            attachment = new Attachment();
          return attachment;
    }
    set;
    }
    
    //Content Version upload
    public List<ContentVersion>  existingContentVersionsList {get;set;}
    public boolean addContentVersions {get;set;}
    
    public void showExistingContentVersions()
    {
      List<ContentDocumentLink> existingContentDocumentLinksList = [select Id, ContentDocumentId, ContentDocument.latestPublishedVersionId, linkedEntityId from ContentDocumentLink where linkedEntityId = :nda.Id and (NOT ContentDocument.LatestPublishedVersion.FileType = 'SNOTE')];
      
      List<id> existingContentVersionIdsList = new List<id>(); 
      
      for(ContentDocumentLink cdl :existingContentDocumentLinksList)
      {
        existingContentVersionIdsList.add(cdl.ContentDocument.latestPublishedVersionId);
      }
      
      existingContentVersionsList = new List<ContentVersion>();
      existingContentVersionsList = [select id, ContentDocumentId, ContentType__c, title, createdDate from ContentVersion where id in: existingContentVersionIdsList];
      
      addAttachments=true;
      addContentVersions = true;
    }
    
    public ContentVersion cVersion 
    {
      get 
      {
        if (cVersion == null)
          cVersion = new ContentVersion();
            
        return cVersion;
      }
    set;
    }
    
    public PageReference upload() 
    {        
      if(attachment.name == null || attachment.name == '' || attachment.body == null || string.isBlank(selectedNDAContentType))
      {
        if(attachment.name == null || attachment.name == '') 
          pageMessage = 'Please provide a file name.';
        if(attachment.body == null) 
          pageMessage = 'No file selected';
        if(string.isBlank(selectedNDAContentType))
          pageMessage = 'Please select a document type.';

        return null;       
      }
      else
      {
        if(attachment.name.length() > 80)
        {  
          attachment.name = attachment.name.substring(0,80); 
        }
            
        try 
        {
          UtilityClass.createAndInsertFile(nda.id, attachment.name, attachment.body, selectedNDAContentType, null,'');
        }
        catch (DMLException e) 
        {
          pageMessage = 'Error uploading file: ' + e;
          ApexPages.currentPage().getParameters().put('Id',ndaId);
          return null;
        }
      }
    
      PageReference samePage = Page.NewDealerAppDocuments;
     
      if(ndaId != null && ndaId !='')
        samePage.getParameters().put('Id', ndaId);
                          
      samePage.getParameters().put('country',nda.country__c);
      samePage.getParameters().put('prod',nda.primary_brand_requested__c);
      samePage.getParameters().put('prMfr',nda.manufacturer__r.name);
       
      if(nda.language__c == 'French Canadian')
        samePage.getParameters().put('lang', 'fr');
      else if(nda.language__c == 'English')
        samePage.getParameters().put('lang', 'en');  
                        
      samePage.setRedirect(true);
      
      return samePage; 
    } 
       

   public static String formatCurrency(Decimal amount, Boolean isAmerican) {//300,200,100.99
          String fractionalSeparator = isAmerican ? '.' : ',';
          String suffix = isAmerican ? '' :  ' $';
          
          boolean containsDecimal = amount.scale() > 0;          
          Integer withoutDecimalAmount = (Integer) amount.round(System.RoundingMode.DOWN); 
          
          string formattedCurrency = formatCurrency(string.valueof(withoutDecimalAmount), isAmerican, containsDecimal);
          if (containsDecimal)
          {
                 return formattedCurrency + fractionalSeparator + String.valueOf(amount - withoutDecimalAmount).subString(amount.scale()) + suffix;
          }
          
          return formattedCurrency;
   }
   
   public static String formatCurrency(string amount, Boolean isAmerican, Boolean excludeSuffix) {
          String thousandsSeparator = isAmerican ? ',' : ' ';          
          String suffix = isAmerican ? '' : excludeSuffix ? '' :  ' $';
          String prefix = isAmerican ? '$' : '';
           
          if(amount == null) return  prefix + '0' + suffix;                   
          
          string stringamount = amount;
          if(isAmerican){
              if(stringAmount.length() > 3) {//300100
                     return formatCurrency(stringAmount.subString(0, stringAmount.length() - 3), isAmerican, excludeSuffix) + thousandsSeparator + stringAmount.subString(stringAmount.length() - 3);
              }
              
              return prefix + stringAmount;
          }else{         
              if(stringAmount.length() > 3) {
                    Integer stringLength = math.mod(stringAmount.length(), 3) == 0 ? 3 : math.mod(stringAmount.length(), 3);
                     return stringAmount.subString(0, stringLength) + thousandsSeparator + formatCurrency(stringAmount.subString(stringLength, stringAmount.length()), isAmerican, excludeSuffix);
              }
              
              return stringAmount + suffix; 
          }
   }    
    
   public class BankPdfWrapper{
        public Bank__c b {get;set;}
        public string creditAmount {get;set;}
        public string avgBalance {get;set;}
        public string name {get;set;}
        public BankPdfWrapper(Bank__c bank, Boolean isUS){
            b = bank; 
            name = (bank.name == string.valueof(bank.id)) || bank.name.contains('a48') ? '' : bank.name;
            creditAmount = b.Credit_Amount__c != null ? formatCurrency(b.Credit_Amount__c, isUS) : '';
            avgBalance = b.Average_Balance__c != null ? formatCurrency(b.Average_Balance__c, isUS) : '';
        }
    }
    
    public List<sobject> checkListForDeleted(List<sobject> r, string objType){
        set<id> recordIds = new set<id>();
        Map<id,boolean> inTrash = new Map<id,boolean>();
        
        if(objType == 'Bank__c'){
            List<Bank__c> tempL = (List<Bank__c>)r;
            List<Bank__c> resultList = new List<Bank__c>();
            for(Bank__c b: tempL){
                recordIds.add(b.id);
            }
            for(Bank__c b : [select Id, IsDeleted from Bank__c where id =: recordIds ALL ROWS]){
               inTrash.put(b.id,b.isdeleted);                 
            }
            for(Bank__c b: tempL){
                if(!inTrash.get(b.id)){
                    resultList.add(b);
                }
            }
            return resultList;
        }
        
        else if(objType == 'Additional_Location__c'){
            List<Additional_Location__c> tempL = (List<Additional_Location__c>)r;
            List<Additional_Location__c> resultList = new List<Additional_Location__c>();
            for(Additional_Location__c b: tempL){
                recordIds.add(b.id);
            }
            for(Additional_Location__c b : [select Id, IsDeleted from Additional_Location__c where id =: recordIds ALL ROWS])
            {
               inTrash.put(b.id,b.isdeleted);                 
            }
            for(Additional_Location__c b: tempL){ 
                if(!inTrash.get(b.id)){ 
                    resultList.add(b);
                }
            }
            return resultList;
        }
    
        return null;
    }
    
    public class NdaPdfWrapper
    {     
        public New_dealer_Application__c app {get;set;}
        public string creditLineRequested {get;set;} 
        public string annualGrossRev {get;set;}
        public string inventoryInsuranceCarrier {get;set;}
        public Decimal inventoryInsuranceCoverageAmount {get;set;}
        public string policyNumber {get;set;}
        public string policyRenewalDate {get;set;}
        public string agentFirstName {get;set;}
        public string agentLastName {get;set;}
        public string agentPhoneNumber {get;set;}
        
        public NdaPdfWrapper(New_dealer_application__c nda, Boolean isUS, Boolean AU_NZ_Support){
          try
          {       
            app = nda;
            creditLineRequested = nda.What_is_your_requested_line_of_credit__c != null ? formatCurrency(nda.What_is_your_requested_line_of_credit__c, isUS) : '';
            annualGrossRev = nda.Annual_Gross_Revenue__c != null ? formatCurrency(nda.Annual_Gross_Revenue__c, isUS) : '';
            inventoryInsuranceCarrier = nda.inventory_insurance_carrier__c; 
            inventoryInsuranceCoverageAmount = nda.inventory_insurance_coverage_amount__c;
            policyNumber = nda.policy_number__c;
            
            system.debug(nda.country__c);
            
            //US application 
            if(nda.country__c == 'United States')
            {
              string dt = nda.policy_renewal_date__c;
              
              if(dt != null && dt != '')
                policyRenewalDate = getMonthNameFromNumber(Integer.valueOf(dt.substring(0,2)), 'US_EN') + ' ' + dt.substring(3,5) + ', ' + dt.substring(6,10);
            }
            //Canada application
            else if(nda.country__c == 'Canada') 
            { 
              string dt = nda.policy_renewal_date__c;
              
              if(dt != null && dt != '')
              {                            
                if(nda.language__c == 'French Canadian')
                  policyRenewalDate = getMonthNameFromNumber(Integer.valueOf(dt.substring(3,5)), 'CA_FR') + ' ' + dt.substring(0,2) + ', ' + dt.substring(6,10);
                else if(nda.language__c == 'English')
                  policyRenewalDate = getMonthNameFromNumber(Integer.valueOf(dt.substring(3,5)), 'CA_EN') + ' ' + dt.substring(0,2) + ', ' + dt.substring(6,10);
              }
            }
            //Australia application
            else if(AU_NZ_Support && nda.country__c == 'Australia') 
            { 
              string dt = nda.policy_renewal_date__c;
              
              if(dt != null && dt != '')
              {                            
                policyRenewalDate = getMonthNameFromNumber(Integer.valueOf(dt.substring(3,5)), 'AU_EN') + ' ' + dt.substring(0,2) + ', ' + dt.substring(6,10);
              }
            }
            //New Zealand application
            else if(AU_NZ_Support && nda.country__c == 'New Zealand') 
            { 
              string dt = nda.policy_renewal_date__c;
              
              if(dt != null && dt != '')
              {                            
                policyRenewalDate = getMonthNameFromNumber(Integer.valueOf(dt.substring(3,5)), 'NZ_EN') + ' ' + dt.substring(0,2) + ', ' + dt.substring(6,10);
              }
            }    
            
            agentFirstName = nda.agent_first_name__c;
            agentLastName =  nda.agent_last_name__c;
            agentPhoneNumber = nda.agent_phone_number__c;            
          }
          catch(Exception excp)
          {
            UtilityClass.logError(excp, 'NDA', nda.Id, 'Credit Line Requested: '+creditLineRequested+', Annual Gross Revennue: '+annualGrossRev+', Inventory Insurance Carrier: '+inventoryInsuranceCarrier+', Inventory Insurance Coverage Amount: '+inventoryInsuranceCoverageAmount+' Policy Number: ,'+policyNumber+', Policy Renewal Date: '+policyRenewalDate+', Agent Firstname: '+agentFirstName+', Agent Lastname:'+agentLastName+', Agent Phone Number'+agentPhoneNumber);
          }
        }
    }
    
       /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //This method is created only for test class purpose. This sets the ndaId field.
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public void setNdaId()
    {
        if(this.nda!=null)     
            ndaId=this.nda.id;
            
        corpOwnerList=new List<corpOwner>();
        indOwnerList = new List<IndOwner>();
    }
    
     public static void savePdf(Id ndaId, String language, String fileNameStr) 
    {
        try
        {
            String langCode ='';
            if(language.toLowercase() =='english')
            {
                langCode ='en';
            }
            else if(language.toLowercase() =='french canadian')
            {
                langCode ='fr';
            }
            
            String siteURL =constructSiteURl();
          
            String partialURL =siteURL+'/apex/newdealerappPDFView?Id='+ndaId+'&lang='+langcode;
            System.debug('=== partialURL ==='+partialURL);
            PageReference pdf =  new PageReference(partialURL);
       
            underwriting__c uw=[select id, initiating_Account__c, initiating_Account__r.Name from underwriting__c where connected_request__c=:ndaId AND underwriting_Request_level__c ='CARE Level' limit 1];
            
            // the contents of the attachment from the pdf
            // returns the output of the page as a PDF
            Blob body= pdf.getContent();
            system.debug('=== body ==='+body);
 
            
            String initName='';
            initName= uw.initiating_Account__r.Name;
            string dateFormat =system.now().format()+'.pdf';
            String fileName = String.isNotBlank(fileNameStr)?(fileNameStr+'_'+initName+'_'+dateFormat): ('Original_App_Submission_'+initName+'_'+dateFormat);
            
            if(fileName.length()>255)
            {
                fileName= fileName.substring(0,255-(dateFormat.length()+1))+'_'+dateFormat;
            }
            utilityClass.createAndInsertFile(uw.id,fileName , body, 'Customer Application', Date.today(), 'DocVault Default Library');
        }
        catch(exception e)
        {
             String message ='Error occured while download NDA PDF file on NDA Verification screen '+'NDA Id : '+ndaId+' Error message : '+e.getMessage();
             utilityClass.logError(e, 'Error occured while download NDA PDF file on NDA Verification screen', '', message);
        }
  }
  
  public static string constructSiteURl()
  {
      String sandboxName='';
      String siteFullUrl='';
      Site site = [SELECT GuestUserId, Name, Subdomain, UrlPathPrefix FROM Site WHERE Name = 'Application'];
      Organization org = [SELECT InstanceName, IsSandbox, OrganizationType FROM Organization];      
      
      if(org.IsSandbox)
      {
            sandboxName =URL.getSalesforceBaseUrl().getHost().substringBetween('--','.')+'-';
      }
      
      if(String.isNotBlank(sandboxName))
      {
           siteFullUrl  = 'https://'+sandboxName + site.Subdomain + '.';    
      }
      else
      {
           siteFullUrl = 'https://' + site.Subdomain + '.'; 
      }
        
      system.debug('=== siteFullUrl 1==='+siteFullUrl);
      siteFullUrl += (org.IsSandbox || org.OrganizationType == 'Developer Edition' ? (org.InstanceName.toLowerCase() + '.') : '') + 'force.com';
      system.debug('=== siteFullUrl 2==='+siteFullUrl);
      siteFullUrl += '/' + site.UrlPathPrefix;
      return siteFullUrl;
  }
}