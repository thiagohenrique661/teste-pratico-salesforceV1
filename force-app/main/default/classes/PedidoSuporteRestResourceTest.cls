/**
 * @description Test class para PedidoSuporteRestResource e PedidoSuporteRestService.
 *              Simula chamadas REST usando RestContext para isolar o endpoint.
 */
@IsTest
private class PedidoSuporteRestResourceTest {

    // ─────────────────────────────────────────────
    // Setup compartilhado
    // ─────────────────────────────────────────────
    @TestSetup
    static void setup() {
        Account conta = new Account(Name = 'Cliente API Teste');
        insert conta;
    }

    // ─────────────────────────────────────────────
    // Cenário 1: POST válido → 201 + pedidoId
    // ─────────────────────────────────────────────
    @IsTest
    static void quandoPayloadValido_deveRetornar201ComPedidoId() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        String body = JSON.serialize(new Map<String, String>{
            'clienteId'  => conta.Id,
            'descricao'  => 'Problema no sistema',
            'prioridade' => 'Alta'
        });

        configurarRestContext('POST', body);

        Test.startTest();
        PedidoSuporteRestResource.criarPedido();
        Test.stopTest();

        RestResponse res = RestContext.response;
        Assert.areEqual(201, res.statusCode, 'Deveria retornar HTTP 201.');

        Map<String, Object> resposta =
            (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        Assert.isTrue(resposta.containsKey('pedidoId'), 'Resposta deve conter "pedidoId".');
        Assert.isNotNull(resposta.get('pedidoId'), 'pedidoId não pode ser nulo.');

        // Verifica que o pedido foi criado com os valores corretos
        PedidoSuporte__c pedidoCriado = [
            SELECT Status__c, Prioridade__c, Descricao__c, UltimaInteracao__c
            FROM PedidoSuporte__c
            LIMIT 1
        ];
        Assert.areEqual('Novo',              pedidoCriado.Status__c,     'Status deve ser Novo.');
        Assert.areEqual('Alta',              pedidoCriado.Prioridade__c, 'Prioridade deve ser Alta.');
        Assert.areEqual('Problema no sistema', pedidoCriado.Descricao__c, 'Descrição incorreta.');
        Assert.isNotNull(pedidoCriado.UltimaInteracao__c, 'UltimaInteracao__c deve ser preenchida.');
    }

    // ─────────────────────────────────────────────
    // Cenário 2: clienteId ausente → 400
    // ─────────────────────────────────────────────
    @IsTest
    static void quandoClienteIdAusente_deveRetornar400() {
        String body = JSON.serialize(new Map<String, String>{
            'descricao'  => 'Problema no sistema',
            'prioridade' => 'Alta'
        });

        configurarRestContext('POST', body);

        Test.startTest();
        PedidoSuporteRestResource.criarPedido();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Deveria retornar HTTP 400.');
        assertRespostaContemErro('"clienteId" é obrigatório');
    }

    // ─────────────────────────────────────────────
    // Cenário 3: clienteId com formato inválido → 400
    // ─────────────────────────────────────────────
    @IsTest
    static void quandoClienteIdInvalido_deveRetornar400() {
        String body = JSON.serialize(new Map<String, String>{
            'clienteId'  => 'ID_INVALIDO',
            'descricao'  => 'Problema no sistema',
            'prioridade' => 'Alta'
        });

        configurarRestContext('POST', body);

        Test.startTest();
        PedidoSuporteRestResource.criarPedido();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Deveria retornar HTTP 400.');
        assertRespostaContemErro('não é um Salesforce Id válido');
    }

    // ─────────────────────────────────────────────
    // Cenário 4: descricao ausente → 400
    // ─────────────────────────────────────────────
    @IsTest
    static void quandoDescricaoAusente_deveRetornar400() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        String body = JSON.serialize(new Map<String, String>{
            'clienteId'  => conta.Id,
            'prioridade' => 'Alta'
        });

        configurarRestContext('POST', body);

        Test.startTest();
        PedidoSuporteRestResource.criarPedido();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Deveria retornar HTTP 400.');
        assertRespostaContemErro('"descricao" é obrigatório');
    }

    // ─────────────────────────────────────────────
    // Cenário 5: prioridade ausente → 400
    // ─────────────────────────────────────────────
    @IsTest
    static void quandoPrioridadeAusente_deveRetornar400() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        String body = JSON.serialize(new Map<String, String>{
            'clienteId' => conta.Id,
            'descricao' => 'Problema no sistema'
        });

        configurarRestContext('POST', body);

        Test.startTest();
        PedidoSuporteRestResource.criarPedido();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Deveria retornar HTTP 400.');
        assertRespostaContemErro('"prioridade" é obrigatório');
    }

    // ─────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────
    private static void configurarRestContext(String metodo, String body) {
        RestRequest req  = new RestRequest();
        req.httpMethod   = metodo;
        req.requestURI   = '/services/apexrest/pedidos-suporte';
        req.requestBody  = Blob.valueOf(body);
        req.addHeader('Content-Type', 'application/json');

        RestContext.request  = req;
        RestContext.response = new RestResponse();
    }

    private static void assertRespostaContemErro(String fragmento) {
        Map<String, Object> resposta =
            (Map<String, Object>) JSON.deserializeUntyped(
                RestContext.response.responseBody.toString()
            );
        Assert.isTrue(resposta.containsKey('erro'), 'Resposta deve conter campo "erro".');
        Assert.isTrue(
            ((String) resposta.get('erro')).contains(fragmento),
            'Mensagem de erro deveria conter: ' + fragmento
        );
    }
}
