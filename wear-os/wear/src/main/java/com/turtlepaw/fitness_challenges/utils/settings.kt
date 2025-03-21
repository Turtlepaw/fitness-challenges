package com.turtlepaw.fitness_challenges.utils

import android.content.Context
import java.time.LocalTime

enum class Animals {
    CATS,
    BUNNIES
}

fun enumToJSON(enumList: List<Animals>): String {
    return enumList.joinToString(",")
}

// Function to retrieve enum list from SharedPreferences
fun enumFromJSON(data: String?): List<Animals> {
    return data?.split(",")?.mapNotNull { enumName ->
        try {
            Animals.valueOf(enumName)
        } catch (e: IllegalArgumentException) {
            null
        }
    } ?: emptyList()
}

enum class Settings(private val key: String, private val default: Any?) {
    LAST_SYNC("last_sync", null);

    fun getKey(): String {
        return key
    }

    fun getDefault(): String {
        return when (default) {
            is String -> {
                default
            }

            else -> {
                default.toString()
            }
        }
    }

    fun getDefaultAsBoolean(): Boolean {
        return when (default) {
            is Boolean -> {
                default
            }

            else -> {
                false
            }
        }
    }

    fun getDefaultAsLocalTime(): LocalTime {
        return when (default) {
            is LocalTime -> {
                default
            }

            is String -> {
                LocalTime.parse(default)
            }

            else -> {
                LocalTime.of(10, 30)
            }
        }
    }

    fun getDefaultAsInt(): Int {
        return when (default) {
            is Int -> {
                default
            }

            is String -> {
                default.toInt()
            }

            else -> {
                0
            }
        }
    }

    fun getDefaultOrNull(): Any? {
        return when (default) {
            is String -> {
                default
            }

            else -> {
                null
            }
        }
    }
}

enum class SettingsBasics(private val key: String, private val mode: Int?) {
    HISTORY_STORAGE_BASE("bedtime_history", null),
    SHARED_PREFERENCES("SleepToolsSettings", Context.MODE_PRIVATE);

    fun getKey(): String {
        return key
    }

    fun getMode(): Int {
        return mode ?: Context.MODE_PRIVATE
    }
}