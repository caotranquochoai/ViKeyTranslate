package com.vivucloud.viKeytranslation

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vivucloud.viKeytranslation/clipboard"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "copyToClipboard") {
                val text = call.argument<String>("text")
                if (text != null) {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val clip = ClipData.newPlainText("ViKeyTranslate Copied Text", text)
                    clipboard.setPrimaryClip(clip)
                    result.success(true)
                } else {
                    result.error("INVALID_TEXT", "Text to copy is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
