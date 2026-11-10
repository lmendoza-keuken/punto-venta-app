package ar.com.keuken.punto_venta_app

import android.os.Build
import android.util.Log

/**
 * Equivalente a `SystemUtil.releaseReflectionLimit()` del SDK Telpo/Common.
 * Necesario para invocar managers del framework (`SubScreen`, `ThermalPrinter`)
 * sin que Android 9+ bloquee la reflexión sobre APIs no-SDK.
 */
object TelpoHiddenApi {
    private const val TAG = "TelpoHiddenApi"
    @Volatile
    private var done = false

    fun releaseReflectionLimit() {
        if (done) return
        synchronized(this) {
            if (done) return
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                done = true
                return
            }
            try {
                val classClass = Class::class.java
                val forName = classClass.getDeclaredMethod("forName", String::class.java)
                val getDeclaredMethod = classClass.getDeclaredMethod(
                    "getDeclaredMethod",
                    String::class.java,
                    Class.forName("[Ljava.lang.Class;"),
                )
                val vmRuntimeClass = forName.invoke(null, "dalvik.system.VMRuntime") as Class<*>
                val getRuntime = getDeclaredMethod.invoke(
                    vmRuntimeClass,
                    "getRuntime",
                    null,
                ) as java.lang.reflect.Method
                val setExemptions = getDeclaredMethod.invoke(
                    vmRuntimeClass,
                    "setHiddenApiExemptions",
                    arrayOf(Class.forName("[Ljava.lang.String;")),
                ) as java.lang.reflect.Method
                val runtime = getRuntime.invoke(null)
                setExemptions.invoke(runtime, arrayOf("L"))
                Log.i(TAG, "Hidden API exemptions set")
            } catch (t: Throwable) {
                Log.w(TAG, "releaseReflectionLimit failed: ${t.message}")
            }
            done = true
        }
    }
}
