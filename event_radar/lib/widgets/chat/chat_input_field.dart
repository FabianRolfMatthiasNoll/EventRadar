import 'package:flutter/material.dart';

import '../../widgets/chat/survey_creation_dialog.dart';

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

  Future<void> _openSurveyCreator() async {
    final result = await showModalBottomSheet<SurveyData>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).bottomSheetTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Wrap(children: const [SurveyCreationDialog()]),
    );
    if (result != null) {
      widget.onCreateSurvey(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _openSurveyCreator,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: "Nachricht eingeben…",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),

            // Send-Button
            IconButton(
              icon: const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
              onPressed: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}
