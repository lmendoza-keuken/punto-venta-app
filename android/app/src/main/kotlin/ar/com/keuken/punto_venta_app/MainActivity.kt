package ar.com.keuken.punto_venta_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var subScreenChannel: SubScreenChannel? = null
    private var thermalPrinterChannel: ThermalPrinterChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        subScreenChannel = SubScreenChannel(
            context = this,
            messenger = messenger,
        )
        thermalPrinterChannel = ThermalPrinterChannel(
            context = this,
            messenger = messenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // dispose → shutdownLcd síncrono (negro + release) antes de desarmar el engine.
        subScreenChannel?.dispose()
        subScreenChannel = null
        thermalPrinterChannel?.dispose()
        thermalPrinterChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    // No apagar LCD en onStop/pause: eso flasha al volver. Solo al destruir.

    override fun onDestroy() {
        // Swipe desde recientes / finish(): último chance de negro+release
        // antes de que el proceso muera. Force-stop desde Settings no llega acá.
        subScreenChannel?.shutdownLcd("onDestroy")
        subScreenChannel?.dispose()
        subScreenChannel = null
        thermalPrinterChannel?.dispose()
        thermalPrinterChannel = null
        super.onDestroy()
    }
}
