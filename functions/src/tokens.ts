import * as admin from "firebase-admin";

async function getTokensByRole(role: string): Promise<string[]> {
  const snapshot = await admin.firestore()
    .collection("users")
    .where("role", "==", role)
    .get();

  const tokens: string[] = [];
  snapshot.forEach((doc: FirebaseFirestore.DocumentSnapshot) => {
    const data = doc.data();
    if (data?.fcmTokens && typeof data.fcmTokens === "object") {
      tokens.push(...Object.keys(data.fcmTokens));
    }
  });

  return tokens;
}
