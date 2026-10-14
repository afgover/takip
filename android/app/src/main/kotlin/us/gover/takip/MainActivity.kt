package us.gover.takip

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Paylaş menüsünden gelen düz metni Dart tarafına taşır (P-031).
 *
 * Metin burada bekletilir ve Dart onu "takeSharedText" ile bir kez alır;
 * uygulama açıkken gelen paylaşım için Dart'a "sharedTextAvailable" denir.
 * Metin yalnız formu doldurur — hiçbir şey kendiliğinden gönderilmez.
 */
class MainActivity : FlutterActivity() {
    private var pending: Map<String, String>? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "takeSharedText") {
                    result.success(pending)
                    pending = null
                } else {
                    result.notImplemented()
                }
            }
        }
        pending = sharedText(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val shared = sharedText(intent) ?: return
        pending = shared
        channel?.invokeMethod("sharedTextAvailable", null)
    }

    private fun sharedText(intent: Intent?): Map<String, String>? {
        if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") return null
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { it.isNotBlank() } ?: return null
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)?.takeIf { it.isNotBlank() }
        return if (subject == null) mapOf("text" to text) else mapOf("text" to text, "subject" to subject)
    }

    private companion object {
        const val CHANNEL = "us.gover.takip/share"
    }
}
