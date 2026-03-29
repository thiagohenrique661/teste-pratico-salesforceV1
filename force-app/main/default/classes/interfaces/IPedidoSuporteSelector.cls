// Interface para abstrair lógica de consulta ao banco relacionado ao pedido de suporte
public interface IPedidoSuporteSelector {

    Database.QueryLocator getQueryLocatorInativos(Integer dias);

    Map<Id, String> getEmailContatoPrincipalPorContas(Set<Id> accountIds);
}