import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
admin.initializeApp();

/**
 * Extrahiert den Storage-Pfad aus dem URL-Pfad.
 *
 * @param {string} rawPath - Der rohe Pfad aus der Storage-URL,
 *   z. B. '/v0/b/.../o/event_images%2Ffile.jpg'.
 * @return {string|null} - Den decodierten Pfad
 *   (z. B. 'event_images/file.jpg') oder null.
 */
function extractFilePath(rawPath: string): string | null {
  const marker = "/o/";
  const idx = rawPath.indexOf(marker);
  if (idx === -1) {
    return null;
  }
  let fp = rawPath.slice(idx + marker.length);
  const qIdx = fp.indexOf("?");
  if (qIdx !== -1) {
    fp = fp.slice(0, qIdx);
  }
  return fp.replace("%2F", "/");
}

export const onAnnouncementCreated = functions
  .firestore
  .document("events/{eventId}/channels/{channelId}/messages/{msgId}")
  .onCreate(async (snap, ctx) => {
    const {eventId, channelId, msgId} = ctx.params;

    // 1) Channel-Dokument laden und auf type === 'announcement' prüfen
    const channelRef = admin
      .firestore()
      .collection("events")
      .doc(eventId)
      .collection("channels")
      .doc(channelId);
    const channelSnap = await channelRef.get();
    const channelData = channelSnap.data();
    if (!channelData) {
      console.log(`Channel-Dokument nicht gefunden: ${channelId}`);
      return null;
    }
    if (channelData.channelType !== "announcement") {
      console.log(
        `Übersprungen: Channel ${channelId} ist vom Typ ` +
        `"${channelData.channelType}", nicht "announcement".`
      );
      return null;
    }

    // 2) Announcement-Daten
    const msgData = snap.data() as {
        text?: string;
        senderId?: string;
        type?: string
    };
    const text = (msgData.text || "").trim();

    // 3) Event-Titel holen
    const eventSnap = await admin
      .firestore()
      .collection("events")
      .doc(eventId)
      .get();
    const eventTitle = eventSnap.data()?.title || "Event";

    // 4) Absender-Name ermitteln
    let senderName = "Teilnehmer";
    if (msgData.senderId && msgData.senderId !== "admin") {
      try {
        const user = await admin.auth().getUser(msgData.senderId);
        senderName = user.displayName || user.email || senderName;
      } catch (e) {
        console.error("Fehler beim Laden des Users", e);
      }
    } else if (msgData.senderId === "admin") {
      senderName = "Admin";
    }

    // 5) Notification Titel & Body
    const title = `${eventTitle}`;
    let body = `${senderName} hat geschrieben: ${text}`;

    if (msgData.type === "update") {
      body = `${text}`;
    }

    // 6) Payload für Topic-Push
    const payload: admin.messaging.Message = {
      topic: `event_${eventId}_announcements`,
      notification: {title, body},
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        eventId,
        channelId,
        messageId: msgId,
        senderId: msgData.senderId || "",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "event_announcements",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    };
    // 7) Push versenden
    try {
      const resp = await admin.messaging().send(payload);
      console.log("Push gesendet:", resp);
      return resp;
    } catch (err) {
      console.error("Fehler beim Senden der Push:", err);
      throw err;
    }
  });

/**
 * Löscht die Event-Bilddatei aus Firebase Storage, falls
 * eine gültige URL vorliegt.
 *
 * @param {string} imageUrl - Vollständige Download-URL
 *   des Bildes in Firebase Storage.
 * @return {Promise<void>} - Promise wird aufgelöst, wenn
 *   die Löschung abgeschlossen oder fehlerhaft war.
 */
async function deleteEventImage(
  imageUrl: string
): Promise<void> {
  try {
    const bucket = admin.storage().bucket();
    const url = new URL(imageUrl);
    const rawPath = decodeURIComponent(url.pathname);
    const filePath = extractFilePath(rawPath);
    if (!filePath) {
      return;
    }
    await bucket
      .file(filePath)
      .delete({ignoreNotFound: true});
  } catch (err) {
    console.error("Error deleting image:", err);
  }
}

export const getEventParticipants = functions.https.onCall(
  async (data, context) => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Du musst eingeloggt sein."
      );
    }
    const eventId = data.eventId as string;
    if (!eventId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "eventId wird benötigt."
      );
    }

    const partsSnap = await admin
      .firestore()
      .collection("events")
      .doc(eventId)
      .collection("participants")
      .get();

    const uids = partsSnap.docs.map((doc) => doc.id);

    const users = await Promise.all(
      uids.map(async (uid) => {
        const authUser = await admin.auth().getUser(uid);
        const pDoc = partsSnap.docs.find((d) => d.id === uid);
        if (!pDoc) {
          throw new functions.https.HttpsError(
            "internal",
            `Teilnehmer-Daten für ${uid} fehlen.`
          );
        }
        const {role} = pDoc.data();
        return {
          uid: authUser.uid,
          name: authUser.displayName || "Unbekannt",
          photo: authUser.photoURL || "",
          role,
        };
      })
    );

    return {participants: users};
  }
);

export const deleteEvent = functions.https.onCall(
  async (data, context) => {
    const eventId = data.eventId as string | undefined;
    if (!eventId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Parameter \"eventId\" fehlt."
      );
    }
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Nur authentifizierte Nutzer dürfen Events löschen."
      );
    }

    const eventRef = admin
      .firestore()
      .collection("events")
      .doc(eventId);
    const eventSnap = await eventRef.get();
    if (!eventSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Event nicht gefunden."
      );
    }

    const eventData = eventSnap.data();
    if (!eventData) {
      throw new functions.https.HttpsError(
        "internal",
        "Event-Daten fehlen."
      );
    }

    const callerId = context.auth.uid;
    const pDoc = await eventRef
      .collection("participants")
      .doc(callerId)
      .get();
    if (!pDoc.exists || pDoc.data()?.role !== "organizer") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Nur ein Admin/Organisator kann das Event löschen."
      );
    }

    if (
      typeof eventData.image === "string" &&
      eventData.image !== ""
    ) {
      await deleteEventImage(eventData.image);
    }

    try {
      await admin
        .firestore()
        .recursiveDelete(eventRef);
    } catch (err) {
      console.warn(
        "recursiveDelete fehlgeschlagen, starte manuelle Löschung...",
        err
      );

      // Teilnehmer löschen
      const parts = await eventRef
        .collection("participants")
        .listDocuments();
      for (const doc of parts) {
        await doc.delete().catch((e) =>
          console.error(
            "Teilnehmer-Löschung fehlgeschlagen:",
            doc.id, e
          )
        );
      }

      // Channels & Nachrichten löschen
      const channelsSnap = await eventRef
        .collection("channels")
        .get();
      for (const ch of channelsSnap.docs) {
        const msgs = await ch.ref
          .collection("messages")
          .listDocuments();
        for (const msg of msgs) {
          await msg.delete().catch((e) =>
            console.error(
              "Nachrichten-Löschung fehlgeschlagen:",
              msg.id, e
            )
          );
        }
        await ch.ref.delete().catch((e) =>
          console.error(
            "Channel-Löschung fehlgeschlagen:",
            ch.id, e
          )
        );
      }

      // Event-Dokument löschen
      await eventRef.delete();
    }

    return {success: true};
  }
);
