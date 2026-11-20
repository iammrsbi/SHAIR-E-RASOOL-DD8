
package com.idrish.shairerasool.shair_e_rasool_dd8

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.idrish.shairerasool/audio"
    private val requestMicCode = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var audioEngine: AudioEngine? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "start" -> {
                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.RECORD_AUDIO
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        pendingResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            requestMicCode
                        )
                    } else {
                        startAudio(result)
                    }
                }

                "stop" -> {
                    audioEngine?.stop()
                    audioEngine = null
                    result.success(true)
                }

                "setDelay" -> {
                    val value = call.argument<Int>("milliseconds") ?: 300
                    audioEngine?.setDelay(value)
                    result.success(true)
                }

                "setFeedback" -> {
                    val value = call.argument<Double>("value") ?: 0.35
                    audioEngine?.setFeedback(value.toFloat())
                    result.success(true)
                }

                "setEffectLevel" -> {
                    val value = call.argument<Double>("value") ?: 0.5
                    audioEngine?.setEffectLevel(value.toFloat())
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startAudio(result: MethodChannel.Result) {
        try {
            val engine = AudioEngine()
            val success = engine.start()

            if (success) {
                audioEngine = engine
                result.success(true)
            } else {
                engine.stop()
                result.error("AUDIO_START_FAILED", "Audio engine could not start", null)
            }
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == requestMicCode) {
            val result = pendingResult
            pendingResult = null

            if (grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            ) {
                if (result != null) startAudio(result)
            } else {
                result?.error("MIC_PERMISSION_DENIED", "Microphone permission denied", null)
            }
        }
    }

    override fun onDestroy() {
        audioEngine?.stop()
        audioEngine = null
        super.onDestroy()
    }
}
