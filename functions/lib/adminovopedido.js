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
exports.notifyAdminNewPedido = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const utils_1 = require("./utils");
if (!admin.apps.length) {
    admin.initializeApp();
}
exports.notifyAdminNewPedido = (0, firestore_1.onDocumentCreated)({ document: "pedidos/{pedidoId}" }, async (event) => {
    const snapshot = event.data;
    const pedidoId = event.params.pedidoId;
    if (!snapshot) {
        logger.error("[notifyAdminNewPedido] Snapshot vazio para novo pedido:", pedidoId);
        return;
    }
    logger.info("[notifyAdminNewPedido] Novo pedido criado:", pedidoId);
    try {
        // Busca todos os admins
        const adminSnapshot = await admin.firestore()
            .collection("users")
            .where("role", "==", "admin")
            .get();
        logger.info(`[notifyAdminNewPedido] Admins encontrados: ${adminSnapshot.size}`);
        const tokens = [];
        const tokenToAdminMap = {};
        adminSnapshot.forEach((doc) => {
            const docTokens = (0, utils_1.getUserTokens)(doc);
            docTokens.forEach(token => tokenToAdminMap[token] = doc.id);
            tokens.push(...docTokens);
        });
        const uniqueTokens = Array.from(new Set(tokens));
        if (uniqueTokens.length === 0) {
            logger.info("[notifyAdminNewPedido] Nenhum token de admin encontrado.");
            return;
        }
        const messagePayload = {
            notification: {
                title: "Novo pedido recebido",
                body: `Pedido ${pedidoId} foi criado.`,
            },
            android: {
                notification: {
                    channelId: "pedidos_channel",
                    sound: "default",
                },
            },
        };
        const messaging = admin.messaging();
        const BATCH_SIZE = 500;
        for (let i = 0; i < uniqueTokens.length; i += BATCH_SIZE) {
            const batchTokens = uniqueTokens.slice(i, i + BATCH_SIZE);
            logger.info(`[notifyAdminNewPedido] Enviando notificação para ${batchTokens.length} tokens`);
            const response = await messaging.sendEachForMulticast({
                ...messagePayload,
                tokens: batchTokens,
            });
            logger.info(`[notifyAdminNewPedido] Envio concluído: sucesso=${response.successCount}, falhas=${response.failureCount}`);
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    const err = resp.error;
                    const token = batchTokens[idx];
                    const adminId = tokenToAdminMap[token];
                    logger.error(`[notifyAdminNewPedido] Falha ao enviar para token ${token}:`, err);
                    if (err &&
                        (err.code === 'messaging/registration-token-not-registered' ||
                            err.code === 'messaging/invalid-argument') &&
                        adminId) {
                        admin.firestore()
                            .collection('users')
                            .doc(adminId)
                            .collection('tokens')
                            .doc(token)
                            .delete()
                            .catch(e => logger.error("Erro ao remover token inválido:", e));
                    }
                }
            });
        }
    }
    catch (error) {
        logger.error("[notifyAdminNewPedido] Erro ao processar notificação:", error);
    }
});
