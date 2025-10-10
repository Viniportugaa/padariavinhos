import * as admin from "firebase-admin";
admin.initializeApp();

import { sendNewPedidoNotification } from "./sendNewPedidoNotification";
import { buildNotification } from "./buildNotification";
import { notifyAdminNewPedido } from "./notifyAdminNewPedido";
import { notifyUserPedidoStatusChange } from "./notifyUserPedidoStatusChange";
import { notifyAdminPedidosPendentesHoje } from "./notifyAdminPedidosPendentesHoje";

export {
  sendNewPedidoNotification,
  buildNotification,
  notifyAdminNewPedido,
  notifyUserPedidoStatusChange,
  notifyAdminPedidosPendentesHoje,
};
