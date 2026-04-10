package com.aeropush.utils

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Process

object ProcessPhoenix {

    /**
     * Restarts the application by launching the default launcher activity
     * and killing the current process.
     */
    fun triggerRebirth(context: Context) {
        val packageManager = context.packageManager
        val intent = packageManager.getLaunchIntentForPackage(context.packageName)

        if (intent != null) {
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            )

            context.startActivity(intent)

            // If the context is an Activity, finish it
            if (context is Activity) {
                context.finish()
            }

            // Kill the current process
            Runtime.getRuntime().exit(0)
        } else {
            // Fallback: just kill the process, the system will restart
            Process.killProcess(Process.myPid())
        }
    }
}
