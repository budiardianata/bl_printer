package com.dipa.bl_printer.permission

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
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
        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
//            Manifest.permission.BLUETOOTH,
//            Manifest.permission.BLUETOOTH_ADMIN,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        return permissions
    }

    private fun hasPermissions(context: Context): Boolean {
        return requiredPermissions().all {
            (ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED)
        }
    }

    fun canRequestPermission(): Boolean {
        activity?.let { act ->
            return requiredPermissions().any {
                ActivityCompat.shouldShowRequestPermissionRationale(act, it)
            }
        } ?: kotlin.run {
            return false
        }
    }

    fun updateActivity(activity: Activity) {
        this.activity = activity
    }

    fun requestPermission(
        onGranted: () -> Unit,
        onError: (Exception) -> Unit,
    ) {
        activity?.let {
            if (hasPermissions(it.applicationContext)) {
                onGranted.invoke()
                return
            }
            this.resultCallback = onGranted
            this.errorCallback = onError
            ActivityCompat.requestPermissions(
                it, requiredPermissions().toTypedArray(), PERMISSION_REQUEST_CODE,
            )
        } ?: kotlin.run {
            onError(Exception("activity cannot be null"))
        }
    }

    fun openSettingsPermission() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)

        activity?.let {
            intent.data = Uri.fromParts("package", it.packageName, null)
            it.startActivity(intent)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) {
            return false
        }
        Log.d(
            "TAG",
            "onRequestPermissionsResult: $requestCode ${grantResults.all { it == PackageManager.PERMISSION_GRANTED }} "
        )

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