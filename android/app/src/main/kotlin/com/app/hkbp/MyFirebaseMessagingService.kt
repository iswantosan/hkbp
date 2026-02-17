package com.app.hkbp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        // Handle background messages here
        // Flutter plugin akan handle ini juga, tapi kita bisa custom handling di sini
        
        if (remoteMessage.notification != null) {
            // Show notification
            showNotification(
                remoteMessage.notification?.title ?: "HKBP Pondok Kopi",
                remoteMessage.notification?.body ?: ""
            )
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Token refresh akan di-handle oleh Flutter plugin
        // Tapi kita bisa log di sini jika diperlukan
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "hkbp_notifications"
            val channelName = "HKBP Notifications"
            val channelDescription = "Notifications for HKBP Pondok Kopi"
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun showNotification(title: String, body: String) {
        val channelId = "hkbp_notifications"
        val notificationId = System.currentTimeMillis().toInt()
        
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Ganti dengan icon custom jika ada
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
        
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.notify(notificationId, notificationBuilder.build())
    }
}


