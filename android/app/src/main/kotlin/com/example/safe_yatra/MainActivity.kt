package com.example.safe_yatra  // <- MUST match folder structure
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ble_utils"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "clearBluetoothCache") {
                val deviceId = call.argument<String>("deviceId")
                val adapter = BluetoothAdapter.getDefaultAdapter()
                val device: BluetoothDevice? = adapter.getRemoteDevice(deviceId)
                try {
                    val m = device?.javaClass?.getMethod("removeBond")
                    m?.invoke(device)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}