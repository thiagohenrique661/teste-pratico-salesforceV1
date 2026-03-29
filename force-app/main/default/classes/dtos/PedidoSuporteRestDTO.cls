// DTO para padronizar a estrutura dos dados
public class PedidoSuporteRestDTO {

    public class ValidationException extends Exception {}

    public class PedidoSuporteRequest {
        public String clienteId;
        public String descricao;
        public String prioridade;
    }
}