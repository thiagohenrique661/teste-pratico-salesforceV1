// Handler para disparar validações da trigger do pedido de suporte
public with sharing class PedidoSuporteTriggerHandler {

    public static void handleBeforeUpdate(
        List<PedidoSuporte__c> newList,
        Map<Id, PedidoSuporte__c> oldMap
    ) {
        PedidoSuporteService service = new PedidoSuporteService();
        service.validarResolucaoAltaPrioridade(newList, oldMap);
        service.validarCancelamentoResolvido(newList, oldMap);
    }
}
