/**
 * @description Service responsável pelas regras de negócio
 *              do objeto PedidoSuporte__c.
 *              Camada de domínio (Domain / Service Layer).
 */
public with sharing class PedidoSuporteService {

    private static final String PRIORIDADE_ALTA   = 'Alta';
    private static final String STATUS_RESOLVIDO  = 'Resolvido';
    private static final String STATUS_CANCELADO  = 'Cancelado';
    private static final String MSG_ERRO =
        'Pedidos de alta prioridade devem possuir pelo menos uma interação de agente antes de serem resolvidos.';
    private static final String MSG_ERRO_CANCELAMENTO =
        'Não é permitido cancelar um pedido que já está resolvido.';

    /**
     * @description Valida que pedidos de alta prioridade só podem ser resolvidos
     *              se possuírem ao menos uma interação do tipo Agente.
     *              Deve ser chamado no contexto before update.
     * @param newList  Trigger.new
     * @param oldMap   Trigger.oldMap
     */
    public static void validarResolucaoAltaPrioridade(
        List<PedidoSuporte__c> newList,
        Map<Id, PedidoSuporte__c> oldMap
    ) {
        // 1. Identificar somente pedidos que se enquadram na regra (bulk-safe)
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

        // 2. Consultar interações via Selector (1 única query para todos os registros)
        List<Interacao__c> interacoesAgente =
            InteracaoSelector.getInteracoesAgentePorPedidos(pedidosParaValidar);

        // 3. Mapear quais pedidos possuem ao menos uma interação de agente
        Set<Id> pedidosComAgente = new Set<Id>();
        for (Interacao__c interacao : interacoesAgente) {
            pedidosComAgente.add(interacao.PedidoSuporte__c);
        }

        // 4. Adicionar erro nos registros que violam a regra
        for (PedidoSuporte__c pedido : newList) {
            if (pedidosParaValidar.contains(pedido.Id) &&
                !pedidosComAgente.contains(pedido.Id)) {
                pedido.addError(MSG_ERRO);
            }
        }
    }

    /**
     * @description Impede que um pedido já resolvido seja alterado para Cancelado.
     *              Deve ser chamado no contexto before update.
     * @param newList  Trigger.new
     * @param oldMap   Trigger.oldMap
     */
    public static void validarCancelamentoResolvido(
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
