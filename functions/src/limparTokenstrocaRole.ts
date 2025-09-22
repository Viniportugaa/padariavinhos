import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

// Função dispara quando o campo "role" do user muda
export const clearTokensOnRoleChange = onDocumentUpdated(
  { document: "users/{userId}" },
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    const userId = event.params.userId;

    if (!before || !after) return;

    const roleBefore = before.data()?.role;
    const roleAfter = after.data()?.role;

    // só faz algo se realmente mudou
    if (roleBefore === roleAfter) return;

    logger.info(`[clearTokensOnRoleChange] Usuário ${userId} mudou de role: ${roleBefore} -> ${roleAfter}`);

    // Apaga o array de tokens
    await admin.firestore()
      .collection("users")
      .doc(userId)
      .update({ fcmTokens: [] })
      .catch((e) => logger.error(`[clearTokensOnRoleChange] Erro ao limpar tokens do usuário ${userId}`, e));

    logger.info(`[clearTokensOnRoleChange] Tokens removidos do usuário ${userId}`);
  }
);
