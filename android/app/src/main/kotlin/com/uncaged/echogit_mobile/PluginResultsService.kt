package com.uncaged.echogit_mobile

import android.app.IntentService
import android.content.Intent
import android.os.Bundle
import android.util.Log

class PluginResultsService : IntentService("PluginResultsService") {

    companion object {
        const val RESULT_ACTION = "com.uncaged.echogit_mobile.RESULT_ACTION"
        const val LOG_TAG = "PluginResultsService"
        const val EXTRA_EXECUTION_ID = "execution_id"
        var EXECUTION_ID = 1000

        @JvmStatic
        fun getNextExecutionId(): Int {
            return EXECUTION_ID++
        }
    }

    override fun onHandleIntent(intent: Intent?) {
        if (intent == null) return

        Log.d(LOG_TAG, "PluginResultsService received execution result")

        // Retrieve result bundle from intent
        val resultBundle: Bundle? = intent.getBundleExtra("result")

        val extras = intent.extras

        if (extras != null) {
            for (key in extras.keySet()) {
                val value = extras.get(key)
                Log.d("IntentDebug", "Key: $key Value: $value")
            }
        } else {
            Log.d("IntentDebug", "No extras in the intent")
        }

        if (resultBundle == null) {
            Log.e(LOG_TAG, "The intent does not contain the result bundle at the key com.termux.result")
            return
        }

        // Extract stdout, stderr, exitCode
        val stdout = resultBundle.getString("stdout", "")
        val stderr = resultBundle.getString("stderr", "")
        val exitCode = resultBundle.getInt("exitCode", -1)

        Log.d(LOG_TAG, "Execution result:\nstdout:\n$stdout\nstderr:\n$stderr\nexitCode: $exitCode")

        // Sending the result back to MainActivity using a broadcast
        val resultIntent = Intent(RESULT_ACTION)
        resultIntent.putExtra("stdout", stdout)
        resultIntent.putExtra("stderr", stderr)
        resultIntent.putExtra("exitCode", exitCode)

        sendBroadcast(resultIntent)
    }
}

