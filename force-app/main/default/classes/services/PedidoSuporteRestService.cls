// Criação de pedido pelo endpoint e validação do payload
public with sharing class PedidoSuporteRestService {

    private static final String STATUS_NOVO = 'Novo';

    public String criarPedido(
        PedidoSuporteRestDTO.PedidoSuporteRequest payload
    ) {
        validarPayload(payload);

        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Cliente__c         = (Id) payload.clienteId,
            Descricao__c       = payload.descricao,
            Prioridade__c      = payload.prioridade,
            Status__c          = STATUS_NOVO,
            UltimaInteracao__c = DateTime.now()
        );

        insert pedido;
        return pedido.Id;
    }

    private void validarPayload(
        PedidoSuporteRestDTO.PedidoSuporteRequest payload
    ) {
        if (payload == null) {
            throw new PedidoSuporteRestDTO.ValidationException('O corpo da requisição não pode ser vazio.');
        }
        if (String.isBlank(payload.clienteId)) {
            throw new PedidoSuporteRestDTO.ValidationException('O campo "clienteId" é obrigatório.');
        }
        if (!isValidId(payload.clienteId)) {
            throw new PedidoSuporteRestDTO.ValidationException('O campo "clienteId" não é um Salesforce Id válido.');
        }
        if (String.isBlank(payload.descricao)) {
            throw new PedidoSuporteRestDTO.ValidationException('O campo "descricao" é obrigatório.');
        }
        if (String.isBlank(payload.prioridade)) {
            throw new PedidoSuporteRestDTO.ValidationException('O campo "prioridade" é obrigatório.');
        }
    }

    private Boolean isValidId(String rawId) {
        try {
            Id validId = (Id) rawId;
            return validId != null;
        } catch (Exception e) {
            return false;
        }
    }
}