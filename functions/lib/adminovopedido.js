"use strict";
// // src/adminovopedido.ts
// import * as admin from "firebase-admin";
// import { onDocumentCreated } from "firebase-functions/v2/firestore";
// import * as logger from "firebase-functions/logger";
// import { sendWhatsAppMessage } from "./sendWhatsAppMessage"; // ajuste o caminho se necessário
//
// if (!admin.apps.length) {
//   admin.initializeApp();
// }
//
// export const notifyAdminNewPedido = onDocumentCreated(
//   { document: "pedidos/{pedidoId}" },
//   async (event) => {
//     const snapshot = event.data;
//     const pedidoId = event.params.pedidoId;
//
//     if (!snapshot) {
//       logger.error("[notifyAdminNewPedido] Snapshot vazio para novo pedido:", pedidoId);
//       return;
//     }
//
//     const pedidoData = snapshot.data();
//     const numeroPedido = pedidoData?.numeroPedido ?? pedidoId;
//     const clienteNome = pedidoData?.nomeUsuario ?? "Cliente";
//     const clienteTelefone = pedidoData?.telefone;
//
//     logger.info("[notifyAdminNewPedido] Novo pedido criado:", pedidoId);
//
//     try {
//       // Envia WhatsApp para o cliente
//       if (clienteTelefone) {
//         const telefoneFormatado = clienteTelefone.startsWith("+")
//           ? clienteTelefone
//           : `+${clienteTelefone.replace(/\D/g, "")}`;
//
//         const mensagem = `Olá ${clienteNome}, seu pedido nº ${numeroPedido} foi recebido com sucesso! 🍞🥖`;
//         await sendWhatsAppMessage(telefoneFormatado, mensagem);
//         logger.info(`[notifyAdminNewPedido] WhatsApp enviado para ${telefoneFormatado}`);
//       } else {
//         logger.warn(`[notifyAdminNewPedido] Cliente sem telefone cadastrado para pedido ${numeroPedido}`);
//       }
//
//       // Notifica todos os admins via FCM
//       const adminSnapshot = await admin.firestore()
//         .collection("users")
//         .where("role", "==", "admin")
//         .get();
//
//       logger.info(`[notifyAdminNewPedido] Admins encontrados: ${adminSnapshot.size}`);
//
//       const tokens: string[] = [];
//       const tokenToAdminMap: Record<string, string> = {};
//
//       adminSnapshot.forEach((doc) => {
//         const data = doc.data();
//         const docTokens: string[] = data?.fcmTokens ?? [];
//         docTokens.forEach(token => {
//           tokenToAdminMap[token] = doc.id;
//           tokens.push(token);
//         });
//       });
//
//       const uniqueTokens = Array.from(new Set(tokens));
//       if (uniqueTokens.length === 0) {
//         logger.info("[notifyAdminNewPedido] Nenhum token de admin encontrado.");
//         return;
//       }
//
//       const messagePayload = {
//         notification: {
//           title: "Novo pedido recebido",
//           body: `Pedido nº ${numeroPedido} foi criado.`,
//         },
//         android: {
//           notification: {
//             channelId: "pedidos_channel",
//             sound: "default",
//           },
//         },
//       };
//
//       const messaging = admin.messaging();
//       const BATCH_SIZE = 500;
//
//       for (let i = 0; i < uniqueTokens.length; i += BATCH_SIZE) {
//         const batchTokens = uniqueTokens.slice(i, i + BATCH_SIZE);
//         logger.info(`[notifyAdminNewPedido] Enviando notificação para ${batchTokens.length} tokens`);
//
//         const response = await messaging.sendEachForMulticast({
//           ...messagePayload,
//           tokens: batchTokens,
//         });
//
//         logger.info(`[notifyAdminNewPedido] Envio concluído: sucesso=${response.successCount}, falhas=${response.failureCount}`);
//
//         // Remove tokens inválidos do Firestore
//         response.responses.forEach((resp, idx) => {
//           if (!resp.success) {
//             const err = resp.error;
//             const token = batchTokens[idx];
//             const adminId = tokenToAdminMap[token];
//
//             logger.error(`[notifyAdminNewPedido] Falha ao enviar para token ${token}:`, err);
//
//             if (
//               err &&
//               (err.code === "messaging/registration-token-not-registered" ||
//                 err.code === "messaging/invalid-argument") &&
//               adminId
//             ) {
//               admin.firestore()
//                 .collection("users")
//                 .doc(adminId)
//                 .update({
//                   fcmTokens: admin.firestore.FieldValue.arrayRemove(token),
//                 })
//                 .then(() =>
//                   logger.info(`[notifyAdminNewPedido] Token inválido removido do admin ${adminId}`)
//                 )
//                 .catch((e) =>
//                   logger.error("[notifyAdminNewPedido] Erro ao remover token inválido:", e)
//                 );
//             }
//           }
//         });
//       }
//     } catch (error) {
//       logger.error("[notifyAdminNewPedido] Erro ao processar notificação:", error);
//     }
//   }
// );
