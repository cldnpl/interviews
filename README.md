# Pronto

App iOS (SwiftUI, iOS 17+) per prepararsi ai colloqui tecnici mobile: Swift, UIKit, Kotlin e Flutter.

- Onboarding: scegli che sviluppatore sei (iOS, Android, Flutter, anche più d'uno)
- Oggi: quiz del giorno da 5 domande che mescola i tuoi linguaggi, streak, "Scegli un argomento"
- Ripasso: 32 lezioni brevi con codice e la risposta da dare al colloquio
- Promemoria giornalieri solo nei giorni in cui il quiz non è ancora fatto

Contenuti in `Resources/Content/<track>.json` (8 argomenti × 10 domande per linguaggio).

```bash
./build.sh            # xcodegen + build + lancio sul simulatore
open Pronto.xcodeproj # oppure da Xcode
```
