# Metal Vault — Setup

A SwiftUI iOS app that tracks your gold and silver holdings against live spot prices.

## What it does
- Log each purchase — gold or silver — with date, weight (oz or grams), and total amount paid.
- Pulls live spot prices for both metals automatically (free, no API key — gold-api.com).
- Filter your purchase list to All / Gold / Silver.
- Shows total vault value, cost basis, and overall gain/loss vs. spot (combining metals correctly when filtered to "All").
- Shows gain/loss for each individual purchase, so you can see which lots are winners vs. losers.
- Tap any purchase to edit it, or swipe to delete.
- Pull-to-refresh or tap the refresh icon to get the latest prices.
- Data is saved locally on your device (JSON file in the app's Documents folder) — no account, no cloud.
- Export your whole vault to a JSON file (the "•••" menu, top right) — share it, AirDrop it, or save it to Files/iCloud Drive as a backup.
- Import that file back in later (same menu) — choose **Merge** to add/update on top of what's already there, or **Replace All** to wipe the vault and load the file fresh. Handy after reinstalling the app or moving to a new device, so you don't have to retype every purchase.

## Setup

1. Double-click `MetalVault.xcodeproj` to open it in Xcode (project file is already set up — no need to create a new project or drag files in).
2. Pick a simulator or your device, then Build & run (⌘R).

That's it — no Info.plist changes or extra permissions needed (the price API is plain HTTPS).

## Files
- `MetalVaultApp.swift` — app entry point
- `Models/GoldLot.swift` — a single purchase + its math (cost, current value, gain/loss)
- `Models/Metal.swift` — gold vs. silver
- `Models/WeightUnit.swift` — oz ⟷ gram conversion
- `Services/GoldPriceService.swift` — fetches live spot prices (XAU + XAG) from gold-api.com
- `Services/VaultStore.swift` — saves/loads your purchases to a local JSON file
- `Utilities/Formatters.swift` — currency/weight/percent formatting
- `Utilities/VaultTransfer.swift` — JSON export/import (file document + merge/replace logic)
- `Views/ContentView.swift` — main screen, incl. the Gold/Silver/All filter
- `Views/SummaryCardView.swift` — total vault value card
- `Views/LotRowView.swift` — one row per purchase
- `Views/AddLotView.swift` — add/edit purchase form

## Notes / things you may want to tweak
- Spot prices are troy-ounce gold (XAU) and silver (XAG) in USD, sourced from `api.gold-api.com` — free, unlimited, no key required.
- If that API ever goes down, `GoldPriceService.swift` is the only file you'd need to point at a different provider.
- Currently single-currency (USD). If you want other currencies, that's a small change in `Formatters.swift` and the price service.
- Old data saved before silver support existed loads fine — those lots default to Gold automatically.
- Exported files carry each purchase's unique ID, so re-importing the same file twice (Merge mode) just updates in place instead of duplicating.
