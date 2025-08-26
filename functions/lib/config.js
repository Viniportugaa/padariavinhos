"use strict";
// import * as admin from "firebase-admin";
// import { onSchedule } from "firebase-functions/v2/scheduler";
//
// if (!admin.apps.length) {
//   admin.initializeApp();
// }
// const db = admin.firestore();
//
// // Abre a padaria às 08:00
// export const abrirPadaria = onSchedule(
//   {
//     schedule: "0 8 * * *", // 08:00 todos os dias
//     timeZone: "America/Sao_Paulo",
//   },
//   async () => {
//     await db.collection("config").doc("padaria").set({ aberto: true }, { merge: true });
//     console.log("✅ Padaria aberta às 08:00");
//   }
// );
//
// // Fecha a padaria às 20:00
// export const fecharPadaria = onSchedule(
//   {
//     schedule: "0 20 * * *", // 20:00 todos os dias
//     timeZone: "America/Sao_Paulo",
//   },
//   async () => {
//     await db.collection("config").doc("padaria").set({ aberto: false }, { merge: true });
//     console.log("✅ Padaria fechada às 20:00");
//   }
// );
