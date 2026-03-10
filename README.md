# Chorin

A family chore-tracking app for iOS. Kids complete daily chores to earn allowance, and parents manage chores and savings goals. Household data syncs through Supabase in real time.

## Features

- **Parent** creates a household and gets a 6-character invite code
- **Child** joins by entering the code
- Daily chore checklist — check off chores to earn money
- Earnings tracked weekly with daily and per-chore breakdowns
- Savings goals with auto-save (% of each chore) and manual contributions
- Real-time sync between parent and child

---

## iOS App (`Chorin`)

Built with SwiftUI and Supabase Swift SDK. Requires Xcode on macOS.

### Setup

1. Clone the repo and open `Chorin.xcodeproj` in Xcode.

2. Let Xcode resolve Swift package dependencies. The project already references `supabase-swift`.

3. Create a local Supabase config file:
   ```bash
   cp Chorin/Config.local.xcconfig.example Chorin/Config.local.xcconfig
   ```

4. Fill in `Chorin/Config.local.xcconfig`:
   ```xcconfig
   SUPABASE_URL = https:/$()/your-project.supabase.co
   SUPABASE_ANON_KEY = your-anon-key
   ```

5. Build and run on Simulator or a device.

### Project Structure

```
Chorin/
├── App/         # App entry point and root navigation
├── Design/      # Theme and shared UI components
├── Features/    # Feature screens
├── Models/      # Codable app models
└── Services/    # App state, Supabase client, date helpers
```

### Credentials

The app reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from generated `Info.plist` values that come from `Chorin/Config.xcconfig`, with optional local overrides in `Chorin/Config.local.xcconfig`.

`Chorin/Config.local.xcconfig` is gitignored so each machine can use its own Supabase project without editing tracked source files.

---

## Database

The app expects a Supabase project with Auth, Postgres, and Realtime enabled. If you need to recreate the backend schema, use the schema and migration files from the Supabase project associated with this app.
