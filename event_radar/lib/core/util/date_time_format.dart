import 'package:intl/intl.dart';

// Formatters.
String formatDateTime(DateTime dt) =>
    DateFormat('dd.MM.yyyy – HH:mm').format(dt);
String formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);
String formatTime(DateTime date) => DateFormat('HH:mm').format(date);
