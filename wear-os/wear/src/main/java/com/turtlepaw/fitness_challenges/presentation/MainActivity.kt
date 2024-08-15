/* While this template provides a good starting point for using Wear Compose, you can always
 * take a look at https://github.com/android/wear-os-samples/tree/main/ComposeStarter and
 * https://github.com/android/wear-os-samples/tree/main/ComposeAdvanced to find the most up to date
 * changes to the libraries and their usages.
 */

package com.turtlepaw.fitness_challenges.presentation

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.turtlepaw.fitness_challenges.presentation.pages.WearHome
import com.turtlepaw.fitness_challenges.presentation.theme.SleepTheme
import com.turtlepaw.fitness_challenges.services.scheduleSyncWorker
import com.turtlepaw.fitness_challenges.utils.Settings
import com.turtlepaw.fitness_challenges.utils.SettingsBasics
import java.time.LocalDateTime


enum class Routes(private val route: String) {
    HOME("/home"),
    SETTINGS("/settings"),
    FAVORITES("/favorites"),
    THEME_PICKER("/theme-picker");

    fun getRoute(query: String? = null): String {
        return if (query != null) {
            "$route/$query"
        } else route
    }
}

const val REQUEST_SYNC_PATH = "/request-sync"
class MainActivity : ComponentActivity(), MessageClient.OnMessageReceivedListener {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()

        super.onCreate(savedInstanceState)

        setTheme(android.R.style.Theme_DeviceDefault)
        setContent {
            SleepTheme {
                WearPages(
                    this
                )
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Wearable.getMessageClient(this).addListener(this)
    }

    override fun onPause() {
        super.onPause()
        Wearable.getMessageClient(this).removeListener(this)
    }

    override fun onMessageReceived(message: MessageEvent) {
        if (message.path == REQUEST_SYNC_PATH) {
            scheduleSyncWorker()
        }
    }
}

fun isNetworkConnected(context: Context): Boolean {
    val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    val network = connectivityManager.activeNetwork ?: return false
    val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
    return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
}


@Composable
fun WearPages(
    context: Context
) {
    SleepTheme {
        // Creates a navigation controller for our pages
        val navController = rememberSwipeDismissableNavController()
        var lastSync by remember { mutableStateOf<LocalDateTime?>(null) }
        var lastWorkerRun by remember { mutableStateOf<LocalDateTime?>(null) }
        val lifecycleOwner = androidx.lifecycle.compose.LocalLifecycleOwner.current
        val state by lifecycleOwner.lifecycle.currentStateFlow.collectAsState()
        val sharedPreferences = context.getSharedPreferences(
            SettingsBasics.SHARED_PREFERENCES.getKey(),
            SettingsBasics.SHARED_PREFERENCES.getMode()
        )
        LaunchedEffect(state, lastWorkerRun) {
            // Get last sync
            lastSync = try {
                LocalDateTime.parse(
                    sharedPreferences.getString(
                        Settings.LAST_SYNC.getKey(),
                        Settings.LAST_SYNC.getDefaultOrNull().toString()
                    )
                )
            } catch(error: Exception){
                null
            }
        }

        SwipeDismissableNavHost(
            navController = navController,
            startDestination = Routes.HOME.getRoute()
        ) {
            composable(Routes.HOME.getRoute()) {
                WearHome(
                    context,
                    lastSync
                ){
                    lastWorkerRun = LocalDateTime.now()
                }
            }
        }
    }
}