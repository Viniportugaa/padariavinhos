import * as admin from "firebase-admin";

export async function getTokensByRole(role: string): Promise<string[]> {
  const snapshot = await admin.firestore()
    .collection("users")
    .where("role", "==", role)
    .get();

  const tokens: string[] = [];
  snapshot.forEach((doc) => {
    const data = doc.data();
    if (Array.isArray(data?.fcmTokens)) {
      tokens.push(...data.fcmTokens);
    }
  });

  return Array.from(new Set(tokens)); // remove duplicados
}
