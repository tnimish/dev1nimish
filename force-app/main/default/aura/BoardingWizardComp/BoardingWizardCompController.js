({
     doInit : function(component, event) {
        var rId =component.get("v.pageReference").state.c__id;
        component.set("v.recordId", rId);
    	document.title = "Boarding Wizard | Inventory Finance";
     }, 
    closescreen: function(component, event) {
        $A.get("e.force:closeQuickAction").fire();
    }
});