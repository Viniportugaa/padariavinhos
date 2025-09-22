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
exports.notifyPedidoCliente = exports.clearTokensOnRoleChange = exports.notifyAdminNewPedido = void 0;
// index.ts
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// Imports
const adminovopedido_1 = require("./adminovopedido");
Object.defineProperty(exports, "notifyAdminNewPedido", { enumerable: true, get: function () { return adminovopedido_1.notifyAdminNewPedido; } });
const limparTokenstrocaRole_1 = require("./limparTokenstrocaRole");
Object.defineProperty(exports, "clearTokensOnRoleChange", { enumerable: true, get: function () { return limparTokenstrocaRole_1.clearTokensOnRoleChange; } });
const notifyPedidoCliente_1 = require("./notifyPedidoCliente");
Object.defineProperty(exports, "notifyPedidoCliente", { enumerable: true, get: function () { return notifyPedidoCliente_1.notifyPedidoCliente; } });
