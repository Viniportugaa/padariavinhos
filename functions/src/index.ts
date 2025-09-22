// index.ts
import * as admin from "firebase-admin";
admin.initializeApp();

// Imports
import { notifyAdminNewPedido } from "./adminovopedido";
import { clearTokensOnRoleChange } from "./limparTokenstrocaRole";
import { notifyPedidoCliente } from "./notifyPedidoCliente";

// Exports centralizados
export {
  notifyAdminNewPedido,
  clearTokensOnRoleChange,
  notifyPedidoCliente,

  // notifyPedidoStatusChange,
  // notifyProdutoDisponivel,
};
