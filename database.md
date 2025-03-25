# Architektur

users
 └── {userId}
      name
      email
      globalRole
      ...  

events
 └── {eventId}
      title
      date
      location
      visibility // "public" | "invite-only"
      ...
      // Subcollection für Teilnehmer (sofern nicht Array):
      participants
        └── {userId}
             role // "organizer" | "moderator" | "participant"
             joinedAt 
             ...
      // Subcollection für Channels
      channels
        └── {channelId}
             channelName
             channelType // "main" | "custom" | "system" ...
             createdAt
             // Subcollection für Nachrichten
             messages
               └── {messageId}
                    text
                    type       // "text" | "update" | "poll" | "link" ...
                    senderId
                    createdAt
                    metadata   // Objekt (Poll-Infos, Link-Infos etc.)


Eventuell noch ne Bannliste oder so