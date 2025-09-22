"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUserTokens = getUserTokens;
function getUserTokens(userDoc) {
    const data = userDoc.data();
    if (!data)
        return [];
    let tokens = [];
    if (Array.isArray(data.fcmTokens) && data.fcmTokens.length > 0) {
        tokens.push(...data.fcmTokens);
    }
    if (typeof data.fcmToken === "string" && data.fcmToken.trim() !== "") {
        tokens.push(data.fcmToken);
    }
    return Array.from(new Set(tokens)); // remove duplicados
}
