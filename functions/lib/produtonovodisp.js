"use strict";
// import * as admin from "firebase-admin";
// import { onDocumentUpdated } from "firebase-functions/v2/firestore";
// import * as logger from "firebase-functions/logger";
// import { getUserTokens } from "./utils";
//
// if (!admin.apps.length) {
//   admin.initializeApp();
// }
//
// export const notifyProdutoDisponivel = onDocumentUpdated(
//   { document: "produtos/{produtoId}" },
//   async (event) => {
//     const before = event.data?.before;
//     const after = event.data?.after;
//     const produtoId = event.params.produtoId;
//
//     if (!after) return;
//
//     const disponivelBefore = before?.data()?.disponivel;
//     const disponivelAfter = after.data()?.disponivel;
//
//     if (disponivelBefore === disponivelAfter) return;
//     if (!disponivelAfter) return; // só enviar quando ficar disponível
//
//     logger.info(`Produto ${produtoId} agora disponível`);
//
//     // Notificar todos os clientes
//     const usersSnapshot = await admin.firestore()
//       .collection("users")
//       .where("role", "==", "cliente")
//       .get();
//
//     const tokens: string[] = [];
//     usersSnapshot.forEach((doc) => {
//       tokens.push(...getUserTokens(doc));
//     });
//
//     const uniqueTokens = Array.from(new Set(tokens));
//     if (uniqueTokens.length === 0) {
//       logger.info("Nenhum token de cliente encontrado.");
//       return;
//     }
//
//     const messagePayload = {
//       notification: {
//         title: "Produto disponível",
//         body: `O produto ${after.data()?.nome} está disponível!`,
//       },
//     };
//
//     const messaging: admin.messaging.Messaging = admin.messaging(); // tipagem explícita
//     const BATCH_SIZE = 500;
//
//     for (let i = 0; i < uniqueTokens.length; i += BATCH_SIZE) {
//       const batchTokens = uniqueTokens.slice(i, i + BATCH_SIZE);
//
//       const response = await messaging.sendMulticast({
//         ...messagePayload,
//         tokens: batchTokens,
//       });
//
//       logger.info(`Envio concluído: sucesso=${response.successCount}, falhas=${response.failureCount}`);
//
//       response.responses.forEach((resp: admin.messaging.SendResponse, idx: number) => {
//         if (!resp.success) {
//           logger.error(`Falha ao enviar para token ${batchTokens[idx]}:`, resp.error);
//         }
//       });
//     }
//   }
// );
