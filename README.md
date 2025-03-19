# EventRadar – Gruppen- und Eventplaner

## Projektbeschreibung

EventRadar ist eine mobile Anwendung zur **einfachen Planung und Organisation von Gruppen-Events**. 
Die App ermöglicht eine **intuitive Verwaltung von Terminen, Gruppen und Veranstaltungen**, sowohl für öffentliche als auch private Events.

Die Zielgruppe umfasst **Freundeskreise, Vereine, Unternehmen und Studierende**, die effizient Veranstaltungen planen und koordinieren möchten.

---

## Funktionen und Anforderungen

### **Must-Haves (Essenzielle Anforderungen)**

#### **Gruppen & Events**

- Erstellung und Verwaltung von Gruppen.
- Planung und Verwaltung von Events.
- Unterstützung für einmalige und wiederkehrende Events.

#### **Event- & Gruppenupdates**

- Gruppenadmins können Updates und Ankündigungen posten.
- Event-Updates können direkt an Teilnehmer gesendet werden.

#### **Einladungen & Mitgliedschaft**

- Einladung zu Gruppen und Events über Links oder QR-Codes.
- Private und öffentliche Gruppen.
- Admin kann Mitglieder hinzufügen, entfernen oder sperren.

#### **Benachrichtigungen & Erinnerungen**

- Push-Benachrichtigungen für Event-Updates.
- Erinnerung an bevorstehende Events.

#### **Sicherheit & Authentifizierung**

- Login über E-Mail/Passwort oder OAuth (Google/Apple).
- DSGVO-konforme Speicherung und Datenschutz-Einstellungen.

#### **Plattformen**

- Mobile App für Android & iOS (Flutter oder React Native).
- Backend mit Firebase oder vergleichbarer Cloud-Lösung.

---

### **Should-Haves (Wichtige, aber nicht essenzielle Features)**

#### **Erweiterte Standort-Funktionen**

- Kartenansicht für geplante Events.

#### **Terminfindung & Abstimmungen**

- Nutzer können Termine vorschlagen und darüber abstimmen.
- Automatische Bestimmung des optimalen Termins.

#### **Event-Statistiken & Teilnehmerübersicht**

- Anzeige, wer teilnimmt oder noch unentschieden ist.
- Einfache Teilnehmerverwaltung für Admins.

#### **Nutzerrollen & Berechtigungen**

- Verschiedene Rollen: Admin, Moderator, Mitglied.
- Admin kann Gruppenrechte vergeben.

#### **Erweiterte Benachrichtigungen**

- Feineinstellungen für Erinnerungen und Benachrichtigungen.
- Unterschiedliche Erinnerungsmodi für Events.

---

### **Nice-to-Haves (Zusätzliche Features, nicht zwingend erforderlich)**

#### **GPS- oder Bluetooth-Erkennung für spontane Treffen**

- Zeigt an, wenn Gruppenmitglieder in der Nähe sind.
- Muss noch erprobt werden (Datenschutz & Akkulaufzeit).

#### **Kalender-Integration**

- Synchronisierung mit Google/Apple-Kalender.
- Automatische Eintragung bestätigter Events.

#### **Event-Erinnerungen per E-Mail & WhatsApp**

- Nutzer können sich zusätzlich per Mail oder WhatsApp erinnern lassen.

#### **Offline-Modus für Event-Infos**

- Events und Gruppen-Updates bleiben auch ohne Internet abrufbar.

#### **Erweiterte Event-Funktionen**

- Öffentliche Event-Feeds für große Gruppen.
- Automatische Archivierung vergangener Events.

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
- **Backend:** Firebase (Auth, Firestore, Notifications) oder Node.js mit MongoDB
- **APIs:** Google Maps API (für Standort-Funktionen), QR-Code API
- **Sicherheit:** OAuth2 für Login, DSGVO-konforme Speicherung
