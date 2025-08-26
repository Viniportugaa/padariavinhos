import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getUserTokens } from "./utils";

export const notifyProdutoDisponivel = onDocumentUpdated(
  { document: "produtos/{produtoId}" },
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    const produtoId = event.params.produtoId;

    if (!after) return;

    const disponivelBefore = before?.data()?.disponivel;
    const disponivelAfter = after.data()?.disponivel;

    if (disponivelBefore === disponivelAfter) return;
    if (!disponivelAfter) return; // só enviar quando ficar disponível

    logger.info(`Produto ${produtoId} agora disponível`);

    // Notificar todos os clientes
    const usersSnapshot = await admin.firestore()
      .collection("users")
      .where("role", "==", "cliente")
      .get();

    const tokens: string[] = [];
    usersSnapshot.forEach((doc: FirebaseFirestore.DocumentSnapshot) => {
      tokens.push(...getUserTokens(doc));
    });

    if (tokens.length === 0) return;

    await admin.messaging().sendMulticast({
      tokens,
      notification: {
        title: "Produto disponível",
        body: `O produto ${after.data()?.nome} está disponível!`,
      },
    });

    logger.info("Notificações enviadas para clientes:", tokens.length);
  } // fecha async
); // fecha onDocumentUpdated