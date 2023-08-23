package com.dipa.bl_printer

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BlStateReceiver(
    private val status: (BluetoothState, BluetoothDevice?) -> Unit
) : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            BluetoothAdapter.ACTION_STATE_CHANGED->{
                when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)) {
                    BluetoothAdapter.STATE_ON -> {
                        status.invoke(BluetoothState.AVAILABLE, null)
                    }
                    BluetoothAdapter.STATE_OFF -> {
                        status.invoke(BluetoothState.DISABLE, null)
                    }
                }
            }
            BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED-> {
                when (intent.getIntExtra(BluetoothAdapter.EXTRA_CONNECTION_STATE, BluetoothAdapter.ERROR)) {
                    BluetoothAdapter.STATE_CONNECTED -> {
                        status.invoke(BluetoothState.CONNECTED, null)
                    }
                    BluetoothAdapter.STATE_CONNECTING->{
                        status.invoke(BluetoothState.CONNECTING, null)
                    }
                    BluetoothAdapter.STATE_DISCONNECTED->{
                        status.invoke(BluetoothState.DISCONNECTED, null)
                    }
                }
            }
            BluetoothDevice.ACTION_ACL_CONNECTED->{
                val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(
                        BluetoothDevice.EXTRA_DEVICE,
                        BluetoothDevice::class.java
                    )
                } else {
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }
                status(BluetoothState.CONNECTED, device)
            }
            BluetoothDevice.ACTION_ACL_DISCONNECTED->{
                status.invoke(BluetoothState.DISCONNECTED, null)
            }
        }
    }
}

enum class BluetoothState{
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    DISABLE,
    AVAILABLE,
}