@IsTest
private class PedidoSuporteTriggerTest {

    @IsTest
    static void quandoAltaPrioridadeSemInteracaoAgente_deveBloquear() {
        PedidoSuporte__c pedido = criarPedido('Alta', 'Em Atendimento');
        insert pedido;

        pedido.Status__c = 'Resolvido';

        Test.startTest();
        Database.SaveResult resultado = Database.update(pedido, false);
        Test.stopTest();

        Assert.isFalse(resultado.isSuccess(), 'A atualização deveria ter sido bloqueada.');
        Assert.isTrue(
            resultado.getErrors()[0].getMessage().contains('pelo menos uma interação de agente'),
            'Mensagem de erro incorreta.'
        );
    }

    @IsTest
    static void quandoAltaPrioridadeComInteracaoAgente_devePermitir() {
        PedidoSuporte__c pedido = criarPedido('Alta', 'Em Atendimento');
        insert pedido;

        Interacao__c interacao = new Interacao__c(
            PedidoSuporte__c = pedido.Id,
            Tipo__c          = 'Agente',
            Data__c          = Date.today()
        );
        insert interacao;

        pedido.Status__c = 'Resolvido';

        Test.startTest();
        Database.SaveResult resultado = Database.update(pedido, false);
        Test.stopTest();

        Assert.isTrue(resultado.isSuccess(), 'A atualização deveria ter sido permitida.');
    }

    @IsTest
    static void quandoBaixaPrioridadeSemInteracaoAgente_devePermitir() {
        PedidoSuporte__c pedido = criarPedido('Baixa', 'Em Atendimento');
        insert pedido;

        pedido.Status__c = 'Resolvido';

        Test.startTest();
        Database.SaveResult resultado = Database.update(pedido, false);
        Test.stopTest();

        Assert.isTrue(resultado.isSuccess(), 'Pedidos de baixa prioridade não devem ser bloqueados.');
    }

    @IsTest
    static void quandoAltaPrioridadeStatusNaoMudaParaResolvido_devePermitir() {
        PedidoSuporte__c pedido = criarPedido('Alta', 'Em Atendimento');
        insert pedido;

        pedido.Status__c = 'Aguardando Cliente';

        Test.startTest();
        Database.SaveResult resultado = Database.update(pedido, false);
        Test.stopTest();

        Assert.isTrue(resultado.isSuccess(), 'Mudança para status diferente de Resolvido não deve ser bloqueada.');
    }

    @IsTest
    static void quandoBulkComMixDeRegistros_deveBloquearApenasPoliticaViolada() {
        // Pedido 1: Alta, sem agente deve bloquear
        PedidoSuporte__c pedidoSemAgente = criarPedido('Alta', 'Em Atendimento');
        // Pedido 2: Alta, com agente deve passar
        PedidoSuporte__c pedidoComAgente = criarPedido('Alta', 'Em Atendimento');

        insert new List<PedidoSuporte__c>{ pedidoSemAgente, pedidoComAgente };

        insert new Interacao__c(
            PedidoSuporte__c = pedidoComAgente.Id,
            Tipo__c          = 'Agente',
            Data__c          = Date.today()
        );

        pedidoSemAgente.Status__c = 'Resolvido';
        pedidoComAgente.Status__c = 'Resolvido';

        Test.startTest();
        List<Database.SaveResult> resultados = Database.update(
            new List<PedidoSuporte__c>{ pedidoSemAgente, pedidoComAgente },
            false
        );
        Test.stopTest();

        Assert.isFalse(resultados[0].isSuccess(), 'Pedido sem agente deveria ser bloqueado.');
        Assert.isTrue(resultados[1].isSuccess(),  'Pedido com agente deveria ser permitido.');
    }

    @IsTest
    static void quandoResolvidoTentaCancelar_deveBloquear() {
        PedidoSuporte__c pedido = criarPedido('Baixa', 'Resolvido');
        insert pedido;

        pedido.Status__c = 'Cancelado';

        Test.startTest();
        Database.SaveResult resultado = Database.update(pedido, false);
        Test.stopTest();

        Assert.isFalse(resultado.isSuccess(), 'Cancelamento de pedido Resolvido deveria ser bloqueado.');
        Assert.isTrue(
            resultado.getErrors()[0].getMessage().contains('Não é permitido cancelar'),
            'Mensagem de erro incorreta.'
        );
    }

    @IsTest
    static void quandoEmAtendimentoTentaCancelar_devePermitir() {
        PedidoSuporte__c pedido = criarPedido('Baixa', 'Em Atendimento');
        insert pedido;

        pedido.Status__c = 'Cancelado';

        Test.startTest();
        Database.SaveResult resultado = Database.update(pedido, false);
        Test.stopTest();

        Assert.isTrue(resultado.isSuccess(), 'Cancelamento de pedido Em Atendimento deveria ser permitido.');
    }

    private static PedidoSuporte__c criarPedido(String prioridade, String status) {
        return new PedidoSuporte__c(
            Prioridade__c = prioridade,
            Status__c     = status
        );
    }
}