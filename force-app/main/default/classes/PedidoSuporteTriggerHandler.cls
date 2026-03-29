/**
 * @description Handler do Trigger de PedidoSuporte__c.
 *              Orquestra as chamadas às classes de serviço conforme
 *              o contexto de execução do trigger.
 *              Camada de aplicação (Application Layer).
 */
public with sharing class PedidoSuporteTriggerHandler {

    /**
     * @description Processa a lógica do contexto before update.
     * @param newList  Trigger.new
     * @param oldMap   Trigger.oldMap
     */
    public static void handleBeforeUpdate(
        List<PedidoSuporte__c> newList,
        Map<Id, PedidoSuporte__c> oldMap
    ) {
        PedidoSuporteService.validarResolucaoAltaPrioridade(newList, oldMap);
        PedidoSuporteService.validarCancelamentoResolvido(newList, oldMap);
    }
}
