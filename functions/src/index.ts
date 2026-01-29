import * as admin from "firebase-admin";
admin.initializeApp();

import { sendNewPedidoNotification } from "./sendNewPedidoNotification";
import { buildNotification } from "./buildNotification";
import { notifyAdminNewPedido } from "./notifyAdminNewPedido";
import { notifyUserPedidoStatusChange } from "./notifyUserPedidoStatusChange";
import { notifyAdminPedidosPendentesHoje } from "./notifyAdminPedidosPendentesHoje";
import { notifyGarcomCall } from "./notifyGarcomCall";

export * from "./notifyGarcomCall";
export * from "./notifyAdminNewPedido";
export * from "./notifyUserPedidoStatusChange";
export * from "./notifyAdminPedidosPendentesHoje";
export * from "./sendNewPedidoNotification";
export * from "./buildNotification";
