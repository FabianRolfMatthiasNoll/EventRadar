# Implementierte Features

- Dashboard
    - Liste beigetretener Events

- Verwaltung von Events
    - Erstellen mit Start-, Endzeit, Ort, Beschreibung, Sichtbarkeit, promoten
    - Ortswahl über Karte
    - Bei Verlassen des Events werden mehrere Szenarios berücksichtigt
      - Letzer User -> User wird gewarnt das Event gelöscht wird
      - Letzter Admin aber noch User -> User kann anderen User promoten
      - Nicht letzter Admin -> User wird gewarnt Status zu verlieren
    - Bearbeitung des Events inPlace als Organisator.
      - Nutzbarkeit der normalen Features gegeben (Klick auf Map fragt ob in GoogleMaps öffnen oder bearbeiten)
    - Teilnehmer-Management
      - Organisatoren können Teilnehmer kicken
      - Organisatoren können Teilnehmer zu Organisatoren promoten oder demoten
    - Events über Links teilen
    - Chats
      - Announcement Channel in welchen nur Organizer schreiben können
      - Eventänderungen werden im Announcement-Channel protokolliert
      - Push-Benachrichtigungen für Announcement-Channel
      - Erstellung mehrerer Channels
      - User können in reguläre Channels schreiben
      - Umfragen (Erstellen, Abstimmen, Abschließen)
    - Hinzufügen zum Kalender durch Klicken auf das Datum

- User Funktionaliäten
    - Erstellung Account
    - Anmelden
    - Abmelden
    - Ein- / Ausschreiben bei Events
    - Nutzung der Karte auch als nicht eingeloggter User
    - Login status wirkt sich auf alle Bereiche sofort aus.

- Kartenansicht von Events
    - Navigation von Karte zu Event
    - Liveupdates zu Mitgliedsstatus
      - Grüne Marker -> Eingetragen
      - Blaue Marker -> Public Event
      - Goldene Marker -> Promoted Event
    - Support für nicht eingeloggte User
    - User sieht auf Karte seine bereits eingetragenen Events neben den public Events

- Cloud Functions
  - Lädt die Liste der Mitglieder eines Events mit Namen und Rolle sowie Bild
  - Löscht ein Event mitsamt aller verbunden ressourcen (subcollections, Bildern)

- Eventliste / Eventsuche
    - Suche nach Name
    - Filter nach Umkreis, Start vor, Start nach, min Teilnehmer, max Teilnehmer
    - Sortierung nach Entfernung, Datum, Teilnehmer aufsteigend, Teilnehmer absteigend

