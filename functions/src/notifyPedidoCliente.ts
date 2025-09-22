import * as functions from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { sendWhatsAppMessage } from "./sendWhatsAppMessage";

// Trigger Firestore v2
export const notifyPedidoCliente = functions.onDocumentCreated(
  "pedidos/{pedidoId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const pedidoData = snapshot.data();
    if (!pedidoData) return;

    const numeroPedido = pedidoData.numeroPedido ?? event.params.pedidoId;
    const clienteNome = pedidoData.nomeUsuario ?? "Cliente";
    let clienteTelefone = pedidoData.telefone;

    logger.info(`[notifyPedidoCliente] Novo pedido: ${numeroPedido}`);

    if (!clienteTelefone) {
      logger.warn(`[notifyPedidoCliente] Cliente sem telefone cadastrado para pedido ${numeroPedido}`);
      return;
    }

    // Garantir formato internacional +55
    if (!clienteTelefone.startsWith("+")) {
      clienteTelefone = `+${clienteTelefone.replace(/\D/g, "")}`;
    }

    const mensagem = `Olá ${clienteNome}, seu pedido nº ${numeroPedido} foi recebido com sucesso! 🍞🥖`;

    try {
      await sendWhatsAppMessage(clienteTelefone, mensagem);
      logger.info(`[notifyPedidoCliente] WhatsApp enviado para ${clienteTelefone}`);
    } catch (error) {
      logger.error(`[notifyPedidoCliente] Erro ao enviar WhatsApp para pedido ${numeroPedido}:`, error);
    }
  }
);
