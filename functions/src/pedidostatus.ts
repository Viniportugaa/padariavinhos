import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getUserTokens } from "./utils";

export const notifyPedidoStatusChange = onDocumentUpdated(
  { document: "pedidos/{pedidoId}" },
  async (event) => {
    try {
      const before = event.data?.before;
      const after = event.data?.after;
      const pedidoId = event.params.pedidoId;

      if (!after) {
        logger.error("Snapshot vazio para pedido atualizado:", pedidoId);
        return;
      }

      const statusBefore = before?.data()?.status;
      const statusAfter = after.data()?.status;

      if (statusBefore === statusAfter) {
        logger.info(`Pedido ${pedidoId} atualizado mas status não mudou (${statusAfter}).`);
        return;
      }

      logger.info(`Pedido ${pedidoId} mudou de ${statusBefore} para ${statusAfter}`);

      // Buscar o usuário dono do pedido
      const userId = after.data()?.userId;
      if (!userId) {
        logger.error(`Pedido ${pedidoId} não possui userId.`);
        return;
      }

      const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        logger.error(`Usuário ${userId} não encontrado para pedido ${pedidoId}`);
        return;
      }

      const tokens = getUserTokens(userDoc); // ✅ aqui agora está dentro do try
      if (tokens.length === 0) {
        logger.warn(`Usuário ${userId} não possui tokens FCM salvos.`);
        return;
      }

      // Enviar notificações
      const response = await admin.messaging().sendMulticast({
        tokens,
        notification: {
          title: "Status do pedido atualizado",
          body: `Seu pedido ${pedidoId} está agora: ${statusAfter}`,
        },
      });

      logger.info(
        `Notificação enviada para ${userId} | sucesso: ${response.successCount}, falhas: ${response.failureCount}`
      );

      // Log detalhado de falhas
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            logger.error(
              `Erro ao enviar para token ${tokens[idx]}:`,
              resp.error
            );
          }
        });
      }
    } catch (err) {
      logger.error("Erro inesperado ao processar notifyPedidoStatusChange:", err);
    }
  }
);
