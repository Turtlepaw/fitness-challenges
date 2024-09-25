package com.turtlepaw.fitness_challenges.presentation.pages

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.People
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.max
import androidx.wear.compose.foundation.lazy.itemsIndexed
import androidx.wear.compose.material.Card
import androidx.wear.compose.material.CardDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
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
fun ChallengeInfo(challenge: ChallengeRecord) {
    Page {
        item {
            Text(text = challenge.name, style = MaterialTheme.typography.title2)
        }
        item {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(
                    6.dp,
                    alignment = Alignment.CenterHorizontally
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(
                    imageVector = Icons.Rounded.People,
                    contentDescription = "People"
                )

                Text("${challenge.users.size} users")
            }
        }
        item {
            if (challenge.ended == true) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(
                        6.dp,
                        alignment = Alignment.CenterHorizontally
                    ),
                    modifier = Modifier.fillMaxWidth().padding(top = 8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Rounded.Check,
                        contentDescription = "Check"
                    )

                    Text("This challenge has ended", modifier = Modifier.widthIn(max = 120.dp), overflow = TextOverflow.Visible)
                }
            } else {
                //Text("This challenge has ended", textAlign = TextAlign.Center)
            }
        }
    }
}

@Preview(
    device = WearDevices.SMALL_ROUND,
    showSystemUi = true,
    showBackground = true,
    backgroundColor = 0xFF000000
)
@Composable
fun ChallengeInfoPreview() {
    val record = ChallengeRecord(
        name = "Test",
        users = listOf(
            "xxx"
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
        ChallengeInfo(
            record
        )
    }
}
