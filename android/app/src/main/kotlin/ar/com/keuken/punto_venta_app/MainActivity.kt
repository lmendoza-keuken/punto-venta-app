package ar.com.keuken.punto_venta_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var subScreenChannel: SubScreenChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        subScreenChannel = SubScreenChannel(
            context = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        subScreenChannel?.dispose()
        subScreenChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onStop() {
        subScreenChannel?.releasePower()
        super.onStop()
    }

    override fun onDestroy() {
        subScreenChannel?.dispose()
        subScreenChannel = null
        super.onDestroy()
    }
}
