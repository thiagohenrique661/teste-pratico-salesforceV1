@RestResource(urlMapping='/pedidos-suporte') // Endpoint para criar pedidos de suporte
global without sharing class PedidoSuporteRestResource {

    global class PedidoSuporteResponse {
        global String pedidoId;

        global PedidoSuporteResponse(String pedidoId) {
            this.pedidoId = pedidoId;
        }
    }

    global class ErroResponse {
        global String erro;

        global ErroResponse(String mensagem) {
            this.erro = mensagem;
        }
    }

    @HttpPost
    global static void criarPedido() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            
            PedidoSuporteRestDTO.PedidoSuporteRequest payload =
                (PedidoSuporteRestDTO.PedidoSuporteRequest) JSON.deserialize(
                    req.requestBody.toString(),
                    PedidoSuporteRestDTO.PedidoSuporteRequest.class
                );

            // Chamada para criar o pedido
            PedidoSuporteRestService service = new PedidoSuporteRestService();
            String pedidoId = service.criarPedido(payload);

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new PedidoSuporteResponse(pedidoId))
            );

        } catch (PedidoSuporteRestDTO.ValidationException ex) {
            
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ErroResponse(ex.getMessage()))
            );

        } catch (Exception e) {
          
            System.debug(LoggingLevel.ERROR, 'PedidoSuporteRestResource.criarPedido: ' + e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ErroResponse('Erro interno. Tente novamente mais tarde.'))
            );
        }
    }
}