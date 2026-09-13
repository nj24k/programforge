# ProgramForge

The workout tracker for people who follow **named programs** — 5/3/1, GZCLP, and nSuns.
The app dictates every set, rep, and weight; you just lift and check off.

## Features (v1)

- **5/3/1** full 4-week cycles (5s week → 3s week → 5/3/1 PR week → deload)
- **GZCLP 4-Day** with phase-based progression schemes (T1/T2)
- **nSuns 4-Day** full T1/T2 set prescriptions
- Training-max management (90% of 1RM, Epley e1RM from AMRAP sets)
- Automatic plate math for every working weight
- Estimated 1RM progress charts per lift, streaks, lifetime set count
- Zero dependencies — pure SwiftUI + Swift Charts

## Cloud build

All compilation, testing, archiving, and signing happen on GitHub-hosted macOS
runners (`macos-26`, Xcode 26.x stable). See `.github/workflows/`.

- `xcode-build.yml` — generates project with XcodeGen, runs unit tests on simulator
- `testflight.yml` — archives, exports App Store IPA, uploads to TestFlight

Secrets required (set once per repo): `APPLE_TEAM_ID`,
`APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`,
`APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64`.
