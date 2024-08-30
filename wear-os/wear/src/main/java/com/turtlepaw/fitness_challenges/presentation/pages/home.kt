package com.turtlepaw.fitness_challenges.presentation.pages

import android.Manifest
import android.content.Context
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Error
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
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
import com.google.android.horologist.annotations.ExperimentalHorologistApi
import com.turtlepaw.fitness_challenges.R
import com.turtlepaw.fitness_challenges.presentation.components.Page
import com.turtlepaw.fitness_challenges.services.scheduleSyncWorker
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@OptIn(
    ExperimentalHorologistApi::class, ExperimentalWearFoundationApi::class,
    ExperimentalFoundationApi::class, ExperimentalPermissionsApi::class
)
@Composable
fun WearHome(
    context: Context,
    lastSync: LocalDateTime?,
    onWorkerRun: () -> Unit
) {
    val permissions = rememberPermissionState(Manifest.permission.ACTIVITY_RECOGNITION) {
        context.scheduleSyncWorker()
        onWorkerRun()
    }

    Page {
        item {}
        item {
            Text("Fitness Challenges")
        }
        item {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if(!permissions.status.isGranted){
                    Icon(
                        imageVector = Icons.Rounded.Error,
                        contentDescription = stringResource(id = R.string.error_icon_description),
                        tint = MaterialTheme.colors.error
                    )
                    Spacer(modifier = Modifier.padding(horizontal = 5.dp))
                }
                Text(
                    context.getString(
                        if(!permissions.status.isGranted) R.string.permissions_not_granted
                    else if (lastSync != null) R.string.last_synced//"Last synced ${lastSync.format(DateTimeFormatter.ofPattern("EEEE h:mm a"))}"
                    else R.string.never_synced,
                        lastSync?.format(DateTimeFormatter.ofPattern("EEEE h:mm a"))
                    ),
                    textAlign = if(permissions.status.isGranted) TextAlign.Center else TextAlign.Start,
                    color = if(permissions.status.isGranted)
                        MaterialTheme.colors.onSurfaceVariant
                    else
                        MaterialTheme.colors.error
                )
            }
        }
        item {
            Spacer(modifier = Modifier.height(8.dp))
        }
        item {
            Chip(
                onClick = {
                    if(permissions.status.isGranted){
                        context.scheduleSyncWorker()
                        onWorkerRun()
                    } else {
                        permissions.launchPermissionRequest()
                    }
                },
                label = {
                    Text(
                        if(permissions.status.isGranted) "Sync" else "Grant"
                    )
                },
                colors = ChipDefaults.chipColors(
                    backgroundColor = MaterialTheme.colors.surface
                ),
                contentPadding = PaddingValues(horizontal = 50.dp)            )
        }
    }
}