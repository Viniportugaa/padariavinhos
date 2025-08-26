"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUserTokens = getUserTokens;
function getUserTokens(userDoc) {
    const data = userDoc.data();
    if (!data)
        return [];
    if (Array.isArray(data.fcmTokens) && data.fcmTokens.length > 0) {
        return data.fcmTokens;
    }
    if (typeof data.fcmToken === "string" && data.fcmToken.trim() !== "") {
        return [data.fcmToken];
    }
    return [];
}
