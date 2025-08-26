import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getUserTokens } from "./utils";

export const notifyAdminNewPedido = onDocumentCreated(
  { document: "pedidos/{pedidoId}" },
  async (event) => {
    const snapshot = event.data;
    const pedidoId = event.params.pedidoId;

    if (!snapshot) {
      logger.error("Snapshot vazio para novo pedido:", pedidoId);
      return;
    }

    logger.info("Novo pedido criado:", pedidoId);

    // Busca todos os admins
    const adminSnapshot = await admin.firestore()
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const tokens: string[] = [];
    adminSnapshot.forEach((doc: FirebaseFirestore.DocumentSnapshot) => {
      tokens.push(...getUserTokens(doc));
    });

    if (tokens.length === 0) {
      logger.info("Nenhum token de admin encontrado.");
      return;
    }

    const message = {
      notification: {
        title: "Novo pedido recebido",
        body: `Pedido ${pedidoId} foi criado.`,
      },
      tokens,
    };

    await admin.messaging().sendMulticast(message);
    logger.info("Notificações enviadas apenas aos admins:", tokens.length);
  }
);