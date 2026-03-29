// Rotina para identificar pedidos inativos
public with sharing class PedidoSuporteInativoBatch
        implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer DIAS_INATIVIDADE  = 3;
    private static final String  STATUS_AGUARDANDO = 'Aguardando Cliente';

    private static final String ASSUNTO_EMAIL =
        'Seu pedido de suporte será encerrado em breve por inatividade';

    private IPedidoSuporteSelector pedidoSelector;

    @TestVisible private Integer totalAtualizados = 0;
    @TestVisible private Integer totalEmailsEnviados = 0;
    @TestVisible private Integer totalErros = 0;

    public PedidoSuporteInativoBatch() {
        this.pedidoSelector = new PedidoSuporteSelector();
    }

    @TestVisible
    private PedidoSuporteInativoBatch(IPedidoSuporteSelector pedidoSelector) {
        this.pedidoSelector = pedidoSelector;
    }

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        return this.pedidoSelector.getQueryLocatorInativos(DIAS_INATIVIDADE);
    }

    public void execute(Database.BatchableContext ctx, List<PedidoSuporte__c> pedidos) {
        List<PedidoSuporte__c>          pedidosParaAtualizar = new List<PedidoSuporte__c>();
        List<Messaging.SingleEmailMessage> emailsParaEnviar  = new List<Messaging.SingleEmailMessage>();

        Set<Id> contaIds = new Set<Id>();
        for (PedidoSuporte__c pedido : pedidos) {
            if (pedido.Cliente__c != null) {
                contaIds.add(pedido.Cliente__c);
            }
        }
        Map<Id, String> emailPorConta =
            this.pedidoSelector.getEmailContatoPrincipalPorContas(contaIds);

        for (PedidoSuporte__c pedido : pedidos) {
            pedido.Status__c = STATUS_AGUARDANDO;
            pedidosParaAtualizar.add(pedido);

            String emailDestino = emailPorConta.get(pedido.Cliente__c);
            if (String.isNotBlank(emailDestino)) {
                emailsParaEnviar.add(montarEmail(pedido, emailDestino));
            }
        }

        if (!pedidosParaAtualizar.isEmpty()) {
            List<Database.SaveResult> resultados =
                Database.update(pedidosParaAtualizar, false);

            for (Database.SaveResult sr : resultados) {
                if (sr.isSuccess()) {
                    totalAtualizados++;
                } else {
                    totalErros++;
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'Erro ao atualizar PedidoSuporte__c: ' + err.getMessage());
                    }
                }
            }
        }

        if (!emailsParaEnviar.isEmpty()) {
            List<Messaging.SendEmailResult> emailResultados =
                Messaging.sendEmail(emailsParaEnviar, false);

            for (Messaging.SendEmailResult er : emailResultados) {
                if (er.isSuccess()) {
                    totalEmailsEnviados++;
                } else {
                    System.debug(LoggingLevel.WARN,
                        'Falha ao enviar e-mail: ' + er.getErrors()[0].getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext ctx) {
        System.debug(LoggingLevel.INFO,
            String.format(
                'PedidoSuporteInativoBatch concluído | Atualizados: {0} | E-mails enviados: {1} | Erros: {2}',
                new List<Object>{ totalAtualizados, totalEmailsEnviados, totalErros }
            )
        );
    }

    private Messaging.SingleEmailMessage montarEmail(
        PedidoSuporte__c pedido,
        String destinatario
    ) {
        String nomeCliente = pedido.Cliente__r?.Name ?? 'Cliente';

        String corpo =
            'Olá ' + nomeCliente + ',\n\n' +
            'Identificamos que o seu Pedido de Suporte não possui novas interações há mais de ' +
            DIAS_INATIVIDADE + ' dias.\n\n' +
            'Caso não haja resposta em breve, o pedido será encerrado automaticamente.\n\n' +
            'Se você ainda precisa de assistência, por favor entre em contato com nossa equipe ' +
            'respondendo este e-mail ou acessando o portal de suporte.\n\n' +
            'Atenciosamente,\n' +
            'Equipe de Suporte';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ destinatario });
        email.setSubject(ASSUNTO_EMAIL);
        email.setPlainTextBody(corpo);
        email.setSaveAsActivity(false);

        return email;
    }
}