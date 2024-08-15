package com.turtlepaw.fitness_challenges.presentation.pages

import android.Manifest
import android.content.Context
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.ExperimentalWearFoundationApi
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.ListHeader
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.android.horologist.annotations.ExperimentalHorologistApi
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
            Text(
                if (lastSync != null) "Last synced ${lastSync.format(DateTimeFormatter.ofPattern("EEEE h:mm a"))}"
                else "Never synced",
                textAlign = TextAlign.Center,
            )
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
                    Text("Sync")
                },
                colors = ChipDefaults.chipColors(
                    backgroundColor = MaterialTheme.colors.surface
                ),
                contentPadding = PaddingValues(horizontal = 50.dp)            )
        }
    }
}