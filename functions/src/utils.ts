export function getUserTokens(userDoc: FirebaseFirestore.DocumentSnapshot): string[] {
  const data = userDoc.data();
  if (!data) return [];

  let tokens: string[] = [];

  if (Array.isArray(data.fcmTokens) && data.fcmTokens.length > 0) {
    tokens.push(...data.fcmTokens);
  }

  if (typeof data.fcmToken === "string" && data.fcmToken.trim() !== "") {
    tokens.push(data.fcmToken);
  }

  return Array.from(new Set(tokens)); // remove duplicados
}
