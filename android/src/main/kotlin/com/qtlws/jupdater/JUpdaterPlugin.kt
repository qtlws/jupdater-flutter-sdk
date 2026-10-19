package com.qtlws.jupdater

import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** Android side of JUpdater: app/device info and opening the update URL. */
class JUpdaterPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformInfo" -> {
                try {
                    result.success(platformInfo())
                } catch (e: Exception) {
                    result.error("jupdater_info", e.message, null)
                }
            }
            "openUrl" -> result.success(openUrl(call.argument<String>("url")))
            else -> result.notImplemented()
        }
    }

    @Suppress("DEPRECATION")
    private fun platformInfo(): Map<String, Any?> {
        val ctx = requireNotNull(context)
        val pm = ctx.packageManager
        val pkg = ctx.packageName
        val info: PackageInfo = if (Build.VERSION.SDK_INT >= 33) {
            pm.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
        } else {
            pm.getPackageInfo(pkg, 0)
        }
        val versionCode: Long = if (Build.VERSION.SDK_INT >= 28) {
            info.longVersionCode
        } else {
            info.versionCode.toLong()
        }
        return mapOf(
            "packageName" to pkg,
            "versionName" to (info.versionName ?: ""),
            "buildNumber" to versionCode,
            "supportDir" to File(ctx.filesDir, "jupdater").absolutePath,
            "brand" to Build.BRAND,
            "device" to Build.DEVICE,
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "board" to Build.BOARD,
            "osVersion" to Build.VERSION.RELEASE,
            "firstInstallTime" to info.firstInstallTime
        )
    }

    private fun openUrl(url: String?): Boolean {
        val ctx = context ?: return false
        if (url.isNullOrEmpty()) return false
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            ctx.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        private const val CHANNEL = "com.qtlws.jupdater/native"
    }
}
