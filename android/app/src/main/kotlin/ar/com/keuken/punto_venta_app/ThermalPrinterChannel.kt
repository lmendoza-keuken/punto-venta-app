package ar.com.keuken.punto_venta_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridge a la impresora térmica integrada (PTA0130 58 mm / PTA0140 80 mm).
 *
 * Mismo patrón que [SubScreenChannel]:
 *  - Servicio Binder: `getSystemService("ThermalPrinter")`
 *  - Clase framework: [com.common.sdk.thermalprinter.ThermalPrinterServiceManager]
 *
 * Los templates Dart llegan como comandos serializados y se mapean a
 * addString / printLogo / setAlgin / setBold / enlargeFontSize / walkPaper.
 */
class ThermalPrinterChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private var manager: Any? = null
    private var managerClass: Class<*>? = null
    private var started = false
    private val methodCache = HashMap<String, java.lang.reflect.Method>()

    init {
        TelpoHiddenApi.releaseReflectionLimit()
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        runCatching {
            if (started) {
                invokeVoid("stop")
            }
        }
        started = false
        channel.setMethodCallHandler(null)
        manager = null
        managerClass = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isAvailable" -> result.success(resolveManager() != null)
                "getInfo" -> result.success(getInfo())
                "connect" -> result.success(doConnect())
                "disconnect" -> result.success(doDisconnect())
                "printCommands" -> {
                    val commands = call.argument<List<Map<String, Any?>>>("commands")
                    if (commands == null) {
                        result.error("bad_args", "commands required", null)
                        return
                    }
                    result.success(printCommands(commands))
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "method ${call.method} failed", e)
            val msg = e.message ?: e.toString()
            val code = when {
                msg.contains("NoPaper", ignoreCase = true) -> "no_paper"
                msg.contains("OverHeat", ignoreCase = true) -> "overheat"
                msg.contains("LowPower", ignoreCase = true) -> "low_power"
                else -> "printer_error"
            }
            result.error(code, msg, null)
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
                methodCache.clear()
                Log.i(TAG, "ThermalPrinter manager bound: ${svc.javaClass.name}")
                svc
            }
        } catch (e: ClassNotFoundException) {
            Log.w(TAG, "$MANAGER_CLASS not on classpath (device sin framework Telpo)")
            null
        }
    }

    private fun getInfo(): Map<String, Any?> {
        if (resolveManager() == null) {
            return mapOf(
                "available" to false,
                "backend" to null,
                "detail" to "ThermalPrinter service missing",
            )
        }
        val version = runCatching { invokeString("getVersion") }.getOrNull()
        val status = runCatching { invokeInt("checkStatus") }.getOrNull()
        return mapOf(
            "available" to true,
            "backend" to "thermal_printer_service",
            "className" to MANAGER_CLASS,
            "version" to version,
            "status" to status,
            "detail" to "Binder ThermalPrinter",
        )
    }

    private fun doConnect(): Map<String, Any?> {
        ensureManager()
        invokeVoid("start")
        invokeVoid("reset")
        applyPrintDefaults()
        started = true
        Log.i(TAG, "ThermalPrinter connect ok")
        return mapOf(
            "ok" to true,
            "backend" to "thermal_printer_service",
            "className" to MANAGER_CLASS,
        )
    }

    private fun doDisconnect(): Map<String, Any?> {
        if (resolveManager() != null && started) {
            runCatching { invokeVoid("walkPaper", 8) }
            runCatching { invokeVoid("stop") }
        }
        started = false
        return mapOf("ok" to true)
    }

    /**
     * PrintStyle default de Telpo usa lineSpace=8 (inserta 8 filas en blanco
     * entre cada addString → ticket muy largo). Lo bajamos a 0.
     */
    private fun applyPrintDefaults() {
        runCatching { invokeVoid("setGray", 5) }
        runCatching { invokeVoid("setLineSpace", 0) }
        runCatching { invokeVoid("setAutoBreak", true) }
        runCatching { invokeVoid("setAlgin", ALIGN_LEFT) }
    }

    /**
     * Adapta TicketCommand (pensados para ESC/POS IP) al API Telpo.
     *
     * Los templates NO se tocan: siguen igual para impresora por IP.
     * Acá solo reinterpretamos:
     *  - text / lineWithValue → addString sin "\n" (en Telpo el \n = fila vacía extra)
     *  - 1º feedLine tras texto → no-op (cierra la línea ESC/POS)
     *  - feedLines extra → a lo sumo 1 avance corto (walkPaper), no addString("\n")
     *  - aplica a standard / blackMarket / whiteMarket / dispose
     */
    private fun printCommands(commands: List<Map<String, Any?>>): Map<String, Any?> {
        ensureReady()
        invokeVoid("reset")
        applyPrintDefaults()

        var pendingText = false
        // Tras emitir texto, el próximo feedLine del template es el LF ESC/POS → no-op.
        var expectTemplateLf = false
        // feedLines adicionales acumulados (se vacían al emitir contenido).
        var pendingBlankFeeds = 0
        var widthMul = 1
        var heightMul = 1

        fun flushBlanks() {
            if (pendingBlankFeeds <= 0) return
            // Templates suelen meter 2–3 LF seguidos; en Telpo addString("\n") es enorme.
            // Un solo walkPaper(1) equivale al “un renglón en blanco” típico de ESC/POS.
            runCatching { invokeVoid("walkPaper", 1) }
            pendingBlankFeeds = 0
        }

        fun flushText() {
            flushBlanks()
            if (!pendingText) return
            invokeVoid("printString")
            pendingText = false
            expectTemplateLf = false
        }

        fun emitText(text: String) {
            flushBlanks()
            val normalized = normalizeFor58mm(text)
            if (normalized.isEmpty()) return
            // Nunca agregar "\n" acá: Telpo lo rasteriza como línea vacía de más.
            invokeVoid("addString", normalized.trimEnd('\n'))
            pendingText = true
            expectTemplateLf = true
        }

        fun applySize() {
            val w = widthMul.coerceIn(1, 2)
            val h = heightMul.coerceIn(1, 2)
            runCatching { invokeVoid("enlargeFontSize", w, h) }
            if (widthMul > 2 || heightMul > 2) {
                val px = (16 * maxOf(widthMul, heightMul)).coerceIn(8, 64)
                runCatching { invokeVoid("setTextSize", px) }
            }
        }

        for (cmd in commands) {
            when (cmd["type"] as? String) {
                "text" -> emitText(cmd["value"] as? String ?: "")
                "feedLine" -> {
                    if (expectTemplateLf) {
                        expectTemplateLf = false
                    } else {
                        pendingBlankFeeds++
                    }
                }
                "alignment" -> {
                    val align = when (cmd["value"] as? String) {
                        "center" -> ALIGN_MIDDLE
                        "right" -> ALIGN_RIGHT
                        else -> ALIGN_LEFT
                    }
                    invokeVoid("setAlgin", align)
                }
                "bold" -> invokeVoid("setBold", cmd["value"] == true)
                "doubleHeight" -> {
                    heightMul = if (cmd["value"] == true) 2 else 1
                    applySize()
                }
                "doubleWidth" -> {
                    widthMul = if (cmd["value"] == true) 2 else 1
                    applySize()
                }
                "textSize" -> {
                    widthMul = ((cmd["width"] as? Number)?.toInt() ?: 1).coerceIn(1, 8)
                    heightMul = ((cmd["height"] as? Number)?.toInt() ?: 1).coerceIn(1, 8)
                    applySize()
                }
                "lineWithValue" -> {
                    val label = (cmd["label"] as? String ?: "").trimEnd()
                    val value = (cmd["value"] as? String ?: "").trim()
                    // Pad a 32 cols. Si no entra, value en la línea siguiente
                    // alineado a la derecha (evita softWrap dejando el $ colgado).
                    if (label.length + value.length + 1 <= LINE_CHARS) {
                        val spaces = LINE_CHARS - label.length - value.length
                        emitText(label + " ".repeat(spaces) + value)
                    } else {
                        if (label.isNotEmpty()) emitText(label.take(LINE_CHARS))
                        if (value.isNotEmpty()) {
                            val pad = (LINE_CHARS - value.length).coerceAtLeast(0)
                            emitText(" ".repeat(pad) + value.take(LINE_CHARS))
                        }
                    }
                }
                "image" -> {
                    flushText()
                    val bytes = cmd["bytes"] as? ByteArray
                    if (bytes != null) {
                        val targetW = ((cmd["imageSize"] as? Number)?.toInt() ?: MAX_DOTS_PER_LINE)
                            .coerceIn(160, MAX_DOTS_PER_LINE)
                        val bmp = decodePrintBitmap(bytes, targetWidth = targetW) ?: continue
                        try {
                            runCatching { invokeVoid("setAlgin", ALIGN_MIDDLE) }
                            invokeVoid("printLogo", bmp)
                        } finally {
                            if (!bmp.isRecycled) bmp.recycle()
                        }
                    }
                }
                "barcode", "barcodeWithType" -> {
                    val code = cmd["code"] as? String ?: cmd["value"] as? String ?: ""
                    if (code.isNotEmpty()) emitText(code)
                }
                "cutPaper" -> {
                    flushText()
                    runCatching { invokeVoid("walkPaper", 2) }
                    runCatching { invokeVoid("cutPaper") }
                }
                else -> { /* ignore unknown */ }
            }
        }

        flushText()
        runCatching { invokeVoid("walkPaper", 2) }
        val status = runCatching { invokeInt("checkStatus") }.getOrNull()
        Log.i(TAG, "printCommands done count=${commands.size} status=$status")
        return mapOf(
            "ok" to true,
            "backend" to "thermal_printer_service",
            "status" to status,
        )
    }

    /**
     * Templates usan lineWidth=48 (80 mm). En PTA0130 (~58 mm) son ~32 cols.
     * - Separadores (-_=.) se recortan a 32.
     * - Texto largo se parte en palabras a 32 cols (además de setAutoBreak).
     */
    private fun normalizeFor58mm(raw: String): String {
        if (raw.isEmpty()) return raw
        val trimmedEnd = raw.trimEnd('\n')
        val hadTrailingNl = raw.endsWith("\n")

        val asSeparator = trimmedEnd.takeIf { it.isNotEmpty() }?.let { s ->
            val c = s[0]
            if (c in "-_=." && s.all { it == c }) c.toString().repeat(LINE_CHARS) else null
        }
        val body = asSeparator ?: softWrap(trimmedEnd, LINE_CHARS)
        return if (hadTrailingNl) "$body\n" else body
    }

    private fun softWrap(text: String, width: Int): String {
        if (text.length <= width) return text
        val out = StringBuilder()
        for (paragraph in text.split('\n')) {
            if (out.isNotEmpty()) out.append('\n')
            if (paragraph.length <= width) {
                out.append(paragraph)
                continue
            }
            var remaining = paragraph
            while (remaining.length > width) {
                var breakAt = remaining.lastIndexOf(' ', width)
                if (breakAt < width / 3) breakAt = width
                out.append(remaining.substring(0, breakAt).trimEnd())
                out.append('\n')
                remaining = remaining.substring(breakAt).trimStart()
            }
            out.append(remaining)
        }
        return out.toString()
    }

    private fun decodePrintBitmap(
        pngBytes: ByteArray,
        targetWidth: Int = MAX_DOTS_PER_LINE,
    ): Bitmap? {
        val decoded = BitmapFactory.decodeByteArray(pngBytes, 0, pngBytes.size) ?: return null
        // Siempre llevar al ancho del papel (384). Si solo downscaleábamos, un QR
        // generado a ~250–416 px quedaba visualmente chico en 58 mm.
        val w = targetWidth.coerceIn(8, MAX_DOTS_PER_LINE)
        val bmp = if (decoded.width != w) {
            val h = ((decoded.height * w) / decoded.width).coerceAtLeast(1)
            Bitmap.createScaledBitmap(decoded, w, h, false).also {
                if (it !== decoded) decoded.recycle()
            }
        } else {
            decoded
        }
        return if (bmp.config == Bitmap.Config.ARGB_8888) {
            bmp
        } else {
            val copy = bmp.copy(Bitmap.Config.ARGB_8888, false)
            if (copy !== bmp && !bmp.isRecycled) bmp.recycle()
            copy
        }
    }

    private fun ensureManager() {
        if (resolveManager() == null) {
            throw IllegalStateException("ThermalPrinter service not available on this device")
        }
    }

    private fun ensureReady() {
        ensureManager()
        if (!started) {
            val c = doConnect()
            if (c["ok"] != true) {
                throw IllegalStateException("ThermalPrinter connect failed")
            }
        }
    }

    private fun invokeVoid(name: String, vararg args: Any?) {
        val owner = manager ?: throw IllegalStateException("manager null")
        resolveMethod(name, args).invoke(owner, *args)
    }

    private fun invokeInt(name: String, vararg args: Any?): Int {
        val owner = manager ?: return -1
        return (resolveMethod(name, args).invoke(owner, *args) as? Int) ?: -1
    }

    private fun invokeString(name: String): String? {
        val owner = manager ?: return null
        return resolveMethod(name, emptyArray()).invoke(owner) as? String
    }

    private fun resolveMethod(name: String, args: Array<out Any?>): java.lang.reflect.Method {
        val clazz = managerClass ?: throw IllegalStateException("manager class null")
        val types = paramTypes(args)
        val key = name + types.joinToString(separator = ",") { it.name }
        methodCache[key]?.let { return it }
        val method = try {
            clazz.getMethod(name, *types)
        } catch (_: NoSuchMethodException) {
            clazz.getDeclaredMethod(name, *types).also { it.isAccessible = true }
        }
        methodCache[key] = method
        return method
    }

    private fun paramTypes(args: Array<out Any?>): Array<Class<*>> {
        return args.map { arg ->
            when (arg) {
                is Int -> Int::class.javaPrimitiveType!!
                is Boolean -> Boolean::class.javaPrimitiveType!!
                is String -> String::class.java
                is ByteArray -> ByteArray::class.java
                is Bitmap -> Bitmap::class.java
                else -> arg?.javaClass ?: Any::class.java
            }
        }.toTypedArray()
    }

    companion object {
        const val CHANNEL = "ar.com.keuken.punto_venta_app/thermal_printer"
        private const val TAG = "ThermalPrinterChannel"
        private const val SERVICE_NAME = "ThermalPrinter"
        private const val MANAGER_CLASS =
            "com.common.sdk.thermalprinter.ThermalPrinterServiceManager"

        private const val ALIGN_LEFT = 0
        private const val ALIGN_MIDDLE = 1
        private const val ALIGN_RIGHT = 2
        /** 384 dots ≈ papel 57±0,5 mm (PTA0130 / rollo Ø50 mm). */
        private const val MAX_DOTS_PER_LINE = 384
        /** Columnas típicas a 58 mm con fuente normal. */
        private const val LINE_CHARS = 32
    }
}
