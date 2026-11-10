import 'package:punto_venta_app/core/utils/app_logger.dart';

class ConfirmSaleFlowLog {
  ConfirmSaleFlowLog._();

  static Stopwatch? _sw;
  static int _lastMs = 0;
  static int _step = 0;

  static bool get isActive => _sw != null;

  static int? get elapsedMs => _sw?.elapsedMilliseconds;

  static void start({String? detail}) {
    _sw = Stopwatch()..start();
    _lastMs = 0;
    _step = 0;
    final extra = detail == null || detail.isEmpty ? '' : ' $detail';
    AppLogger.info('ConfirmSaleFlow: START$extra');
  }

  static void step(String name, {String? detail}) {
    final sw = _sw;
    if (sw == null) return;

    final total = sw.elapsedMilliseconds;
    final delta = total - _lastMs;
    _lastMs = total;
    _step++;

    final extra = detail == null || detail.isEmpty ? '' : ' $detail';
    AppLogger.info(
      'ConfirmSaleFlow: step=$_step name=$name '
      'elapsedMs=$total deltaMs=$delta$extra',
    );
  }

  static void end(String result, {String? detail}) {
    final sw = _sw;
    if (sw == null) return;

    sw.stop();
    final total = sw.elapsedMilliseconds;
    final extra = detail == null || detail.isEmpty ? '' : ' $detail';
    AppLogger.info(
      'ConfirmSaleFlow: END result=$result '
      'totalElapsedMs=$total steps=$_step$extra',
    );
    _sw = null;
    _lastMs = 0;
    _step = 0;
  }

  static void fail(String reason, [Object? error]) {
    final sw = _sw;
    if (sw == null) return;

    sw.stop();
    final total = sw.elapsedMilliseconds;
    final err = error == null ? '' : ' error=$error';
    AppLogger.error(
      'ConfirmSaleFlow: END result=fail '
      'reason=$reason totalElapsedMs=$total steps=$_step$err',
    );
    _sw = null;
    _lastMs = 0;
    _step = 0;
  }
}
