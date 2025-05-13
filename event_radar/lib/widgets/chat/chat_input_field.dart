import 'package:event_radar/widgets/chat/survey_creation_dialog.dart';
import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final ValueChanged<String> onSend;
  final ValueChanged<SurveyData> onCreateSurvey;
  const ChatInputField({
    super.key,
    required this.onSend,
    required this.onCreateSurvey,
  });

  @override
  _ChatInputFieldState createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[100],
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog<SurveyData>(
                context: context,
                builder: (_) => const SurveyCreationDialog(),
              );
              if (result != null) {
                // hier onSend overloaden: wir brauchen Frage+Optionen
                widget.onCreateSurvey(result);
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Nachricht eingeben...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
