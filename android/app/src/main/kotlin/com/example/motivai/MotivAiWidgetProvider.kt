package com.example.motivai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MotivAiWidgetProvider : AppWidgetProvider() {
    companion object {
        const val ACTION_REFRESH = "com.example.motivai.WIDGET_REFRESH"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val greeting = prefs.getString("greeting", "MotivAI") ?: "MotivAI"
        val nextTask = prefs.getString(
            "nextTask",
            "Bugun sizni nima ruhlantiradi?"
        ) ?: "Bugun sizni nima ruhlantiradi?"
        val streak = prefs.getInt("streak", 0)
        val tasksDone = prefs.getInt("tasksDone", 0)
        val tasksTotal = prefs.getInt("tasksTotal", 0)

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.motivai_widget)
            views.setTextViewText(R.id.widgetGreeting, greeting)
            views.setTextViewText(R.id.widgetTask, nextTask)
            views.setTextViewText(
                R.id.widgetStreak,
                "🔥 $streak"
            )
            views.setTextViewText(
                R.id.widgetProgress,
                "$tasksDone/$tasksTotal"
            )

            // Tap body -> launch app
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pi = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widgetRoot, pi)
            }

            // Tap refresh icon -> broadcast refresh
            val refreshIntent = Intent(context, MotivAiWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
            }
            val refreshPi = PendingIntent.getBroadcast(
                context,
                id,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widgetRefresh, refreshPi)

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, MotivAiWidgetProvider::class.java)
            )
            onUpdate(context, mgr, ids)
        }
    }
}
