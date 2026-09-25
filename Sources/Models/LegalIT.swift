import Foundation

/// I documenti legali in italiano: l'unica traduzione dell'app.
extension Legal {
    static let effectiveIT = "In vigore dal 25 settembre 2026"

    static let privacyIT = LegalDocument(
        id: "privacy",
        title: "Informativa sulla privacy",
        effective: effectiveIT,
        sections: [
            .init(heading: "In due righe", body: """
            Interviews non raccoglie nulla. Nessun account, nessuna pubblicità, nessuna statistica \
            d'uso, nessun servizio di terze parti. L'app funziona interamente sul tuo iPhone e non \
            manda dati a nessuno, nemmeno a chi l'ha scritta.
            """),
            .init(heading: "Chi è il titolare", body: """
            \(developer), raggiungibile a **\(supportEmail)**. Non ricevendo alcun dato personale, \
            non svolge alcun trattamento sui tuoi dati.
            """),
            .init(heading: "Che cosa resta sul dispositivo", body: """
            L'app salva sul tuo iPhone soltanto ciò che serve a farla funzionare: i percorsi scelti, \
            il livello di partenza, XP e grado, lo streak e i giorni completati, le risposte giuste e \
            sbagliate, le lezioni lette e l'ora del promemoria. Stanno nell'area riservata all'app \
            (`UserDefaults`), non escono dal dispositivo e non contengono nome, email, posizione, \
            rubrica, foto o identificativi pubblicitari.
            """),
            .init(heading: "Niente rete", body: """
            L'app non ha alcuna funzione che si colleghi a Internet: domande, lezioni e immagini sono \
            dentro l'app fin dall'installazione. Non ci sono server nostri da contattare, quindi non \
            esistono log, indirizzi IP raccolti o cookie.
            """),
            .init(heading: "Backup", body: """
            Se hai attivo il backup dell'iPhone su iCloud o su computer, i progressi dell'app finiscono \
            in quel backup insieme al resto del telefono. È un backup tuo, gestito da Apple secondo la \
            sua informativa: noi non vi abbiamo accesso.
            """),
            .init(heading: "Notifiche", body: """
            I promemoria sono notifiche **locali**: le pianifica il tuo iPhone, non arrivano da un server \
            e non viene creato né inviato alcun token push. Il permesso lo concedi tu e puoi toglierlo \
            quando vuoi da Impostazioni › Notifiche › Interviews, oppure spegnendo l'interruttore nel Profilo.
            """),
            .init(heading: "Nessun tracciamento", body: """
            Interviews non traccia la tua attività su altre app o siti, non usa l'identificativo \
            pubblicitario (IDFA), non mostra il messaggio di App Tracking Transparency perché non ne ha \
            motivo e non condivide nulla con data broker. Non include SDK di terze parti di alcun tipo.
            """),
            .init(heading: "Cancellare tutto", body: """
            **Profilo › Azzera i progressi** cancella subito streak, statistiche, XP ed errori. \
            Disinstallando l'app sparisce ogni dato salvato. Non devi chiedere niente a noi: non \
            esistono copie altrove.
            """),
            .init(heading: "I tuoi diritti", body: """
            Il Regolamento europeo (GDPR) ti riconosce accesso, rettifica, cancellazione, limitazione, \
            portabilità e opposizione. Poiché non deteniamo alcun dato che ti riguardi, non c'è nulla su \
            cui esercitarli nei nostri confronti; se vuoi comunque scriverci, l'indirizzo è \
            **\(supportEmail)**. Puoi rivolgerti al Garante per la protezione dei dati personali \
            (garanteprivacy.it) se ritieni che qualcosa non vada.
            """),
            .init(heading: "Minori", body: """
            L'app tratta argomenti tecnici da colloquio di lavoro e si rivolge a un pubblico generale. \
            Non raccogliendo dati da nessuno, non ne raccoglie neanche dai minori.
            """),
            .init(heading: "Modifiche", body: """
            Se questa informativa cambierà, la nuova versione comparirà qui dentro e su \
            \(privacyURL(.it).absoluteString), con la data aggiornata in cima. Le modifiche sostanziali \
            saranno segnalate nelle note di versione dell'aggiornamento.
            """),
            .init(heading: "Contatti", body: """
            Per qualsiasi domanda su questa informativa: **\(supportEmail)**.
            """)
        ]
    )

    static let termsIT = LegalDocument(
        id: "terms",
        title: "Termini d'uso",
        effective: effectiveIT,
        sections: [
            .init(heading: "Con chi stai contrattando", body: """
            Questi termini sono un accordo fra te e \(developer) («lo sviluppatore»), **non con Apple**. \
            Usando Interviews li accetti. Valgono insieme all'EULA standard di Apple per le app concesse \
            in licenza; dove dicono qualcosa di più specifico, prevalgono questi.
            """),
            .init(heading: "Licenza d'uso", body: """
            Ti viene concessa una licenza personale, non esclusiva, non trasferibile e revocabile per \
            usare Interviews sui prodotti a marchio Apple che possiedi o controlli, secondo le Regole \
            d'uso dei Termini di servizio dell'App Store. La licenza riguarda l'uso dell'app, non la \
            proprietà: l'app ti è concessa, non venduta.
            """),
            .init(heading: "A che cosa serve l'app", body: """
            Interviews è materiale di studio per prepararsi ai colloqui tecnici mobile. Non è consulenza \
            professionale e non promette alcun risultato: nessun colloquio superato, nessuna assunzione. \
            I linguaggi cambiano, quindi qualche contenuto può invecchiare o contenere imprecisioni: in \
            caso di dubbio fa fede la documentazione ufficiale di Apple, Google o della Kotlin Foundation.
            """),
            .init(heading: "Contenuti dell'app", body: """
            Domande, spiegazioni, lezioni, testi e grafica sono opera dello sviluppatore e protetti dal \
            diritto d'autore. Puoi usarli per studiare; non puoi copiarli, ripubblicarli, rivenderli, \
            estrarli in blocco o usarli per costruire un prodotto concorrente o per addestrare modelli, \
            senza un permesso scritto.
            """),
            .init(heading: "Che cosa non fare", body: """
            Niente reverse engineering, decompilazione o disassemblaggio dell'app, salvo nei limiti \
            inderogabili di legge; niente aggiramento dei suoi meccanismi; niente uso contrario alla legge.
            """),
            .init(heading: "Prezzo", body: """
            L'app è gratuita e non contiene acquisti in-app, abbonamenti né pubblicità. Se in futuro \
            arrivassero funzioni a pagamento, sarebbero annunciate prima e non toccherebbero i progressi \
            già fatti.
            """),
            .init(heading: "Assistenza", body: """
            L'assistenza è a carico esclusivo dello sviluppatore, a cui puoi scrivere a \
            **\(supportEmail)**. Apple non ha alcun obbligo di fornire assistenza o manutenzione su \
            questa app.
            """),
            .init(heading: "Garanzia", body: """
            L'app è fornita «così com'è», nei limiti consentiti dalla legge. Restano fermi i diritti che \
            la normativa sui consumatori ti riconosce e che nessun contratto può togliere. Se l'app non \
            fosse conforme a un'eventuale garanzia, puoi avvisare Apple, che ti rimborserà l'eventuale \
            prezzo d'acquisto: oltre a questo, Apple non ha alcun obbligo di garanzia.
            """),
            .init(heading: "Responsabilità", body: """
            Nei limiti consentiti dalla legge, lo sviluppatore non risponde di danni indiretti o \
            conseguenti derivanti dall'uso dell'app. Nulla di quanto scritto qui limita la responsabilità \
            per dolo o colpa grave, né i diritti inderogabili del consumatore.
            """),
            .init(heading: "Reclami sull'app", body: """
            Di ogni reclamo che riguardi l'app risponde lo sviluppatore, non Apple: responsabilità da \
            prodotto, mancata conformità a obblighi di legge, tutela del consumatore e della privacy \
            compresi. Lo stesso vale per eventuali contestazioni di terzi sulla proprietà intellettuale: \
            se ne occupa lo sviluppatore.
            """),
            .init(heading: "Conformità alle norme sull'export", body: """
            Usando l'app dichiari di non trovarti in un Paese soggetto a embargo del governo statunitense \
            o designato come Paese «che sostiene il terrorismo», e di non comparire in alcun elenco di \
            soggetti interdetti o sottoposti a restrizioni.
            """),
            .init(heading: "Apple come terzo beneficiario", body: """
            Apple e le sue controllate sono terzi beneficiari di questi termini e, accettandoli, \
            riconosci che Apple ha il diritto di farli valere nei tuoi confronti.
            """),
            .init(heading: "Legge applicabile", body: """
            Si applica la legge italiana. Se usi l'app come consumatore, resta competente il giudice del \
            luogo in cui risiedi o sei domiciliato.
            """),
            .init(heading: "Marchi", body: trademarks(.it)),
            .init(heading: "Modifiche", body: """
            Questi termini possono essere aggiornati: la versione in vigore è quella che leggi qui e su \
            \(termsURL(.it).absoluteString). Continuando a usare l'app dopo un aggiornamento li accetti.
            """),
            .init(heading: "Contatti", body: """
            \(developer) — **\(supportEmail)**
            """)
        ]
    )
}
