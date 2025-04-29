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

- User Funktionaliäten
    - Erstellung Account
    - Anmelden
    - Abmelden
    - Ein- / Ausschreiben bei Events

- Kartenansicht von Events
    - Navigation von Karte zu Event

- Cloud Functions
  - Lädt die Liste der Mitglieder eines Events mit Namen und Rolle sowie Bild
  - Löscht ein Event mitsamt aller verbunden ressourcen (subcollections, Bildern)

