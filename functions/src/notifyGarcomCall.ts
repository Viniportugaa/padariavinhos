import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const db = getFirestore();

export const notifyGarcomCall = onDocumentCreated(
  "notificacoes_garcom/{notificacaoId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const mesa = data.mesa;
    const lido = data.lido;

    // Notificações só enviam quando criadas e ainda não lidas
    if (lido === true) return;

    logger.info(`📣 Chamada de garçom recebida da mesa ${mesa}`);

    // Buscar todos usuários admins
    const adminsSnap = await db
      .collection("users")
      .where("role", "==", "admin")
      .get();

    if (adminsSnap.empty) {
      logger.warn("Nenhum admin encontrado com role == admin");
      return;
    }

    const tokens: string[] = [];

    adminsSnap.forEach((doc) => {
      const user = doc.data();
      if (
        user.fcmTokens &&
        Array.isArray(user.fcmTokens) &&
        user.fcmTokens.length
      ) {
        tokens.push(...user.fcmTokens);
      }
    });

    if (tokens.length === 0) {
      logger.warn("Nenhum admin possui tokens FCM salvos");
      return;
    }

    const message = {
      notification: {
        title: "🚨 Chamada de Garçom",
        body: `A mesa ${mesa} solicitou atendimento`,
      },
      data: {
        mesa: String(mesa),
        tipo: "chamada-garcom",
      },
      tokens,
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);
      logger.info(
        `Notificação enviada aos admins. Sucesso: ${response.successCount}, Falhas: ${response.failureCount}`
      );
    } catch (err) {
      logger.error("Erro ao enviar notificação de chamada de garçom", err);
    }
  }
);
