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

            val intent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pi = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widgetRoot, pi)
            }

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
