"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupInvalidTokens = exports.onObservationUpdated = exports.onAlertUpdated = exports.onAlertCreated = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Initialize the Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
// ============================================================
// Helper functions
// ============================================================
/**
 * Sends an FCM notification to a list of tokens.
 * Handles invalid tokens gracefully.
 */
async function sendMulticastNotification(tokens, payload) {
    if (tokens.length === 0) {
        return { successCount: 0, failureCount: 0 };
    }
    try {
        const response = await messaging.sendEachForMulticast({
            tokens,
            ...payload,
        });
        // Clean up invalid tokens
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
            if (!resp.success && resp.error) {
                const errorCode = resp.error.code;
                if (errorCode === 'messaging/invalid-registration-token' ||
                    errorCode === 'messaging/registration-token-not-registered') {
                    failedTokens.push(tokens[idx]);
                }
            }
        });
        if (failedTokens.length > 0) {
            // TODO: Clean up invalid tokens in a separate batch job
            console.warn(`Found ${failedTokens.length} invalid FCM tokens`);
        }
        return { successCount: response.successCount, failureCount: response.failureCount };
    }
    catch (error) {
        console.error('Error sending multicast notification:', error);
        return { successCount: 0, failureCount: tokens.length };
    }
}
/**
 * Gets all valid FCM tokens for a user.
 */
async function getUserFcmTokens(uid) {
    const tokensSnapshot = await db
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .get();
    return tokensSnapshot.docs
        .map(doc => doc.data().token)
        .filter(token => token && token.length > 0);
}
/**
 * Gets user notification preferences.
 */
async function getUserPreferences(uid) {
    var _a, _b;
    const prefsDoc = await db
        .collection('users')
        .doc(uid)
        .collection('notificationPreferences')
        .doc('prefs')
        .get();
    if (!prefsDoc.exists) {
        return null;
    }
    const data = prefsDoc.data();
    return {
        nearbyAlertsEnabled: (_a = data.nearbyAlertsEnabled) !== null && _a !== void 0 ? _a : true,
        reportUpdatesEnabled: (_b = data.reportUpdatesEnabled) !== null && _b !== void 0 ? _b : true,
    };
}
/**
 * Gets all user UIDs that have a specific preference enabled.
 */
async function getUsersWithPreference(preference) {
    const prefsSnapshot = await db
        .collectionGroup('notificationPreferences')
        .where(preference, '==', true)
        .get();
    return prefsSnapshot.docs.map(doc => doc.ref.parent.parent.id);
}
// ============================================================
// 1. Nearby Risk Alert Notifications
// ============================================================
/**
 * Triggered when an alert is created in the 'alerts' collection.
 * Sends notifications to users with nearbyAlertsEnabled in the affected zone.
 */
exports.onAlertCreated = functions.firestore
    .document('alerts/{alertId}')
    .onCreate(async (snap, context) => {
    const alertData = snap.data();
    if (!alertData)
        return;
    // Only notify for active, non-expired alerts
    if (!alertData.active)
        return;
    const expiresAt = alertData.expiresAt;
    if (expiresAt && admin.firestore.Timestamp.now().toMillis() > expiresAt.toMillis()) {
        return;
    }
    const zoneId = alertData.zoneId;
    if (!zoneId)
        return;
    // Get users with nearbyAlertsEnabled preference
    const usersWithPref = await getUsersWithPreference('nearbyAlertsEnabled');
    // For now, send to all users with nearbyAlertsEnabled
    // TODO: Implement proper zone-based filtering
    for (const uid of usersWithPref) {
        const prefs = await getUserPreferences(uid);
        if (!(prefs === null || prefs === void 0 ? void 0 : prefs.nearbyAlertsEnabled))
            continue;
        const tokens = await getUserFcmTokens(uid);
        if (tokens.length > 0) {
            await sendMulticastNotification(tokens, {
                notification: {
                    title: `Alerte: ${alertData.title}`,
                    body: alertData.message,
                },
                data: {
                    type: 'risk_alert',
                    alertId: context.params.alertId,
                    zoneId: alertData.zoneId || '',
                    hazardType: alertData.hazardType || '',
                    severity: alertData.severity || '',
                },
            });
        }
    }
});
/**
 * Triggered when an alert is updated (e.g., activated/deactivated).
 */
exports.onAlertUpdated = functions.firestore
    .document('alerts/{alertId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    // Only notify if alert became active
    if (!(before === null || before === void 0 ? void 0 : before.active) && (after === null || after === void 0 ? void 0 : after.active)) {
        const alertData = after;
        const zoneId = alertData.zoneId;
        if (!zoneId)
            return;
        const usersWithPref = await getUsersWithPreference('nearbyAlertsEnabled');
        for (const uid of usersWithPref) {
            const prefs = await getUserPreferences(uid);
            if (!(prefs === null || prefs === void 0 ? void 0 : prefs.nearbyAlertsEnabled))
                continue;
            const tokens = await getUserFcmTokens(uid);
            if (tokens.length > 0) {
                await sendMulticastNotification(tokens, {
                    notification: {
                        title: `Alerte: ${alertData.title}`,
                        body: alertData.message,
                    },
                    data: {
                        type: 'risk_alert',
                        alertId: context.params.alertId,
                        zoneId: alertData.zoneId || '',
                        hazardType: alertData.hazardType || '',
                        severity: alertData.severity || '',
                    },
                });
            }
        }
    }
});
// ============================================================
// 2. Observation Status Change Notifications
// ============================================================
/**
 * Triggered when an observation's status changes.
 * Sends notification to the submitting user if they have reportUpdatesEnabled.
 */
exports.onObservationUpdated = functions.firestore
    .document('observations/{observationId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    // Check if status changed
    if (before.status === after.status) {
        return;
    }
    // Only notify for status changes to confirmed or rejected
    const newStatus = after.status;
    if (newStatus !== 'confirmed' && newStatus !== 'rejected') {
        return;
    }
    const userId = after.userId;
    if (!userId)
        return;
    // Check user's notification preference
    const prefs = await getUserPreferences(after.userId);
    if (!(prefs === null || prefs === void 0 ? void 0 : prefs.reportUpdatesEnabled)) {
        return;
    }
    // Get user's FCM tokens
    const tokens = await getUserFcmTokens(after.userId);
    if (tokens.length === 0)
        return;
    const statusLabel = newStatus === 'confirmed' ? 'confirmée' : 'rejetée';
    const title = `Signalement ${statusLabel}`;
    const body = `Votre signalement a été ${statusLabel}.`;
    await sendMulticastNotification(tokens, {
        notification: {
            title,
            body,
        },
        data: {
            type: 'observation_status',
            observationId: context.params.observationId,
            status: newStatus,
        },
    });
});
// ============================================================
// 3. Token cleanup (optional - can be run as a scheduled function)
// ============================================================
/**
 * Scheduled function to clean up invalid FCM tokens.
 * Run daily.
 */
exports.cleanupInvalidTokens = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async () => {
    const usersSnapshot = await db.collection('users').get();
    let deletedCount = 0;
    for (const userDoc of usersSnapshot.docs) {
        const tokensSnapshot = await db
            .collection('users')
            .doc(userDoc.id)
            .collection('fcm_tokens')
            .get();
        for (const tokenDoc of tokensSnapshot.docs) {
            const token = tokenDoc.data().token;
            try {
                // Test if token is valid by sending a dry-run message
                await messaging.send({
                    token: token,
                    data: { test: 'token-validation' },
                }, true); // dryRun = true
            }
            catch (error) {
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    await tokenDoc.ref.delete();
                }
            }
        }
    }
    console.log(`Cleaned up ${deletedCount} invalid FCM tokens`);
});
//# sourceMappingURL=index.js.map