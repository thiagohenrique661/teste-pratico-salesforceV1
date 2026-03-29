/**
 * @description Apex REST Resource para criação de PedidoSuporte__c.
 *
 *              Endpoint: POST /services/apexrest/pedidos-suporte
 *
 *              Payload esperado:
 *              {
 *                  "clienteId":  "001XXXXXXXXXXXX",
 *                  "descricao":  "Problema no sistema",
 *                  "prioridade": "Alta"
 *              }
 *
 *              Resposta de sucesso (HTTP 201):
 *              { "pedidoId": "a01XXXXXXXXXXXX" }
 *
 *              Resposta de erro (HTTP 400 / 500):
 *              { "erro": "mensagem descritiva" }
 *
 *              Esta classe é somente o controller REST (thin layer).
 *              Toda regra de negócio fica em PedidoSuporteRestService.
 */
@RestResource(urlMapping='/pedidos-suporte')
global without sharing class PedidoSuporteRestResource {

    // ─── DTO de saída — sucesso ────────────────────────────────────────────────
    global class PedidoSuporteResponse {
        global String pedidoId;

        global PedidoSuporteResponse(String pedidoId) {
            this.pedidoId = pedidoId;
        }
    }

    // ─── DTO de saída — erro ──────────────────────────────────────────────────
    global class ErroResponse {
        global String erro;

        global ErroResponse(String mensagem) {
            this.erro = mensagem;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST /services/apexrest/pedidos-suporte
    // ─────────────────────────────────────────────────────────────────────────
    @HttpPost
    global static void criarPedido() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Desserializa o body usando o DTO centralizado
            PedidoSuporteRestDTO.PedidoSuporteRequest payload =
                (PedidoSuporteRestDTO.PedidoSuporteRequest) JSON.deserialize(
                    req.requestBody.toString(),
                    PedidoSuporteRestDTO.PedidoSuporteRequest.class
                );

            // Delega validação e criação ao Service
            String pedidoId = PedidoSuporteRestService.criarPedido(payload);

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new PedidoSuporteResponse(pedidoId))
            );

        } catch (PedidoSuporteRestDTO.ValidationException ex) {
            // Erros de validação de negócio → 400 Bad Request
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ErroResponse(ex.getMessage()))
            );

        } catch (Exception e) {
            // Erros inesperados → 500 Internal Server Error
            System.debug(LoggingLevel.ERROR, 'PedidoSuporteRestResource.criarPedido: ' + e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ErroResponse('Erro interno. Tente novamente mais tarde.'))
            );
        }
    }
}
