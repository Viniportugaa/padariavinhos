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
exports.notifyAdminNewPedido = (0, firestore_1.onDocumentCreated)({ document: "pedidos/{pedidoId}" }, async (event) => {
    const snapshot = event.data;
    const pedidoId = event.params.pedidoId;
    if (!snapshot) {
        logger.error("Snapshot vazio para novo pedido:", pedidoId);
        return;
    }
    logger.info("Novo pedido criado:", pedidoId);
    // Busca todos os admins
    const adminSnapshot = await admin.firestore()
        .collection("users")
        .where("role", "==", "admin")
        .get();
    const tokens = [];
    adminSnapshot.forEach((doc) => {
        tokens.push(...(0, utils_1.getUserTokens)(doc));
    });
    if (tokens.length === 0) {
        logger.info("Nenhum token de admin encontrado.");
        return;
    }
    const message = {
        notification: {
            title: "Novo pedido recebido",
            body: `Pedido ${pedidoId} foi criado.`,
        },
        tokens,
    };
    await admin.messaging().sendMulticast(message);
    logger.info("Notificações enviadas apenas aos admins:", tokens.length);
});
