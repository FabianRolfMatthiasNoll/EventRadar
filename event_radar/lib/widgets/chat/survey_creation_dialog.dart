import 'package:flutter/material.dart';

class SurveyData {
  final String question;
  final List<Map<String, String>> options;
  SurveyData(this.question, this.options);
}

class SurveyCreationDialog extends StatefulWidget {
  const SurveyCreationDialog({super.key});
  @override
  _SurveyCreationDialogState createState() => _SurveyCreationDialogState();
}

class _SurveyCreationDialogState extends State<SurveyCreationDialog> {
  final TextEditingController _qCtrl = TextEditingController();
  final List<TextEditingController> _optCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  void _addOption() {
    setState(() => _optCtrls.add(TextEditingController()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Umfrage erstellen'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _qCtrl,
              decoration: const InputDecoration(labelText: 'Frage'),
            ),
            const SizedBox(height: 8),
            ..._optCtrls.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: c,
                  decoration: const InputDecoration(labelText: 'Option'),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Option hinzufügen'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            final question = _qCtrl.text.trim();
            final options =
                _optCtrls
                    .map((c) => c.text.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
            if (question.isEmpty || options.length < 2) return;
            final data = SurveyData(
              question,
              options
                  .asMap()
                  .entries
                  .map((e) => {'id': 'opt${e.key}', 'text': e.value})
                  .toList(),
            );
            Navigator.pop(context, data);
          },
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}
