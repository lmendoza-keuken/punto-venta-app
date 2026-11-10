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
        subScreenChannel?.dispose()
        subScreenChannel = null
        thermalPrinterChannel?.dispose()
        thermalPrinterChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onStop() {
        subScreenChannel?.releasePower()
        super.onStop()
    }

    override fun onDestroy() {
        subScreenChannel?.dispose()
        subScreenChannel = null
        thermalPrinterChannel?.dispose()
        thermalPrinterChannel = null
        super.onDestroy()
    }
}
