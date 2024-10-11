package com.uncaged.echogit_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.os.Build
import android.util.Log
import android.content.Intent
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.uncaged.echogit_mobile/termux"
    private val RESULT_ACTION = "com.uncaged.echogit_mobile.RESULT_ACTION"
    private var flutterResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "executeTermuxCommand") {
                val command = call.argument<String>("command")
                val workingDirectory = call.argument<String>("workingDirectory")
                val arguments = call.argument<String>("arguments")
                executeTermuxCommand(command, workingDirectory, arguments, result)
            } else {
                result.notImplemented()
            }
        }

        // Registering a receiver to capture the results from the service
        val receiverIntentFilter = IntentFilter(RESULT_ACTION)

        // Set the exported flag based on Android version
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {  // Android 13+
            registerReceiver(resultReceiver, receiverIntentFilter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(resultReceiver, receiverIntentFilter)
        }
    }

    private val resultReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent != null) {
                val stdout = intent.getStringExtra("stdout")
                val stderr = intent.getStringExtra("stderr")
                val exitCode = intent.getIntExtra("exitCode", -1)
                Log.d("MainActivity", "Received result: stdout=$stdout, stderr=$stderr, exitCode=$exitCode")

                // Create a result map to send back to Flutter
                val resultMap = HashMap<String, Any?>()
                resultMap["stdout"] = stdout
                resultMap["stderr"] = stderr
                resultMap["exitCode"] = exitCode

                // Pass the result back to Flutter
                flutterResult?.success(resultMap)
            }
        }
    }

    private fun executeTermuxCommand(command: String?, workingDirectory: String?, arguments: String?, result: MethodChannel.Result) {
        if (command != null && workingDirectory != null) {
            this.flutterResult = result

            val intent = Intent()
            intent.setClassName("com.termux", "com.termux.app.RunCommandService")
            intent.action = "com.termux.RUN_COMMAND"
            intent.putExtra("com.termux.RUN_COMMAND_PATH", command)
            val argumentsArray = arguments?.split(" ")?.toTypedArray() // Split by space
            intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", argumentsArray)
            intent.putExtra("com.termux.RUN_COMMAND_WORKDIR", workingDirectory)
            intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)

            // Creating the Intent for PluginResultsService to get the result
            val pluginResultsServiceIntent = Intent(this, PluginResultsService::class.java)
            val executionId = PluginResultsService.getNextExecutionId()

            // Add unique execution ID to PluginResultsService Intent
            pluginResultsServiceIntent.putExtra(PluginResultsService.EXTRA_EXECUTION_ID, executionId)

            // Creating the PendingIntent
            val pendingIntent = PendingIntent.getService(
                this,
                executionId,
                pluginResultsServiceIntent,
                PendingIntent.FLAG_ONE_SHOT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
            )
            intent.putExtra("com.termux.RUN_COMMAND_PENDING_INTENT", pendingIntent)

            try {
                Log.d("MainActivity", "Sending execution command with id $executionId")
                startService(intent)
            } catch (e: Exception) {
                Log.e("MainActivity", "Failed to start execution command with id $executionId: ${e.message}")
                result.error("EXECUTION_FAILED", "Failed to execute command", e.message)
            }
        } else {
            result.error("INVALID_ARGUMENT", "Command argument is null", null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(resultReceiver)
    }
}
