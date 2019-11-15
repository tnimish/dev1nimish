//Common wrapper class that contains different wrapper classes to hold various data

public class CommonWrapperClass 
{
  /**********************************/
  /* Wrapper class to display Tasks */
  /**********************************/
      
  public class TaskWrapper 
  {            
    @AuraEnabled public string  taskId;
    @AuraEnabled public string  subject;
    @AuraEnabled public string  assignedTo;
    @AuraEnabled public string  whoId;
    @AuraEnabled public string  whoIdName;
    @AuraEnabled public string  whoIdURL;
    @auraEnabled public string  whatId;
    @AuraEnabled public string  whatIdName;
    @AuraEnabled public string  whatIdURL;
    @AuraEnabled public boolean displayWhoId;
    @AuraEnabled public boolean displayWhatId;
    @AuraEnabled public string  dueDate;
    @AuraEnabled public boolean dueDatePassed;
    @AuraEnabled public string  status;
    @AuraEnabled public string  description;
    @AuraEnabled public string  recordURL;
    @AuraEnabled public string  ownerIdURL;
    @AuraEnabled public string  editURL;
    @AuraEnabled public boolean taskIsClosed;
    @AuraEnabled public string  taskCompletionDate;  
    @AuraEnabled public boolean taskIsArchived;
    @AuraEnabled public string  lastModifiedDate;
  }
  
  //Data retrieved for a dealer from DnB
  public class DnBLookupIOWrapper
  {
    public string name {get;set;}
    public string DUNSNumber {get;set;}
    public string streetAddress {get;set;}
    public string city {get;set;}
    public string zipcode {get;set;}
    public string phoneNumber {get;set;}
    public string state {get;set;}
    public string countryCode {get;set;} 
  }
  
  //Data retrieved from DnB Packet 46
  public class Packet46Wrapper
  {
    public integer numUSP46PacketsReceived {get;set;}
    public string  usp46_sos_province_name {get;set;}
    public string  usp46_name_type {get;set;}
    public string  usp46_reg_type {get;set;}
    public string  usp46_sos_status {get;set;}
    public string  usp46_verification_date {get;set;}
    public string  usp46_annual_report_due_date {get;set;}
    public string  usp46_annual_report_filed_date {get;set;}
    public string  usp46_annual_report_mailed_date {get;set;}
    public string  usp46_annual_report_delq_date {get;set;}
    public string  usp46_last_annual_report_date {get;set;}
  }
  
  //Wrapper class to store OM inuts and outputs and Pkt46
  public class OMAndPkt46DataWrapper
  {
    public OriginationModel.OriginationModelInputsAndOutputs omInputsOutputs {get;set;}
    public Packet46Wrapper                                   pkt46Wrapper {get;set;}
  }
  
  public class communicationScheduleWrapper
   {
        public String accountId;
        public String caseId;
        public List<Task> directContactTaskList;
        public Messaging.SingleEmailMessage email;
        public error__c e;   
   }
 
   // This wrapper class is used in utilityClass
   public Class cbrScoreWrapper 
    {
          public account primaryAccount;
          public decimal cbScore;
          public String errorMessage;
    }
     // This wrapper class is used in utilityClass
    public class downloadURLWrapperClass
    {
        public blob responseAsBlob ;
        public error__c e;
        public Integer responseCode;
    }
    
    // This wrapper class is used in RelatedDeficientCaseWidgetVFC, supports a single activity related to the case
    public class caseWithOpenTaskWrapper
    {
        public Case c {get; set;}
        public Task t {get; set;}
        public boolean SaveTask {get; set;}
        public User taskOwner {get; set;}
        public date LastActivityDate {get; set;}
        public Financial_Statement_Requirements__c fsr {get; set;} //added 5.16.19 for WI 2964   
        public boolean readOnly {get; set;} //added 7.24.19 for WI 3806     
    }
    
    // This wrapper class is used in UtilityClass, to handle saving an Account while checking for duplicate matching rules
    public class accountWithDuplicateSaveResultWrapper{
        public Account a {get; set;}
        public Boolean IsSuccess = false;
        public set<id> duplicateMatchIds {get; set;} 
        public string errorMessage {get; set;}   
        public exception e {get; set; }
        public Boolean getIsSuccess(){
            if(IsSuccess == null){ IsSuccess = false; }
            return IsSuccess;
        }
        public void setIsSuccess(boolean x){ IsSuccess = x; }
    }
    
    //used for manual merge table output.  each represents a table row: 1 field, 2 record values List[0] and List[1]
    public class mergeDuplicateTableRow{
        public string fieldName {get; set;}
        public string fieldLabel {get; set;}
        public string fieldType {get; set;}
        public boolean blank {get; set;}
        public boolean editable {get; set;}
        public boolean locked {get; set;}
        public List<boolean>  keep {get; set;}
    
        public mergeDuplicateTableRow(string namep, string labelp, string typep){
            fieldName = namep;
            fieldLabel = labelp;
            fieldType = typep;
            editable = false;
            locked = false;
            keep = new List<boolean>{false, false};
            blank = false;
        }
        
    }
    
    public class UBOOwnerData
    {
     @AuraEnabled public integer keyValue {get;set;}
     @AuraEnabled public string associationId{get;set;}
     @AuraEnabled public Integer level {get;set;}
     @AuraEnabled public string type {get;set;}
     @AuraEnabled public String associationType{get;set;}
     @AuraEnabled public boolean isControlProng {get;set;}
     
     @AuraEnabled public boolean isIndividual {get;set;}
     @AuraEnabled public boolean isEntity {get;set;}
     @AuraEnabled public boolean isUnderThreshold {get;set;}
     //This name property is populated for Entity Type associations
     @AuraEnabled public string name {get;set;}
     
     //This firstname and lastname property is populated for Individual Type associations
     @AuraEnabled public string firstname {get;set;}
     @AuraEnabled public string lastname {get;set;}
    
     @AuraEnabled public string goPrimaryRelRecordId {get;set;}
     @AuraEnabled public string goRelationshipRecordId {get;set;}
     @AuraEnabled public string goRelationshipRecordURL {get;set;}
     @AuraEnabled public string ownershipPct {get;set;}
     @AuraEnabled public string effectiveOwnershipPct {get;set;}
     @AuraEnabled public string dateOfBirth {get;set;}
    //SSN, EIN, ITIN, NO TIN, FOREIGN TAX ID
     @AuraEnabled public string TINType {get;set;}
     @AuraEnabled public string TINTypeNumber {get;set;}
     @AuraEnabled public string TIN {get;set;}
     @AuraEnabled public string addrStreet {get;set;}
     @AuraEnabled public string addrCity {get;set;}
     @AuraEnabled public string addrStateCode {get;set;}
     @AuraEnabled public string addrZip {get;set;}
     @AuraEnabled public string addrCountryCode {get;set;}
     @AuraEnabled public List<UBOOwnerData> ownersList {get;set;}
     @AuraEnabled public boolean hasNextLevel {get;set;}
     @AuraEnabled public boolean hasDataErrors {get;set;}
     @AuraEnabled public string dataErrors {get;set;}
     @AuraEnabled public boolean isNoTIN {get;set;}
  }

  public class UBOBorrowerData
  {
    @AuraEnabled public integer keyValue {get;set;}
    @AuraEnabled public string name {get;set;}   
    @AuraEnabled public string borrowerRelationshipRecordId {get;set;}
    @AuraEnabled public string borrowerRelationshipRecordURL {get;set;}
    @AuraEnabled public string borrowerWMSNumber {get;set;}
    @AuraEnabled public string TINType {get;set;}
    @AuraEnabled public string TINTypeNumber {get;set;}
    @AuraEnabled public string TIN {get;set;}
    @AuraEnabled public string addrStreet {get;set;}
    @AuraEnabled public string addrCity {get;set;}
    @AuraEnabled public string addrStateCode {get;set;}
    @AuraEnabled public string addrZip {get;set;}
    @AuraEnabled public string addrCountryCode {get;set;}
    @AuraEnabled public string lineOfBusiness {get;set;}
    @AuraEnabled public string exemptionCategoryId {get;set;}
    @AuraEnabled public string borrowerSubCategory {get;set;}
    @AuraEnabled public string NAICSCode {get;set;}
    @AuraEnabled public string reference {get;set;}
    @AuraEnabled public List<UBOOwnerData> ownersList {get;set;}
    @AuraEnabled public boolean hasDataErrors {get;set;}
    @AuraEnabled public string dataErrors {get;set;}
    @AuraEnabled public boolean childrenHaveErrors {get;set;}
    @AuraEnabled public boolean allOwnersPassedScreening {get;set;}
  }
  public class BankAuthDealerWrapper
    {
      public string recordId {get;set;}
      public string wmsNumber {get;set;}
      public string name {get;set;}
      public string billingStreet {get;set;}
      public string billingCity {get;set;}
      public string billingState {get;set;}
      public string billingZipCode {get;set;}
      public string billingCountry {get;set;}
      public string primaryContactName {get;set;}
      public string primaryPhone {get;set;}
      public string brand {get;set;} 
      public string businessUnit {get;set;}
    }

    public class BWScreenWrapper
    {
      @AuraEnabled public string  name {get;set;}
      @AuraEnabled public boolean isActive {get;set;}
      @AuraEnabled public boolean isCompleted {get;set;}
      @AuraEnabled public boolean isRequestStage {get;set;}
      @AuraEnabled public boolean isUnderwritingStage {get;set;}
      @AuraEnabled public boolean isDocumentCreationStage {get;set;}
      @AuraEnabled public boolean isAccountSetupStage {get;set;}
      @AuraEnabled public boolean displayScreenAsLink {get;set;}
    }
    
    public class BWStepWrapper{
        @AuraEnabled public string stepRecordId {get;set;}
        @AuraEnabled public integer stepNumber {get;set;}     
        @AuraEnabled public string screenRecordId {get;set;}
        @AuraEnabled public string displayText {get; set;}
        @AuraEnabled public boolean stepCompleted {get;set;}
        @AuraEnabled public BWElementWrapper element1Wrapper{get;set;}
        @AuraEnabled public BWElementWrapper element2Wrapper{get;set;}     
        @AuraEnabled public BWElementWrapper element3Wrapper{get;set;}      
        @AuraEnabled public BWElementWrapper element4Wrapper{get;set;}
        @AuraEnabled public BWElementWrapper element5Wrapper{get;set;}
        @AuraEnabled public boolean hiddenOnScreen {get;set;}
        @AuraEnabled public boolean readOnlyCheckMark {get;set;}
        @AuraEnabled public string stepTitle {get;set;}
        @AuraEnabled public string userAnswer {get;set;}
    }
    
     public class BWElementWrapper
     {
        @AuraEnabled public boolean isButton {get; set;}
        @AuraEnabled public boolean isCheckbox {get; set;}
        @AuraEnabled public boolean isURL {get; set;}
        @AuraEnabled public boolean isPicklist {get; set;}
        @AuraEnabled public boolean isText {get;set;}
        @AuraEnabled public boolean isCurrency {get; set;}
        @AuraEnabled public boolean isDate {get; set;}
        @AuraEnabled public boolean isLookup {get;set;}
        @AuraEnabled public string textData {get;set;}
        @AuraEnabled public String lookupObjectName {get;set;}
        @AuraEnabled public String lookupFieldName {get;set;}
        @AuraEnabled public String lookupSelectedValue {get;set;}
        @AuraEnabled public String lookupPlaceHolderText {get;set;}
        @AuraEnabled public string elementLabel {get;set;}
        @AuraEnabled public string elementActionName {get;set;}
        @AuraEnabled public List<string> elementPicklistValues {get;set;}
        @AuraEnabled public string elementSelectedPicklistValue {get;set;}
        @AuraEnabled public List<BWcbOption> cbOptions {get;set;}
        @AuraEnabled  public Map<String, sObject> validLookupRecordIds{get;set;}
        @AuraEnabled public boolean isButtonSpinner{get;set;}
     }
     
    //for dynamic combobox options 
    public class BWcbOption {
        @AuraEnabled public string label {get; set;}
        @AuraEnabled public string value {get; set;}    
    }

     
    public class BWStepActionOutComeWrapper{
        @AuraEnabled public boolean outCome {get; set;}
        @AuraEnabled public string errorString {get; set;}
        @AuraEnabled public string resultString {get;set;}
        @AuraEnabled public string resultRecordId {get;set;}
    }

     public class BWBorrowerDbaWrapper{
        @AuraEnabled public boolean verified {get; set;}
        @AuraEnabled public string rowType {get; set;}
        @AuraEnabled public integer index {get; set;}
        @AuraEnabled public Account relationship {get; set;}
        @AuraEnabled public string relationshipId {get; set;}
        @AuraEnabled public string relTIN {get; set;}
        @AuraEnabled public string relYearStart {get; set;}
        @AuraEnabled public string relYearOwn {get; set;}
        @AuraEnabled public string relTINWarn {get; set;}
        @AuraEnabled public string relYearStartWarn {get; set;}
        @AuraEnabled public string relYearOwnWarn {get; set;}
        @AuraEnabled public string relName {get; set;}
        @AuraEnabled public string relURL {get; set;}
        @AuraEnabled public string relLEStructure {get; set;}
        @AuraEnabled public List<DBA_Name__c> dbaNames1 {get; set;}
        @AuraEnabled public List<string> dbaNames {get; set;}
        @AuraEnabled public string newDbaNames {get; set;}
        @AuraEnabled public BW_Chart_Row__c chartData {get; set;}
        @AuraEnabled public string screenId {get; set;}
        @AuraEnabled public boolean isEntityGuarantor {get; set;}
    }
    
      public class BWDupeAppsRowWrapper{
      @AuraEnabled public integer index {get;set;}
      @AuraEnabled public string prospectId {get;set;}
      @AuraEnabled public string prospectName {get;set;}
      @AuraEnabled public string ndaId {get;set;}
      @AuraEnabled public string ndaName {get;set;}
      @AuraEnabled public string underwritingId {get;set;}
      @AuraEnabled public string underwritingName {get;set;}
      @AuraEnabled public string businessEntity {get;set;}
      @AuraEnabled public boolean primaryNDA {get;set;}
      @AuraEnabled public string primaryNDAIndex {get;set;}
      @AuraEnabled public boolean coBorrower {get;set;}
      @AuraEnabled public string coBorrowerIndex {get;set;}
    }

     public class BWCBRWrapper {
      @AuraEnabled public integer index {get; set;}
      @AuraEnabled public Account relationship {get; set;}
      @AuraEnabled public string relationshipId {get; set;}
      @AuraEnabled public string relURL {get; set;}
      @AuraEnabled public string relName {get; set;}
      @AuraEnabled public string firstName {get;set;}
      @AuraEnabled public string middleName {get;set;}
      @AuraEnabled public string lastName {get;set;}
      @AuraEnabled public string suffix {get;set;}
      @AuraEnabled public string ssn {get;set;}
      @AuraEnabled public date dob {get;set;}
      @AuraEnabled public date cbrDate {get;set;}
      @AuraEnabled public date uwCreatedDate {get; set;}
      @AuraEnabled public integer cbrScore {get;set;}
      @AuraEnabled public integer cbrQtlyChange {get; set;}
      @AuraEnabled public boolean cbrRequired {get; set;}
      @AuraEnabled public boolean cbrPending {get; set;}
      @AuraEnabled public boolean cbrClicked {get; set;}
      @AuraEnabled public List<string> cbrSpMessageList {get;set;}
      @AuraEnabled public string initiatingAccountTCFLegalEntity {get; set;}
      @AuraEnabled public string countryCode {get; set;}
      @AuraEnabled public boolean showSpMessages {get; set;}
      
    }
    
    ////////////////////////////////
    // Entity Verification Screen //
    ////////////////////////////////
    public class BWDataInfoWrapper
    {
        @AuraEnabled public BW_Chart_Row__c chartData{get;set;}
        @AuraEnabled public List<BWDataInfo> dataList{get;set;}
        @AuraEnabled public String rowType{get;set;}
        @AuraEnabled public Integer index{get;set;}
        @AuraEnabled public String recordId{get;set;}
    }
  
    public class BWDataInfo
    {
        @AuraEnabled public String data{get;set;}
        @AuraEnabled public boolean booleanData{get;set;}
        //combination of steptitle and index.
        @AuraEnabled public String key{get;set;}
        @AuraEnabled public boolean isTextInput{get;set;}
        @AuraEnabled public boolean isTextArea{get;set;}
        @AuraEnabled public boolean isLink{get;set;}
        @AuraEnabled public boolean isReadOnly{get;set;}
        @AuraEnabled public boolean isPickList{get;set;}
        @AuraEnabled public boolean isBoolean{get;set;}
        @AuraEnabled public List<String> picklistvalues{get;set;}
        @AuraEnabled public string linkLabel{get;set;}
        @AuraEnabled public string linkURL{get;set;}
    }

    public class BWFormationDocRowWrapper
    {
      @AuraEnabled public integer index {get;set;}
      @AuraEnabled public string key {get;set;}
      @AuraEnabled public string reviewType {get;set;}
      @AuraEnabled public string relationshipName {get;set;}
      @AuraEnabled public string relationshipState {get;set;}
      @AuraEnabled public string relationshipId {get;set;}
      @AuraEnabled public string relationshipLink {get;set;}
      @AuraEnabled public string formationLink {get;set;}
      @AuraEnabled public string formationOption {get;set;}
      @AuraEnabled public boolean formationOptionsShow {get;set;}
      @AuraEnabled public boolean formationLinkCheck {get;set;}      
      @AuraEnabled public boolean formationLinkShow {get;set;}
      @AuraEnabled public string formationDocLegalName {get;set;}
      @AuraEnabled public boolean formationDocMatch {get;set;}
      @AuraEnabled public string  uploadedDocVault  {get;set;}
      @AuraEnabled public boolean uploadedDocVaultMatch {get;set;}
      @AuraEnabled public string uploadedSharepoint {get;set;}
      @AuraEnabled public boolean uploadedSharepointMatch {get;set;}
      @AuraEnabled public BW_Chart_Row__c chartData {get; set;}
  }
  
  public class SObJectResult 
  {
        @AuraEnabled public String Name;
        @AuraEnabled public Id Id;
        @Auraenabled public String type;
        @Auraenabled public String objectname;
        @Auraenabled public boolean displayAdditionalInfo;
  }

    public class BWStepWrapperWithResult{
        public BWStepWrapper step {get; set;}
        public Boarding_Wizard_Step_Result__c stepResult {get; set;}
    }
    
     public class BWRouteToCreditMatrixResult{
        @AuraEnabled public boolean runDRRBeforeCredit {get; set;}
        @AuraEnabled public boolean needFinancials {get; set;}
        @AuraEnabled public boolean routeToCredit {get; set;}
        @AuraEnabled public string  additionalComments {get; set;}
        @AuraEnabled public string  reason {get; set;}
    }
    
    public class BWUpsertStepResultRecordInfo
    {
        public String stepRecId;
        public string value;
    } 
    public class BWSecuritySearchRowWrapper
    {
      @AuraEnabled public integer index {get;set;}
      @AuraEnabled public string key {get;set;}
      @AuraEnabled public string relationshipname {get;set;}
      @AuraEnabled public string relationshipId {get;set;}
      @AuraEnabled public string tcfLegalEntity {get;set;}
      @AuraEnabled public string searchBillingCode {get;set;}
      @AuraEnabled public string searchLabel {get;set;}
      @AuraEnabled public boolean existingSearch {get;set;}
      @AuraEnabled public string searchId {get;set;}    
      @AuraEnabled public string filingType {get;set;}
      @AuraEnabled public string filingLabel {get;set;}
      @AuraEnabled public boolean existingFiling {get;set;}
      @AuraEnabled public string filingId {get;set;}
      @AuraEnabled public boolean certified {get;set;}
      @AuraEnabled public string specialInstructions {get;set;}
      @AuraEnabled public BW_Chart_Row__c chartData {get; set;}
    }
}