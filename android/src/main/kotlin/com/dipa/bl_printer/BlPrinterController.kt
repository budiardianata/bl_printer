package com.dipa.bl_printer

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.datecs.api.printer.Printer
import com.datecs.api.printer.ProtocolAdapter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.Base64
import java.util.UUID


//@SuppressLint("MissingPermission")
class BlPrinterController(private val context: Context) {
    private val bluetoothManager by lazy {
        ContextCompat.getSystemService(context, BluetoothManager::class.java)
    }

    private val bluetoothAdapter by lazy {
        bluetoothManager?.adapter
    }

    private var bluetoothSocket: BluetoothSocket? = null

    private var printer: Printer? = null

    private var protocolAdapter: ProtocolAdapter? = null

    val isBluetoothEnable get() = bluetoothAdapter?.isEnabled == true

    val getConnectedDevice get() = bluetoothSocket?.remoteDevice

    val initialState: BluetoothState
        get() {
            try {
                return when (bluetoothAdapter?.state) {
                    BluetoothAdapter.STATE_ON -> BluetoothState.AVAILABLE
                    else -> BluetoothState.DISCONNECTED
                }
            } catch (e: Exception) {
                throw e
            }
        }

    suspend fun connectToDevice(
        address: String,
        onSuccess: () -> Unit,
        onFailure: (Exception) -> Unit,
    ) {

        if (!isBluetoothEnable) {
            throw Exception("Bluetooth Not Enabled")
        }
        withContext(Dispatchers.IO) {
            bluetoothAdapter?.cancelDiscovery()
            bluetoothSocket = bluetoothAdapter
                ?.getRemoteDevice(address)
                ?.createRfcommSocketToServiceRecord(
                    UUID.fromString("00001101-0000-1000-8000-00805f9b34fb")
                )

            bluetoothSocket?.let { socket ->
                try {
                    socket.connect()
                    initializePrinter(socket.inputStream, socket.outputStream)
                    onSuccess.invoke()
                } catch (e: Exception) {
                    bluetoothSocket?.close()
                    printer = null
                    bluetoothSocket = null
                    onFailure.invoke(e)
                }
            }
        }
    }

    @Throws(IOException::class)
    private fun initializePrinter(inputStream: InputStream, outputStream: OutputStream) {
        protocolAdapter = ProtocolAdapter(inputStream, outputStream)
        protocolAdapter?.let {
            if (it.isProtocolEnabled) {
                val channel = it.getChannel(ProtocolAdapter.CHANNEL_PRINTER)
                // Create new event pulling thread
                val coroutineScope = CoroutineScope(Dispatchers.IO)
                coroutineScope.launch {
                    while (true) {
                        delay(50)
                        try {
                            channel.pullEvent()
                        } catch (e: IOException) {
                            break
                        }
                    }
                }
                printer = Printer(channel.inputStream, channel.outputStream)
            } else {
                printer = Printer(it.rawInputStream, it.rawOutputStream)
            }
        }
    }

    suspend fun print(items: List<String>, result: (Exception?) -> Unit) =
        withContext(Dispatchers.IO) {
            try {
                printer?.let { p ->
                    p.reset()
                    for (i in items.indices) {
                        if (items[i].contains("feedPaper#")) {
                            val split = items[i].split("#").dropLastWhile { it.isEmpty() }
                            val feed = split[1].toIntOrNull() ?: 0
                            p.feedPaper(feed)
                        } else if (items[i].contains("bitmap#")) {
                            val split = items[i].split("#").dropLastWhile { it.isEmpty() }
                            val img = split[1]
                            Log.e("TAG", "print:img $img")
                            val align = split[2].toIntOrNull() ?: Printer.ALIGN_LEFT
                            val width = split[3].toIntOrNull() ?: 200
                            val height = split[4].toIntOrNull() ?: 200
                            val argb = resizeBitmapFromBase64(img, width, height)
                            p.printCompressedImage(argb, width, height, align, true)
                        } else if (items[i].contains("qrCode#")) {
                            try {
                                val split = items[i].split("#").dropLastWhile { it.isEmpty() }
                                val qrCode = split[1]
                                val align = split[2].toIntOrNull() ?: Printer.ALIGN_CENTER
                                val size = split[3].toIntOrNull() ?: 25
                                val height = 255
                                p.also {
                                    it.setBarcode(
                                        align,
                                        false,
                                        4,
                                        Printer.HRI_NONE,
                                        height
                                    )
                                    it.printQRCode(size, 4, qrCode)
                                    it.feedPaper(35)
                                }
                            } catch (e: Exception) {
                                Log.e("TAG", "print: ", e)
                            }

                        } else {
                            p.printTaggedText(items[i])
                        }
                    }
                    p.flush()
                    result.invoke(null)
                } ?: kotlin.run {
                    throw Exception("Printer not connected")
                }
            } catch (e: Exception) {
                result.invoke(e)
            }
        }

    suspend fun printByte(byteArray: ByteArray, result: (Exception?) -> Unit) =
        withContext(Dispatchers.IO) {
            try {
                printer?.let { p ->
                    p.reset()
                    synchronized(this) {
                        p.write(byteArray)
                    }
                    p.flush()
                    result.invoke(null)
                } ?: kotlin.run {
                    throw Exception("Printer not connected")
                }
            } catch (e: Exception) {
                result.invoke(e)
            }
        }

    private fun resizeBitmapFromBase64(
        base64Image: String,
        targetWidth: Int,
        targetHeight: Int,
    ): IntArray {
        // Decode the base64 string into a byte array
        val imageBytes =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Base64.getDecoder().decode(base64Image.toByteArray(charset("UTF-8")))
            } else {
                android.util.Base64.decode(base64Image, android.util.Base64.DEFAULT)
            }

        // Decode the byte array into a bitmap
        val originalBitmap = BitmapFactory.decodeStream(ByteArrayInputStream(imageBytes))

        // Create a resized bitmap
        val resizedBitmap =
            Bitmap.createScaledBitmap(originalBitmap, targetWidth, targetHeight, false)

        val pixelArray = IntArray(resizedBitmap.width * resizedBitmap.height)
        resizedBitmap.getPixels(
            pixelArray,
            0,
            resizedBitmap.width,
            0,
            0,
            resizedBitmap.width,
            resizedBitmap.height
        )

        // Recycle the original bitmap if needed
        if (originalBitmap != resizedBitmap) {
            originalBitmap.recycle()
        }

        return pixelArray
    }

    suspend fun printTest(result: (Exception?) -> Unit) = withContext(Dispatchers.IO) {
        try {
            if (printer == null) {
                throw Exception("Printer not connected")
            }
            printer?.apply {
                reset()
                printSelfTest()
                this.flush()
            }
        } catch (e: Exception) {
            result.invoke(e)
        }
    }

    fun getBluetoothList(): List<String> = bluetoothAdapter?.bondedDevices?.map {
        "${it.name}#${it.address}".trim()
    } ?: mutableListOf()


    @Throws(IOException::class)
    fun closeConnection() {
        try {
            bluetoothSocket?.close()
            printer?.release()
            protocolAdapter?.release()
            bluetoothSocket = null
            printer = null
            protocolAdapter = null
        } catch (e: Exception) {
            throw e
        }
    }
}