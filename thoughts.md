# Ablaufplan Projekt

## Phase 1: Projekt-Setup & Basisfunktionalitäten

- Flutter-Projekt aufsetzen
  - Grundstruktur (Ordner, Pubspec.yaml, etc.)
  - Package-Auswahl für State-Management (z. B. Provider, Riverpod, Bloc)
  - Klare Namenskonventionen, Coding Guidelines festlegen falls wir da überhaupt so drauf achten wollen

- Firebase-Anbindung
  - Firebase Auth (für Login/Registrierung)
  - Firestore (als Datenbank für Events, User, Chats etc.)

- Evtl Funktionierende Build-Pipeline?: Lauffähige App auf Emulator / realem Gerät Könnte praktisch sein gibt und gibt gute Bewertung?

- Erste UI-Basis
  - Login-/Registrierungsscreen (noch rudimentär)
  - Einfacher Home-Screen (z. B. „Willkommen, du bist eingeloggt“) oder so nen shit

- Grobes Datenbankschema definieren
  - Also welche Collections & welche Felder? (User, Events, Messages)
    Beispiel:
    users/{userId}: Name, Email, Roles, etc.
    events/{eventId}: Titel, Datum, Ort, Teilnehmerliste, etc.
    events/{eventId}/messages/{messageId}: Abgelegter Chat pro Event
    bzw events/{eventId}/channel/{channelId}/messages/{messageId}: Wenn wir eh mehrere Channels wollen

Ziel erste Woche?:

- lauffähige Flutter-App, in die man sich einloggen kann.
- Firebase ist angebunden, User können in Firestore gespeichert werden (wenigstens rudimentär mal).

## Phase 2: Events & CRUD-Funktionen

- CRUD für Events
  - Event erstellen (Name, Datum, Ort, Sichtbarkeit, etc.)
  - Event lesen (Übersicht, Detailansicht)
  - Event bearbeiten (Name, Zeit, Ort ändern)
  - Event löschen

- Benutzerbindung an Events
  - User kann Event beitreten oder verlassen (Join/Leave)
  - Datenbankseitig: Feld participants im Event (Speicherung der User-IDs)

- UI-Verbesserungen / erste Layouts
  - Einfaches und cleanes Layout für die Eventlisten-Ansicht
  - Formulare mit Standard Validierung (z. B. „Name darf nicht leer sein“)

- Datenbank-Regeln und Sicherheitsaspekte
  - Erste Firestore Security Rules (nur Owner darf Event löschen, etc.). Kann man wohl recht easy managen auf firebase seite

Ziel Phase 2:

- Wir können Events anlegen, beitreten und haben eine grundlegende Oberfläche.
- Die User-Auth ist an Events gebunden weil das kann man im gleichen Zug machen.

## Phase 3: Chats Funktionalität

- Wir haben zwar die restlichen Chats in Should Haves aber kann man gleich richitg implementieren aber nicht unbedingt in UI verfügbar machen (Channels erstellen)

- Chat-Funktion
  - Aufsetzen der Subcollectionen im Event am besten direkt mit Channel ID wie oben beschrieben
  - Realtime Updates anschauen (StreamBuilder / Firestore snapshots)
  - Und dann halt Simple Features (Nachricht schreiben/löschen, minimaler UI-Chatverlauf)

- Push Notifications
  - Firebase Cloud Messaging (FCM) einbinden
  - Benachrichtigungen bei neuer Nachricht oder Eventänderung

- Performance & Security Gedanken
  - Limitierung / Paginierung in Chat (damit nicht alle Chats auf einmal geladen werden) Standard Practice aber sollte man im Kopf behalten und schauen wie das bei Flutter und Firebase geht
  - Genaue Firestore-Sicherheitsregeln (nur Teilnehmer können Nachrichten lesen, etc.) kann man hier auch wieder wohl recht simpel einstellen auf Firebase seite

Ziel Phase 3:

- Admins / Orgas können updates in event channel erstellen / verfassen
- Das Updaten von Eventinfos erzeugt eine Nachricht im Event Channel
- Wir haben eine basic Chat UI die man am besten so gestaltet das sie später für sämtlich Chats verwendet werden kann.

Gedanken:

- Nachrichten brauchen einen Typ: Nachricht, Update, Umfrage, verlinkung auf Feature oder so nen quatsch dann kann in DB generell handlen

## Phase 4: Location und Eventsuche

- Location & Kartenansicht
  - Integration von einer Kartenbibliothek (z. B. Google Maps)
  - Events auf einer Karte anzeigen
  - Location-Suche (Radius / Geofirestore) Geofirestore interessant. Auszug aus Doku: GeoFirestore is an open-source library that extends the Firestore library in order to store and query documents based on their geographic location. At its heart, GeoFirestore is just a wrapper for the Firestore library, exposing many of the same functions and features of Firestore. Its main benefit, however, is the possibility of retrieving only those documents within a given geographic area - all in realtime.
  - Für „Events in der Nähe“ könnt wir dann Geolocation-Queries nutzen (z. B. Geofirestore oder Geohash-Felder in Firestore).
  - Generell erstmal auch einfache Filter- oder Sortierfunktionen (z. B. nach Datum).

- Verfeinerung der UI
  - Visuell ansprechende Darstellung der Events (List View, Cards, Map-Snippet)
  - Klick auf Event führt zur Detailseite

Gedanken:

- Sollen wir Testing implementieren oder lassen wir das einfach komplett außen vor?

## Phase 5: Restliche Should Have Features

- Rollensystem aktivieren / implementieren
  - Welche Rollen soll es geben und was sollen diese tun können?
- Chat Channels implementieren bzw. in der UI verfügbar machen / User auch schreiben lassen
- Chat Channels erstellen und löschen können.