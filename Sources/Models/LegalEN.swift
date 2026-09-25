import Foundation

/// I documenti legali in inglese: è la lingua base dell'app, quindi questa è
/// la versione che vale e che App Store Connect indicizza per prima.
extension Legal {
    static let effectiveEN = "In effect from 25 September 2026"

    static let privacyEN = LegalDocument(
        id: "privacy",
        title: "Privacy Policy",
        effective: effectiveEN,
        sections: [
            .init(heading: "In two lines", body: """
            Interviews collects nothing. No account, no advertising, no usage analytics, no \
            third-party services. The app runs entirely on your iPhone and sends data to nobody, \
            not even to the person who wrote it.
            """),
            .init(heading: "Who the controller is", body: """
            \(developer), reachable at **\(supportEmail)**. Since no personal data ever arrives, \
            there is no processing of your data to speak of.
            """),
            .init(heading: "What stays on your device", body: """
            The app saves on your iPhone only what it needs to work: the tracks you picked, your \
            starting level, XP and rank, your streak and completed days, right and wrong answers, \
            lessons read and the reminder time. They live in the app's own storage (`UserDefaults`), \
            never leave the device, and contain no name, email, location, contacts, photos or \
            advertising identifiers.
            """),
            .init(heading: "No network", body: """
            The app has no feature that connects to the Internet: questions, lessons and images ship \
            inside the app from the moment you install it. There are no servers of ours to reach, so \
            there are no logs, no collected IP addresses and no cookies.
            """),
            .init(heading: "Backups", body: """
            If your iPhone backs up to iCloud or to a computer, the app's progress goes into that \
            backup along with the rest of the phone. That backup is yours, handled by Apple under \
            Apple's own privacy policy: we have no access to it.
            """),
            .init(heading: "Notifications", body: """
            Reminders are **local** notifications: your iPhone schedules them, they do not come from \
            a server, and no push token is ever created or sent. You grant the permission and you can \
            take it back whenever you like, from Settings › Notifications › Interviews or by turning \
            the switch off in your Profile.
            """),
            .init(heading: "No tracking", body: """
            Interviews does not track your activity across other apps or websites, does not use the \
            advertising identifier (IDFA), does not show the App Tracking Transparency prompt because \
            it has no reason to, and shares nothing with data brokers. It bundles no third-party SDK \
            of any kind.
            """),
            .init(heading: "Deleting everything", body: """
            **Profile › Reset progress** immediately erases your streak, stats, XP and mistakes. \
            Deleting the app removes every saved trace. You do not need to ask us for anything: no \
            copies exist anywhere else.
            """),
            .init(heading: "Your rights", body: """
            European law (GDPR) gives you access, rectification, erasure, restriction, portability \
            and objection. Since we hold no data about you, there is nothing to exercise them against \
            here; if you would like to write anyway, the address is **\(supportEmail)**. You can also \
            complain to your national data protection authority — in Italy, the Garante per la \
            protezione dei dati personali (garanteprivacy.it).
            """),
            .init(heading: "Children", body: """
            The app covers technical job-interview material and is meant for a general audience. \
            Since it collects data from nobody, it collects none from children either.
            """),
            .init(heading: "Changes", body: """
            If this policy changes, the new version will appear in the app and at \
            \(privacyURL(.en).absoluteString), with the date at the top updated. Substantial changes \
            will be called out in the release notes of the update.
            """),
            .init(heading: "Contact", body: """
            Any question about this policy: **\(supportEmail)**.
            """)
        ]
    )

    static let termsEN = LegalDocument(
        id: "terms",
        title: "Terms of Use",
        effective: effectiveEN,
        sections: [
            .init(heading: "Who you are contracting with", body: """
            These terms are an agreement between you and \(developer) (“the developer”), **not with \
            Apple**. By using Interviews you accept them. They apply alongside Apple's standard \
            Licensed Application End User License Agreement; where these say something more specific, \
            these prevail.
            """),
            .init(heading: "Licence", body: """
            You are granted a personal, non-exclusive, non-transferable, revocable licence to use \
            Interviews on Apple-branded products that you own or control, in accordance with the \
            Usage Rules of the App Store Terms of Service. The licence covers use of the app, not \
            ownership: the app is licensed to you, not sold.
            """),
            .init(heading: "What the app is for", body: """
            Interviews is study material for preparing for mobile technical interviews. It is not \
            professional advice and promises no outcome: no interview passed, no job offer. Languages \
            move on, so some content can age or contain slips: when in doubt, the official \
            documentation from Apple, Google or the Kotlin Foundation is what counts.
            """),
            .init(heading: "The app's content", body: """
            Questions, explanations, lessons, text and artwork are the developer's work and protected \
            by copyright. You may use them to study; you may not copy, republish, resell, bulk-extract \
            them, or use them to build a competing product or to train models, without written permission.
            """),
            .init(heading: "What not to do", body: """
            No reverse engineering, decompiling or disassembling the app, except within the limits the \
            law makes non-waivable; no circumventing its mechanisms; no use contrary to the law.
            """),
            .init(heading: "Price", body: """
            The app is free and contains no in-app purchases, subscriptions or advertising. Should paid \
            features ever arrive, they would be announced beforehand and would not touch progress you \
            have already made.
            """),
            .init(heading: "Support", body: """
            Support is the developer's sole responsibility, at **\(supportEmail)**. Apple has no \
            obligation whatsoever to furnish any maintenance or support services for this app.
            """),
            .init(heading: "Warranty", body: """
            The app is provided “as is”, to the extent permitted by law. The rights consumer legislation \
            gives you, and which no contract can take away, remain untouched. In the event of any failure \
            of the app to conform to any applicable warranty, you may notify Apple, and Apple will refund \
            the purchase price, if any; beyond that, Apple has no other warranty obligation whatsoever.
            """),
            .init(heading: "Liability", body: """
            To the extent permitted by law, the developer is not liable for indirect or consequential \
            damages arising from use of the app. Nothing written here limits liability for wilful \
            misconduct or gross negligence, nor your non-waivable consumer rights.
            """),
            .init(heading: "Claims about the app", body: """
            The developer, not Apple, is responsible for addressing any claims relating to the app: \
            product liability, failure to conform to legal or regulatory requirements, and consumer \
            protection or privacy claims included. The same goes for any third-party claim that the app \
            infringes intellectual property rights: the developer handles it, not Apple.
            """),
            .init(heading: "Export compliance", body: """
            By using the app you represent that you are not located in a country subject to a U.S. \
            Government embargo or designated as a “terrorist supporting” country, and that you are not \
            listed on any U.S. Government list of prohibited or restricted parties.
            """),
            .init(heading: "Apple as third-party beneficiary", body: """
            Apple and its subsidiaries are third-party beneficiaries of these terms and, upon your \
            acceptance, will have the right to enforce them against you.
            """),
            .init(heading: "Governing law", body: """
            Italian law applies. If you use the app as a consumer, the courts of the place where you \
            live or are domiciled remain competent.
            """),
            .init(heading: "Trademarks", body: trademarks(.en)),
            .init(heading: "Changes", body: """
            These terms may be updated: the version in force is the one you are reading here and at \
            \(termsURL(.en).absoluteString). Continuing to use the app after an update means you accept them.
            """),
            .init(heading: "Contact", body: """
            \(developer) — **\(supportEmail)**
            """)
        ]
    )
}
