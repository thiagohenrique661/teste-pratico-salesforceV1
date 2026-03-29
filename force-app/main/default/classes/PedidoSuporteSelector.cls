/**
 * @description Selector responsável por encapsular todas as queries
 *              relacionadas ao objeto PedidoSuporte__c.
 *              Camada de acesso a dados (Data Access Layer).
 */
public with sharing class PedidoSuporteSelector {

    /**
     * @description Retorna um QueryLocator com pedidos inativos há mais de N dias.
     *              Exclui pedidos já Resolvidos ou Cancelados.
     *              Utilizado no start() do Batch.
     * @param dias  Número de dias de inatividade (ex: 3)
     * @return Database.QueryLocator
     */
    public static Database.QueryLocator getQueryLocatorInativos(Integer dias) {
        DateTime limiteInatividade = DateTime.now().addDays(-dias);

        return Database.getQueryLocator([
            SELECT Id,
                   Status__c,
                   UltimaInteracao__c,
                   Cliente__c,
                   Cliente__r.Name
            FROM PedidoSuporte__c
            WHERE UltimaInteracao__c < :limiteInatividade
            AND   Status__c NOT IN ('Resolvido', 'Cancelado')
            WITH SECURITY_ENFORCED
        ]);
    }

    /**
     * @description Retorna um mapa de AccountId → E-mail do Contact principal
     *              (primeiro Contact criado com e-mail preenchido).
     *              Utilizado no execute() do Batch para evitar PersonEmail.
     * @param accountIds Set de IDs de Account
     * @return Map<Id, String>
     */
    public static Map<Id, String> getEmailContatoPrincipalPorContas(Set<Id> accountIds) {
        Map<Id, String> mapaEmailPorConta = new Map<Id, String>();

        List<Contact> contatos = [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE AccountId IN :accountIds
            AND   Email != null
            ORDER BY CreatedDate ASC
            
        ];

        // Mantém apenas o primeiro e-mail encontrado por conta
        for (Contact c : contatos) {
            if (!mapaEmailPorConta.containsKey(c.AccountId)) {
                mapaEmailPorConta.put(c.AccountId, c.Email);
            }
        }

        return mapaEmailPorConta;
    }
}
