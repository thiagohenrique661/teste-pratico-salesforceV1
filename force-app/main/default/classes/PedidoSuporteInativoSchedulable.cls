/**
 * @description Schedulable wrapper para PedidoSuporteInativoBatch.
 *              Permite agendar o batch via Setup > Apex Scheduler ou via código.
 *
 *              Para agendar via Developer Console (executa todo dia às 02:00):
 *
 *                String cron = '0 0 2 * * ?';
 *                System.schedule(
 *                    'Pedido Suporte - Inatividade Diária',
 *                    cron,
 *                    new PedidoSuporteInativoSchedulable()
 *                );
 */
public with sharing class PedidoSuporteInativoSchedulable implements Schedulable {

    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new PedidoSuporteInativoBatch(), 200);
    }
}
