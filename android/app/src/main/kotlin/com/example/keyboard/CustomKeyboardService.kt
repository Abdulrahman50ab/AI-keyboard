package com.example.keyboard

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.FrameLayout
import android.graphics.PixelFormat
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterTextureView
import android.util.Log
import android.speech.SpeechRecognizer
import android.speech.RecognitionListener
import android.content.Intent
import android.speech.RecognizerIntent
import android.os.Bundle
import java.util.Locale
import androidx.core.view.inputmethod.InputConnectionCompat
import androidx.core.view.inputmethod.InputContentInfoCompat
import androidx.core.view.inputmethod.EditorInfoCompat
import android.net.Uri
import android.content.ClipDescription
import java.io.File
import java.io.FileOutputStream
import java.net.URL
import java.util.concurrent.Executors
import androidx.core.content.FileProvider

class CustomKeyboardService : InputMethodService() {
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var methodChannel: MethodChannel? = null
    private var isFullScreenTouch = false
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false

    private val clipListener = android.content.ClipboardManager.OnPrimaryClipChangedListener {
        val clipboard = getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
        val clip = clipboard.primaryClip
        Log.d("VibeKey", "Native clipboard listener fired. Clip count: ${clip?.itemCount ?: 0}")
        if (clip != null && clip.itemCount > 0) {
            val text = clip.getItemAt(0).coerceToText(this)?.toString()
            if (text != null && text.isNotEmpty()) {
                Log.d("VibeKey", "Pushing clipboard update to Flutter: '$text'")
                methodChannel?.invokeMethod("onClipboardChanged", mapOf("text" to text))
            } else {
                Log.d("VibeKey", "Clipboard text was null or empty")
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("VibeKey", "Service onCreate")
        
        val clipboard = getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
        clipboard.addPrimaryClipChangedListener(clipListener)
        
        // Basic transparency setup
        window?.window?.setBackgroundDrawableResource(android.R.color.transparent)
        window?.window?.setFormat(PixelFormat.TRANSLUCENT)
        
        if (flutterEngine == null) {
            flutterEngine = FlutterEngine(this)
            flutterEngine?.navigationChannel?.setInitialRoute("/keyboard")
            flutterEngine?.dartExecutor?.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
        }
        
        methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "custom_keyboard/input")
        
        // Capture initial clipboard state once channel is ready
        val initialClip = clipboard.primaryClip
        if (initialClip != null && initialClip.itemCount > 0) {
            val text = initialClip.getItemAt(0).coerceToText(this)?.toString()
            if (text != null) {
                Log.d("VibeKey", "Initial clipboard captured: '$text'")
                // Delay slightly to ensure Flutter side handler is ready
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    methodChannel?.invokeMethod("onClipboardChanged", mapOf("text" to text))
                }, 500)
            }
        }
        
        initializeSpeechRecognizer()
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "insertText" -> {
                    val text = call.argument<String>("text")
                    currentInputConnection?.commitText(text, 1)
                    result.success(null)
                }
                "deleteText" -> {
                    val ic = currentInputConnection
                    if (ic != null) {
                        // Using sendKeyEvent is the most reliable way to simulate a backspace
                        // that respects text selections across all Android apps.
                        ic.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_DEL))
                        ic.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, android.view.KeyEvent.KEYCODE_DEL))
                    }
                    result.success(null)
                }
                "hideKeyboard" -> {
                    requestHideSelf(0)
                    result.success(null)
                }
                "getTextBeforeCursor" -> {
                    val length = call.argument<Int>("length") ?: 1000
                    val text = currentInputConnection?.getTextBeforeCursor(length, 0)
                    result.success(text?.toString() ?: "")
                }
                "replaceText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val deleteCount = call.argument<Int>("deleteCount") ?: 0
                    Log.d("VibeKey", "Replacing text. Deleting $deleteCount chars, inserting: '$text'")
                    
                    val ic = currentInputConnection
                    if (ic != null) {
                        ic.beginBatchEdit()
                        try {
                            // Precisely delete the number of characters we retrieved from native/flutter side
                            if (deleteCount > 0) {
                                ic.deleteSurroundingText(deleteCount, 0)
                            }
                            // Commit the new text
                            ic.commitText(text, 1)
                        } finally {
                            ic.endBatchEdit()
                        }
                    } else {
                        Log.e("VibeKey", "replaceText failed: currentInputConnection is null")
                    }
                    result.success(null)
                }
                "setFullScreenTouch" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    isFullScreenTouch = enabled
                    
                    // Force a reliable re-computation of insets across different Android versions
                    val window = window?.window
                    if (window != null) {
                        val decorView = window.decorView
                        decorView.post {
                            decorView.requestLayout()
                            decorView.requestApplyInsets()
                            // Also trigger the standard way to dispatch global layout
                            decorView.viewTreeObserver.dispatchOnGlobalLayout()
                        }
                    }
                    result.success(null)
                }
                "getNativeClipboard" -> {
                    val clipboard = getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                    val clip = clipboard.primaryClip
                    Log.d("VibeKey", "Manual clipboard fetch. Clip count: ${clip?.itemCount ?: 0}")
                    if (clip != null && clip.itemCount > 0) {
                        val text = clip.getItemAt(0).coerceToText(this)?.toString()
                        Log.d("VibeKey", "Manual fetch result: '${text?.take(20)}...'")
                        result.success(text)
                    } else {
                        result.success(null)
                    }
                }
                "performEnterAction" -> {
                    val actionStr = call.argument<String>("action") ?: "newline"
                    val actionId = when (actionStr) {
                         "search" -> EditorInfo.IME_ACTION_SEARCH
                         "go" -> EditorInfo.IME_ACTION_GO
                         "send" -> EditorInfo.IME_ACTION_SEND
                         "next" -> EditorInfo.IME_ACTION_NEXT
                         "done" -> EditorInfo.IME_ACTION_DONE
                         else -> EditorInfo.IME_ACTION_UNSPECIFIED
                    }
                    if (actionId != EditorInfo.IME_ACTION_UNSPECIFIED) {
                         currentInputConnection?.performEditorAction(actionId)
                    } else {
                         currentInputConnection?.commitText("\n", 1)
                    }
                    result.success(null)
                }
                "getSettings" -> {
                    // Try FlutterSharedPreferences first (standard for the plugin), 
                    // then fall back to default preferences if empty.
                    var prefs = getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
                    if (prefs.all.isEmpty()) {
                        prefs = getSharedPreferences("${packageName}_preferences", android.content.Context.MODE_PRIVATE)
                    }
                    
                    val settings = mutableMapOf<String, Any>()
                    settings["api_key"] = prefs.getString("flutter.api_key", "") ?: ""
                    settings["vibration_enabled"] = prefs.getBoolean("flutter.vibration_enabled", true)
                    
                    val all = prefs.all
                    val langKey = "flutter.selected_languages"
                    val defaultLangs = listOf("Urdu", "Arabic", "English", "French")
                    
                    if (all.containsKey(langKey)) {
                        val value = all[langKey]
                        if (value is Set<*>) {
                            settings["selected_languages"] = value.toList()
                        } else if (value is List<*>) {
                            settings["selected_languages"] = value
                        } else {
                            settings["selected_languages"] = defaultLangs
                        }
                    } else {
                        settings["selected_languages"] = defaultLangs
                    }
                    
                    Log.d("VibeKey", "Native getSettings Results: $settings")
                    result.success(settings)
                }
                "startVoiceInput" -> {
                    if (!isListening) {
                        try {
                            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                            }
                            speechRecognizer?.startListening(intent)
                            isListening = true
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e("VibeKey", "Voice input error: ${e.message}")
                            result.error("VOICE_ERROR", "Voice input not available", e.message)
                            isListening = false
                        }
                    } else {
                        result.success(null)
                    }
                }
                "stopVoiceInput" -> {
                    try {
                        speechRecognizer?.stopListening()
                        speechRecognizer?.cancel()
                        isListening = false
                        Log.d("VibeKey", "Voice input stopped and cancelled manually")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("VibeKey", "Error stopping voice input: ${e.message}")
                        result.success(null) // Silently fail
                    }
                }
                "commitContent" -> {
                    val url = call.argument<String>("url") ?: ""
                    val mimeType = call.argument<String>("mimeType") ?: "image/gif"
                    val label = call.argument<String>("label") ?: "Media"
                    
                    val ic = currentInputConnection
                    val info = currentInputEditorInfo
                    
                    if (ic != null && info != null && url.isNotEmpty()) {
                        val supportedMimeTypes = EditorInfoCompat.getContentMimeTypes(info)
                        // RELAXED CHECK: Even if not explicitly supported in the list, try to send it.
                        // Many apps (like WhatsApp) might not advertise GIF support in the standard way but accept it via commitContent.
                        // RELAXED CHECK: Always attempt to commit
                        val isSupported = true

                        if (isSupported) {
                            // Download or Copy in background thread
                            Executors.newSingleThreadExecutor().execute {
                                try {
                                    val imagesDir = File(cacheDir, "images")
                                    if (!imagesDir.exists()) imagesDir.mkdirs()
                                    
                                    val fileName = "share_${System.currentTimeMillis()}.${if (mimeType.contains("gif")) "gif" else "webp"}"
                                    val targetFile = File(imagesDir, fileName)
                                    
                                    // Check if 'url' is actually a local file path
                                    if (url.startsWith("/")) {
                                        val sourceFile = File(url)
                                        if (sourceFile.exists()) {
                                            Log.d("VibeKey", "Copying local file from: $url")
                                            sourceFile.inputStream().use { input ->
                                                FileOutputStream(targetFile).use { output ->
                                                    input.copyTo(output)
                                                }
                                            }
                                        } else {
                                             Log.e("VibeKey", "Source file does not exist: $url")
                                             throw Exception("Source file not found")
                                        }
                                    } else {
                                        Log.d("VibeKey", "Downloading file from: $url")
                                        URL(url).openStream().use { input ->
                                            FileOutputStream(targetFile).use { output ->
                                                input.copyTo(output)
                                            }
                                        }
                                    }

                                    Log.d("VibeKey", "File ready at: ${targetFile.absolutePath}")

                                    val contentUri = FileProvider.getUriForFile(this, "${packageName}.fileprovider", targetFile)
                                    val description = ClipDescription(label, arrayOf(mimeType))
                                    val inputContentInfo = InputContentInfoCompat(contentUri, description, null)
                                    
                                    var flags = InputConnectionCompat.INPUT_CONTENT_GRANT_READ_URI_PERMISSION

                                    val committed = InputConnectionCompat.commitContent(ic, info, inputContentInfo, flags, null)
                                    Log.d("VibeKey", "Media commit result for $contentUri: $committed")
                                    
                                    // Send result back to Flutter on main thread
                                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                                        result.success(committed)
                                    }
                                } catch (e: Exception) {
                                    Log.e("VibeKey", "Error downloading/committing media: ${e.message}")
                                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                                        result.success(false)
                                    }
                                }
                            }
                        } else {
                            Log.d("VibeKey", "Media type $mimeType not supported by target app")
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreateInputView(): View {
        val root = FrameLayout(this)
        root.setBackgroundColor(0) // Full transparent
        
        // Use MATCH_PARENT so Flutter can cover the whole screen if needed (for menus)
        root.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )

        // Using TextureView for the best transparency performance on modern Android
        val flutterTextureView = FlutterTextureView(this).apply {
            isOpaque = false
        }
        
        flutterView = FlutterView(this, flutterTextureView)
        flutterView?.attachToFlutterEngine(flutterEngine!!)
        
        root.addView(flutterView)
        return root
    }

    override fun onEvaluateFullscreenMode(): Boolean {
        return false
    }

    override fun onComputeInsets(outInsets: android.inputmethodservice.InputMethodService.Insets) {
        super.onComputeInsets(outInsets)
        val density = resources.displayMetrics.density
        // Use Math.round for better precision, then cast to Int for Insets
        // Increased to 295.0dp to create a larger transparent buffer that pushes app windows higher
        val keyboardHeightInPx = Math.round(295.0 * density).toInt()
        val screenHeight = window?.window?.decorView?.height ?: resources.displayMetrics.heightPixels
        
        Log.d("VibeKey", "Computing insets: density=$density, kbHeightPx=$keyboardHeightInPx, screenHeight=$screenHeight")

        // No extra space above keyboard
        outInsets.visibleTopInsets = screenHeight - keyboardHeightInPx
        outInsets.contentTopInsets = screenHeight - keyboardHeightInPx
        
        if (isFullScreenTouch) {
            // Capture touches on the ENTIRE screen (for menu barriers)
            outInsets.touchableInsets = android.inputmethodservice.InputMethodService.Insets.TOUCHABLE_INSETS_FRAME
        } else {
            // Capture touches only in the keyboard area (let app behind handle the rest)
            outInsets.touchableInsets = android.inputmethodservice.InputMethodService.Insets.TOUCHABLE_INSETS_CONTENT
        }
    }


    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        
        // Reset Flutter UI state on every start
        methodChannel?.invokeMethod("resetState", null)

        flutterEngine?.lifecycleChannel?.appIsResumed()
        
        // Log the raw IME options for debugging
        val imeOptions = info?.imeOptions ?: 0
        val actionId = imeOptions and EditorInfo.IME_MASK_ACTION
        
        android.util.Log.d("VibeKey", "StartInput: imeOptions=$imeOptions, actionId=$actionId")

        val actionLabel = when (actionId) {
            EditorInfo.IME_ACTION_SEARCH -> "search"
            EditorInfo.IME_ACTION_GO -> "go"
            EditorInfo.IME_ACTION_SEND -> "send"
            EditorInfo.IME_ACTION_NEXT -> "next"
            EditorInfo.IME_ACTION_DONE -> "done"
            else -> {
                // Some apps like Google Search might not set IME_ACTION_SEARCH explicitly
                // or might rely on just the Enter key.
                // We can check for specific flags if needed, but for now fallback to newline.
                if ((imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION) != 0) {
                     "newline"
                } else {
                     "newline"
                }
            }
        }
        
        android.util.Log.d("VibeKey", "Sending action to Flutter: $actionLabel")
        
        // Send to Flutter
        methodChannel?.invokeMethod("updateAction", mapOf("action" to actionLabel))
    }

    override fun onUpdateSelection(
        oldSelStart: Int, oldSelEnd: Int,
        newSelStart: Int, newSelEnd: Int,
        candidatesStart: Int, candidatesEnd: Int
    ) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        
        if (newSelStart != newSelEnd) {
            val selectedText = currentInputConnection?.getSelectedText(0)
            if (selectedText != null) {
                Log.d("VibeKey", "Selection updated: '$selectedText'")
                methodChannel?.invokeMethod("updateSelection", mapOf("text" to selectedText.toString()))
            }
        } else {
            methodChannel?.invokeMethod("updateSelection", mapOf("text" to ""))
        }
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        flutterEngine?.lifecycleChannel?.appIsPaused()
    }

    override fun onDestroy() {
        flutterView?.detachFromFlutterEngine()
        flutterEngine?.destroy()
        flutterEngine = null
        flutterView = null
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }
    
    private fun initializeSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                Log.d("VibeKey", "Ready for speech")
                methodChannel?.invokeMethod("onVoiceReady", null)
            }
            
            override fun onBeginningOfSpeech() {
                Log.d("VibeKey", "Speech started")
                methodChannel?.invokeMethod("onVoiceListening", null)
            }
            
            override fun onRmsChanged(rmsdB: Float) {}
            
            override fun onBufferReceived(buffer: ByteArray?) {}
            
            override fun onEndOfSpeech() {
                Log.d("VibeKey", "Speech ended")
                methodChannel?.invokeMethod("onVoiceProcessing", null)
                isListening = false
            }
            
            override fun onError(error: Int) {
                val errorMessage = when(error) {
                    SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
                    SpeechRecognizer.ERROR_NETWORK -> "Network error"
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                    SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                    SpeechRecognizer.ERROR_SERVER -> "Server error"
                    SpeechRecognizer.ERROR_CLIENT -> "Client error"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission required"
                    else -> "Voice input error"
                }
                Log.e("VibeKey", "Voice recognition error: $errorMessage (code: $error)")
                methodChannel?.invokeMethod("onVoiceError", mapOf("error" to errorMessage))
                isListening = false
            }
            
            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (matches != null && matches.isNotEmpty()) {
                    val text = matches[0]
                    Log.d("VibeKey", "Voice recognition result: $text")
                    currentInputConnection?.commitText(text + " ", 1)
                    methodChannel?.invokeMethod("onVoiceResult", mapOf("text" to text))
                }
                isListening = false
            }
            
            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (matches != null && matches.isNotEmpty()) {
                    val text = matches[0]
                    Log.d("VibeKey", "Voice partial result: $text")
                    methodChannel?.invokeMethod("onVoicePartialResult", mapOf("text" to text))
                }
            }
            
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
    }
}