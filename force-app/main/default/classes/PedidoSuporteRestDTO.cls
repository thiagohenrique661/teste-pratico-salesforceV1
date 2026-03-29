/**
 * @description Classe de DTOs e exceções compartilhados entre
 *              PedidoSuporteRestResource e PedidoSuporteRestService.
 *              Elimina dependência circular entre as duas classes.
 */
public class PedidoSuporteRestDTO {

    // ─── Exceção de validação de negócio (HTTP 400) ───────────────────────────
    public class ValidationException extends Exception {}

    // ─── DTO de entrada ───────────────────────────────────────────────────────
    public class PedidoSuporteRequest {
        public String clienteId;
        public String descricao;
        public String prioridade;
    }
}
