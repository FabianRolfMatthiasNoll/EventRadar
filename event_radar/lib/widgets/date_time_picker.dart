import 'package:flutter/material.dart';

import '../core/util/date_time_format.dart';

class DateTimePicker extends StatefulWidget {
  final String label;
  final DateTime initialStart;
  final DateTime? initialEnd;
  final void Function(DateTime start, DateTime? end) onChanged;

  const DateTimePicker({
    super.key,
    required this.label,
    required this.initialStart,
    this.initialEnd,
    required this.onChanged,
  });

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late DateTime _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pickDate({required bool isStart}) async {
    DateTime base = isStart ? _start : (_end ?? _start);
    DateTime today = DateTime.now();

    final first = isStart ? (_start.isBefore(today) ? _start : today) : _start;

    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: first,
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _start.hour,
          _start.minute,
        );
        if (_end != null && _end!.isBefore(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _end?.hour ?? _start.hour,
          _end?.minute ?? _start.minute,
        );
      }
      widget.onChanged(_start, _end);
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    DateTime base =
        isStart ? _start : (_end ?? _start.add(const Duration(hours: 1)));
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        );
        if (_end != null && _end!.isBefore(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = DateTime(
          base.year,
          base.month,
          base.day,
          picked.hour,
          picked.minute,
        );
      }
      widget.onChanged(_start, _end);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String label, DateTime dt, bool isStart) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(isStart: isStart),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 4),
                    Text(formatDate(dt)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(isStart: isStart),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 4),
                    Text(formatTime(dt)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child:
                !isStart
                    ? IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed:
                          () => setState(() {
                            _end = null;
                            widget.onChanged(_start, _end);
                          }),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(widget.label, _start, true),
        const SizedBox(height: 16),
        if (_end != null)
          row('Ende:', _end!, false)
        else
          TextButton.icon(
            onPressed:
                () => setState(() {
                  _end = _start.add(const Duration(hours: 1));
                  widget.onChanged(_start, _end);
                }),
            icon: const Icon(Icons.add),
            label: const Text('Endzeit hinzufügen'),
          ),
      ],
    );
  }
}
