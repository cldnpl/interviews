import SwiftUI
import StoreKit

/// Il motivo per cui si apre l'abbonamento, da passare a `.sheet(item:)`.
/// Serve un tipo identificabile: una `String` nuda non basta.
struct PaywallReason: Identifiable {
    let text: String?
    var id: String { text ?? "—" }

    /// Aperto dal Profilo o da una card: niente riga di contesto.
    static let plain = PaywallReason(nil)

    init(_ text: String? = nil) { self.text = text }
}

/// La schermata dell'abbonamento. Si apre da sola quando si tocca una lezione chiusa,
/// e dal Profilo. Dice tre cose e basta: che cosa si apre, quanto costa, come si disdice.
struct PremiumSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    /// La riga in cima che ricorda da dove si arriva ("Questa lezione è in Pro").
    var reason: String?

    @State private var appeared = false
    @State private var shine = false

    private var theme: Theme { state.activeTrack.theme }
    private var store: Store { state.store }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    hero
                    if let reason {
                        Text(reason)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                    }
                    benefits
                    priceCard
                    supportNote
                    legal
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(backdrop)
            .safeAreaInset(edge: .bottom) { buyBar }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 30, height: 30)
                            .background(.thinMaterial, in: Circle())
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel(Text("Close", bundle: .app))
                }
            }
        }
        .task { await store.load() }
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.35)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { shine = true }
        }
        .alert(Text("Something went wrong", bundle: .app),
               isPresented: Binding(get: { store.failure != nil }, set: { if !$0 { store.failure = nil } })) {
            Button(String(localized: "OK", bundle: .app), role: .cancel) { store.failure = nil }
        } message: {
            Text(store.failure ?? "")
        }
        // Appena l'abbonamento è attivo la schermata si chiude da sé: niente
        // "grazie" da leggere, si torna subito alla lezione che si voleva aprire.
        .onChange(of: store.isPremium) { _, premium in
            if premium { dismiss() }
        }
    }

    // MARK: Il cappello

    private var hero: some View {
        VStack(spacing: 18) {
            ZStack {
                // Il bagliore che gira dietro al lucchetto aperto.
                Circle()
                    .fill(LinearGradient(colors: [theme.primary.opacity(0.35), .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 190, height: 190)
                    .blur(radius: 28)
                    .scaleEffect(shine ? 1.12 : 0.9)
                ForEach(0..<8, id: \.self) { i in
                    Capsule()
                        .fill(theme.primary.opacity(0.22))
                        .frame(width: 5, height: appeared ? 26 : 6)
                        .offset(y: -74)
                        .rotationEffect(.degrees(Double(i) / 8 * 360))
                }
                AppMark()
                    .frame(width: 96)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .rotationEffect(.degrees(appeared ? 0 : -12))
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(11)
                    .background(theme.linear, in: Circle())
                    .overlay { Circle().strokeBorder(Color(.systemBackground), lineWidth: 3) }
                    .offset(x: 44, y: 44)
                    .scaleEffect(appeared ? 1 : 0.2)
            }
            .frame(height: 170)

            VStack(spacing: 8) {
                Text("Interviews Pro")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                Text("Every lesson, every question, on all four tracks.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 6)
    }

    // MARK: Cosa si apre

    private var benefits: some View {
        VStack(spacing: 0) {
            BenefitRow(symbol: "lock.open.fill", tint: theme.primary,
                       title: String(localized: "All the Mid and Senior topics", bundle: .app),
                       detail: locked)
            Divider().padding(.leading, 60)
            BenefitRow(symbol: "sparkles", tint: .flame,
                       title: String(localized: "A daily quiz that grows with you", bundle: .app),
                       detail: String(localized: "Without Pro the daily questions stay on the Junior topics. With Pro they follow your rank, all the way to Staff.", bundle: .app))
            Divider().padding(.leading, 60)
            BenefitRow(symbol: "arrow.uturn.backward.circle.fill", tint: .wrong,
                       title: String(localized: "Corrections for every mistake", bundle: .app),
                       detail: String(localized: "Each wrong answer is explained: what you picked, why it does not hold, and why the right one does.", bundle: .app))
            Divider().padding(.leading, 60)
            BenefitRow(symbol: "globe", tint: Track.flutter.theme.primary,
                       title: String(localized: "Six languages, light and dark", bundle: .app),
                       detail: String(localized: "The whole app in English, Italian, Spanish, French, German and Portuguese, in the theme you prefer.", bundle: .app))
        }
        .padding(.vertical, 6)
        .card()
    }

    private var locked: String {
        let n = state.lockedTopicCount
        return n > 0
            ? String(localized: "\(n) locked topics open up right away, with their lessons and their quizzes.", bundle: .app)
            : String(localized: "The lessons and quizzes beyond the fundamentals, on every track.", bundle: .app)
    }

    // MARK: Il prezzo

    private var priceCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.priceText)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                Text("/ month", bundle: .app)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Text("Renews every month. Cancel whenever you like, from Settings on your iPhone.", bundle: .app)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.soft)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(theme.primary.opacity(0.35), lineWidth: 1.5)
                }
        }
    }

    /// La riga che spiega perché l'abbonamento esiste. Vuole stare sotto il prezzo,
    /// non nascosta in fondo: è la ragione vera per cui qualcuno paga.
    private var supportNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
                .font(.subheadline)
                .padding(.top, 2)
            Text("It's a symbolic price to support an independent developer and push me to keep making this better.", bundle: .app)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var legal: some View {
        VStack(spacing: 10) {
            Button {
                Task { await store.restore() }
            } label: {
                HStack(spacing: 6) {
                    if store.restoring { ProgressView().controlSize(.mini) }
                    Text("Restore purchases", bundle: .app)
                }
                .font(.subheadline.weight(.semibold))
            }
            .disabled(store.restoring)

            HStack(spacing: 14) {
                Button(String(localized: "Terms", bundle: .app)) { openURL(Legal.termsURL) }
                Text(verbatim: "·").foregroundStyle(.tertiary)
                Button(String(localized: "Privacy", bundle: .app)) { openURL(Legal.privacyURL) }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: Il bottone

    private var buyBar: some View {
        VStack(spacing: 0) {
            Button {
                Task { await store.purchase() }
            } label: {
                HStack(spacing: 8) {
                    if store.purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "lock.open.fill")
                    }
                    Text("Unlock everything", bundle: .app)
                }
            }
            .buttonStyle(PrimaryButtonStyle(gradient: theme.linear))
            .disabled(store.purchasing || store.product == nil)
            .opacity(store.product == nil ? 0.5 : 1)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(.bar)
    }

    private var backdrop: some View {
        ZStack {
            Color(.systemGroupedBackground)
            theme.linear.opacity(0.07)
        }
        .ignoresSafeArea()
    }
}

private struct BenefitRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.bold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

/// Il lucchetto che compare sugli argomenti chiusi.
struct LockBadge: View {
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [Color(hex: 0xFFC24B), Color(hex: 0xF5A000)],
                               startPoint: .top, endPoint: .bottom),
                in: Circle()
            )
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
    }
}

/// La riga "Pro" da mettere sotto l'intestazione di uno stage chiuso.
struct LockedStageNote: View {
    let stage: Stage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                LockBadge(size: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text("These lessons are in Interviews Pro", bundle: .app)
                        .font(.subheadline.weight(.bold))
                    Text("Tap to see what opens up.", bundle: .app)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0xF5A000).opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color(hex: 0xF5A000).opacity(0.3), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}
