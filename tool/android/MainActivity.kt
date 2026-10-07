package cn.lightfuture.light_future_demo

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var tones: ToneGenerator? = null
    private val storageExecutor = Executors.newSingleThreadExecutor()
    @Volatile private var closed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferences = getSharedPreferences("lightfuture_training", Context.MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lightfuture/storage")
            .setMethodCallHandler { call, reply ->
                when (call.method) {
                    "read" -> storageExecutor.execute {
                        try {
                            val data = preferences.getString("training_v1", null)
                            runOnUiThread { if (!closed) reply.success(data) }
                        } catch (_: RuntimeException) {
                            runOnUiThread { if (!closed) reply.error("read_failed", "Local storage read failed", null) }
                        }
                    }
                    "write" -> {
                        val data = call.argument<String>("data")
                        if (data == null) {
                            reply.error("invalid_data", "Training data is missing", null)
                        } else {
                            storageExecutor.execute {
                                val saved = try { preferences.edit().putString("training_v1", data).commit() }
                                    catch (_: RuntimeException) { false }
                                runOnUiThread {
                                    if (!closed) {
                                        if (saved) reply.success(null)
                                        else reply.error("save_failed", "Local storage write failed", null)
                                    }
                                }
                            }
                        }
                    }
                    else -> reply.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lightfuture/feedback")
            .setMethodCallHandler { call, reply ->
                if (call.method != "play") {
                    reply.notImplemented()
                } else {
                    try {
                        if (tones == null) tones = ToneGenerator(AudioManager.STREAM_MUSIC, 45)
                        val correct = call.argument<Boolean>("correct") ?: true
                        tones?.startTone(if (correct) ToneGenerator.TONE_PROP_ACK else ToneGenerator.TONE_PROP_NACK, 100)
                    } catch (_: RuntimeException) {
                        // Sound availability never affects scoring or local records.
                    }
                    reply.success(null)
                }
            }
    }

    override fun onDestroy() {
        closed = true
        tones?.release()
        tones = null
        storageExecutor.shutdown()
        super.onDestroy()
    }
}
