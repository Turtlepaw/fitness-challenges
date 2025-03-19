package com.turtlepaw.fitness_challenges.presentation.pages

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.SendToMobile
import androidx.compose.material.icons.rounded.Error
import androidx.compose.material.icons.rounded.SendToMobile
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.concurrent.futures.await
import androidx.wear.compose.foundation.ExperimentalWearFoundationApi
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.ListHeader
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.android.gms.wearable.Wearable
import com.google.android.horologist.annotations.ExperimentalHorologistApi
import com.turtlepaw.fitness_challenges.R
import com.turtlepaw.fitness_challenges.presentation.components.Page
import com.turtlepaw.fitness_challenges.services.scheduleSyncWorker
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import androidx.wear.remote.interactions.RemoteActivityHelper
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks.await
import com.turtlepaw.fitness_challenges.presentation.theme.AppTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.Executor
import java.util.concurrent.Executors

@OptIn(
    ExperimentalHorologistApi::class, ExperimentalWearFoundationApi::class,
    ExperimentalFoundationApi::class, ExperimentalPermissionsApi::class
)
@Composable
fun Login(context: Context) {
    Page {
        item {
            Text("Login", style = MaterialTheme.typography.title2)
        }
        item {
            Text(
                "View all your challenges on your wrist.",
                style = MaterialTheme.typography.body2,
                textAlign = TextAlign.Center
            )
        }
        item {}
        item {
            Button(
                onClick = {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            // Get connected nodes using Tasks.await()
                            val nodes = Wearable.getNodeClient(context).connectedNodes.await()
                            for (node in nodes) {
                                val remoteActivityHelper = RemoteActivityHelper(context)

                                // Get the companion package using Tasks.await()
                                val pkg = context.packageName

                                val intent = Intent().apply {
                                    action = Intent.ACTION_VIEW
                                    addCategory(Intent.CATEGORY_BROWSABLE)
                                    setData(
                                        Uri.parse("fitnesschallenges://fitnesschallenges")
                                    )
                                    setPackage(pkg)
                                }

                                //remoteActivityHelper.startRemoteActivity(intent, node.id).await()
                                // Optionally send a message after starting the activity
                                Wearable.getMessageClient(context).sendMessage(
                                    node.id,
                                    "/auth_request",
                                    ByteArray(0)
                                )
                            }
                        } catch (e: ActivityNotFoundException) {
                            Log.e("WearOS", "Companion app not found: ${e.message}")
                        } catch (e: Exception) {
                            Log.e("WearOS", "Error retrieving companion package: ${e.message}")
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Rounded.SendToMobile,
                        contentDescription = stringResource(id = R.string.error_icon_description),
                        tint = MaterialTheme.colors.onPrimary
                    )
                    Spacer(modifier = Modifier.padding(horizontal = 5.dp))
                    Text("Request login details")
                }
            }
        }
    }
}

@Preview(
    device = androidx.wear.tooling.preview.devices.WearDevices.SMALL_ROUND,
    showSystemUi = true
)
@Composable
fun LoginPreview(){
    AppTheme {
        Box(Modifier.fillMaxSize().background(MaterialTheme.colors.background)){
            Login(LocalContext.current)
        }
    }
}

suspend fun <T> Task<T>.await(): T {
    return await(this)
}