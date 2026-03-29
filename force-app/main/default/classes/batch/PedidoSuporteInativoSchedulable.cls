// Schedulable que dispara o batch de inativação de pedidos
public with sharing class PedidoSuporteInativoSchedulable implements Schedulable {

    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
    }
}
