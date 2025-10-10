import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const db = getFirestore();

export const notifyAdminPedidosPendentesHoje = onSchedule(
  {
    schedule: "every 1 hours", // ou "0 7 * * *" para rodar todo dia às 07:00
    timeZone: "America/Sao_Paulo",
  },
  async () => {
    logger.info("Verificando pedidos pendentes para hoje...");

    const hoje = new Date();
    const inicioDoDia = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), 0, 0, 0);
    const fimDoDia = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), 23, 59, 59);

    const pedidosSnapshot = await db
      .collection("pedidos")
      .where("status", "==", "pendente")
      .where("dataHoraEntrega", ">=", inicioDoDia)
      .where("dataHoraEntrega", "<=", fimDoDia)
      .get();

    if (pedidosSnapshot.empty) {
      logger.info("Nenhum pedido pendente para hoje.");
      return;
    }

    const pedidos = pedidosSnapshot.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));

    const count = pedidos.length;
    const adminSnapshot = await db.collection("users").where("role", "==", "admin").get();

    const tokens: string[] = [];
    adminSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.fcmTokens && Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
    });

    if (!tokens.length) {
      logger.info("Nenhum token FCM encontrado para admins");
      return;
    }

    const message = {
      notification: {
        title: `Pedidos Pendentes de Hoje`,
        body: `Existem ${count} pedidos pendentes com entrega hoje.`,
      },
      data: {
        tipo: "pendentesHoje",
        total: count.toString(),
      },
      tokens,
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);
      logger.info(
        `Notificação enviada aos admins. Sucesso: ${response.successCount}, Falhas: ${response.failureCount}`
      );
    } catch (err) {
      logger.error("Erro ao enviar notificação para admins", err);
    }
  }
);
