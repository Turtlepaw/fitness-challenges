/* While this template provides a good starting point for using Wear Compose, you can always
 * take a look at https://github.com/android/wear-os-samples/tree/main/ComposeStarter and
 * https://github.com/android/wear-os-samples/tree/main/ComposeAdvanced to find the most up to date
 * changes to the libraries and their usages.
 */

package com.turtlepaw.fitness_challenges.presentation

import android.content.Context
import android.content.SharedPreferences
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Error
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import androidx.compose.ui.tooling.preview.PreviewParameterProvider
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.navigation.NavHostController
import androidx.wear.compose.material.CircularProgressIndicator
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import androidx.wear.tooling.preview.devices.WearDevices
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.android.horologist.annotations.ExperimentalHorologistApi
import com.turtlepaw.fitness_challenges.presentation.components.Page
import com.turtlepaw.fitness_challenges.presentation.pages.Challenge
import com.turtlepaw.fitness_challenges.presentation.pages.ChallengeInfo
import com.turtlepaw.fitness_challenges.presentation.pages.Login
import com.turtlepaw.fitness_challenges.presentation.pages.UserSteps
import com.turtlepaw.fitness_challenges.presentation.pages.WearHome
import com.turtlepaw.fitness_challenges.presentation.pages.calculateUserRankings
import com.turtlepaw.fitness_challenges.presentation.theme.AppTheme
import com.turtlepaw.fitness_challenges.services.scheduleSyncWorker
import com.turtlepaw.fitness_challenges.utils.Settings
import com.turtlepaw.fitness_challenges.utils.SettingsBasics
import io.github.agrevster.pocketbaseKotlin.PocketbaseClient
import io.github.agrevster.pocketbaseKotlin.dsl.login
import io.github.agrevster.pocketbaseKotlin.dsl.query.ExpandRelations
import io.github.agrevster.pocketbaseKotlin.models.Record
import io.github.agrevster.pocketbaseKotlin.models.User
import io.github.agrevster.pocketbaseKotlin.stores.BaseAuthStore
import io.ktor.http.URLProtocol
import kotlinx.coroutines.delay
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import java.time.LocalDateTime


enum class Routes(private val route: String) {
    HOME("/home"),
    SIGN_IN("/sign-in"),
    CHALLENGE("/challenge"),
    CHALLENGE_INFO("/info/challenge");

    fun getRoute(query: String? = null): String {
        return if (query != null) {
            "$route/$query"
        } else route
    }
}

const val TOKEN_KEY = "token"

class AuthStore(var sharedPreferences: SharedPreferences) : BaseAuthStore(null) {
    init {
        this.token = sharedPreferences.getString(TOKEN_KEY, null)
    }

    override fun save(token: String?) {
        super.save(token)
        sharedPreferences.edit()
            .putString(TOKEN_KEY, token)
            .apply()
    }

    override fun clear() {
        super.clear()
        sharedPreferences.edit()
            .putString(TOKEN_KEY, null)
            .apply()
    }
}

const val REQUEST_SYNC_PATH = "/request-sync"

@Suppress("")
class MainActivity : ComponentActivity(), MessageClient.OnMessageReceivedListener,
    DataClient.OnDataChangedListener {
    private lateinit var pb: PocketbaseClient
    private var isLoggedIn = mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)

        Wearable.getMessageClient(this).addListener(this)
        Wearable.getDataClient(this).addListener(this)

        val sharedPreferences = getSharedPreferences(
            SettingsBasics.SHARED_PREFERENCES.getKey(),
            SettingsBasics.SHARED_PREFERENCES.getMode()
        )

        pb = PocketbaseClient({
            protocol = URLProtocol.HTTPS
            host = "fitnesschallenges.webredirect.org"
        }, store = AuthStore(sharedPreferences))

        setTheme(android.R.style.Theme_DeviceDefault)
        setContent {
            val navController = rememberSwipeDismissableNavController()

            LaunchedEffect(isLoggedIn.value) { // Trigger navigation when isLoggedIn changes
                if (isLoggedIn.value) {
                    delay(100)
                    navController.navigate(Routes.HOME.getRoute()) {
                        popUpTo(Routes.SIGN_IN.getRoute()) { inclusive = true }
                    }
                }
            }

            AppTheme {
                WearPages(
                    this,
                    pb,
                    sharedPreferences,
                    navController
                )
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Wearable.getMessageClient(this).addListener(this)
        Wearable.getDataClient(this).addListener(this)
    }

    override fun onPause() {
        super.onPause()
        Wearable.getMessageClient(this).removeListener(this)
        Wearable.getDataClient(this).removeListener(this)
    }

    override fun onMessageReceived(message: MessageEvent) {
        if (message.path == REQUEST_SYNC_PATH) {
            scheduleSyncWorker()
        }
    }

    override fun onDataChanged(data: DataEventBuffer) {
        for (event in data) {
            if (event.dataItem.uri.path == "/auth") {
                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                if (!dataMap.containsKey("token")) continue
                val receivedToken = dataMap.getString("token")

                pb.login(receivedToken)
                pb.authStore.save(receivedToken)
                isLoggedIn.value = true // Update state to trigger navigation
                Log.d(
                    "MainActivity",
                    "Received token: $receivedToken and logged in as ${pb.authStore}"
                )
            }
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

@Serializable
data class ChallengeRecord(
    val name: String,
    var users: List<String>,
    val ended: Boolean,
    val winner: String? = null,
    val type: Int,
    val data: JsonObject
) : Record()

@Serializable
data class ExpandedChallengeRecord(
    val name: String,
    val users: List<User>,
    val ended: Boolean,
    val winner: String? = null,
    val type: Int,
    val data: JsonObject
) : Record()

@Composable
fun WearPages(
    context: Context,
    pb: PocketbaseClient,
    sharedPreferences: SharedPreferences,
    navController: NavHostController
) {
    AppTheme {
        // Creates a navigation controller for our pages
        var lastSync by remember { mutableStateOf<LocalDateTime?>(null) }
        var lastWorkerRun by remember { mutableStateOf<LocalDateTime?>(null) }
        var challenges by remember { mutableStateOf<List<ChallengeRecord>>(emptyList()) }
        var error by remember { mutableStateOf<String?>(null) }
        val lifecycleOwner = androidx.lifecycle.compose.LocalLifecycleOwner.current
        val state by lifecycleOwner.lifecycle.currentStateFlow.collectAsState()
        LaunchedEffect(state, lastWorkerRun) {
            // Get last sync
            lastSync = try {
                LocalDateTime.parse(
                    sharedPreferences.getString(
                        Settings.LAST_SYNC.getKey(),
                        Settings.LAST_SYNC.getDefaultOrNull().toString()
                    )
                )
            } catch (error: Exception) {
                null
            }

            val connectivityState = isNetworkConnected(context)

            if (connectivityState == true) {
                val results = pb.records.getFullList<ChallengeRecord>(
                    "challenges",
                    500,
                    expandRelations = ExpandRelations("users")
                )

                challenges = results
            } else {
                error = "No internet connection"
            }
        }

        LaunchedEffect(state, pb.authStore.token) {
            Log.d("MainActivity", "Logged in as ${pb.authStore.token}")
            if (pb.authStore.token == null) {
                navController.navigate(Routes.SIGN_IN.getRoute()) {
                    // Clear the back stack
                    popUpTo(navController.graph.startDestinationId) { inclusive = true }
                }
            } else if (navController.currentDestination?.route == Routes.SIGN_IN.getRoute()) {
                navController.navigate(Routes.HOME.getRoute()) {
                    // Clear the back stack
                    popUpTo(navController.graph.startDestinationId) { inclusive = true }
                }
            }
        }

        SwipeDismissableNavHost(
            navController = navController,
            startDestination = Routes.HOME.getRoute()
        ) {
            composable(Routes.HOME.getRoute()) {
                if(error == null) {
                    WearHome(
                        context,
                        lastSync,
                        pb,
                        challenges,
                        onLogout = {
                            pb.authStore.clear()
                            navController.navigate(Routes.SIGN_IN.getRoute()) {
                                // Clear the back stack
                                popUpTo(navController.graph.startDestinationId) { inclusive = true }
                            }
                        },
                        onSelect = {
                            navController.navigate(Routes.CHALLENGE.getRoute(it))
                        }
                    ) {
                        lastWorkerRun = LocalDateTime.now()
                    }
                } else {
                    ErrorPage(error!!)
                }
            }
            composable(Routes.SIGN_IN.getRoute()) {
                Login(context)
            }
            composable(Routes.CHALLENGE.getRoute("{challengeId}")) {
                val challengeId = it.arguments?.getString("challengeId")
                val rawChallenge = challenges.find { it.id == challengeId }
                var challenge by remember { mutableStateOf<ExpandedChallengeRecord?>(null) }
                var rankings by remember { mutableStateOf<List<UserSteps>?>(null) }
                LaunchedEffect(Unit) {
                    if (rawChallenge != null) {
                        val expanded = expandChallengeRecord(
                            rawChallenge,
                            pb
                        )

                        Log.d("a", "${expanded}")
                        rankings = calculateUserRankings(expanded)
                        challenge = expanded
                    }
                }

                if (challenge == null || rankings == null) {
                    LoadingPage()
                } else if (rawChallenge == null) {
                    ErrorPage("Challenge not found")
                } else if (challenge?.type != 1) {
                    ErrorPage("Unsupported challenge type")
                } else {
                    Challenge(challenge!!, rankings!!){
                        navController.navigate(
                            Routes.CHALLENGE_INFO.getRoute(rawChallenge.id ?: challengeId)
                        )
                    }
                }
            }
            composable(Routes.CHALLENGE_INFO.getRoute("{challengeId}")) {
                val challengeId = it.arguments?.getString("challengeId")
                val challenge = challenges.find { it.id == challengeId }

                if (challenge == null) {
                    ErrorPage("Challenge not found")
                } else if (challenge?.type != 1) {
                    ErrorPage("Unsupported challenge type")
                } else {
                    ChallengeInfo(challenge)
                }
            }
        }
    }
}

class StringProvider : PreviewParameterProvider<String> {
    override val values: Sequence<String>
        get() = sequenceOf(
            "An unexpected error occurred.",
            "Please try again later.",
            "Network connection lost."
        )
}

@OptIn(ExperimentalHorologistApi::class)
@Composable
fun ErrorPage(message: String) {
    Page {
        item {
            Icon(
                imageVector = Icons.Rounded.Error,
                contentDescription = "Error Icon",
                tint = MaterialTheme.colors.error
            )
        }
        item {
            Text(message, textAlign = TextAlign.Center)
        }
    }
}

@Preview(
    device = WearDevices.SMALL_ROUND,
    showSystemUi = true,
    showBackground = true,
    backgroundColor = 0xFF000000,
)
@Composable
fun PreviewErrorPage(
    @PreviewParameter(StringProvider::class) message: String
) {
    AppTheme {
        ErrorPage(message)
    }
}

@OptIn(ExperimentalHorologistApi::class)
@Composable
fun LoadingPage() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}

suspend fun resolveRelationList(relations: List<String>, pb: PocketbaseClient): List<User> {
    return relations.map {
        pb.records.getOne<User>("users", it)
    }
}

suspend fun expandChallengeRecord(
    challengeRecord: ChallengeRecord,
    pb: PocketbaseClient
): ExpandedChallengeRecord {
    // Convert the list of user IDs to full User objects
    val usersList = resolveRelationList(challengeRecord.users, pb)

    // Return the new ExpandedChallengeRecord with the converted user list
    return ExpandedChallengeRecord(
        name = challengeRecord.name,
        users = usersList,
        ended = challengeRecord.ended,
        winner = challengeRecord.winner,
        type = challengeRecord.type,
        data = challengeRecord.data
    )
}
