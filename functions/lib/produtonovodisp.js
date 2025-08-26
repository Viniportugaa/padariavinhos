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
exports.notifyProdutoDisponivel = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const utils_1 = require("./utils");
exports.notifyProdutoDisponivel = (0, firestore_1.onDocumentUpdated)({ document: "produtos/{produtoId}" }, async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    const produtoId = event.params.produtoId;
    if (!after)
        return;
    const disponivelBefore = before?.data()?.disponivel;
    const disponivelAfter = after.data()?.disponivel;
    if (disponivelBefore === disponivelAfter)
        return;
    if (!disponivelAfter)
        return; // só enviar quando ficar disponível
    logger.info(`Produto ${produtoId} agora disponível`);
    // Notificar todos os clientes
    const usersSnapshot = await admin.firestore()
        .collection("users")
        .where("role", "==", "cliente")
        .get();
    const tokens = [];
    usersSnapshot.forEach((doc) => {
        tokens.push(...(0, utils_1.getUserTokens)(doc));
    });
    if (tokens.length === 0)
        return;
    await admin.messaging().sendMulticast({
        tokens,
        notification: {
            title: "Produto disponível",
            body: `O produto ${after.data()?.nome} está disponível!`,
        },
    });
    logger.info("Notificações enviadas para clientes:", tokens.length);
} // fecha async
); // fecha onDocumentUpdated
