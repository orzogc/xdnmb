package org.xnonymous.nmbxd

import android.os.Build
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
    }
}
