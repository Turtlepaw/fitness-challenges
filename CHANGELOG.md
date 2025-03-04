# March Changelog

###### Yes, we've been developing this update for many months.

## Highlights

### 🔒 Privacy controls

You can now hide your username in private and community challenges.

### 🎨 Refreshed components

We've refreshed most components to use our new design.

## Other noteworthy features

### New data types

We've added 3 new data types (viewable in ⚙️ Settings) for bingo.

- 💧 Water
- 🔥 Calories
- 🏃 Distance

### More account controls in-app

> [!NOTE]
> Access this feature by going to ⚙️ Settings -> ✏️ [edit profile]

- 📨 Change password
- 🗑️ Delete Account

### More challenge controls

> [!NOTE]
> Access this feature by selecting a challenge -> More [three dots]

- 🕑 End challenge

### It's easier for us to debug issues

We can now obtain app logs, making it easier for us to troubleshoot issues. Download app logs by going to ⚙️ Settings -> More [three dots] -> 🪲 Debug Logs

> [!WARNING]
> App logs may contain sensitive information!

## Other small changes

- Improve accessibility by adding tooltips to more buttons

### Internal

We've really cleaned up a lot of code, and added the [`SharedLogger`](/lib/utils/sharedLogger.dart) which allows logs to be exported. As always, we've also fixed a bunch of bugs, and you'll notice several improvements throughout the app.

Animated emojis have also been added to [Turtlepaw/flutter_emoji_feedback](https://github.com/Turtlepaw/flutter_emoji_feedback), the code for our feedback widget.
