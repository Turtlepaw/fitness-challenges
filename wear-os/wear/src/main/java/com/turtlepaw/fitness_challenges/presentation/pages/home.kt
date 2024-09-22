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
import androidx.wear.compose.foundation.lazy.items
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
import com.turtlepaw.fitness_challenges.presentation.ChallengeRecord
import com.turtlepaw.fitness_challenges.presentation.components.Page
import com.turtlepaw.fitness_challenges.services.scheduleSyncWorker
import io.github.agrevster.pocketbaseKotlin.PocketbaseClient
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
    pb: PocketbaseClient,
    challenges: List<ChallengeRecord>,
    onLogout: () -> Unit,
    onSelect: (id: String) -> Unit,
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
        items(challenges) {
            Chip(
                onClick = {
                    if(it.id != null){
                        onSelect(it.id!!)
                    }
                },
                label = {
                    Text(
                        it.name
                    )
                },
                colors = ChipDefaults.chipColors(
                    backgroundColor = MaterialTheme.colors.surface
                ),
                contentPadding = PaddingValues(horizontal = 50.dp),
                modifier = Modifier.fillMaxWidth()
            )
        }
        item {
            Chip(
                onClick = {
                    pb.authStore.clear()
                    onLogout()
                },
                label = {
                    Text(
                        "Logout"
                    )
                },
                colors = ChipDefaults.chipColors(
                    backgroundColor = MaterialTheme.colors.surface
                ),
                contentPadding = PaddingValues(horizontal = 50.dp)
            )
        }
    }
}