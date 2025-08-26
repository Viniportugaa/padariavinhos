"use strict";
// import * as admin from "firebase-admin";
// import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
// import { logger } from "firebase-functions";
//
// if (!admin.apps.length) {
//   admin.initializeApp();
// }
//
// // Função auxiliar para envio de FCM
// async function sendFcmMessage(token: string, title: string, body: string, data: any = {}) {
//   const message = {
//     token,
//     notification: { title, body },
//     data,
//   };
//
//   try {
//     await admin.messaging().send(message);
//     logger.info(`✅ Notificação enviada para token: ${token}`);
//   } catch (error) {
//     logger.error("❌ Erro ao enviar notificação", error);
//   }
// }
//
// // --- Notificação para novos pedidos (ADMIN) ---
// export const sendOrderNotification = onDocumentCreated(
//   { document: "pedidos/{pedidoId}", region: "us-central1" },
//   async (event) => {
//     const pedido = event.data?.data();
//     if (!pedido) return;
//
//     const { nomeUsuario, total } = pedido;
//
//     // Busca apenas admins
//     const adminsSnapshot = await admin.firestore()
//       .collection("users")
//       .where("role", "==", "admin")
//       .get();
//
//     for (const doc of adminsSnapshot.docs) {
//       const adminUser = doc.data();
//       if (adminUser?.fcmToken) {
//         await sendFcmMessage(
//           adminUser.fcmToken,
//           "📦 Novo Pedido Recebido",
//           `Pedido de ${nomeUsuario} no valor de R$${total.toFixed(2)}`,
//           { pedidoId: event.params.pedidoId }
//         );
//       }
//     }
//   }
// );
//
// // --- Notificação para mudança de status (CLIENTE) ---
// export const notifyOrderStatus = onDocumentUpdated(
//   { document: "pedidos/{pedidoId}", region: "us-central1" },
//   async (event) => {
//     const before = event.data?.before.data();
//     const after = event.data?.after.data();
//
//     if (!before || !after) return;
//     if (before.status === after.status) return; // só se status mudou
//
//     const { userId, status, nomeUsuario } = after;
//
//     // Busca o cliente dono do pedido
//     const userDoc = await admin.firestore().collection("users").doc(userId).get();
//     const user = userDoc.data();
//
//     if (user?.fcmToken) {
//       await sendFcmMessage(
//         user.fcmToken,
//         "🔔 Status do Pedido Atualizado",
//         `Olá ${nomeUsuario}, seu pedido agora está "${status}".`,
//         {
//           pedidoId: event.params.pedidoId,
//           status,
//         }
//       );
//       logger.info(`✅ Status atualizado enviado para ${nomeUsuario} (${userId})`);
//     }
//   }
// );
