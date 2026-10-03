import Foundation

/// Una sezione di un documento legale: titoletto e corpo in markdown inline,
/// lo stesso che sa leggere `RichText`.
struct LegalSection: Identifiable, Hashable {
    let heading: String
    let body: String
    var id: String { heading }
}

struct LegalDocument: Identifiable, Hashable {
    let id: String
    let title: String
    /// Riga sotto il titolo: da quando vale questa versione.
    let effective: String
    let sections: [LegalSection]
}

/// Le lingue dell'app. L'interfaccia è tradotta in tutte; lezioni e domande,
/// che sono testo tecnico lungo, esistono in inglese e in italiano, e le altre
/// lingue leggono quelle inglesi (lo dice `contentLanguage`).
/// La sceglie l'utente in Profilo e non dipende dalla lingua dell'iPhone:
/// finché non la cambia, l'app parla nella lingua del telefono se la conosce,
/// altrimenti inglese.
enum AppLanguage: String, CaseIterable, Identifiable {
    case en, it, es, fr, de
    case ptBR = "pt-BR"

    var id: String { rawValue }

    private static let key = "interviews.language"

    static var current: AppLanguage {
        get { UserDefaults.standard.string(forKey: key).flatMap(AppLanguage.init) ?? .en }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            // Anche iOS la deve sapere: gli avvisi di sistema dentro l'app e la voce
            // Lingua in Impostazioni › Interviews restano allineati alla scelta.
            UserDefaults.standard.set([newValue.rawValue], forKey: "AppleLanguages")
        }
    }

    /// All'avvio: se l'utente ha cambiato lingua da Impostazioni › Interviews,
    /// quella scelta vince; se non ha mai scelto niente si prova la lingua
    /// dell'iPhone, e solo come ultima spiaggia l'inglese.
    static func bootstrap() {
        let domain = Bundle.main.bundleIdentifier.flatMap(UserDefaults.standard.persistentDomain(forName:))
        let fromSettings = (domain?["AppleLanguages"] as? [String])?.first.flatMap(match)
        let saved = UserDefaults.standard.string(forKey: key).flatMap(AppLanguage.init)
        current = fromSettings ?? saved ?? Locale.preferredLanguages.lazy.compactMap(match).first ?? .en
    }

    /// Da un codice lingua qualsiasi ("it-CH", "pt-PT", "de_DE") alla lingua dell'app.
    static func match(_ identifier: String) -> AppLanguage? {
        let code = identifier.replacingOccurrences(of: "_", with: "-")
        if let exact = AppLanguage(rawValue: code) { return exact }
        let base = String(code.prefix(while: { $0 != "-" })).lowercased()
        if base == "pt" { return .ptBR }
        return AppLanguage.allCases.first { $0.rawValue.lowercased() == base }
    }

    /// Il nome della lingua scritto in quella lingua, come nei selettori di sistema.
    var nativeName: String {
        switch self {
        case .en: "English"
        case .it: "Italiano"
        case .es: "Español"
        case .fr: "Français"
        case .de: "Deutsch"
        case .ptBR: "Português"
        }
    }

    /// In che lingua sono scritte lezioni e domande quando l'app parla questa lingua.
    /// Il testo tecnico è curato a mano: dove non c'è una traduzione si legge l'inglese,
    /// che è meglio di una traduzione automatica di un concetto difficile.
    var contentLanguage: AppLanguage { self == .it ? .it : .en }

    /// Vero quando lezioni e domande non sono in questa lingua: l'app lo dice
    /// all'utente invece di lasciarlo scoprire aprendo una lezione.
    var contentIsTranslated: Bool { contentLanguage == self }

    var locale: Locale { Locale(identifier: rawValue) }

    /// La cartella `.lproj` di questa lingua: da qui arrivano stringhe e contenuti,
    /// così il cambio di lingua vale subito, senza riavviare l'app.
    var bundle: Bundle {
        Bundle.main.path(forResource: rawValue, ofType: "lproj").flatMap(Bundle.init(path:))
            // "pt-BR" nel bundle può finire in "pt_BR" o "pt": si prova anche così.
            ?? Bundle.main.path(forResource: rawValue.replacingOccurrences(of: "-", with: "_"), ofType: "lproj").flatMap(Bundle.init(path:))
            ?? Bundle.main.path(forResource: String(rawValue.prefix(2)), ofType: "lproj").flatMap(Bundle.init(path:))
            ?? .main
    }

    /// Dove stanno le pagine di questa lingua sul sito: l'inglese alla radice,
    /// e per le lingue senza pagine tradotte si resta sull'inglese.
    var pathPrefix: String { self == .it ? "it/" : "" }
}

extension Locale {
    /// Numeri, date ed elenchi seguono la lingua scelta nell'app, non quella di
    /// sistema: se l'app parla inglese su un iPhone in italiano, anche le date
    /// devono essere inglesi.
    static var app: Locale { AppLanguage.current.locale }
}

extension Bundle {
    /// Le stringhe tradotte della lingua scelta. `String(localized:)` senza bundle
    /// guarderebbe la lingua con cui l'app è partita, non quella attuale.
    static var app: Bundle { AppLanguage.current.bundle }
}

/// Recapiti e testi legali. Stanno nel binario e non su un server: l'app
/// funziona senza rete, e privacy e termini devono restare leggibili comunque.
/// Le stesse parole sono pubblicate su `siteURL`, che è l'indirizzo richiesto
/// da App Store Connect.
enum Legal {
    static let developer = "Claudia Napolitano"
    static let supportEmail = "napolitano.claudia@icloud.com"

    private static let site = "https://cldnpl.github.io/interviews/"

    static var siteURL: URL { URL(string: site)! }
    static func privacyURL(_ language: AppLanguage) -> URL { URL(string: site + language.pathPrefix + "privacy.html")! }
    static func termsURL(_ language: AppLanguage) -> URL { URL(string: site + language.pathPrefix + "terms.html")! }
    static func supportURL(_ language: AppLanguage) -> URL { URL(string: site + language.pathPrefix + "support.html")! }

    static var privacyURL: URL { privacyURL(.current) }
    static var termsURL: URL { termsURL(.current) }
    static var supportURL: URL { supportURL(.current) }

    /// L'EULA standard che Apple applica a ogni app concessa in licenza.
    static let appleEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    static var mailtoURL: URL {
        URL(string: "mailto:\(supportEmail)?subject=Interviews%20%E2%80%93%20support")!
    }

    /// Versione e build, lette dal bundle: non vanno riscritte a mano a ogni rilascio.
    static var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return String(localized: "Version \(short) (\(build))", bundle: .app)
    }

    // MARK: Quello che l'app mostra

    static var trademarks: String { trademarks(.current) }
    static var privacy: LegalDocument { privacy(.current) }
    static var terms: LegalDocument { terms(.current) }

    // MARK: Le due lingue

    /// I marchi citati. Esiste in inglese e in italiano; le altre lingue leggono l'inglese.
    static func trademarks(_ language: AppLanguage) -> String {
        switch language {
        case .it: """
        Swift, il logo Swift, UIKit, Xcode, iPhone, iOS e App Store sono marchi di Apple Inc., \
        registrati negli Stati Uniti e in altri Paesi. Kotlin e il logo Kotlin sono marchi della \
        Kotlin Foundation. Flutter, il logo Flutter, Dart, Android e Google Play sono marchi di \
        Google LLC. Interviews è un'app indipendente: non è affiliata, sponsorizzata né approvata \
        da Apple Inc., Google LLC, JetBrains s.r.o. o Kotlin Foundation. Quei nomi e quei segni \
        compaiono solo per dire di che cosa parlano i percorsi di studio.
        """
        default: """
        Swift, the Swift logo, UIKit, Xcode, iPhone, iOS and App Store are trademarks of Apple Inc., \
        registered in the U.S. and other countries. Kotlin and the Kotlin logo are trademarks of the \
        Kotlin Foundation. Flutter, the Flutter logo, Dart, Android and Google Play are trademarks of \
        Google LLC. Interviews is an independent app: it is not affiliated with, sponsored by or \
        endorsed by Apple Inc., Google LLC, JetBrains s.r.o. or the Kotlin Foundation. Those names \
        and marks appear only to say what the study tracks are about.
        """
        }
    }

    /// Privacy e termini esistono in inglese e in italiano. Le altre lingue
    /// leggono l'inglese: un testo legale tradotto male è peggio di uno in inglese.
    static func privacy(_ language: AppLanguage) -> LegalDocument {
        language == .it ? privacyIT : privacyEN
    }

    static func terms(_ language: AppLanguage) -> LegalDocument {
        language == .it ? termsIT : termsEN
    }
}
