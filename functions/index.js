const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const {
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// Mirrors Observation.typeLabel from lib/features/observations/domain/observation.dart
// so the notification text matches what admins see in the app.
const TYPE_LABELS = {
  flooding: "Inondation",
  blockedRoad: "Route bloquée",
  landslide: "Glissement de terrain",
  other: "Autre",
  custom: "Autre",
};

function typeLabelFor(data) {
  if (data.type === "custom" && data.customTypeLabel) {
    const trimmed = String(data.customTypeLabel).trim();
    if (trimmed.length > 0) return trimmed;
  }
  return TYPE_LABELS[data.type] || "Signalement";
}

/**
 * Triggered whenever a citizen submits a new observation.
 * Notifies every admin device (even if the app is closed) via FCM,
 * and prunes tokens that are no longer valid.
 */
exports.notifyAdminsOnNewObservation = onDocumentCreated(
  "observations/{observationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("notifyAdminsOnNewObservation: no snapshot data.");
      return;
    }

    const observation = snapshot.data();
    const observationId = event.params.observationId;

    const adminsSnapshot = await db
      .collection("users")
      .where("role", "==", "admin")
      .get();

    if (adminsSnapshot.empty) {
      logger.info("No admin users found, skipping notification.");
      return;
    }

    /** @type {{ token: string, userId: string }[]} */
    const tokenEntries = [];
    adminsSnapshot.forEach((doc) => {
      const tokens = doc.data().fcmTokens;
      if (Array.isArray(tokens)) {
        for (const token of tokens) {
          if (typeof token === "string" && token.length > 0) {
            tokenEntries.push({ token, userId: doc.id });
          }
        }
      }
    });

    if (tokenEntries.length === 0) {
      logger.info("No admin FCM tokens registered, skipping notification.");
      return;
    }

    const label = typeLabelFor(observation);
    const description =
      typeof observation.description === "string"
        ? observation.description.trim()
        : "";

    const title = `Nouveau signalement : ${label}`;
    const body =
      description.length > 0
        ? description.length > 120
          ? `${description.slice(0, 117)}...`
          : description
        : "Un citoyen a signalé un nouveau risque.";

    const uniqueTokens = [...new Set(tokenEntries.map((e) => e.token))];

    const response = await messaging.sendEachForMulticast({
      tokens: uniqueTokens,
      notification: { title, body },
      data: {
        type: "new_observation",
        observationId,
      },
      android: {
        priority: "high",
        notification: { channelId: "observations" },
      },
      apns: {
        payload: {
          aps: { sound: "default" },
        },
      },
    });

    logger.info(
      `Notified ${response.successCount}/${uniqueTokens.length} admin device(s) ` +
        `for observation ${observationId}.`
    );

    await pruneInvalidTokens(uniqueTokens, tokenEntries, response.responses);
  }
);

/**
 * Removes tokens that FCM reports as no longer registered, so the admin's
 * token list doesn't grow unbounded with stale/uninstalled devices.
 */
async function pruneInvalidTokens(tokens, tokenEntries, responses) {
  const staleTokensByUser = new Map();

  responses.forEach((result, index) => {
    if (result.success) return;

    const errorCode = result.error && result.error.code;
    const isInvalid =
      errorCode === "messaging/registration-token-not-registered" ||
      errorCode === "messaging/invalid-registration-token";

    if (!isInvalid) return;

    const token = tokens[index];
    const entry = tokenEntries.find((e) => e.token === token);
    if (!entry) return;

    if (!staleTokensByUser.has(entry.userId)) {
      staleTokensByUser.set(entry.userId, []);
    }
    staleTokensByUser.get(entry.userId).push(token);
  });

  if (staleTokensByUser.size === 0) return;

  const batch = db.batch();
  for (const [userId, staleTokens] of staleTokensByUser) {
    const userRef = db.collection("users").doc(userId);
    batch.update(userRef, {
      fcmTokens: FieldValue.arrayRemove(...staleTokens),
    });
  }
  await batch.commit();

  logger.info(
    `Removed ${[...staleTokensByUser.values()].flat().length} stale token(s).`
  );
}
