// index.ts
import * as admin from "firebase-admin";
admin.initializeApp();

// Imports das triggers
import { sendNewPedidoNotification } from "./sendNewPedidoNotification";
import { buildNotification } from "./buildNotification";
import { notifyAdminNewPedido } from "./notifyAdminNewPedido"
// Exports das triggers
export {
  sendNewPedidoNotification
};

export {
    buildNotification
};

export {
  notifyAdminNewPedido,
};