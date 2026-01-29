// notifyAdminNewPedido.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();

/**
 * Build notification for admins when a new pedido is created
 */
function buildAdminNotification(pedido: any) {
  return {
    notification: {
      title: `Novo Pedido #${pedido.numeroPedido}`,
      body: `${pedido.nomeUsuario} fez um pedido de R$${pedido.totalFinal.toFixed(2)}`,
    },
    data: {
      pedidoId: pedido.id,
      userId: pedido.userId,
      numeroPedido: pedido.numeroPedido.toString(),
    },
  };
}

/**
 * Send notification to all admins with FCM tokens
 */
async function dispatchNotificationToAdmins(message: any) {
  logger.info("Buscando admins com tokens FCM...");

  const adminsSnapshot = await db
    .collection("users")
    .where("role", "==", "admin")
    .get();

  if (adminsSnapshot.empty) {
    logger.info("Nenhum admin encontrado");
    return;
  }

  const tokens: string[] = [];
  adminsSnapshot.forEach((doc) => {
    const data = doc.data();
    if (data.fcmTokens && Array.isArray(data.fcmTokens)) {
      tokens.push(...data.fcmTokens);
    }
  });

  if (!tokens.length) {
    logger.info("Nenhum token FCM encontrado para admins");
    return;
  }

  try {
    const response = await getMessaging().sendEachForMulticast({
      ...message,
      tokens,
    });

    logger.info(
      `Notificação enviada para admins. Success: ${response.successCount}, Failures: ${response.failureCount}`,
      response
    );
  } catch (err) {
    logger.error("Erro ao enviar notificação para admins", err);
  }
}

/**
 * Trigger: On new pedido created
 */
export const notifyAdminNewPedido = onDocumentCreated(
  "pedidos/{pedidoId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("Snapshot de pedido criado está vazio");
      return;
    }

    const pedido = snapshot.data();
    pedido.id = snapshot.id;

    logger.info(`Novo pedido criado: ${pedido.id}, usuário: ${pedido.userId}`);

    const message = buildAdminNotification(pedido);
    await dispatchNotificationToAdmins(message);
  }
);
