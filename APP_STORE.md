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

Fatto: GitHub Pages pubblica `main` / `/docs`. Queste pagine rispondono:

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
| Lingua principale | English (U.S.), italiano come localizzazione |
| Copyright | `2026 Claudia Napolitano` |
| Content Rights | «Non contiene contenuti di terze parti» |
| Age Rating | 4+ — rispondi *Nessuno/Mai* a tutte le domande del questionario |

### 3. App Privacy (le "nutrition label")

Alla domanda «Do you or your third-party partners collect data from this app?»
rispondi **No**, e poi conferma. È coerente col privacy manifest e con l'informativa:
l'app non ha rete, non ha SDK di terze parti, non ha account.

### 4. Note per la review

Da incollare in *App Review Information › Notes*:

> The app works entirely offline: it needs no account, no login and no internet
> connection. There is nothing to unlock and no demo credentials are required.
> All content (questions, explanations, lessons) is original.
> The app is in English by default; Italian can be selected in Profile › Language.
> The only notifications are local reminders, scheduled on the device after the
> user's explicit consent: there is no push server.
> Progress is stored on the device (UserDefaults) and can be erased from
> Profile › Reset progress or by deleting the app.

Ricorda anche i tuoi recapiti in *App Review Information* (nome, email, telefono):
Apple li usa se ha bisogno di chiamarti durante la review.

### 5. Testi della scheda

La lingua principale è **English (U.S.)**, come l'app. L'italiano si aggiunge come
localizzazione (menu della lingua in alto a destra nella pagina della versione): chi ha
lo Store in italiano vede quei testi.

Niente "Android" o "Google Play" nei testi: la linea guida 2.3.10 vieta di citare altre
piattaforme mobili nei metadati. I nomi di linguaggi e framework (Swift, UIKit, Kotlin,
Flutter) descrivono i contenuti e si possono usare.

"Interviews" da solo è già preso sullo Store, da qui il nome più lungo. Sotto l'icona
resta "Interviews" (`INFOPLIST_KEY_CFBundleDisplayName`), che non deve essere unico.
Crea l'app a mano in *My Apps › + › New App* (Bundle ID `com.cldnpl.interviews`, lingua
principale English (U.S.), SKU `interviews`), poi carica da Xcode: l'upload la trova
tramite il Bundle ID.

#### English (U.S.) — lingua principale

**Name** (max 30)

```
Interviews: Mobile Dev Prep
```

**Subtitle** (max 30)

```
Ace your mobile tech interview
```

**Keywords** (max 100)

```
interview,swift,uikit,kotlin,flutter,ios,quiz,coding,developer,prep,senior,junior,mobile
```

**Promotional Text** (max 170)

```
Five questions a day to walk into your interview with no surprises. Swift, UIKit, Kotlin and Flutter, from your first optional all the way to senior topics.
```

**Description**

```
Interviews is the daily workout for anyone preparing for a mobile developer
technical interview. Five questions a day, two minutes, and a path that grows
with you.

FOUR TRACKS, EACH ON ITS OWN
Swift, UIKit, Kotlin and Flutter. Turn on one or all of them: each has its own
topics, in the order it makes sense to study them. You start from the
fundamentals of the language, never halfway through.

THE DAILY QUIZ
Five questions tuned to your level, drawn only from the topics you've already
unlocked. Answer, read the explanation, keep your streak alive.

XP AND RANKS
From Junior I all the way to Staff. Every correct answer is worth 10, 20 or 30
XP depending on difficulty, and as your rank goes up the mid and senior topics
open up.

REVIEW WITH REAL ANSWERS
Short lessons with annotated code and, above all, the answer to actually give
out loud to the person interviewing you.

CORRECTIONS THAT EXPLAIN
When you get one wrong you don't just see the right answer: you read why yours
was wrong. Your mistakes stay set aside until you fix them.

SMART REMINDERS
One notification at the time you choose, only on days you haven't done the
quiz yet. Never one more.

OFFLINE, NO ACCOUNT
Interviews works on the subway as well as on the couch. No sign-up, no ads, no
tracking: your progress stays on your iPhone.

Available in English and Italian.
```

**What's New** (1.0)

```
First release. Four tracks (Swift, UIKit, Kotlin and Flutter) with a daily quiz,
XP and ranks, review lessons and reminders. In English and Italian.
```

#### Italiano — localizzazione

**Nome** (max 30)

```
Interviews: Mobile Dev Prep
```

**Sottotitolo** (max 30)

```
Preparati al colloquio mobile
```

**Parole chiave** (max 100)

```
colloquio,swift,uikit,kotlin,flutter,ios,quiz,programmazione,sviluppatore,studio,mobile
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
sbloccato. Rispondi, leggi la spiegazione, tieni viva la serie.

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

Disponibile in inglese e in italiano: la lingua si cambia in Profilo.
```

**Novità di questa versione** (1.0)

```
Prima versione. Quattro percorsi (Swift, UIKit, Kotlin e Flutter) con quiz del
giorno, XP e gradi, lezioni di ripasso e promemoria. In inglese e in italiano.
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

I mockup sono in inglese, come l'app al primo avvio: combaciano con quello che il
revisore vede aprendola (linea guida 2.3.3). Per la localizzazione italiana puoi
riusare gli stessi screenshot, oppure rifarli dopo aver scelto Italiano in Profilo.

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
