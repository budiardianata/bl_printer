package com.dipa.bl_printer.permission

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.PluginRegistry

class PermissionManager : PluginRegistry.RequestPermissionsResultListener {
    companion object {
        const val PERMISSION_REQUEST_CODE = 199
    }

    private var activity: Activity? = null
    private var resultCallback: () -> Unit = {}
    private var errorCallback: (Exception) -> Unit = {}

    private fun requiredPermissions(): List<String> {
        val permission = mutableListOf(
            Manifest.permission.BLUETOOTH,
            Manifest.permission.BLUETOOTH_ADMIN,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permission.addAll(
                listOf(Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN)
            )
        }
        return permission
    }

    private fun hasPermissions(context: Context): Boolean {
        return requiredPermissions().all {
            (ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED)
        }
    }

    fun requestPermission(
        activity: Activity,
        onGranted: () -> Unit,
        onError: (Exception) -> Unit,
    ) {
        if (hasPermissions(activity.applicationContext)) {
            onGranted.invoke()
            return
        }
        this.activity = activity
        this.resultCallback = onGranted
        this.errorCallback = onError
        ActivityCompat.requestPermissions(
            activity, requiredPermissions().toTypedArray(), PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) {
            return false
        }
        if (this.activity == null) {
            errorCallback.invoke(Exception("Trying to process permission result without an valid Activity instance"))
            return false
        }

        if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
            resultCallback.invoke()
        } else {
            errorCallback.invoke(Exception("some permission not granted"))
        }
        return true
    }

}