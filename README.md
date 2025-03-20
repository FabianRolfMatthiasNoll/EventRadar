# EventRadar – Gruppen- und Eventplaner

## Projektbeschreibung

EventRadar ist eine mobile Anwendung zur **einfachen Planung und Organisation von Gruppen-Events**.
Die App ermöglicht eine **intuitive Verwaltung von Terminen, Gruppen und Veranstaltungen**, sowohl für öffentliche als auch private Events und Gruppen.

Die Zielgruppe umfasst primär **Freundeskreise** jedoch auch **Vereine, Unternehmen und Studierende**, die effizient Veranstaltungen planen und koordinieren möchten.

---

## Funktionen und Anforderungen

### **Must-Haves (Essenzielle Anforderungen)**

#### **Gruppen**

- Erstellung und Verwaltung von Gruppen.
  - Anzeigen der Mitglieder
  - Einladung und Entfernen von Usern
- Planung und Verwaltung von Aktivitäten.
- Private und Öffentliche Gruppen erstellen

#### **Events**

- Erstellung und Verwaltung von Events.
- Einmalig oder Wiederkehrend erstellbar
- Haben Zeitpunkt und Ort

#### **Event- & Gruppenupdates**

- Gruppen- / Eventadmins können Updates und Ankündigungen posten.

#### **Einladungen & Mitgliedschaft**

- Einladung zu privaten Gruppen und Events über Links oder QR-Codes.
- Öffentliche Gruppen und Events können frei betreten und verlassen werden.
- Admin kann Mitglieder hinzufügen, entfernen oder sperren.

#### **Benachrichtigungen & Erinnerungen**

- Push-Benachrichtigungen für Event-Updates.
- Erinnerung an bevorstehende Events.

#### **Sicherheit & Authentifizierung**

- Login über E-Mail/Passwort oder OAuth (Google/Apple).
- DSGVO-konforme Speicherung und Datenschutz-Einstellungen.

#### **Standort-Funktionen** (Wichtig für Sensoranforderung)

- Anzeige von öffentlichen Events anhand geografischer Lage

---

### **Should-Haves (Wichtige, aber nicht essenzielle Features)**

#### **Terminfindung in Gruppen Aktivitäten**

- Nutzer können Termine vorschlagen und darüber abstimmen.
- Automatische Bestimmung des optimalen Termins.

#### **Abstimmungen in Gruppen Aktivitäten**

- Möglichkeit Umfragen zu erstellen
- Übersicht über bereits abgeschlossene Umfragen
  - Potentiell Übersichtsattribute wie WerBringtWas Liste.
  -> Eliminiert neben Doodle dann auch Excellisten als Beispiel

#### **Event-Statistiken & Teilnehmerübersicht**

- Anzeige, wer teilnimmt oder noch unentschieden ist.
- Einfache Teilnehmerverwaltung für Admins.

#### **Nutzerrollen & Berechtigungen**

- Verschiedene Rollen: Admin, Moderator, Mitglied.
- Admin kann Gruppenrechte vergeben.

---

### **Nice-to-Haves (Zusätzliche Features, nicht zwingend erforderlich)**

#### **GPS- oder Bluetooth-Erkennung für spontane Treffen**

- Privatsphärenmodus
- Zeigt an, wenn Gruppenmitglieder in der Nähe sind.

#### **Kalender-Integration**

- Synchronisierung mit Google/Apple-Kalender.
- Automatische Eintragung bestätigter Events.

#### **Event-Erinnerungen per E-Mail & WhatsApp**

- Nutzer können sich zusätzlich per Mail oder WhatsApp erinnern lassen.

#### **Offline-Modus für Event-Infos**

- Events und Gruppen-Updates bleiben auch ohne Internet abrufbar.

#### **Vollwertiger Chat**

- Direkte Kommunikation zwischen Teilnehmern innerhalb einer Gruppe oder eines Events.

---

## Nicht-Ziele (Was die App nicht können soll)

- Keine öffentliche Social-Media-Funktion (keine Posts oder Timelines).
- Kein Payment-System (z. B. Ticketverkauf oder Rechnungen).
- Keine KI-gestützten Vorschläge für Events oder Gruppen.

---

## Technische Anforderungen

- **Frontend:** Flutter
- **Backend:** Firebase (Auth, Firestore, Notifications)
- **APIs:** Google Maps API (für Standort-Funktionen), QR-Code API
- **Sicherheit:** Firebase Auth
