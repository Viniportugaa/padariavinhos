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
  }
);
