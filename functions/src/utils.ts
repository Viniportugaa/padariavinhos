// utils.ts
import * as admin from "firebase-admin";

export function getUserTokens(userDoc: FirebaseFirestore.DocumentSnapshot): string[] {
  const data = userDoc.data();
  if (!data) return [];

  if (Array.isArray(data.fcmTokens) && data.fcmTokens.length > 0) {
    return data.fcmTokens;
  }

  if (typeof data.fcmToken === "string" && data.fcmToken.trim() !== "") {
    return [data.fcmToken];
  }

  return [];
}
