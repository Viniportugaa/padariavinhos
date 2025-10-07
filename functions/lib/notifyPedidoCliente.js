"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyPedidoCliente = void 0;
const functions = __importStar(require("firebase-functions/v2/firestore"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
exports.notifyPedidoCliente = functions.firestore
    .document("pedidos/{pedidoId}")
    .onCreate(async (event) => {
    try {
        const snapshot = event.data; // snapshot é acessado via event.data
        const context = event; // context.params está em event.params
        if (!snapshot)
            return;
        const data = snapshot;
        console.log(`[notifyPedidoCliente] Novo pedido: ${data.numeroPedido}`);
        // Recupera tokens FCM do usuário
        const userSnap = await admin.firestore().collection("users").doc(data.userId).get();
        const fcmTokens = userSnap.get("fcmTokens") || [];
        if (!fcmTokens.length) {
            console.log(`[notifyPedidoCliente] Nenhum token FCM para pedido ${data.numeroPedido}`);
            return;
        }
        // Mensagem push
        const mensagem = {
            tokens: fcmTokens,
            notification: {
                title: "Pedido recebido ✅",
                body: `Olá ${data.nomeUsuario}, seu pedido nº ${data.numeroPedido} foi recebido!`,
            },
            data: {
                pedidoId: context.params.pedidoId,
                numeroPedido: String(data.numeroPedido),
            },
        };
        // Envia push
        const messaging = admin.messaging();
        const response = await messaging.sendMulticast(mensagem);
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                console.error(`[notifyPedidoCliente] Erro push para ${fcmTokens[idx]}:`, resp.error);
            }
        });
        console.log(`[notifyPedidoCliente] Push enviado para pedido ${data.numeroPedido}`);
    }
    catch (err) {
        console.error("[notifyPedidoCliente] Erro geral:", err);
    }
});
