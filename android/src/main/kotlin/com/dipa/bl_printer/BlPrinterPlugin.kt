package com.dipa.bl_printer

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.IntentFilter
import android.os.Build
import com.dipa.bl_printer.permission.PermissionManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** BlPrinterPlugin */
class BlPrinterPlugin : FlutterPlugin, ActivityAware, MethodCallHandler, StreamHandler {
    companion object {
        const val NAMESPACE = "bl_printer"
    }

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var stateChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var binding: ActivityPluginBinding? = null

    private var controller: BlPrinterController? = null

    private var blStateReceiver = BlStateReceiver(::emitSink)

    private val coroutineScope by lazy {
        CoroutineScope(SupervisorJob() + Dispatchers.Main)
    }

    private val permissionManager by lazy { PermissionManager() }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        setup(flutterPluginBinding.binaryMessenger, flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            "isBluetoothEnable" -> result.success(controller?.isBluetoothEnable == true)
            "getConnectedDevice" -> {
                val selected = controller?.getConnectedDevice
                if (selected != null) {
                    result.success("${selected.name}#${selected.address}")
                } else {
                    result.error(
                        "No Device Connected",
                        "No Device Connected",
                        "No Device Connected",
                    )
                }
            }

            "devices" -> {
                controller?.let {
                    val devices = it.getBluetoothList()
                    result.success(devices)
                } ?: kotlin.run {
                    emitMethodFailure(result, Exception("Controller Not initialize"))
                }
            }

            "connect" -> {
                try {
                    val address = call.argument<String>("address")
                        ?: throw Exception("Address Cannot be null")
                    controller?.let {
                        coroutineScope.launch {
                            it.connectToDevice(
                                address,
                                { result.success(true) },
                                { e -> emitMethodFailure(result, e) },
                            )
                        }
                    } ?: kotlin.run {
                        throw Exception("Controller Not initialize")
                    }
                } catch (e: Exception) {
                    emitMethodFailure(result, e)
                }
            }

            "disconnect" -> {
                try {
                    controller?.closeConnection()
                    result.success(true)
                } catch (e: Exception) {
                    emitMethodFailure(result, e)
                }
            }

            "close" -> {
                try {
                    controller?.closeConnection()
                    eventSink = null
                    context.unregisterReceiver(blStateReceiver)
                    result.success(true)
                } catch (e: Exception) {
                    emitMethodFailure(result, e)
                }
            }

            "printTest" -> {
                try {
                    coroutineScope.launch {
                        controller?.printTest { e ->
                            if (e == null) {
                                result.success(true)
                            } else {
                                emitMethodFailure(result, e)
                            }
                        }
                    }
                } catch (e: Exception) {
                    emitMethodFailure(result, e)
                }
            }

            "print" -> {
                try {
                    val data = call.argument<List<String>>("data")
                        ?: throw Exception("print data cannot be empty")
                    coroutineScope.launch {
                        controller?.print(data) { e ->
                            if (e == null) {
                                result.success(true)
                            } else {
                                emitMethodFailure(result, e)
                            }
                        }
                    }
                } catch (e: Exception) {
                    emitMethodFailure(result, e)
                }
            }

            "printBytes" -> {
                val data = call.argument<List<Int>>("data")
                    ?: throw Exception("print data cannot be empty")
                coroutineScope.launch {

                    var bytes: ByteArray = "\n".toByteArray()
                    data.forEach {
                        bytes += it.toByte()
                    }

                    controller?.printByte(bytes) { e ->
                        if (e == null) {
                            result.success(true)
                        } else {
                            emitMethodFailure(result, e)
                        }
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stateChannel.setStreamHandler(null)
        controller?.closeConnection()
        controller = null
        coroutineScope.cancel()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addRequestPermissionsResultListener(permissionManager)
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {
        binding?.removeRequestPermissionsResultListener(permissionManager)
        this.binding = null
    }

    private fun setup(
        binaryMessenger: BinaryMessenger,
        context: Context,
    ) {
        synchronized(this) {
            channel = MethodChannel(binaryMessenger, "$NAMESPACE/methods")
            channel.setMethodCallHandler(this)
            stateChannel = EventChannel(binaryMessenger, "$NAMESPACE/states")
            stateChannel.setStreamHandler(this)
            controller = BlPrinterController(context)
        }
    }

    private fun emitSink(state: BluetoothState, device: BluetoothDevice? = null) {
        eventSink?.let {
            val data = HashMap<String, Any>()
            data["status"] = state.ordinal
            if (device != null) {
                data["devices"] = "${device.name}#${device.address}"
            }

            it.success(data)
        }
    }

    private fun emitMethodFailure(result: Result, e: Exception) {
        result.error(
            e.message ?: e.localizedMessage ?: e.toString(),
            e.localizedMessage,
            e.stackTraceToString(),
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED).also {
            it.addAction(BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED)
            it.addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            it.addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
        }
        binding?.let {
            permissionManager.requestPermission(
                it.activity,
                {
                    eventSink = events
                    val state = controller?.initialState ?: BluetoothState.DISABLE
                    emitSink(state)
                    context.registerReceiver(blStateReceiver, filter)
                },
                { error ->
                    events?.error(
                        "Permission Not Granted",
                        error.message ?: error.localizedMessage,
                        error.toString(),
                    )
                },
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        context.unregisterReceiver(blStateReceiver)
    }
}
