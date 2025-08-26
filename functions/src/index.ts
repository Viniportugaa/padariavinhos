// index.ts
import * as admin from "firebase-admin";
admin.initializeApp();  // Inicialização única

import { notifyPedidoStatusChange } from "./pedidostatus";
import { notifyProdutoDisponivel } from "./produtonovodisp";
import { notifyAdminNewPedido } from "./adminovopedido";

export { notifyPedidoStatusChange, notifyProdutoDisponivel, notifyAdminNewPedido };
