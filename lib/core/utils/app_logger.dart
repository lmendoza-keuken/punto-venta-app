import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class AppLogger {
  static File? _file;
  static String logPath = '';
  static bool _stdoutUsable = false;
  static Timer? _heartbeat;
  static int _currentBytes = 0;

  /// Tamaño máximo del archivo activo antes de rotar.
  static const int maxBytes = 2 * 1024 * 1024; // 2 MB

  /// Archivo activo + N-1 rotados (ej. .log, .log.1 … .log.4).
  static const int maxFiles = 5;

  static Future<void> init() async {
    final sep = Platform.pathSeparator;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final tempLogsDir = '${Directory.systemTemp.path}${sep}punto_venta_app${sep}logs';

    final candidates = <File>[
      File('$exeDir${sep}logs${sep}punto_venta_app.log'),
      File('$tempLogsDir${sep}punto_venta_app.log'),
      File('${Directory.systemTemp.path}${sep}punto_venta_app.log'),
      File('$exeDir${sep}punto_venta_app.log'),
    ];

    for (final candidate in candidates) {
      try {
        final parent = candidate.parent;
        if (!await parent.exists()) {
          await parent.create(recursive: true);
        }
        await candidate.writeAsString(
          '\n===== sesión ${DateTime.now().toIso8601String()} =====\n',
          mode: FileMode.append,
          flush: true,
        );
        _file = candidate;
        logPath = candidate.path;
        _currentBytes = await candidate.length();
        break;
      } catch (_) {
        continue;
      }
    }

    // En builds release sin consola adjunta, escribir a stdout lanza
    // FileSystemException asíncrona (handle inválido).
    try {
      _stdoutUsable = stdout.hasTerminal;
    } catch (_) {
      _stdoutUsable = false;
    }

    info(
      'Logger iniciado. Archivo: ${logPath.isEmpty ? '(solo consola)' : logPath} '
      '(max ${maxBytes ~/ 1024}KB x $maxFiles archivos)',
    );
  }

  /// Latido periódico: si el log se corta sin más latidos, el proceso murió
  /// (crash nativo). Si los latidos siguen, la app quedó colgada.
  static void startHeartbeat({Duration interval = const Duration(seconds: 5)}) {
    _heartbeat?.cancel();
    /*_heartbeat = Timer.periodic(interval, (timer) {
      _write('BEAT', 'app viva (${timer.tick * interval.inSeconds}s)');
    });*/
  }

  static void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  static void info(String message) => _write('INFO', message);

  static void warn(String message) => _write('WARN', message);

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _write('ERROR', message);
    if (error != null) {
      _write('ERROR', 'detalle: $error');
    }
    if (stackTrace != null) {
      _write('ERROR', stackTrace.toString());
    }
  }

  static void _write(String level, String message) {
    final line = '[${DateTime.now().toIso8601String()}] [$level] $message';
    debugPrint(line);
    if (_stdoutUsable) {
      try {
        stdout.writeln(line);
      } catch (_) {}
    }
    try {
      final payload = '$line\n';
      _rotateIfNeeded(payload.length);
      _file?.writeAsStringSync(payload, mode: FileMode.append, flush: true);
      _currentBytes += payload.length;
    } catch (_) {}
  }

  /// Rota cuando el archivo activo + la próxima escritura superarían [maxBytes].
  /// Resultado: `punto_venta_app.log` (activo), `.log.1` … `.log.(maxFiles-1)`.
  static void _rotateIfNeeded(int incomingBytes) {
    final file = _file;
    if (file == null || logPath.isEmpty) return;
    if (_currentBytes + incomingBytes < maxBytes) return;

    try {
      final oldest = File('$logPath.${maxFiles - 1}');
      if (oldest.existsSync()) {
        oldest.deleteSync();
      }

      for (var i = maxFiles - 2; i >= 1; i--) {
        final src = File('$logPath.$i');
        if (src.existsSync()) {
          src.renameSync('$logPath.${i + 1}');
        }
      }

      if (file.existsSync()) {
        file.renameSync('$logPath.1');
      }

      _file = File(logPath);
      _file!.writeAsStringSync(
        '===== rotación ${DateTime.now().toIso8601String()} '
        '(límite ${maxBytes ~/ 1024}KB) =====\n',
        flush: true,
      );
      _currentBytes = _file!.lengthSync();
    } catch (_) {
      // Si la rotación falla, seguimos append al archivo actual.
      try {
        _currentBytes = file.existsSync() ? file.lengthSync() : 0;
      } catch (_) {
        _currentBytes = 0;
      }
    }
  }
}
