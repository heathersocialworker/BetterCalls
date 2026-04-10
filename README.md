# BetterCalls

A native iOS app that connects people to peer warmline mental health support services across the United States. BetterCalls provides a searchable, filterable directory of NAMI warmlines — making it easy to find and call the right support line when you need it most.

## Features

- **Warmline Directory** — Browse a comprehensive list of peer warmline contacts sourced from a cloud database, sorted alphabetically for quick access.
- **Search** — Instantly search contacts by name or state.
- **Advanced Filters** — Filter by state, Spanish language support, chat support, and text support to find the right match.
- **One-Tap Calling** — Call any warmline directly from the app with a single tap.
- **Contact Details** — View detailed information for each contact including state, phone number, and available support options.
- **Favorites** — Save frequently used contacts to a dedicated Favorites tab for quick access, synced to your account via Firestore.
- **User Authentication** — Sign up and sign in with email/password or Google Sign-In, with password reset support.
- **User Profile** — View account info, email verification status, and app version from the Profile tab.

## Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | SwiftUI |
| **Language** | Swift |
| **Backend** | Firebase (Firestore, Authentication) |
| **Auth Providers** | Email/Password, Google Sign-In |
| **IDE** | Xcode |
| **Min Target** | iOS 16+ |

## Architecture

```
BetterCalls/
├── BetterCallsApp.swift          # App entry point & Firebase configuration
├── ContentView.swift             # Main views (Contacts, Favorites, Profile, Info Dialog)
├── LoginView.swift               # Login & registration UI
├── AuthenticationManager.swift   # Firebase Auth + Favorites logic
├── GoogleService-Info.plist      # Firebase configuration
├── Info.plist                    # URL schemes for Google Sign-In
└── Assets.xcassets/              # App icons & accent color
```

### Key Components

| Component | Description |
|---|---|
| `ContentView` | Root view — shows `LoginView` when unauthenticated, or a `TabView` (Contacts / Favorites / Profile) when signed in. |
| `ContactsView` | Searchable, filterable list of warmline contacts with call, favorite, and info actions. |
| `FavoritesView` | Displays the user's favorited contacts for quick access. |
| `ProfileView` | Shows user account information, app version, and sign-out. |
| `LoginView` | Email/password and Google Sign-In authentication flow. |
| `AuthenticationManager` | Manages Firebase Auth state, sign-in/sign-up/sign-out, and Firestore-backed favorites. |
| `WarmlineService` | Fetches warmline contacts from the `nami_warmlines` Firestore collection. |

## Getting Started

### Prerequisites

- **Xcode 15+**
- **iOS 16+ device or simulator**
- A Firebase project with **Firestore** and **Authentication** enabled

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/heathersocialworker/BetterCalls.git
   cd BetterCalls
   ```

2. **Open in Xcode**
   ```bash
   open BetterCalls.xcodeproj
   ```

3. **Firebase configuration**
   - The project includes a `GoogleService-Info.plist`. Replace it with your own if connecting to a different Firebase project.
   - Ensure **Email/Password** and **Google** sign-in methods are enabled in the Firebase console under Authentication → Sign-in method.

4. **Add Firebase packages** (if not already resolved)
   - In Xcode: **File → Add Package Dependencies**
   - Add `https://github.com/firebase/firebase-ios-sdk`
   - Select: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseCore`
   - Add `https://github.com/google/GoogleSignIn-iOS`
   - Select: `GoogleSignIn`, `GoogleSignInSwift`

5. **Build & Run**
   - Select a simulator or connected device and press **⌘R**.

### Firestore Data Model

The app reads from the following Firestore collections:

**`nami_warmlines`** — each document represents a warmline contact:

| Field | Type | Description |
|---|---|---|
| `name` | `String` | Organization name |
| `phoneNumber` | `String` | Contact phone number |
| `description` | `String?` | Optional description |
| `state` | `String?` | US state abbreviation (e.g. `"CA"`) |
| `hasSpanishSupport` | `Bool?` | Offers Spanish language support |
| `hasChatSupport` | `Bool?` | Offers chat-based support |
| `hasTextSupport` | `Bool?` | Offers text-based support |

**`favorites`** — keyed by user UID:

| Field | Type | Description |
|---|---|---|
| `contacts` | `[String]` | Array of favorited contact document IDs |
| `userEmail` | `String` | User's email address |

## License

This project is proprietary. All rights reserved.
