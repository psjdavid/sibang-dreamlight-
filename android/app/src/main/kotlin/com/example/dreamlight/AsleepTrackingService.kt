package com.example.dreamlight

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import ai.asleep.asleepsdk.Asleep
import ai.asleep.asleepsdk.data.AsleepConfig
import com.example.dreamlight.R // 프로젝트의 기본 패키지에 맞게 변경
import com.example.dreamlight.MainActivity // MainActivity 클래스도 명시적으로 import

// AsleepConfig를 PreferenceHelper 등을 통해 가져오는 로직 필요
// 예시에서는 Intent에서 직접 받도록 구현합니다.

class AsleepTrackingService : Service() {
    private val TAG = "AsleepService"
    private val NOTIFICATION_CHANNEL_ID = "asleep_tracking_channel"
    private val NOTIFICATION_ID = 101 // 임의의 고유 ID

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "AsleepTrackingService 시작")

        // 1. Intent에서 속성들을 받습니다.
        val apiKey = intent?.getStringExtra("API_KEY")
        val userId = intent?.getStringExtra("USER_ID")
        val serviceName = intent?.getStringExtra("SERVICE_NAME")
        val baseUrl = intent?.getStringExtra("BASE_URL")
        val callbackUrl = intent?.getStringExtra("CALLBACK_URL")
        val notificationIconId = intent?.getIntExtra("NOTIFICATION_ICON_ID", 0)

        if (apiKey == null || userId == null || serviceName == null || notificationIconId == 0) { // 👈 아이콘 ID가 0이면 실패로 간주            Log.e(TAG, "❌ 필수 Config 값이 서비스로 전달되지 않음. 서비스 중지.")
            Log.e(TAG, "❌ 필수 Config 값 또는 아이콘 ID가 서비스로 전달되지 않음. 서비스 중지.")
            stopSelf()
            return START_NOT_STICKY
        }

        // 2. AsleepConfig 객체를 재구성합니다.
        val config = AsleepConfig(
            apiKey = apiKey,
            userId = userId,
            baseUrl = baseUrl,
            callbackUrl = callbackUrl,
            service = serviceName
        )

        startForeground(NOTIFICATION_ID, createNotification(notificationIconId!!)) // 👈 !! 추가

        // 3. 재구성된 config 객체로 beginSleepTracking 호출
        try {
            Log.d(TAG, "🔍 beginSleepTracking 호출 직전: Config 준비 완료") // 👈 이 로그를 추가
            Asleep.beginSleepTracking(
                asleepConfig = config, // ✅ 수정된 config 사용
                asleepTrackingListener = object : Asleep.AsleepTrackingListener {
                    override fun onStart(sessionId: String) {
                        Log.d(TAG, "🟢 [Service] 수면 추적 시작 성공: $sessionId")
                        // TODO: EventChannel을 통해 이 sessionId를 Flutter로 전달해야 합니다.
                    }

                    override fun onPerform(sequence: Int) { /* ... */ }

                    override fun onFinish(sessionId: String?) { /* ... */ }

                    override fun onFail(errorCode: Int, detail: String) {
                        Log.e(TAG, "❌ [Service] 추적 실패: $errorCode / $detail")
                        // TODO: EventChannel을 통해 Flutter에 실패를 전달해야 합니다.
                        stopSelf()
                    }
                },
                notificationTitle = "DreamLight 수면 측정",
                notificationText = "측정 중",
                notificationIcon = notificationIconId,
                notificationClass = MainActivity::class.java
            )
        } catch (e: Exception) {
            Log.e(TAG, "❌ beginSleepTracking 예외 발생: ${e.message}", e)
            stopSelf()
        }

        return START_STICKY
    }

    private fun createNotification(iconId: Int): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "수면 측정 서비스",
                NotificationManager.IMPORTANCE_LOW // 백그라운드 서비스는 보통 Low로 설정
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("DreamLight 수면 측정")
            .setContentText("측정 중")
            .setSmallIcon(iconId) // 👈 전달받은 유효한 아이콘 ID 사용
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "AsleepTrackingService 종료")
        super.onDestroy()
    }
}