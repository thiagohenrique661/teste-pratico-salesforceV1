// Repositório para consulta de interações relacionado a determinado pedido
public with sharing class InteracaoSelector implements IInteracaoSelector {

    public List<Interacao__c> getInteracoesAgentePorPedidos(Set<Id> pedidoIds) {
         String Tipo_Agente = 'Agente';

        return [
            // Security para proteger dados de usuários sem acesso aos pedidos
            SELECT Id, Tipo__c, PedidoSuporte__c
            FROM Interacao__c
            WHERE PedidoSuporte__c IN :pedidoIds
            AND Tipo__c = :Tipo_Agente
            WITH SECURITY_ENFORCED
        ];
    }
}