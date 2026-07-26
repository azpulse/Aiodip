# DJ Aiodip

Native Flutter app (iOS + Android) — mix, edit, and record sets.

**Brand:** black + phosphoric yellow `#D4FF00`

## What works now (dynamic, not static preview)

| Flow | Behavior |
|------|----------|
| Start free trial | Opens **App Store / Google Play** sheet → 7-day trial then **$16/mo** |
| I have a code | Enter quota code → pay **$3.20** via store |
| Create quota code | Track uses; at **4+** unlock **$3.20** store subscribe |
| Log in / Sign up | Supabase Auth when keys set |
| Account | Edit name/email + Save only (cancel in store settings) |
| Home → Upload | Real audio files → editor → mixer → record → save |

**Not a web app.** No Stripe / web checkout. Billing = native IAP only.  
`preview/` is design reference only.

## Supabase setup

1. Create a project at [supabase.com](https://supabase.com)
2. SQL Editor → run [`supabase/migrations/001_init.sql`](supabase/migrations/001_init.sql)
3. Auth → enable Email provider
4. Run the app with keys:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Without keys, the app still works with a **local persistent store** (SharedPreferences) so quota counts, profiles, and projects are saved on device.

## Run

```bash
cd c:\Users\Azizn\Downloads\dj-aiodip
C:\Users\Azizn\flutter-sdk\flutter\bin\flutter.bat pub get
C:\Users\Azizn\flutter-sdk\flutter\bin\flutter.bat run
```

## Pricing rules (code + DB)

- Full plan: **$16/mo** with **7-day free trial** (store trial / `trialing` status)
- Invitee with valid code: **$3.20** immediately
- Inviter: stays **$16** until **4** paid redemptions of their code → then **$3.20** subscribe unlocks on Create code page
- Account screen does **not** manage billing (store handles cancel)

## Store billing (required for real payments)

Code already opens the native purchase sheet (`lib/services/billing_service.dart`).

### Google Play (Android)
1. Play Console → create app → **Subscriptions**
2. Product ID: `dj_aiodip_pro_monthly` — \$16/mo + **7-day free trial**
3. Product ID: `dj_aiodip_pro_quota_monthly` — \$3.20/mo (quota price)
4. License testers for testing; install from Play (internal testing track)

### App Store (iPhone)
1. App Store Connect → **Subscriptions**
2. Same product IDs as above
3. Add **1 week free trial** introductory offer on `dj_aiodip_pro_monthly`
4. Sandbox Apple ID for testing on device

Cancel / manage subscription: user does this in **Play Store** or **App Store** settings (not in Account).

## Project layout

```
lib/
  main.dart
  core/           theme, constants, supabase config
  models/         profile, quota, project
  services/       app_state, local_store, billing
  features/       gate, quota, home, account, upload, editor, mixer
supabase/migrations/001_init.sql
preview/          UI mock only
```
