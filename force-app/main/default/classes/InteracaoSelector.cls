/**
 * @description Selector responsável por encapsular todas as queries
 *              relacionadas ao objeto Interacao__c.
 *              Camada de acesso a dados (Data Access Layer).
 */
public with sharing class InteracaoSelector {

    /**
     * @description Retorna interações do tipo Agente associadas a um conjunto de PedidoSuporte__c.
     * @param pedidoIds Set de Ids dos pedidos a serem consultados
     * @return List<Interacao__c> lista de interações encontradas
     */
    public static List<Interacao__c> getInteracoesAgentePorPedidos(Set<Id> pedidoIds) {
        return [
            SELECT Id, Tipo__c, PedidoSuporte__c
            FROM Interacao__c
            WHERE PedidoSuporte__c IN :pedidoIds
            AND Tipo__c = 'Agente'
            WITH SECURITY_ENFORCED
        ];
    }
}
