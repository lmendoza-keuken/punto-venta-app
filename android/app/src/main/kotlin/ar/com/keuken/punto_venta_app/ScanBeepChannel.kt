package ar.com.keuken.punto_venta_app

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bip corto al escanear con cámara (estilo pistola / POS).
 */
class ScanBeepChannel(
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "ar.com.keuken.punto_venta_app/scan_beep"
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "beep" -> {
                try {
                    playBeep()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("BEEP_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun playBeep() {
        // STREAM_MUSIC + volume 100: más fuerte que NOTIFICATION en el PTA.
        val toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
        toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 220)
        mainHandler.postDelayed({
            try {
                toneGen.release()
            } catch (_: Exception) {
            }
        }, 320)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
