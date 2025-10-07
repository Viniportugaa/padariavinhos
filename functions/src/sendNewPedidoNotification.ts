// File: functions/src/index.ts
import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = getFirestore();

// Trigger when a new pedido is created
export const sendNewPedidoNotification = onDocumentCreated(
  "pedidos/{pedidoId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No snapshot data found");
      return;
    }

    const pedidoData = snapshot.data();
    const userId = pedidoData.userId;

    if (!userId) {
      logger.error("Pedido has no userId");
      return;
    }

    try {
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        logger.error(`User ${userId} not found`);
        return;
      }

      const { fcmTokens } = userDoc.data() as { fcmTokens?: string[] };

      if (!fcmTokens || fcmTokens.length === 0) {
        logger.info(`User ${userId} has no fcmTokens`);
        return;
      }

      const message = {
        notification: {
          title: "Novo pedido!",
          body: "Você recebeu um novo pedido.",
        },
        tokens: fcmTokens,
      };

      const response = await getMessaging().sendEachForMulticast(message);
      logger.info(`Notifications sent to user ${userId}`, response);
    } catch (error) {
      logger.error("Error sending notification", error);
    }
  }
);
