package com.example.frontend

import com.otpless.otplessflutter.OtplessFlutterPlugin
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity(){
    override fun onBackPressed() {
    val plugin = flutterEngine?.plugins?.get(OtplessFlutterPlugin::class.java)
    if (plugin is OtplessFlutterPlugin) {
      if (plugin.onBackPressed()) return
  }
  // handle other cases
  super.onBackPressed()
}

}
