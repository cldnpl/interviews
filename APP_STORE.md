# Submission su App Store

Tutto ciò che riguarda la review sta qui. Quello che il repo risolve da solo è
spuntato; quello che resta va fatto a mano su App Store Connect.

## Fatto nel repo

- [x] **Privacy manifest** — `Resources/PrivacyInfo.xcprivacy`. Dichiara zero tracciamento,
      zero raccolta dati e l'unica API a motivazione obbligatoria che l'app usa
      (`UserDefaults`, motivo `CA92.1`). Senza questo file Apple risponde all'upload con
      l'email **ITMS-91053 — Missing API declaration**.
- [x] **Icona senza canale alpha** — `Resources/Assets.xcassets/AppIcon.appiconset/icon.png`
      è ora RGB puro. Con l'alpha l'upload viene respinto con **ITMS-90717**.
      Anche `scripts/make_icon.swift` la rigenera senza alpha.
- [x] **Export compliance** — `ITSAppUsesNonExemptEncryption = NO` nell'Info.plist
      (via `project.yml`), così App Store Connect non chiede la dichiarazione a ogni build.
- [x] **Informativa sulla privacy** — testo in `Sources/Models/Legal.swift`, leggibile
      offline dentro l'app (Profilo › Informazioni) e pubblicata su `docs/privacy.html`.
- [x] **Termini d'uso / EULA** — stessi due posti. Contengono tutte le clausole minime
      che Apple pretende da un EULA personalizzato: Apple non è parte del contratto,
      ambito della licenza, assistenza a carico dello sviluppatore, garanzia e rimborso
      tramite Apple, reclami sul prodotto, proprietà intellettuale, conformità export,
      Apple terzo beneficiario.
- [x] **Disclaimer sui marchi** — nel piè di pagina del profilo e in fondo a ogni pagina
      del sito: l'app non è affiliata ad Apple, Google, JetBrains o Kotlin Foundation
      (Linea guida 5.2.5).
- [x] **Link in-app** — privacy, termini, EULA standard di Apple e contatto supporto
      in Profilo › Informazioni, più la riga di consenso in fondo all'onboarding.
- [x] **Pagine pubbliche** — `docs/` (index, privacy, terms, support), generate dagli
      stessi testi dell'app con `./scripts/make_legal_pages.sh`: la versione online e
      quella nell'app non possono divergere.
- [x] **Niente simbolo `applelogo`** — la licenza di SF Symbols non consente i marchi
      Apple dentro app di terzi.

## Da fare prima di premere "Submit"

### 1. Pubblicare le pagine

Su GitHub: **Settings › Pages › Source: Deploy from a branch › `main` / `/docs`**.
Dopo un paio di minuti devono rispondere:

- https://cldnpl.github.io/interviews/privacy.html
- https://cldnpl.github.io/interviews/terms.html
- https://cldnpl.github.io/interviews/support.html

Se cambi indirizzo, gli URL stanno in un punto solo: `Legal.siteURL` e le tre costanti
sotto, in `Sources/Models/Legal.swift`. Poi rilancia `./scripts/make_legal_pages.sh`.

### 2. Campi di App Store Connect

| Campo | Valore |
| --- | --- |
| Privacy Policy URL | `https://cldnpl.github.io/interviews/privacy.html` |
| Support URL | `https://cldnpl.github.io/interviews/support.html` |
| Marketing URL | `https://cldnpl.github.io/interviews/` (facoltativo) |
| License Agreement | Lascia l'EULA standard di Apple |
| Prezzo | Gratis, nessun acquisto in-app |
| Categoria primaria | Istruzione |
| Categoria secondaria | Consultazione |
| Lingua principale | Italiano |
| Copyright | `2026 Claudia Napolitano` |
| Content Rights | «Non contiene contenuti di terze parti» |
| Age Rating | 4+ — rispondi *Nessuno/Mai* a tutte le domande del questionario |

### 3. App Privacy (le "nutrition label")

Alla domanda «Do you or your third-party partners collect data from this app?»
rispondi **No**, e poi conferma. È coerente col privacy manifest e con l'informativa:
l'app non ha rete, non ha SDK di terze parti, non ha account.

### 4. Note per la review

Da incollare in *App Review Information › Notes*:

> L'app è interamente offline: non richiede account, login o connessione a Internet.
> Non c'è nulla da sbloccare e non servono credenziali demo.
> Tutti i contenuti (domande, spiegazioni, lezioni) sono originali e scritti da me.
> L'interfaccia e i contenuti sono in italiano.
> Le uniche notifiche sono promemoria locali, pianificati dal dispositivo dopo
> il consenso esplicito dell'utente: non esiste alcun server push.
> I progressi restano in `UserDefaults` sul dispositivo e si cancellano da
> Profilo › Azzera i progressi o disinstallando l'app.

Ricorda anche i tuoi recapiti in *App Review Information* (nome, email, telefono):
Apple li usa se ha bisogno di chiamarti durante la review.

### 5. Testi della scheda

**Nome** (max 30)

```
Interviews
```

**Sottotitolo** (max 30)

```
Preparati al colloquio mobile
```

**Parole chiave** (max 100 caratteri, separate da virgola, senza spazi)

```
colloquio,swift,uikit,kotlin,flutter,ios,android,quiz,programmazione,sviluppatore,studio,mobile
```

**Testo promozionale** (max 170)

```
Cinque domande al giorno per arrivare al colloquio senza sorprese. Swift, UIKit, Kotlin e Flutter, dal primo optional fino agli argomenti da senior.
```

**Descrizione**

```
Interviews è la palestra quotidiana per chi si prepara a un colloquio tecnico da
sviluppatore mobile. Cinque domande al giorno, due minuti, e un percorso che cresce
insieme a te.

QUATTRO PERCORSI, OGNUNO A SÉ
Swift, UIKit, Kotlin e Flutter. Attivane uno o tutti: ciascuno ha i suoi argomenti,
messi nell'ordine in cui conviene studiarli. Si parte dalle fondamenta del linguaggio,
mai da metà strada.

IL QUIZ DEL GIORNO
Cinque domande dosate sul tuo livello, pescate solo dagli argomenti che hai già
sbloccato. Rispondi, leggi la spiegazione, tieni viva la serie. Ogni giorno saltato
azzera lo streak: è quello che ti fa tornare.

XP E GRADI
Da Junior I fino a Staff. Ogni risposta giusta vale 10, 20 o 30 XP secondo la
difficoltà, e salendo di grado si aprono gli argomenti da mid e da senior.

RIPASSO CON LE RISPOSTE VERE
Lezioni brevi con codice commentato e, soprattutto, la risposta da dare davvero
a voce davanti a chi ti sta intervistando.

CORREZIONI CHE SPIEGANO
Quando sbagli non leggi solo qual era la risposta giusta: leggi perché la tua era
sbagliata. Gli errori restano da parte finché non li sistemi.

PROMEMORIA GIUSTI
Una notifica all'ora che scegli tu, e solo nei giorni in cui il quiz non è ancora
fatto. Mai una in più.

SENZA RETE, SENZA ACCOUNT
Interviews funziona in metropolitana come sul divano. Nessuna registrazione, nessuna
pubblicità, nessuna statistica raccolta: i tuoi progressi restano sul tuo iPhone.
```

**Novità di questa versione** (1.0)

```
Prima versione. Quattro percorsi — Swift, UIKit, Kotlin e Flutter — con quiz del
giorno, XP e gradi, lezioni di ripasso e promemoria.
```

### 6. Screenshot

I cinque mockup stanno in `UIAppStore/`. Erano 1260 × 2736 con canale alpha: nessuna
delle due cose passa l'upload, perché App Store Connect accetta solo le misure del suo
elenco e rifiuta i PNG con trasparenza. In `UIAppStore/appstore-6.9/` ci sono le copie
pronte da caricare: **1320 × 2868** (6.9", l'unica misura iPhone obbligatoria), RGB
senza alpha. Le altre misure Apple le ricava da sole.

L'ingrandimento è del 4,8% e le proporzioni coincidono quasi al millesimo, quindi non
si vede; se hai ancora il file di design, riesportare direttamente a 1320 × 2868 resta
più nitido.

**Da decidere: i mockup sono in inglese, l'app è solo in italiano.** La Linea guida
2.3.3 chiede screenshot che mostrino l'app in uso, e quell'interfaccia inglese l'app
non sa produrla: il revisore apre l'app e trova un'altra lingua. È il rischio di
rifiuto più concreto rimasto. Le strade sono due, e la prima è quella giusta:

1. Rifare i cinque mockup con i testi italiani dell'app (*Pronto per oggi?*,
   *Quiz del giorno*, *I tuoi errori*, *Il tuo percorso*) e pubblicare la scheda in
   italiano.
2. Localizzare davvero l'app in inglese e tenere la scheda in inglese — molto più lavoro,
   ma apre il mercato non italiano.

Pubblicare la scheda in inglese tenendo l'app in italiano è l'unica combinazione da
evitare: è esattamente quella che la 2.3.3 punisce.

### 7. Build

```bash
xcodegen generate
xcodebuild -project Interviews.xcodeproj -scheme Interviews \
  -configuration Release -archivePath build/Interviews.xcarchive archive
```

Poi *Distribute App › App Store Connect* da Xcode Organizer, oppure `xcrun altool`.
Alza `CURRENT_PROJECT_VERSION` in `project.yml` a ogni upload: un build number non
può essere riusato.

## Rischi residui, da sapere

- **Nome generico.** "Interviews" è una parola comune e potrebbe essere già in uso sullo
  Store. Se App Store Connect lo rifiuta serve un nome diverso (per esempio
  "Interviews — Colloqui Mobile"), da cambiare anche in `INFOPLIST_KEY_CFBundleDisplayName`.
- **Marchi tra le parole chiave.** "swift", "kotlin", "flutter" descrivono davvero i
  contenuti, ma capita che la review contesti i marchi altrui nei metadati
  (Linea guida 5.2.5). Se succede, toglili: il disclaimer in-app e la loro presenza
  nella descrizione restano legittimi.
- **Simbolo `swift` nell'interfaccia.** Il track Swift usa l'SF Symbol `swift`, che è il
  logo di Apple. È uso descrittivo e passa quasi sempre, ma se la review lo contesta
  basta sostituirlo in `Track.symbol` (`Sources/Models/Content.swift`).
- **Linea guida 4.2 — funzionalità minima.** Le app-quiz vengono guardate con
  attenzione. Qui i contenuti sono 400 domande originali con spiegazioni e 40
  lezioni di ripasso: se arriva la contestazione, rispondi citando i numeri.
- **Correttezza dei contenuti.** La review non li verifica, ma un utente sì:
  un errore in una domanda diventa una recensione a una stella.
