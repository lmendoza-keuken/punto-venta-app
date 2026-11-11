package ar.com.keuken.punto_venta_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Bridge al LCD cliente del PTA0130 (Binder "SubScreen").
 *
 * SPI en un único hilo dedicado (no main): init puede tardar 5–10s y si corre
 * en main congela la tablet. La causa real de 61448 (ERR_BUSY) fue abortar
 * con timeout/shutdown mientras init seguía en curso, no el hilo en sí.
 */
class SubScreenChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val lcdExecutor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "pta-subscreen").apply { isDaemon = true }
    }
    private var manager: Any? = null
    private var managerClass: Class<*>? = null
    private var initialized = false
    @Volatile private var shutDown = false

    init {
        TelpoHiddenApi.releaseReflectionLimit()
        channel.setMethodCallHandler(this)
    }

    fun shutdownLcd(reason: String = "shutdown") {
        if (shutDown) return
        if (lcdExecutor.isShutdown) {
            shutdownLcdOnWorker(reason)
            return
        }
        val done = CountDownLatch(1)
        lcdExecutor.execute {
            try {
                shutdownLcdOnWorker(reason)
            } finally {
                done.countDown()
            }
        }
        if (!done.await(1500, TimeUnit.MILLISECONDS)) {
            Log.w(TAG, "shutdownLcd timed out reason=$reason")
        }
    }

    private fun shutdownLcdOnWorker(reason: String) {
        if (shutDown) return
        if (!initialized && resolveManager() == null) {
            shutDown = true
            return
        }
        runCatching {
            Log.i(TAG, "shutdownLcd reason=$reason")
            if (!initialized) {
                val code = initWithBusyRetry()
                if (code == 0 || code == ERR_ALREADY_INIT) {
                    initialized = true
                }
            }
            if (initialized) {
                paintSolid(Color.BLACK)
                Thread.sleep(SHUTDOWN_SETTLE_MS)
            }
            invokeInt("release")
        }.onFailure { Log.w(TAG, "shutdownLcd failed", it) }
        initialized = false
        shutDown = true
    }

    fun dispose() {
        shutdownLcd("dispose")
        channel.setMethodCallHandler(null)
        manager = null
        managerClass = null
        lcdExecutor.shutdownNow()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> {
                runCatching { result.success(resolveManager() != null) }
                    .onFailure { result.error("subscreen_error", it.message, null) }
            }
            "getInfo" -> {
                runCatching { result.success(getInfo()) }
                    .onFailure { result.error("subscreen_error", it.message, null) }
            }
            "init", "release", "shutdown", "showColor", "showBitmap" -> {
                lcdExecutor.execute {
                    try {
                        val payload: Map<String, Any?> = when (call.method) {
                            "init" -> doInit()
                            "release", "shutdown" -> doShutdown()
                            "showColor" -> {
                                val color = call.argument<Number>("color")?.toInt()
                                    ?: Color.BLUE
                                val label = call.argument<String>("label")
                                showColor(color, label)
                            }
                            "showBitmap" -> {
                                val bytes = call.argument<ByteArray>("bytes")
                                    ?: return@execute replyError(
                                        result,
                                        "bad_args",
                                        "bytes required",
                                    )
                                val x = call.argument<Number>("x")?.toInt() ?: 0
                                val y = call.argument<Number>("y")?.toInt() ?: 0
                                showBitmapBytes(bytes, x, y)
                            }
                            else -> emptyMap()
                        }
                        replySuccess(result, payload)
                    } catch (e: Exception) {
                        Log.e(TAG, "method ${call.method} failed", e)
                        replyError(result, "subscreen_error", e.message)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun replySuccess(result: MethodChannel.Result, payload: Any?) {
        mainHandler.post {
            try {
                result.success(payload)
            } catch (e: IllegalStateException) {
                Log.w(TAG, "result already replied", e)
            }
        }
    }

    private fun replyError(
        result: MethodChannel.Result,
        code: String,
        message: String?,
    ) {
        mainHandler.post {
            try {
                result.error(code, message, null)
            } catch (e: IllegalStateException) {
                Log.w(TAG, "result already replied", e)
            }
        }
    }

    private fun resolveManager(): Any? {
        manager?.let { return it }
        TelpoHiddenApi.releaseReflectionLimit()
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

    private fun doInit(coverWithBlack: Boolean = true): Map<String, Any?> {
        ensureManager()
        if (initialized) {
            return mapOf("code" to ERR_ALREADY_INIT, "ok" to true)
        }
        val code = initWithBusyRetry()
        if (code == 0 || code == ERR_ALREADY_INIT) {
            initialized = true
            shutDown = false
            if (coverWithBlack) {
                runCatching { paintSolid(Color.BLACK) }
                    .onFailure { Log.i(TAG, "cover black after init failed: $it") }
            }
        } else {
            Log.i(TAG, "doInit failed code=$code")
        }
        return mapOf("code" to code, "ok" to (code == 0 || code == ERR_ALREADY_INIT))
    }

    /** Siempre release previo; si 61448 BUSY, release + retry. */
    private fun initWithBusyRetry(): Int {
        Log.i(TAG, "init: pre-release")
        runCatching { invokeInt("release") }
        initialized = false
        sleepQuiet(120)

        var code = invokeInt("init")
        Log.i(TAG, "init: first code=$code")
        if (code == 0 || code == ERR_ALREADY_INIT) return code

        Log.i(TAG, "init: code=$code → release + retry")
        runCatching { invokeInt("release") }
        initialized = false
        sleepQuiet(250)
        code = invokeInt("init")
        Log.i(TAG, "init: retry code=$code")
        return code
    }

    private fun doShutdown(): Map<String, Any?> {
        if (shutDown) {
            return mapOf("code" to 0, "ok" to true)
        }
        if (resolveManager() == null) {
            shutDown = true
            return mapOf("code" to ERR_NOT_SUPPORT, "ok" to false)
        }
        return try {
            if (!initialized) {
                val initCode = initWithBusyRetry()
                if (initCode == 0 || initCode == ERR_ALREADY_INIT) {
                    initialized = true
                }
            }
            if (initialized) {
                paintSolid(Color.BLACK)
                sleepQuiet(SHUTDOWN_SETTLE_MS)
            }
            val code = invokeInt("release")
            initialized = false
            shutDown = true
            mapOf("code" to code, "ok" to (code == 0))
        } catch (e: Exception) {
            initialized = false
            shutDown = true
            Log.e(TAG, "doShutdown failed", e)
            mapOf("code" to -1, "ok" to false, "error" to (e.message ?: "shutdown"))
        }
    }

    private fun paintSolid(argb: Int): Int {
        val w = invokeInt("getScreenWidth").coerceIn(1, 320)
        val h = invokeInt("getScreenHeight").coerceIn(1, 240)
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        bmp.eraseColor(argb)
        val code = invokeShow(bmp, 0, 0)
        bmp.recycle()
        return code
    }

    private fun showColor(argb: Int, label: String?): Map<String, Any?> {
        ensureManager()
        ensureReady(coverWithBlack = true)
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
        ensureManager()
        ensureReady(coverWithBlack = true)
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
        try {
            val code = invokeShow(scaled, x, y)
            Log.i(TAG, "showBitmap invokeShow code=$code ${w}x$h")
            if (code != 0) {
                Log.e(TAG, "showBitmap invokeShow code=$code → release")
                runCatching { invokeInt("release") }
                initialized = false
            }
            return mapOf("code" to code, "ok" to (code == 0))
        } catch (e: Exception) {
            Log.e(TAG, "showBitmap failed → release", e)
            runCatching { invokeInt("release") }
            initialized = false
            throw e
        } finally {
            scaled.recycle()
        }
    }

    private fun ensureManager() {
        if (resolveManager() == null) {
            throw IllegalStateException("SubScreen service not available on this device")
        }
    }

    private fun ensureReady(coverWithBlack: Boolean = true) {
        ensureManager()
        if (!initialized) {
            val initResult = doInit(coverWithBlack = coverWithBlack)
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

    private fun sleepQuiet(ms: Long) {
        try {
            Thread.sleep(ms)
        } catch (_: InterruptedException) {
        }
    }

    companion object {
        const val CHANNEL = "ar.com.keuken.punto_venta_app/subscreen"
        private const val TAG = "SubScreenChannel"
        private const val SERVICE_NAME = "SubScreen"
        private const val MANAGER_CLASS = "com.common.sdk.subscreen.SubScreenServiceManager"

        private const val ERR_INVALID = 61441
        private const val ERR_ALREADY_INIT = 61444
        private const val ERR_NOT_SUPPORT = 61447
        private const val ERR_BUSY = 61448

        private const val SHUTDOWN_SETTLE_MS = 100L
    }
}
