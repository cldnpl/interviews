// Genera le pagine pubbliche di GitHub Pages dagli stessi testi che l'app mostra.
// Compila insieme i file di Legal, così la versione online e quella dentro l'app
// non possono divergere. L'inglese sta alla radice, l'italiano in /it/.
//
// Uso: ./scripts/make_legal_pages.sh
import Foundation

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"

func esc(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}

/// Lo stesso markdown inline che l'app rende con `RichText`: **grassetto** e `codice`.
func inline(_ s: String) -> String {
    var out = esc(s)
    for (pattern, template) in [
        (#"\*\*(.+?)\*\*"#, "<strong>$1</strong>"),
        (#"`(.+?)`"#, "<code>$1</code>"),
        (#"(https?://[^\s<)]+)"#, #"<a href="$1">$1</a>"#),
        (#"([\w.+-]+@[\w-]+\.[\w.]+)"#, #"<a href="mailto:$1">$1</a>"#),
    ] {
        out = out.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
    }
    return out
}

let css = """
:root { color-scheme: light dark; --ink:#1c1b1a; --dim:#6b6764; --bg:#fff8f3; --card:#fff; --line:#eadfd6; --accent:#f05138; }
@media (prefers-color-scheme: dark) { :root { --ink:#f2efec; --dim:#a8a19c; --bg:#17161a; --card:#201e24; --line:#332f38; --accent:#ff8a6b; } }
* { box-sizing: border-box; }
body { margin:0; padding:0 20px 72px; background:var(--bg); color:var(--ink);
  font:16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; }
main { max-width: 42rem; margin: 0 auto; }
header { padding: 48px 0 28px; }
h1 { font-size: clamp(1.7rem, 5vw, 2.3rem); line-height:1.15; margin:0 0 6px; letter-spacing:-.02em; }
h2 { font-size:1.05rem; margin:34px 0 6px; color:var(--accent); letter-spacing:-.01em; }
p { margin:0 0 14px; color:var(--dim); }
h2 + p { margin-top:0; }
a { color:var(--accent); }
code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size:.9em;
  background: color-mix(in srgb, var(--ink) 8%, transparent); padding:1px 5px; border-radius:5px; }
.eff { color:var(--dim); font-size:.85rem; margin:0; }
nav { display:flex; flex-wrap:wrap; gap:10px; margin:28px 0 0; }
nav a { display:inline-block; padding:9px 15px; border:1px solid var(--line); border-radius:999px;
  background:var(--card); text-decoration:none; font-size:.9rem; font-weight:600; }
footer { margin-top:56px; padding-top:20px; border-top:1px solid var(--line); font-size:.8rem; color:var(--dim); }
.lead { font-size:1.05rem; }
ul { color:var(--dim); padding-left:1.2em; } li { margin-bottom:8px; }
"""

/// Le stringhe del sito che non vengono da `Legal`.
struct Site {
    let lang, home, privacy, terms, support, back, other, otherHref: String
    let tagline, whatItDoes, privacyLine, privacyLead, writeTo, faq: String
    let bullets: [String]
    let questions: [(String, String)]

    static let en = Site(
        lang: "en", home: "Interviews", privacy: "Privacy Policy", terms: "Terms of Use",
        support: "Support", back: "← Interviews", other: "Italiano", otherHref: "it/index.html",
        tagline: "Get ready for mobile tech interviews — Swift, UIKit, Kotlin and Flutter — with a five-question quiz a day, short lessons and a path that grows with your rank. An iPhone app, in English and Italian.",
        whatItDoes: "What it does",
        privacyLine: "Privacy in one line",
        privacyLead: "The app collects nothing: no account, no advertising, no analytics, no connection to the Internet. Your progress stays on your iPhone. The full text is in the",
        writeTo: "Writing to a person",
        faq: "Frequently asked",
        bullets: [
            "A daily quiz of five questions, tuned to your level, with a streak you won't want to break.",
            "Four independent tracks: Swift, UIKit, Kotlin, Flutter. Keep as many switched on as you like.",
            "XP and ranks from Junior I to Staff: as you climb, mid and senior topics unlock.",
            "Review lessons with code and the answer you would actually give out loud.",
            "A daily reminder, only on days the quiz isn't done yet.",
        ],
        questions: [
            ("I lost my streak.", "The streak counts consecutive days on which you completed the daily quiz; skip a day and it starts over. Your record stays in your Profile."),
            ("Reminders don't arrive.", "Check Settings › Notifications › Interviews, then the switch in Profile › Notifications. The notification stays quiet on days the quiz is already done: that's on purpose."),
            ("I want to start over.", "Profile › Reset progress clears the streak, stats, XP and mistakes, keeping the tracks you picked."),
            ("An answer looks wrong to me.", "Write to me quoting the question: content gets fixed and ships with the next update."),
            ("My data.", "I collect none, so I have nothing to hand over or delete. Deleting the app removes everything."),
        ])

    static let it = Site(
        lang: "it", home: "Interviews", privacy: "Informativa sulla privacy", terms: "Termini d'uso",
        support: "Supporto", back: "← Interviews", other: "English", otherHref: "../index.html",
        tagline: "Preparati ai colloqui tecnici mobile — Swift, UIKit, Kotlin e Flutter — con un quiz da cinque domande al giorno, lezioni brevi e un percorso che cresce col tuo grado. App per iPhone, in inglese e in italiano.",
        whatItDoes: "Che cosa fa",
        privacyLine: "Privacy in una riga",
        privacyLead: "L'app non raccoglie nulla: nessun account, nessuna pubblicità, nessuna statistica, nessun collegamento a Internet. I progressi restano sul tuo iPhone. La versione completa è nell'",
        writeTo: "Scrivere a una persona",
        faq: "Domande frequenti",
        bullets: [
            "Un quiz del giorno da cinque domande, dosate sul tuo livello, con streak da non spezzare.",
            "Quattro percorsi indipendenti: Swift, UIKit, Kotlin, Flutter. Ne puoi tenere accesi quanti vuoi.",
            "XP e gradi da Junior I a Staff: salendo si sbloccano gli argomenti da mid e da senior.",
            "Lezioni di ripasso con codice e la risposta da dare davvero al colloquio.",
            "Promemoria giornaliero, solo nei giorni in cui il quiz non è ancora fatto.",
        ],
        questions: [
            ("Ho perso lo streak.", "Lo streak conta i giorni consecutivi in cui hai completato il quiz del giorno; salta un giorno e riparte da zero. Il record resta scritto nel Profilo."),
            ("Non arrivano i promemoria.", "Controlla Impostazioni › Notifiche › Interviews, poi l'interruttore in Profilo › Notifiche. La notifica non suona nei giorni in cui il quiz è già fatto: è voluto."),
            ("Voglio ricominciare da capo.", "Profilo › Azzera i progressi cancella streak, statistiche, XP ed errori, tenendo i percorsi scelti."),
            ("Una risposta mi sembra sbagliata.", "Scrivimi citando la domanda: i contenuti si correggono e arrivano col prossimo aggiornamento."),
            ("I miei dati.", "Non ne raccolgo nessuno, quindi non ho nulla da darti o da cancellare. Disinstallando l'app sparisce tutto."),
        ])
}

func page(_ site: Site, title: String, body: String) -> String {
    """
    <!doctype html>
    <html lang="\(site.lang)">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>\(esc(title)) · Interviews</title>
    <style>\(css)</style>
    </head>
    <body>
    <main>
    \(body)
    <footer>
    <p>\(inline(Legal.trademarks(site.lang == "it" ? .it : .en)))</p>
    <p>© 2026 \(esc(Legal.developer)) · <a href="index.html">Interviews</a> · <a href="privacy.html">\(esc(site.privacy))</a> · <a href="terms.html">\(esc(site.terms))</a> · <a href="support.html">\(esc(site.support))</a> · <a href="\(site.otherHref)">\(esc(site.other))</a></p>
    </footer>
    </main>
    </body>
    </html>
    """
}

func document(_ site: Site, _ doc: LegalDocument) -> String {
    let sections = doc.sections.map { "<h2>\(esc($0.heading))</h2>\n<p>\(inline($0.body))</p>" }.joined(separator: "\n")
    return """
    <header>
    <h1>\(esc(doc.title))</h1>
    <p class="eff">\(esc(doc.effective)) · Interviews for iPhone</p>
    <nav><a href="index.html">\(esc(site.back))</a> <a href="\(site.otherHref)">\(esc(site.other))</a></nav>
    </header>
    \(sections)
    """
}

func index(_ site: Site) -> String {
    """
    <header>
    <h1>Interviews</h1>
    <p class="lead">\(esc(site.tagline))</p>
    <nav>
    <a href="privacy.html">\(esc(site.privacy))</a>
    <a href="terms.html">\(esc(site.terms))</a>
    <a href="support.html">\(esc(site.support))</a>
    <a href="\(site.otherHref)">\(esc(site.other))</a>
    </nav>
    </header>
    <h2>\(esc(site.whatItDoes))</h2>
    <ul>
    \(site.bullets.map { "<li>\(esc($0))</li>" }.joined(separator: "\n"))
    </ul>
    <h2>\(esc(site.privacyLine))</h2>
    <p>\(esc(site.privacyLead)) <a href="privacy.html">\(esc(site.privacy.lowercased()))</a>.</p>
    """
}

func support(_ site: Site) -> String {
    """
    <header>
    <h1>\(esc(site.support))</h1>
    <p class="eff">Interviews for iPhone</p>
    <nav><a href="index.html">\(esc(site.back))</a> <a href="\(site.otherHref)">\(esc(site.other))</a></nav>
    </header>
    <h2>\(esc(site.writeTo))</h2>
    <p><a href="mailto:\(Legal.supportEmail)">\(Legal.supportEmail)</a> — \(esc(Legal.developer)).</p>
    <h2>\(esc(site.faq))</h2>
    \(site.questions.map { "<p><strong>\(esc($0.0))</strong> \(esc($0.1))</p>" }.joined(separator: "\n"))
    """
}

let fm = FileManager.default
for (site, dir) in [(Site.en, outDir), (Site.it, outDir + "/it")] {
    try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
    let language: AppLanguage = site.lang == "it" ? .it : .en
    let files = [
        ("index.html", page(site, title: "Interviews", body: index(site))),
        ("privacy.html", page(site, title: Legal.privacy(language).title, body: document(site, Legal.privacy(language)))),
        ("terms.html", page(site, title: Legal.terms(language).title, body: document(site, Legal.terms(language)))),
        ("support.html", page(site, title: site.support, body: support(site))),
    ]
    for (name, html) in files {
        try! html.write(toFile: dir + "/" + name, atomically: true, encoding: .utf8)
        print("scritto \(dir)/\(name)")
    }
}
