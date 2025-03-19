package com.turtlepaw.fitness_challenges

import android.app.Application
import androidx.work.Configuration
import androidx.work.WorkManager

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        WorkManager.initialize(
            this,
            Configuration.Builder().build()
        )
    }
}