import Foundation
import Observation
import StoreKit

/// L'abbonamento. Gratis si studia tutto lo stage Junior di ogni linguaggio;
/// Mid e Senior si aprono con Interviews Pro.
///
/// Tiene una sola cosa vera: `isPremium`. La verità sta su StoreKit, non nei
/// nostri `UserDefaults`, così l'abbonamento vale su tutti i dispositivi di chi
/// l'ha preso e sparisce da sé quando scade.
@Observable
final class Store {
    static let shared = Store()

    /// L'identificativo del prodotto su App Store Connect.
    static let monthlyID = "com.cldnpl.interviews.pro.monthly"

    private(set) var product: Product?
    private(set) var isPremium = false
    /// Vero mentre l'acquisto è in corso: il bottone si blocca e mostra la rotella.
    private(set) var purchasing = false
    /// Vero mentre si rileggono gli acquisti già fatti ("Ripristina acquisti").
    private(set) var restoring = false
    /// Il messaggio da mostrare se qualcosa non va.
    var failure: String?

    private var updates: Task<Void, Never>?

    private init() {
        // Le transazioni possono arrivare anche da fuori dall'app (rinnovi, acquisti
        // su un altro dispositivo, rimborsi): si resta in ascolto per tutta la vita dell'app.
        updates = Task.detached { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task { await load() }
    }

    deinit { updates?.cancel() }

    /// Prezzo e titolo veri, presi da App Store: non si scrive "1,99 €" a mano,
    /// perché ogni Paese ha la sua valuta e il suo prezzo.
    @MainActor
    func load() async {
        await refresh()
        do {
            product = try await Product.products(for: [Self.monthlyID]).first
        } catch {
            product = nil
        }
    }

    /// Il prezzo come lo scrive App Store nella valuta dell'utente.
    /// Prima che il prodotto arrivi si mostra il prezzo base, per non lasciare un buco.
    var priceText: String {
        product?.displayPrice ?? "€1,99"
    }

    @MainActor
    func refresh() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.monthlyID,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
    }

    @MainActor
    func purchase() async {
        guard let product, !purchasing else { return }
        purchasing = true
        defer { purchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refresh()
                } else {
                    failure = String(localized: "We couldn't verify the purchase with App Store. Try again.", bundle: .app)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            failure = error.localizedDescription
        }
    }

    /// Rimette l'abbonamento su un iPhone nuovo, o dopo aver reinstallato l'app.
    @MainActor
    func restore() async {
        guard !restoring else { return }
        restoring = true
        defer { restoring = false }
        do {
            try await AppStore.sync()
        } catch {
            // Un annullamento della richiesta di password non è un errore da mostrare.
        }
        await refresh()
        if !isPremium {
            failure = String(localized: "No active subscription found on this Apple Account.", bundle: .app)
        }
    }

    #if DEBUG
    /// Solo per provare l'app dal simulatore senza passare da StoreKit.
    func debugSetPremium(_ on: Bool) { isPremium = on }
    #endif
}
