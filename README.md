# Interviews

App iOS (SwiftUI, iOS 17+) per prepararsi ai colloqui tecnici mobile: Swift, UIKit, Kotlin e Flutter.

- Onboarding: scegli che sviluppatore sei (iOS, Android, Flutter, anche più d'uno) e il tuo livello (Junior, Mid, Senior)
- Oggi: quiz del giorno da 5 domande dosate sul tuo livello, streak, "Scegli un argomento"
- XP e gradi: Junior I → Staff; ogni risposta giusta vale 10/20/30 XP (piena solo la prima volta), salendo di grado le domande si fanno più difficili
- Ripasso: 32 lezioni brevi con codice e la risposta da dare al colloquio
- Promemoria giornalieri solo nei giorni in cui il quiz non è ancora fatto

Contenuti in `Resources/Content/<track>.json` (8 argomenti × 10 domande per linguaggio).

```bash
./build.sh            # xcodegen + build + lancio sul simulatore
open Interviews.xcodeproj # oppure da Xcode
```
