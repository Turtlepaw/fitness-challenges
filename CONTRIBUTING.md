# Contributing to Fitness Challenges

We love your input! We want to make contributing to Fitness Challenges as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer (see below 👇)

### ⭐ Become a team member, maintainer, or contributer!

We're currently looking for people to help with developing this project. While developing features and fixing bugs is our top priority, we would love help with other aspects, such as marketing, documentation, etc.

If you'd like to apply/join, contact:

- @turtlepaw on Discord
- [@turtlepaw.github.io](https://bsky.app/profile/turtlepaw.github.io) on Bluesky
- [@turtlepaw:matrix.org](https://matrix.to/#/@turtlepaw:matrix.org) on Matrix

> *Note that this is an open-source project, which generates no revenue at the moment, therefore we cannot pay our team members, maintainers, or contributors.*

## Development Stack

- **Flutter** is used for the app's framework (basically what runs/renders the app)
- **PocketBase** is the app's backend (this stores and handles requests to view/modify data, e.g. create a user)

### What is Fitness Challenges?

Fitness Challenges is an app that allows users to create fitness-based challenges. It's primarily targeted to users shifting away from Fitbit's challenges feature.

### Navigating the codebase

- `/lib` – this is the heart of the app, where all the codebase is
  - `/components` – UI components to be reused throughout the app (e.g. modals, cards)
  - `/gen` – generated hardcoded constants of files in `/images`
  - `/routes` – where all the screens of each route are stored (e.g. home)
  - `/types` – this is where we store enums (e.g. collections) and classes
  - `/utils` – general utilities like our health data wrapper, Wear OS communications manager, etc.
- `/android` – native code like manifests (where we declare app label, permissions, etc.), `MainActivity`, fastlane, etc.
- `/android-old` – copy of `/android`, to be deleted
- `/docs` – where the code of our future website will be
- `/images` – where all the icons, branding images, etc. are
- `/ios` – native code for iOS, this has never been touched so all libs will need to be configured
- `/linux`, `/macos`, `/web`, `/windows` – unused, and will probably never be sent to production as the platforms lack health APIs
- `/wear-os` – where the Wear OS app lives (currently on pause)
- `/test` – where testing will once be in the far far future /s
- `/pb_hooks` – PocketBase API routes for special functions (e.g. checking a username)

### File naming

Pay attention to how we name our files. The correct casing is snake_casing, e.g. `my_awesome_file.dart` (which is what Dart recommends)

## Development Process

1. Fork the repo and create your branch from `main`
1. Initialize your environment
    <details>
    <summary>💡 Learn how</summary>

    If you'd like to develop Fitness Challenges, we recommend:

    - Android Studio
    - Android SDK/NDK
    - Java 20 or higher
    - Android emulator or physical device

    For Android Studio, you'll need to install the Flutter and Dart plugin.
    </details>
1. Make your changes
1. Update documentation as needed
1. Ensure your code follows our style guidelines
1. Create a pull request

### Code Style

We don't have a set code style currently, we just ask that you keep the code clean and readable.

## Pull Request Process

1. Update the README.md with details of changes, if required
2. Update documentation in `/docs` if applicable
3. We'll review and merge your PR as soon as possible
    - If you receive no activity within 1-2 days, you may mention (`@`) a maintainer.

### 💡 Need help? Don't understand something?

This documentation is heavily work-in-progress, if you don't understand something or need help, **feel free to open a issue or a discussion**.

### ©️ License

By contributing, you agree that your contributions will be licensed under the same license as the main project.
