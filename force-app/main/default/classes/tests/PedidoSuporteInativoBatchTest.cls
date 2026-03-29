@IsTest
private class PedidoSuporteInativoBatchTest {

    @TestSetup
    static void setup() {
        Account conta = new Account(
            Name = 'Cliente Teste'
        );
        insert conta;

        Contact contato = new Contact(
            AccountId = conta.Id,
            LastName  = 'Contato Teste',
            Email     = 'cliente@teste.com'
        );
        insert contato;
    }

    @IsTest
    static void quandoPedidoInativoHaMaisDe3Dias_deveAtualizarStatus() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Cliente__c       = conta.Id,
            Status__c        = 'Em Atendimento',
            UltimaInteracao__c = DateTime.now().addDays(-4)
        );
        insert pedido;

        Test.startTest();
        Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
        Test.stopTest();

        PedidoSuporte__c atualizado = [SELECT Status__c FROM PedidoSuporte__c WHERE Id = :pedido.Id];
        Assert.areEqual('Aguardando Cliente', atualizado.Status__c,
            'Status deveria ter sido atualizado para Aguardando Cliente.');
    }


    @IsTest
    static void quandoPedidoAtivoNosUltimos3Dias_naoDeveAtualizar() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Cliente__c        = conta.Id,
            Status__c         = 'Em Atendimento',
            UltimaInteracao__c = DateTime.now().addDays(-1)
        );
        insert pedido;

        Test.startTest();
        Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
        Test.stopTest();

        PedidoSuporte__c naAtualizado = [SELECT Status__c FROM PedidoSuporte__c WHERE Id = :pedido.Id];
        Assert.areEqual('Em Atendimento', naAtualizado.Status__c,
            'Status não deveria ter sido alterado para pedido recente.');
    }

    @IsTest
    static void quandoPedidoResolvido_naoDeveSerProcessado() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Cliente__c        = conta.Id,
            Status__c         = 'Resolvido',
            UltimaInteracao__c = DateTime.now().addDays(-10)
        );
        insert pedido;

        Test.startTest();
        Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
        Test.stopTest();

        PedidoSuporte__c naAtualizado = [SELECT Status__c FROM PedidoSuporte__c WHERE Id = :pedido.Id];
        Assert.areEqual('Resolvido', naAtualizado.Status__c,
            'Pedido Resolvido não deve ser alterado pelo batch.');
    }

    @IsTest
    static void quandoPedidoCancelado_naoDeveSerProcessado() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Cliente__c        = conta.Id,
            Status__c         = 'Cancelado',
            UltimaInteracao__c = DateTime.now().addDays(-10)
        );
        insert pedido;

        Test.startTest();
        Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
        Test.stopTest();

        PedidoSuporte__c naAtualizado = [SELECT Status__c FROM PedidoSuporte__c WHERE Id = :pedido.Id];
        Assert.areEqual('Cancelado', naAtualizado.Status__c,
            'Pedido Cancelado não deve ser alterado pelo batch.');
    }

    @IsTest
    static void quandoAgendado_deveExecutarSemErro() {
        Test.startTest();
        String jobId = System.schedule(
            'Teste - Inatividade',
            '0 0 2 * * ?',
            new PedidoSuporteInativoSchedulable()
        );
        Test.stopTest();

        Assert.isNotNull(jobId, 'O job agendado deveria retornar um Id.');
    }

    @IsTest
    static void quandoBulkDePedidosInativos_todosDevemSerAtualizados() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        List<PedidoSuporte__c> pedidos = new List<PedidoSuporte__c>();
        for (Integer i = 0; i < 10; i++) {
            pedidos.add(new PedidoSuporte__c(
                Cliente__c        = conta.Id,
                Status__c         = 'Em Atendimento',
                UltimaInteracao__c = DateTime.now().addDays(-5)
            ));
        }
        insert pedidos;

        Test.startTest();
        Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
        Test.stopTest();

        List<PedidoSuporte__c> atualizados = [
            SELECT Status__c
            FROM PedidoSuporte__c
            WHERE Status__c = 'Aguardando Cliente'
        ];
        Assert.areEqual(10, atualizados.size(), 'Todos os 10 pedidos deveriam estar com status Aguardando Cliente.');
    }
}