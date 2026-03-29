// Repositório para consulta de pedidos de suporte resolvidos ou cancelados há mais de 3 dias
public with sharing class PedidoSuporteSelector implements IPedidoSuporteSelector {

    public Database.QueryLocator getQueryLocatorInativos(Integer dias) {
        DateTime limiteInatividade = DateTime.now().addDays(-dias);
        String Status_Resolvido = 'Resolvido';
        String Status_Cancelado = 'Cancelado';

        return Database.getQueryLocator([
            SELECT Id,
                   Status__c,
                   UltimaInteracao__c,
                   Cliente__c,
                   Cliente__r.Name
            FROM PedidoSuporte__c
            WHERE UltimaInteracao__c < :limiteInatividade
            AND   Status__c NOT IN (:Status_Resolvido, :Status_Cancelado)
            WITH SECURITY_ENFORCED
        ]);
    }

    public Map<Id, String> getEmailContatoPrincipalPorContas(Set<Id> accountIds) {
        Map<Id, String> mapaEmailPorConta = new Map<Id, String>();

        List<Contact> contatos = [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE AccountId IN :accountIds
            AND   Email != null
            ORDER BY CreatedDate ASC
        ];

        for (Contact c : contatos) {
            if (!mapaEmailPorConta.containsKey(c.AccountId)) {
                mapaEmailPorConta.put(c.AccountId, c.Email);
            }
        }

        return mapaEmailPorConta;
    }
}