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

  static const int _maxQuestionLength = 200;
  static const int _maxOptionLength = 50;
  static const int _maxOptions = 5;

  void _addOption() {
    if (_optCtrls.length < _maxOptions) {
      setState(() => _optCtrls.add(TextEditingController()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Umfrage'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Frage
            TextField(
              controller: _qCtrl,
              maxLength: _maxQuestionLength,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Frage',
                counterText: '', // counter unten ausblenden, alternativ null
              ),
            ),
            const SizedBox(height: 16),

            // Antwort-Optionen
            ...List.generate(_optCtrls.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _optCtrls[i],
                  maxLength: _maxOptionLength,
                  decoration: InputDecoration(
                    labelText: 'Option ${i + 1}',
                    counterText: '',
                    suffixIcon:
                        i >= 2
                            ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _optCtrls.removeAt(i);
                                });
                              },
                            )
                            : null,
                  ),
                ),
              );
            }),

            // „+ Option“ erst aktivieren, wenn unter dem Limit
            if (_optCtrls.length < _maxOptions)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Option hinzufügen (${_optCtrls.length}/$_maxOptions)',
                  ),
                  onPressed: _addOption,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
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
