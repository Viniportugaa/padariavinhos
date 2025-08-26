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
exports.notifyPedidoStatusChange = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const utils_1 = require("./utils");
exports.notifyPedidoStatusChange = (0, firestore_1.onDocumentUpdated)({ document: "pedidos/{pedidoId}" }, async (event) => {
    try {
        const before = event.data?.before;
        const after = event.data?.after;
        const pedidoId = event.params.pedidoId;
        if (!after) {
            logger.error("Snapshot vazio para pedido atualizado:", pedidoId);
            return;
        }
        const statusBefore = before?.data()?.status;
        const statusAfter = after.data()?.status;
        if (statusBefore === statusAfter) {
            logger.info(`Pedido ${pedidoId} atualizado mas status não mudou (${statusAfter}).`);
            return;
        }
        logger.info(`Pedido ${pedidoId} mudou de ${statusBefore} para ${statusAfter}`);
        // Buscar o usuário dono do pedido
        const userId = after.data()?.userId;
        if (!userId) {
            logger.error(`Pedido ${pedidoId} não possui userId.`);
            return;
        }
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(userId)
            .get();
        if (!userDoc.exists) {
            logger.error(`Usuário ${userId} não encontrado para pedido ${pedidoId}`);
            return;
        }
        const tokens = (0, utils_1.getUserTokens)(userDoc); // ✅ aqui agora está dentro do try
        if (tokens.length === 0) {
            logger.warn(`Usuário ${userId} não possui tokens FCM salvos.`);
            return;
        }
        // Enviar notificações
        const response = await admin.messaging().sendMulticast({
            tokens,
            notification: {
                title: "Status do pedido atualizado",
                body: `Seu pedido ${pedidoId} está agora: ${statusAfter}`,
            },
        });
        logger.info(`Notificação enviada para ${userId} | sucesso: ${response.successCount}, falhas: ${response.failureCount}`);
        // Log detalhado de falhas
        if (response.failureCount > 0) {
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    logger.error(`Erro ao enviar para token ${tokens[idx]}:`, resp.error);
                }
            });
        }
    }
    catch (err) {
        logger.error("Erro inesperado ao processar notifyPedidoStatusChange:", err);
    }
});
