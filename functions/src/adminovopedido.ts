import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getUserTokens } from "./utils";

const pedidoId = event.params.pedidoId;
const pedidoData = snapshot.data();
const numeroPedido = pedidoData?.numeroPedido ?? pedidoId;

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
      const tokenToAdminMap: Record<string, string> = {};

      adminSnapshot.forEach((doc) => {
        const docTokens = getUserTokens(doc);
        docTokens.forEach(token => tokenToAdminMap[token] = doc.id);
        tokens.push(...docTokens);
      });

      const uniqueTokens = Array.from(new Set(tokens));
      if (uniqueTokens.length === 0) {
        logger.info("[notifyAdminNewPedido] Nenhum token de admin encontrado.");
        return;
      }

const messagePayload = {
  notification: {
    title: "Novo pedido recebido",
    body: `Pedido nº ${numeroPedido} foi criado.`,
  },
  android: {
    notification: {
      channelId: "pedidos_channel",
      sound: "default",
    },
  },
};

      const messaging = admin.messaging();
      const BATCH_SIZE = 500;

      for (let i = 0; i < uniqueTokens.length; i += BATCH_SIZE) {
        const batchTokens = uniqueTokens.slice(i, i + BATCH_SIZE);
        logger.info(`[notifyAdminNewPedido] Enviando notificação para ${batchTokens.length} tokens`);

        const response = await messaging.sendEachForMulticast({
          ...messagePayload,
          tokens: batchTokens,
        });

        logger.info(`[notifyAdminNewPedido] Envio concluído: sucesso=${response.successCount}, falhas=${response.failureCount}`);

        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const err = resp.error;
            const token = batchTokens[idx];
            const adminId = tokenToAdminMap[token];

            logger.error(`[notifyAdminNewPedido] Falha ao enviar para token ${token}:`, err);

            if (err &&
                (err.code === 'messaging/registration-token-not-registered' ||
                 err.code === 'messaging/invalid-argument') &&
                adminId
            ) {
              admin.firestore()
                .collection('users')
                .doc(adminId)
                .collection('tokens')
                .doc(token)
                .delete()
                .catch(e => logger.error("Erro ao remover token inválido:", e));
            }
          }
        });
      }

    } catch (error) {
      logger.error("[notifyAdminNewPedido] Erro ao processar notificação:", error);
    }
  }
);
