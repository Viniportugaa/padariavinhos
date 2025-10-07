// File: functions/src/index.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getFirestore } from "firebase-admin/firestore";

admin.initializeApp();
const db = getFirestore();

/**
 * Build notification message based on pedido data
 */
export function buildNotification(pedido: any, statusBefore?: string) {
  const baseTitle = `Pedido #${pedido.numeroPedido}`;
  let title = baseTitle;
  let body = "";

  if (!statusBefore) {
    // Novo pedido criado
    title = "Novo Pedido Recebido!";
    body = `${pedido.nomeUsuario} fez um pedido de R$${pedido.totalFinal.toFixed(2)}.`;
    logger.info(`Construindo notificação para novo pedido: ${pedido.id}`);
  } else if (pedido.status !== statusBefore) {
    switch (pedido.status) {
      case "aceito":
        body = `Seu pedido foi aceito e está em preparação.`;
        break;
      case "saiu para entrega":
        body = `Seu pedido saiu para entrega 🚚.`;
        break;
      case "entregue":
        body = `Pedido entregue com sucesso ✅.`;
        break;
      case "cancelado":
        body = `Seu pedido foi cancelado.`;
        break;
      default:
        body = `Status do seu pedido: ${pedido.status}`;
    }
    logger.info(`Construindo notificação para atualização de status do pedido: ${pedido.id}, de "${statusBefore}" para "${pedido.status}"`);
  } else {
    logger.info(`Status do pedido ${pedido.id} não mudou (${statusBefore}) - nenhuma notificação será enviada`);
  }

  return {
    notification: {
      title,
      body,
    },
    data: {
      pedidoId: pedido.id,
      status: pedido.status,
      userId: pedido.userId,
      numeroPedido: pedido.numeroPedido.toString(),
    },
  };
}

/**
 * Send notification to user's FCM tokens
 */
async function dispatchNotification(userId: string, message: any) {
  logger.info(`Tentando enviar notificação para usuário ${userId}...`);
  const userDoc = await db.collection("users").doc(userId).get();

  if (!userDoc.exists) {
    logger.error(`Usuário ${userId} não encontrado no Firestore`);
    return;
  }

  const userData = userDoc.data() as any;
  const fcmTokens: string[] = userData.fcmTokens || [];

  if (!fcmTokens.length) {
    logger.info(`Usuário ${userId} não possui tokens FCM`);
    return;
  }

  try {
    const response = await getMessaging().sendEachForMulticast({
      ...message,
      tokens: fcmTokens,
    });

    logger.info(`Notificação enviada para usuário ${userId}. Success: ${response.successCount}, Failures: ${response.failureCount}`, response);

    // Optional: log notification in Firestore
    await db
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .add({
        ...message.notification,
        data: message.data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    logger.info(`Notificação registrada no Firestore para o usuário ${userId}`);
  } catch (err) {
    logger.error(`Erro ao enviar notificação para o usuário ${userId}`, err);
  }
}

/**
 * Trigger: When a new pedido is created
 */
export const onPedidoCreated = onDocumentCreated("pedidos/{pedidoId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("Snapshot de pedido criado está vazio");
    return;
  }

  const pedido = snapshot.data();
  pedido.id = snapshot.id;
  logger.info(`Novo pedido criado: ${pedido.id}, usuário: ${pedido.userId}`);

  const message = buildNotification(pedido);
  await dispatchNotification(pedido.userId, message);
});

/**
 * Trigger: When a pedido is updated (check status changes)
 */
export const onPedidoUpdated = onDocumentUpdated("pedidos/{pedidoId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();

  if (!before || !after) {
    logger.error("Snapshot de pedido atualizado está vazio");
    return;
  }

  if (before.status === after.status) {
    logger.info(`Pedido ${event.data?.after.id} atualizado, mas o status não mudou (${before.status})`);
    return; // Only notify if status changed
  }

  after.id = event.data?.after.id;
  logger.info(`Pedido ${after.id} atualizado. Status de "${before.status}" para "${after.status}"`);
  const message = buildNotification(after, before.status);

  await dispatchNotification(after.userId, message);
});
