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
exports.clearTokensOnRoleChange = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
// Função dispara quando o campo "role" do user muda
exports.clearTokensOnRoleChange = (0, firestore_1.onDocumentUpdated)({ document: "users/{userId}" }, async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    const userId = event.params.userId;
    if (!before || !after)
        return;
    const roleBefore = before.data()?.role;
    const roleAfter = after.data()?.role;
    // só faz algo se realmente mudou
    if (roleBefore === roleAfter)
        return;
    logger.info(`[clearTokensOnRoleChange] Usuário ${userId} mudou de role: ${roleBefore} -> ${roleAfter}`);
    // Apaga todos os tokens antigos do usuário
    const tokensCol = admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("tokens");
    const tokensSnap = await tokensCol.get();
    if (tokensSnap.empty) {
        logger.info(`[clearTokensOnRoleChange] Nenhum token para limpar do usuário ${userId}`);
        return;
    }
    const batch = admin.firestore().batch();
    tokensSnap.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    logger.info(`[clearTokensOnRoleChange] Tokens removidos do usuário ${userId}`);
});
