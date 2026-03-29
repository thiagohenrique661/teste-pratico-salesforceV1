trigger PedidoSuporteTrigger on PedidoSuporte__c (before update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        PedidoSuporteTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}
