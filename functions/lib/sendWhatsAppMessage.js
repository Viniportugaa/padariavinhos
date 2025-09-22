"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendWhatsAppMessage = sendWhatsAppMessage;
const node_fetch_1 = __importDefault(require("node-fetch"));
// No v2, os secrets são lidos direto do process.env
const WHATSAPP_TOKEN = process.env.WHATSAPP_TOKEN;
const WHATSAPP_PHONE_ID = process.env.WHATSAPP_PHONE_ID;
async function sendWhatsAppMessage(to, message) {
    if (!WHATSAPP_TOKEN || !WHATSAPP_PHONE_ID) {
        throw new Error("As variáveis de ambiente WHATSAPP_TOKEN e WHATSAPP_PHONE_ID não estão definidas.");
    }
    const res = await (0, node_fetch_1.default)(`https://graph.facebook.com/v17.0/${WHATSAPP_PHONE_ID}/messages`, {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${WHATSAPP_TOKEN}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            messaging_product: "whatsapp",
            to,
            type: "text",
            text: { body: message },
        }),
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`Erro WhatsApp API: ${text}`);
    }
    return await res.json();
}
