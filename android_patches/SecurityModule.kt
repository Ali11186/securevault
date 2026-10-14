package com.alaa.securevault

import android.content.Context
import android.content.pm.PackageManager
import android.os.Debug
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.Socket
import java.security.MessageDigest

class SecurityModule(private val ctx: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSignatureHash" -> result.success(getSignatureHash())
            "checkSignature"   -> result.success(checkSignature(call.argument<String>("expected") ?: ""))
            "checkDebugger"    -> result.success(checkDebugger())
            "checkFrida"       -> result.success(checkFrida())
            "checkRoot"        -> result.success(checkRoot())
            else -> result.notImplemented()
        }
    }

    private fun getSignatureHash(): String {
        return try {
            val pm = ctx.packageManager
            @Suppress("DEPRECATION")
            val info = if (android.os.Build.VERSION.SDK_INT >= 28) {
                pm.getPackageInfo(ctx.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                pm.getPackageInfo(ctx.packageName, PackageManager.GET_SIGNATURES)
            }
            val sigs = if (android.os.Build.VERSION.SDK_INT >= 28)
                info.signingInfo?.apkContentsSigners
            else info.signatures
            if (sigs.isNullOrEmpty()) return ""
            val md = MessageDigest.getInstance("SHA-256")
            val hash = md.digest(sigs[0].toByteArray())
            Base64.encodeToString(hash, Base64.NO_WRAP)
        } catch (t: Throwable) { "" }
    }

    private fun checkSignature(expected: String): Boolean {
        if (expected.isEmpty()) return true
        return getSignatureHash() == expected
    }

    private fun checkDebugger(): Boolean {
        if (Debug.isDebuggerConnected()) return true
        if (Debug.waitingForDebugger()) return true
        return try {
            BufferedReader(FileReader("/proc/self/status")).use { r ->
                var line = r.readLine()
                while (line != null) {
                    if (line.startsWith("TracerPid:")) {
                        val pid = line.substringAfter(":").trim().toIntOrNull() ?: 0
                        return pid != 0
                    }
                    line = r.readLine()
                }
            }
            false
        } catch (t: Throwable) { false }
    }

    private fun checkFrida(): Boolean {
        for (port in intArrayOf(27042, 27043)) {
            try {
                Socket("127.0.0.1", port).use { return true }
            } catch (_: Throwable) {}
        }
        val paths = arrayOf(
            "/data/local/tmp/frida-server",
            "/data/local/tmp/re.frida.server",
            "/system/lib/libfrida-gadget.so",
            "/system/lib64/libfrida-gadget.so"
        )
        for (p in paths) if (File(p).exists()) return true
        try {
            BufferedReader(FileReader("/proc/self/maps")).use { r ->
                var line = r.readLine()
                while (line != null) {
                    if (line.contains("frida") || line.contains("gadget")) return true
                    line = r.readLine()
                }
            }
        } catch (_: Throwable) {}
        return false
    }

    private fun checkRoot(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su", "/system/bin/su", "/system/xbin/su",
            "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su",
            "/data/local/su", "/su/bin/su"
        )
        for (p in paths) if (File(p).exists()) return true
        return false
    }
}
