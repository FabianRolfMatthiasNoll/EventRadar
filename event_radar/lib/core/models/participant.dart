class ParticipantProfile {
  final String uid, name, photo, role;
  ParticipantProfile({
    required this.uid,
    required this.name,
    required this.photo,
    required this.role,
  });
  factory ParticipantProfile.fromMap(Map m) => ParticipantProfile(
    uid:   m['uid'],
    name:  m['name'],
    photo: m['photo'],
    role:  m['role'],
  );
}
