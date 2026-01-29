import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const db = getFirestore();

export const notifyUserPedidoStatusChange = onDocumentUpdated(
  "pedidos/{pedidoId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    // Verifica se houve mudança de status
    if (before.status === after.status) return;

    const userId = after.userId;
    const novoStatus = after.status;
    const numeroPedido = after.numeroPedido;

    logger.info(`Pedido #${numeroPedido} alterado para status: ${novoStatus}`);

    // Busca usuário para pegar tokens FCM
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      logger.warn(`Usuário ${userId} não encontrado`);
      return;
    }

    const userData = userDoc.data();
    if (!userData?.fcmTokens || !Array.isArray(userData.fcmTokens) || !userData.fcmTokens.length) {
      logger.warn(`Usuário ${userId} não possui tokens FCM`);
      return;
    }

    const tokens = userData.fcmTokens;

    const message = {
      notification: {
        title: `Atualização do Pedido #${numeroPedido}`,
        body: `Seu pedido agora está: ${novoStatus}`,
      },
      data: {
        pedidoId: event.params.pedidoId,
        status: novoStatus,
      },
      tokens,
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);
      logger.info(
        `Notificação enviada para usuário ${userId}. Sucesso: ${response.successCount}, Falhas: ${response.failureCount}`
      );
    } catch (err) {
      logger.error("Erro ao enviar notificação de status para usuário", err);
    }
  }
);
