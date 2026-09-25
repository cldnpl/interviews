# Interviews

App iOS (SwiftUI, iOS 17+) per prepararsi ai colloqui tecnici mobile: Swift, UIKit, Kotlin e Flutter.

- Onboarding: scegli i tuoi percorsi (Swift, UIKit, Kotlin, Flutter — anche più d'uno, ognuno a sé) e il tuo livello (Junior, Mid, Senior)
- Oggi: quiz del giorno da 5 domande dosate sul tuo livello, streak, "Scegli un argomento"
- XP e gradi: Junior I → Staff; ogni risposta giusta vale 10/20/30 XP (piena solo la prima volta), salendo di grado si sbloccano gli stage successivi del percorso
- Percorso progressivo: in ogni linguaggio gli argomenti sono in ordine di studio e divisi in Junior, Mid e Senior — si parte dalle basi del linguaggio, mai da metà strada. Il quiz del giorno pesca solo dagli stage già raggiunti
- Ripasso: 40 lezioni brevi con codice e la risposta da dare al colloquio, nello stesso ordine del percorso
- Promemoria giornalieri solo nei giorni in cui il quiz non è ancora fatto

Contenuti in `Resources/it.lproj/<track>.json` (italiano, la struttura) e `Resources/en.lproj/<track>.json` (inglese, generato): 10 domande per argomento, 9 argomenti per Swift, UIKit e Kotlin e 13 per Flutter, già scritti nell'ordine del percorso. Ogni argomento dichiara il suo `stage` (`junior`, `mid`, `senior`): è quello a dividere le sezioni e a decidere cosa entra nel quiz del giorno.

```bash
./build.sh            # xcodegen + build + lancio sul simulatore
open Interviews.xcodeproj # oppure da Xcode
```

## Lingue

L'app parla inglese di default, anche su un iPhone in italiano; in Profilo › Language si passa
all'italiano e il cambio vale subito, lezioni e promemoria compresi. Le stringhe dell'interfaccia
stanno in `Resources/Localizable.xcstrings`. I contenuti inglesi si scrivono in
`translations/en/<track>/<topic>.json`, che contiene solo la prosa e il codice tradotti, e poi si
ricompongono:

```bash
python3 scripts/content_tools.py status   # quanti argomenti sono tradotti
python3 scripts/content_tools.py build    # rigenera Resources/en.lproj/*.json
```

Id, risposte giuste e difficoltà arrivano sempre dal file italiano: se modifichi una domanda,
aggiorna anche il suo frammento inglese.

## App Store

`APP_STORE.md` tiene la checklist della submission: che cosa il repo risolve già
(privacy manifest, icona senza alpha, export compliance, informativa e termini) e
che cosa resta da compilare su App Store Connect, testi della scheda compresi.

Privacy e termini sono scritti una volta sola in `Sources/Models/Legal.swift`:
l'app li mostra offline in Profilo › Informazioni, e `./scripts/make_legal_pages.sh`
ne ricava le pagine di `docs/` pubblicate su GitHub Pages, che sono gli indirizzi
richiesti da App Store Connect.
