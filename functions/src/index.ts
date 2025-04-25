import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
admin.initializeApp();

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
      uids.map((uid) =>
        admin.auth().getUser(uid).then((u) => ({
          uid: u.uid,
          name: u.displayName || "Unbekannt",
          photo: u.photoURL || "",
          role: partsSnap.docs.find((d) => d.id === uid)!.data().role,
        }))
      )
    );

    return {participants: users};
  }
);

