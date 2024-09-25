package com.turtlepaw.fitness_challenges.presentation.pages

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.itemsIndexed
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonColors
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.Card
import androidx.wear.compose.material.CardDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import androidx.wear.tooling.preview.devices.WearDevices
import com.google.android.horologist.annotations.ExperimentalHorologistApi
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
fun Challenge(
    challenge: ExpandedChallengeRecord,
    rankings: List<UserSteps>,
    onNavigateInfo: () -> Unit
) {
    Page {
        item {
            Button(
                onClick = onNavigateInfo,
                enabled = true,
                colors = ButtonDefaults.buttonColors(
                    backgroundColor = Color.Transparent,
                    contentColor = MaterialTheme.colors.onBackground,
                ),
                modifier = Modifier.fillMaxWidth() // Ensures button takes full width
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth(), // Ensures Row takes full width
                    horizontalArrangement = Arrangement.Center // Center both items in the Row
                ) {
                    Text(text = challenge.name)
                    Spacer(modifier = Modifier.width(5.dp)) // Space between text and icon
                    Icon(
                        imageVector = Icons.Rounded.ChevronRight,
                        contentDescription = "Chevron Right",
                        modifier = Modifier.size(25.dp) // Ensures icon size is always 25.dp
                    )
                }
            }
        }
        item {}
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
                    modifier = Modifier.fillMaxWidth()
                ) {
                    // Show ranking number
                    if (challenge.ended && index == 0)
                        Icon(
                            imageVector = Icons.Rounded.EmojiEvents,
                            contentDescription = "Trophy",
                            modifier = Modifier.padding(end = 8.dp)
                        )
                    else Text("${index + 1}.", modifier = Modifier.padding(end = 8.dp))

                    // Truncate username and limit its width
                    Text(
                        text = it.user.username.toString().truncate(10),
                        modifier = Modifier.weight(1f), // Take the available space
                        maxLines = 1, // Ensure it's a single line
                        overflow = TextOverflow.Ellipsis // Add ellipsis if too long
                    )

                    // Display steps aligned to the right
                    Text(
                        text = DecimalFormat("#,###").format(it.totalSteps),
                        modifier = Modifier.align(Alignment.CenterVertically)
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
    backgroundColor = 0xFF000000
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
        ){}
    }
}

fun String.truncate(maxLength: Int): String {
    return if (this.length > maxLength) {
        this.substring(0, maxLength).trimEnd() + "..." // Add ellipsis
    } else {
        this
    }
}
