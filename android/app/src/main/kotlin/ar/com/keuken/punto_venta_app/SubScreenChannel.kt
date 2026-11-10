package ar.com.keuken.punto_venta_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridge al LCD cliente del PTA0130 (Binder "SubScreen").
 *
 * La clase [com.common.sdk.subscreen.SubScreenServiceManager] vive en el
 * framework del fabricante; se invoca por reflexión (mismo patrón que
 * SimpleSubLcd del SDK Telpo/Common).
 */
class SubScreenChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private var manager: Any? = null
    private var managerClass: Class<*>? = null
    private var initialized = false

    init {
        channel.setMethodCallHandler(this)
    }

    /** Apaga el LCD sin desregistrar el MethodChannel (p. ej. onStop). */
    fun releasePower() {
        if (!initialized && resolveManager() == null) return
        runCatching {
            invokeInt("release")
        }.onFailure { Log.w(TAG, "releasePower failed", it) }
        initialized = false
    }

    fun dispose() {
        releasePower()
        channel.setMethodCallHandler(null)
        manager = null
        managerClass = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isAvailable" -> result.success(resolveManager() != null)
                "getInfo" -> result.success(getInfo())
                "init" -> result.success(doInit())
                "release" -> result.success(doRelease())
                "showColor" -> {
                    val color = call.argument<Number>("color")?.toInt() ?: Color.BLUE
                    val label = call.argument<String>("label")
                    result.success(showColor(color, label))
                }
                "showBitmap" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("bad_args", "bytes required", null)
                        return
                    }
                    val x = call.argument<Number>("x")?.toInt() ?: 0
                    val y = call.argument<Number>("y")?.toInt() ?: 0
                    result.success(showBitmapBytes(bytes, x, y))
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "method ${call.method} failed", e)
            result.error("subscreen_error", e.message, null)
        }
    }

    private fun resolveManager(): Any? {
        manager?.let { return it }
        return try {
            val clazz = Class.forName(MANAGER_CLASS)
            val svc = context.getSystemService(SERVICE_NAME)
            if (svc == null) {
                Log.w(TAG, "getSystemService($SERVICE_NAME) == null")
                null
            } else if (!clazz.isInstance(svc)) {
                Log.w(TAG, "service type mismatch: ${svc.javaClass.name}")
                null
            } else {
                managerClass = clazz
                manager = svc
                Log.i(TAG, "SubScreen manager bound: ${svc.javaClass.name}")
                svc
            }
        } catch (e: ClassNotFoundException) {
            Log.w(TAG, "$MANAGER_CLASS not on classpath (device sin framework Telpo)")
            null
        }
    }

    private fun getInfo(): Map<String, Any?> {
        if (resolveManager() == null) {
            return mapOf("available" to false)
        }
        val width = invokeInt("getScreenWidth")
        val height = invokeInt("getScreenHeight")
        val version = invokeString("getVersion")
        // width/height == 61442 (ERR_SYS_NO_DEV) cuando /dev/tp_spi_lcd no existe
        val hasDev = width in 1..4096 && height in 1..4096
        return mapOf(
            "available" to hasDev,
            "width" to if (hasDev) width else null,
            "height" to if (hasDev) height else null,
            "version" to version,
            "rawWidth" to width,
            "rawHeight" to height,
        )
    }

    private fun doInit(): Map<String, Any?> {
        ensureManager()
        val code = invokeInt("init")
        // 0 OK, 61444 already init → tratamos ambos como listo
        if (code == 0 || code == ERR_ALREADY_INIT) {
            initialized = true
        }
        return mapOf("code" to code, "ok" to (code == 0 || code == ERR_ALREADY_INIT))
    }

    private fun doRelease(): Map<String, Any?> {
        if (resolveManager() == null) {
            return mapOf("code" to ERR_NOT_SUPPORT, "ok" to false)
        }
        val code = invokeInt("release")
        initialized = false
        return mapOf("code" to code, "ok" to (code == 0))
    }

    private fun showColor(argb: Int, label: String?): Map<String, Any?> {
        ensureReady()
        val w = invokeInt("getScreenWidth").coerceIn(1, 320)
        val h = invokeInt("getScreenHeight").coerceIn(1, 240)
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        bmp.eraseColor(argb)
        if (!label.isNullOrBlank()) {
            val canvas = Canvas(bmp)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (luminance(argb) > 0.5f) Color.BLACK else Color.WHITE
                textSize = 26f
                typeface = Typeface.DEFAULT_BOLD
                textAlign = Paint.Align.CENTER
            }
            val lines = label.split('\n')
            val lineHeight = paint.fontSpacing
            val blockHeight = lineHeight * lines.size
            var y = (h - blockHeight) / 2f - paint.ascent()
            for (line in lines) {
                canvas.drawText(line, w / 2f, y, paint)
                y += lineHeight
            }
        }
        val code = invokeShow(bmp, 0, 0)
        bmp.recycle()
        return mapOf("code" to code, "ok" to (code == 0))
    }

    private fun showBitmapBytes(bytes: ByteArray, x: Int, y: Int): Map<String, Any?> {
        ensureReady()
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: return mapOf("code" to ERR_INVALID, "ok" to false, "error" to "decode_failed")
        val w = invokeInt("getScreenWidth").coerceIn(1, 320)
        val h = invokeInt("getScreenHeight").coerceIn(1, 240)
        val scaled = if (decoded.width != w || decoded.height != h) {
            Bitmap.createScaledBitmap(decoded, w, h, true).also {
                if (it !== decoded) decoded.recycle()
            }
        } else {
            decoded
        }
        val code = invokeShow(scaled, x, y)
        scaled.recycle()
        return mapOf("code" to code, "ok" to (code == 0))
    }

    private fun ensureManager() {
        if (resolveManager() == null) {
            throw IllegalStateException("SubScreen service not available on this device")
        }
    }

    private fun ensureReady() {
        ensureManager()
        if (!initialized) {
            val initResult = doInit()
            if (initResult["ok"] != true) {
                throw IllegalStateException("SubScreen init failed code=${initResult["code"]}")
            }
        }
    }

    private fun invokeShow(bitmap: Bitmap, x: Int, y: Int): Int {
        val clazz = managerClass ?: return ERR_NOT_SUPPORT
        val owner = manager ?: return ERR_NOT_SUPPORT
        val method = clazz.getMethod(
            "show",
            Bitmap::class.java,
            Int::class.javaPrimitiveType,
            Int::class.javaPrimitiveType,
        )
        return (method.invoke(owner, bitmap, x, y) as Int)
    }

    private fun invokeInt(name: String): Int {
        val clazz = managerClass ?: return ERR_NOT_SUPPORT
        val owner = manager ?: return ERR_NOT_SUPPORT
        return (clazz.getMethod(name).invoke(owner) as Int)
    }

    private fun invokeString(name: String): String? {
        val clazz = managerClass ?: return null
        val owner = manager ?: return null
        return clazz.getMethod(name).invoke(owner) as? String
    }

    private fun luminance(argb: Int): Float {
        val r = Color.red(argb) / 255f
        val g = Color.green(argb) / 255f
        val b = Color.blue(argb) / 255f
        return 0.2126f * r + 0.7152f * g + 0.0722f * b
    }

    companion object {
        const val CHANNEL = "ar.com.keuken.punto_venta_app/subscreen"
        private const val TAG = "SubScreenChannel"
        private const val SERVICE_NAME = "SubScreen"
        private const val MANAGER_CLASS = "com.common.sdk.subscreen.SubScreenServiceManager"

        private const val ERR_INVALID = 61441
        private const val ERR_ALREADY_INIT = 61444
        private const val ERR_NOT_SUPPORT = 61447
    }
}
