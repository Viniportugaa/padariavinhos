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
const logger = __importStar(require("firebase-functions/logger"));
const sendWhatsAppMessage_1 = require("./sendWhatsAppMessage");
// Trigger Firestore v2
exports.notifyPedidoCliente = functions.onDocumentCreated("pedidos/{pedidoId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot)
        return;
    const pedidoData = snapshot.data();
    if (!pedidoData)
        return;
    const numeroPedido = pedidoData.numeroPedido ?? event.params.pedidoId;
    const clienteNome = pedidoData.nomeUsuario ?? "Cliente";
    let clienteTelefone = pedidoData.telefone;
    logger.info(`[notifyPedidoCliente] Novo pedido: ${numeroPedido}`);
    if (!clienteTelefone) {
        logger.warn(`[notifyPedidoCliente] Cliente sem telefone cadastrado para pedido ${numeroPedido}`);
        return;
    }
    // Garantir formato internacional +55
    if (!clienteTelefone.startsWith("+")) {
        clienteTelefone = `+${clienteTelefone.replace(/\D/g, "")}`;
    }
    const mensagem = `Olá ${clienteNome}, seu pedido nº ${numeroPedido} foi recebido com sucesso! 🍞🥖`;
    try {
        await (0, sendWhatsAppMessage_1.sendWhatsAppMessage)(clienteTelefone, mensagem);
        logger.info(`[notifyPedidoCliente] WhatsApp enviado para ${clienteTelefone}`);
    }
    catch (error) {
        logger.error(`[notifyPedidoCliente] Erro ao enviar WhatsApp para pedido ${numeroPedido}:`, error);
    }
});
