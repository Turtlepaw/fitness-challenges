package com.turtlepaw.fitness_challenges.presentation.pages

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.itemsIndexed
import androidx.wear.compose.material.Card
import androidx.wear.compose.material.CardDefaults
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import androidx.wear.compose.ui.tooling.preview.WearPreviewSmallRound
import androidx.wear.tooling.preview.devices.WearDevices
import com.google.android.horologist.annotations.ExperimentalHorologistApi
import com.turtlepaw.fitness_challenges.presentation.ChallengeRecord
import com.turtlepaw.fitness_challenges.presentation.ExpandedChallengeRecord
import com.turtlepaw.fitness_challenges.presentation.components.Page
import com.turtlepaw.fitness_challenges.presentation.theme.AppTheme
import io.github.agrevster.pocketbaseKotlin.models.User
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.text.DecimalFormat

@OptIn(ExperimentalHorologistApi::class)
@Composable
fun Challenge(challenge: ExpandedChallengeRecord, rankings: List<UserSteps>) {
    Page {
        item {
            Text(text = challenge.name)
        }
        itemsIndexed(
            rankings
        ) { index, it ->
            Card(
                onClick = {},
                enabled = false,
                backgroundPainter = CardDefaults.cardBackgroundPainter(
                    startBackgroundColor = MaterialTheme.colors.onSurfaceVariant.copy(alpha = 0.20f)
                        .compositeOver(MaterialTheme.colors.background)
                )
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth().heightIn(min = 20.dp)
                ) {
                    if (challenge.ended && index == 0) {
                        Icon(
                            imageVector = Icons.Rounded.EmojiEvents,
                            contentDescription = "Trophy"
                        )
                    } else {
                        Text("${index + 1}.")
                    }

                    Spacer(modifier = Modifier.width(8.dp))
                    Text(it.user.username.toString().truncate(7))

                    // Move the steps display to the end
                    Text(
                        text = DecimalFormat("#,###").format(it.totalSteps),
                        modifier = Modifier.weight(1f), // This ensures it takes remaining space
                        textAlign = TextAlign.End // Align the steps to the right
                    )
                }
            }
        }
        if (challenge.ended == true) {
            item {
                Text("This challenge has ended", textAlign = TextAlign.Center)
            }
        }
    }
}

data class UserSteps(
    val userId: String,
    val user: User,
    val totalSteps: Int
)

fun calculateUserRankings(challengeData: ExpandedChallengeRecord): List<UserSteps> {
    val userStepsList = mutableListOf<UserSteps>()

    // Extract the array of users and their entries
    val dataArray = challengeData.data["data"]?.jsonArray ?: return emptyList()

    // Loop through each user's data
    for (userData in dataArray) {
        val userObject = userData.jsonObject

        // Get userId
        val userId = userObject["userId"]?.jsonPrimitive?.content ?: continue

        // Get the associated User object from challenge.users
        val user = challengeData.users.find { it.id == userId } ?: continue

        // Sum up all the steps for this user from their entries
        val entriesArray = userObject["entries"]?.jsonArray ?: continue
        val totalSteps = entriesArray.sumOf { entry ->
            entry.jsonObject["value"]?.jsonPrimitive?.int ?: 0
        }

        // Add the user's total steps to the list
        userStepsList.add(UserSteps(userId = userId, user = user, totalSteps = totalSteps))
    }

    // Sort users by total steps in descending order (highest steps first)
    return userStepsList.sortedByDescending { it.totalSteps }
}

@Preview(
    device = WearDevices.SMALL_ROUND,
    showSystemUi = true,
    showBackground = true,
    backgroundColor = android.graphics.Color.BLACK.toLong()
)
@Composable
fun ChallengePreview() {
    val record = ExpandedChallengeRecord(
        name = "Test",
        users = listOf(
            User(
                userId = "xxx", // Ensure this is provided
                verified = true,
                username = "User with looooong name",
                email = "*",
                emailVisibility = false
            )
        ),
        ended = true,
        type = 1,
        data = JsonObject(
            mapOf(
                "data" to JsonArray(
                    listOf(
                        JsonObject(
                            mapOf(
                                "entries" to JsonArray(
                                    listOf(
                                        JsonObject(
                                            mapOf(
                                                "dateTime" to JsonPrimitive("2024-09-17T00:00:00.000"),
                                                "value" to JsonPrimitive(2758)
                                            )
                                        ),
                                        JsonObject(
                                            mapOf(
                                                "dateTime" to JsonPrimitive("2024-09-18T00:00:00.000"),
                                                "value" to JsonPrimitive(7757)
                                            )
                                        ),
                                        JsonObject(
                                            mapOf(
                                                "dateTime" to JsonPrimitive("2024-09-21T00:00:00.000"),
                                                "value" to JsonPrimitive(736)
                                            )
                                        )
                                    )
                                ),
                                "userId" to JsonPrimitive("xxx")
                            )
                        )
                    )
                )
            )
        )
    )

    AppTheme {
        Challenge(
            record,
            calculateUserRankings(record)
        )
    }
}

fun String.truncate(maxLength: Int): String {
    return if (this.length > maxLength) {
        this.substring(0, maxLength).trimEnd() + "..." // Add ellipsis
    } else {
        this
    }
}
