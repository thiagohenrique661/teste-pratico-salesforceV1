// Interface para abstrair a lógica de consulta de interações ao pedido
public interface IInteracaoSelector {

    List<Interacao__c> getInteracoesAgentePorPedidos(Set<Id> pedidoIds);
}