/**
 * @description Batch Apex responsável por identificar Pedidos de Suporte
 *              sem interação há mais de 3 dias, atualizar o status para
 *              "Aguardando Cliente" e notificar o cliente por e-mail.
 *
 *              Implementa Database.Stateful para acumular contadores
 *              entre os chunks de execute().
 *
 *              Para executar manualmente via Developer Console:
 *                Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
 *
 *              Para agendar, use PedidoSuporteInativoSchedulable.
 */
public with sharing class PedidoSuporteInativoBatch
        implements Database.Batchable<SObject>, Database.Stateful {

    // ─── Constantes ───────────────────────────────────────────────────────────
    private static final Integer DIAS_INATIVIDADE  = 3;
    private static final String  STATUS_AGUARDANDO = 'Aguardando Cliente';

    private static final String ASSUNTO_EMAIL =
        'Seu pedido de suporte será encerrado em breve por inatividade';

    // ─── Contadores (Database.Stateful) ───────────────────────────────────────
    @TestVisible private Integer totalAtualizados = 0;
    @TestVisible private Integer totalEmailsEnviados = 0;
    @TestVisible private Integer totalErros = 0;

    // ─────────────────────────────────────────────────────────────────────────
    // START — Delega a query ao Selector (clean arch)
    // ─────────────────────────────────────────────────────────────────────────
    public Database.QueryLocator start(Database.BatchableContext ctx) {
        return PedidoSuporteSelector.getQueryLocatorInativos(DIAS_INATIVIDADE);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // EXECUTE — Processa cada chunk
    // ─────────────────────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext ctx, List<PedidoSuporte__c> pedidos) {
        List<PedidoSuporte__c>          pedidosParaAtualizar = new List<PedidoSuporte__c>();
        List<Messaging.SingleEmailMessage> emailsParaEnviar  = new List<Messaging.SingleEmailMessage>();

        // Coleta IDs das contas do chunk e busca e-mail do Contact principal (1 query)
        Set<Id> contaIds = new Set<Id>();
        for (PedidoSuporte__c pedido : pedidos) {
            if (pedido.Cliente__c != null) {
                contaIds.add(pedido.Cliente__c);
            }
        }
        Map<Id, String> emailPorConta =
            PedidoSuporteSelector.getEmailContatoPrincipalPorContas(contaIds);

        for (PedidoSuporte__c pedido : pedidos) {
            pedido.Status__c = STATUS_AGUARDANDO;
            pedidosParaAtualizar.add(pedido);

            String emailDestino = emailPorConta.get(pedido.Cliente__c);
            if (String.isNotBlank(emailDestino)) {
                emailsParaEnviar.add(montarEmail(pedido, emailDestino));
            }
        }

        // DML com allOrNone=false para não abortar o batch por falha pontual
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

        // Envio de e-mails com allOrNone=false
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

    // ─────────────────────────────────────────────────────────────────────────
    // FINISH — Log consolidado ao final do job
    // ─────────────────────────────────────────────────────────────────────────
    public void finish(Database.BatchableContext ctx) {
        System.debug(LoggingLevel.INFO,
            String.format(
                'PedidoSuporteInativoBatch concluído | Atualizados: {0} | E-mails enviados: {1} | Erros: {2}',
                new List<Object>{ totalAtualizados, totalEmailsEnviados, totalErros }
            )
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Método privado — monta o e-mail de inatividade
    // ─────────────────────────────────────────────────────────────────────────
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
        email.setSaveAsActivity(false); // Não criar Activity para não poluir histórico

        return email;
    }
}
