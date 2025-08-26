import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getUserTokens } from "./utils";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const notifyAdminNewPedido = onDocumentCreated(
  { document: "pedidos/{pedidoId}" },
  async (event) => {
    const snapshot = event.data;
    const pedidoId = event.params.pedidoId;

    if (!snapshot) {
      logger.error("[notifyAdminNewPedido] Snapshot vazio para novo pedido:", pedidoId);
      return;
    }

    logger.info("[notifyAdminNewPedido] Novo pedido criado:", pedidoId);

    try {
      // Busca todos os admins
      const adminSnapshot = await admin.firestore()
        .collection("users")
        .where("role", "==", "admin")
        .get();

      logger.info(`[notifyAdminNewPedido] Admins encontrados: ${adminSnapshot.size}`);

      const tokens: string[] = [];
      adminSnapshot.forEach((doc) => {
        const docTokens = getUserTokens(doc);
        logger.info(`[notifyAdminNewPedido] Tokens do admin ${doc.id}:`, docTokens);
        tokens.push(...docTokens);
      });

      // Remove duplicatas
      const uniqueTokens = Array.from(new Set(tokens));

      if (uniqueTokens.length === 0) {
        logger.info("[notifyAdminNewPedido] Nenhum token de admin encontrado.");
        return;
      }

      // Define mensagem
      const messagePayload = {
        notification: {
          title: "Novo pedido recebido",
          body: `Pedido ${pedidoId} foi criado.`,
        },
        android: {
          notification: {
            channelId: "pedidos_channel",
            sound: "default",
          },
        },
      };
        const messaging = admin.messaging();

      // Envia notificações em lotes de até 500 tokens
      const BATCH_SIZE = 500;
      for (let i = 0; i < uniqueTokens.length; i += BATCH_SIZE) {
        const batchTokens = uniqueTokens.slice(i, i + BATCH_SIZE);
        logger.info(`[notifyAdminNewPedido] Enviando notificação para ${batchTokens.length} tokens`);

        const response = await messaging.sendEachForMulticast({
          ...messagePayload,
          tokens: batchTokens,
        });

        logger.info(`[notifyAdminNewPedido] Envio concluído: sucesso=${response.successCount}, falhas=${response.failureCount}`);

        // Log de falhas detalhadas
        response.responses.forEach((resp: admin.messaging.SendResponse, idx: number) => {
          if (!resp.success) {
            logger.error(`[notifyAdminNewPedido] Falha ao enviar para token ${batchTokens[idx]}:`, resp.error);
          }
        });
      }

    } catch (error) {
      logger.error("[notifyAdminNewPedido] Erro ao processar notificação:", error);
    }
  }
);
