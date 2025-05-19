tenum ChannelType { announcement, chat }

class ChatChannel {
  final String id;
  final String name;
  final ChannelType type;

  ChatChannel({required this.id, required this.name, required this.type});

  factory ChatChannel.fromMap(Map<String, dynamic> map) {
    final raw = map['type'] as String? ?? 'chat';
    final parsedType = ChannelType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ChannelType.chat,
    );

    return ChatChannel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: parsedType,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'type': type.name};
}
