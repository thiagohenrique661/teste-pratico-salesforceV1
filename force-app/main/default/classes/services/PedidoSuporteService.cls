// Regra de negócio para validação dos pedidos e diferentes cenários de status
public with sharing class PedidoSuporteService {

    private static final String PRIORIDADE_ALTA   = 'Alta';
    private static final String STATUS_RESOLVIDO  = 'Resolvido';
    private static final String STATUS_CANCELADO  = 'Cancelado';
    private static final String MSG_ERRO =
        'Pedidos de alta prioridade devem possuir pelo menos uma interação de agente antes de serem resolvidos.';
    private static final String MSG_ERRO_CANCELAMENTO =
        'Não é permitido cancelar um pedido que já está resolvido.';

    private final IInteracaoSelector interacaoSelector;

    public PedidoSuporteService() {
        this.interacaoSelector = new InteracaoSelector();
    }

    @TestVisible
    private PedidoSuporteService(IInteracaoSelector interacaoSelector) {
        this.interacaoSelector = interacaoSelector;
    }


    public void validarResolucaoAltaPrioridade(
        List<PedidoSuporte__c> newList,
        Map<Id, PedidoSuporte__c> oldMap
    ) {
        Set<Id> pedidosParaValidar = new Set<Id>();

        for (PedidoSuporte__c pedido : newList) {
            PedidoSuporte__c pedidoAntigo = oldMap.get(pedido.Id);

            Boolean ehAltaPrioridade     = pedido.Prioridade__c == PRIORIDADE_ALTA;
            Boolean statusMudouParaResolvido =
                pedido.Status__c == STATUS_RESOLVIDO &&
                pedidoAntigo.Status__c != STATUS_RESOLVIDO;

            if (ehAltaPrioridade && statusMudouParaResolvido) {
                pedidosParaValidar.add(pedido.Id);
            }
        }

        if (pedidosParaValidar.isEmpty()) {
            return;
        }

        List<Interacao__c> interacoesAgente =
            this.interacaoSelector.getInteracoesAgentePorPedidos(pedidosParaValidar);

        Set<Id> pedidosComAgente = new Set<Id>();
        for (Interacao__c interacao : interacoesAgente) {
            pedidosComAgente.add(interacao.PedidoSuporte__c);
        }

        for (PedidoSuporte__c pedido : newList) {
            if (pedidosParaValidar.contains(pedido.Id) &&
                !pedidosComAgente.contains(pedido.Id)) {
                pedido.addError(MSG_ERRO);
            }
        }
    }

    public void validarCancelamentoResolvido(
        List<PedidoSuporte__c> newList,
        Map<Id, PedidoSuporte__c> oldMap
    ) {
        for (PedidoSuporte__c pedido : newList) {
            PedidoSuporte__c pedidoAntigo = oldMap.get(pedido.Id);

            Boolean eraResolvido       = pedidoAntigo.Status__c == STATUS_RESOLVIDO;
            Boolean tentaCancelar      = pedido.Status__c == STATUS_CANCELADO;

            if (eraResolvido && tentaCancelar) {
                pedido.addError(MSG_ERRO_CANCELAMENTO);
            }
        }
    }
}