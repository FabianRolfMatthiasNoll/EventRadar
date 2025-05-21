import 'package:flutter/material.dart';

class SurveyData {
  final String question;
  final List<Map<String, String>> options;
  SurveyData(this.question, this.options);
}

class SurveyCreationDialog extends StatefulWidget {
  const SurveyCreationDialog({super.key});

  @override
  State<SurveyCreationDialog> createState() => _SurveyCreationDialogState();
}

class _SurveyCreationDialogState extends State<SurveyCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qCtrl = TextEditingController();
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
  void dispose() {
    _qCtrl.dispose();
    for (final c in _optCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color:
          theme.bottomSheetTheme.backgroundColor ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Neue Umfrage', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Frage
                    TextFormField(
                      controller: _qCtrl,
                      maxLength: _maxQuestionLength,
                      maxLines: null,
                      decoration: const InputDecoration(labelText: 'Frage'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Bitte eine Frage eingeben';
                        }
                        if (text.length > _maxQuestionLength) {
                          return 'Max. $_maxQuestionLength Zeichen';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ...List.generate(_optCtrls.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _optCtrls[i],
                          maxLength: _maxOptionLength,
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              color: Colors.red,
                              tooltip: 'Option löschen',
                              onPressed:
                                  _optCtrls.length > 2
                                      ? () {
                                        setState(() {
                                          _optCtrls.removeAt(i).dispose();
                                        });
                                      }
                                      : null,
                            ),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Bitte Option eingeben';
                            }
                            if (text.length > _maxOptionLength) {
                              return 'Max. $_maxOptionLength Zeichen';
                            }
                            return null;
                          },
                        ),
                      );
                    }),

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

              const SizedBox(height: 24),
              // Action-Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _onSubmit,
                    child: const Text('Erstellen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() != true) return;

    final question = _qCtrl.text.trim();
    final optionTexts =
        _optCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

    if (optionTexts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens 2 Optionen eingeben.')),
      );
      return;
    }

    final data = SurveyData(
      question,
      optionTexts
          .asMap()
          .entries
          .map((e) => {'id': 'opt${e.key}', 'text': e.value})
          .toList(),
    );
    Navigator.of(context).pop(data);
  }
}
