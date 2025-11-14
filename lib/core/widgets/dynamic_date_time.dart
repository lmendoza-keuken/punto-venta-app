import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class DynamicDateTime extends StatefulWidget {
  final TextStyle? style;

  const DynamicDateTime({
    super.key,
    this.style,
  });

  @override
  State<DynamicDateTime> createState() => _DynamicDateTimeState();
}

class _DynamicDateTimeState extends State<DynamicDateTime> {
  late Timer _timer;
  late DateTime _currentDateTime;

  @override
  void initState() {
    super.initState();
    _currentDateTime = DateTime.now();

    // Actualizar cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    // Días de la semana en español
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];

    // Meses en español
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    final dayName = days[dateTime.weekday - 1];
    final day = dateTime.day;
    final monthName = months[dateTime.month - 1];
    final year = dateTime.year;
    final time = DateFormat('HH:mm:ss').format(dateTime);

    return '$dayName, $day de $monthName de $year / $time';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDateTime(_currentDateTime),
      style: widget.style,
    );
  }
}
