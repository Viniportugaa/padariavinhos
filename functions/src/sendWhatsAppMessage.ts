import fetch from "node-fetch";

// No v2, os secrets são lidos direto do process.env
const whatsappToken = process.env.WHATSAPP_TOKEN;
const whatsappPhoneId = process.env.WHATSAPP_PHONE_ID;

export async function sendWhatsAppMessage(to: string, message: string) {
if (!whatsappToken || !whatsappPhoneId) {
  console.error("[notifyPedidoCliente] Variáveis de ambiente não definidas");
}

  const res = await fetch(`https://graph.facebook.com/v17.0/${WHATSAPP_PHONE_ID}/messages`, {
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
