package com.example.dreamlight

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import ai.asleep.asleepsdk.Asleep
import ai.asleep.asleepsdk.data.AsleepConfig
import android.content.Intent
import com.example.dreamlight.R // R 파일을 명시적으로 import

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.dreamlight/asleep"
    private val TAG = "AsleepSDK"

    private var createdUserId: String? = null
    private var createdAsleepConfig: AsleepConfig? = null
    private var createdSessionId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initAsleep" -> {
                        val apiKey = call.argument<String>("apiKey") ?: "0MlUUm49iPbsko2ovZ8tRmc9IRFP4lbuJIEu2RIt"
                        val existingUserId = call.argument<String>("userId")

                        Asleep.initAsleepConfig(
                            context = applicationContext,
                            apiKey = apiKey,
                            userId = existingUserId,
                            baseUrl = null,
                            callbackUrl = null,
                            //service = "DreamLight",
                            asleepConfigListener = object : Asleep.AsleepConfigListener {

                                override fun onSuccess(
                                    userId: String?,
                                    asleepConfig: AsleepConfig? // import된 클래스 이름을 그대로 사용
                                ) {
                                    Log.d(TAG, "✅ initAsleepConfig onSuccess: $userId, $asleepConfig")

                                    createdUserId = userId
                                    createdAsleepConfig = asleepConfig

                                    result.success(
                                        mapOf(
                                            "success" to true,
                                            "userId" to userId
                                        )
                                    )
                                }

                                override fun onFail(errorCode: Int, detail: String) {
                                    Log.e(TAG, "❌ initAsleepConfig onFail: $errorCode / $detail")
                                    result.error("INIT_FAILED", detail, errorCode)
                                }
                            },
                            asleepLogger = null
                        )
                    }

                    "beginTracking" -> {
                        val config = createdAsleepConfig
                        if (config != null) {
                            // 1. AsleepConfig 객체 자체를 전달하는 대신, 필수 속성을 Intent에 담습니다.
                            val serviceIntent = Intent(this, AsleepTrackingService::class.java).apply {
                                // Service에서 config 객체를 재구성하는 데 필요한 필수 값들을 전달합니다.
                                putExtra("API_KEY", config.apiKey)
                                putExtra("USER_ID", config.userId)
                                putExtra("SERVICE_NAME", config.service) // 'DreamLight'
                                // 필요하다면 baseUrl 및 callbackUrl도 전달
                                putExtra("BASE_URL", config.baseUrl)
                                putExtra("CALLBACK_URL", config.callbackUrl)
                                putExtra("NOTIFICATION_ICON_ID", R.mipmap.ic_launcher)
                            }

                            // Android 10 (Q) 이상에서는 startForegroundService를 사용해야 합니다.
                            startForegroundService(serviceIntent)

                            Log.d(TAG, "🟢 Service 호출 완료: AsleepTrackingService 시작됨")
                            result.success("ServiceStarted")

                        } else {
                            // config가 null인 경우
                            Log.e(TAG, "❌ Config is null. Call initAsleep first.")
                            result.error("CONFIG_NULL", "Config not initialized.", null)
                        }
                    }

                    "endTracking" -> {
                        val sessionIdToEnd = call.argument<String>("sessionId")
                        // SDK 문서상 endSleepTracking()은 파라미터 없이 바로 호출하면 됨
                        // https://docs-en.asleep.ai/docs/android-begin-end-sleep-tracking
                        try {
                            Asleep.endSleepTracking()
                            Log.d(TAG, "🔴 endSleepTracking 호출 완료")
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ endSleepTracking 호출 실패: ${e.message}", e)
                            result.error("END_FAILED", e.message, null)
                        }
                    }

                    "testSDK" -> {
                        Log.d(TAG, "SDK loaded successfully!")
                        result.success("SDK OK")
                    }

                    else -> result.notImplemented()
                }
            }
    }
}