# Fitness Challenges

#### Compete in challenges with friends and family.

### 📸 Preview Images

|                                                                  |                                                                  |                                                                  |                                                                  |
|------------------------------------------------------------------|------------------------------------------------------------------|------------------------------------------------------------------|------------------------------------------------------------------|
| <img src="./images/Screenshot_20240902_003413.png" width="200"/> | <img src="./images/Screenshot_20240902_003428.png" width="200"/> | <img src="./images/Screenshot_20240902_003443.png" width="200"/> | <img src="./images/Screenshot_20240902_003507.png" width="200"/> |
| Home                                                             | Step Challenge                                                   | Invite Users                                                     | Health connections and profile                                   |

## 🛠️ Developing

This app is built with [Flutter](https://flutter.dev/), if you don't have flutter setup, flutter has a guide on [how to install and setup flutter on your desktop](https://docs.flutter.dev/get-started/install).

#### ⌚ Wear OS

<img src="./images/Wear_Screenshot (with shell).png" width="200" alt="Wear OS Preview"/>

The app includes a native Wear OS companion app to sync health data (only steps currently, see [363538427](https://issuetracker.google.com/issues/363538427)) located in [`/wear-os`](./wear-os). In the future, users will be able to view challenges on Wear OS.

### 💻 Creating a pocketbase instance

See [Pocketbase's documentation](https://pocketbase.io/docs/) to learn how to setup pocketbase locally. All hooks are located in `/pb_hooks`, you will need to add them to your pocketbase instance for developing. [(learn more)](https://pocketbase.io/docs/js-overview/)
