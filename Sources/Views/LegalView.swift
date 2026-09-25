import SwiftUI

/// Privacy e termini si leggono così come sono scritti in `Legal`: niente rete,
/// niente WebView, funzionano anche in aereo.
struct LegalDocumentView: View {
    @Environment(AppState.self) private var state
    let document: LegalDocument

    private var theme: Theme { state.activeTrack.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.title)
                        .font(.system(.title, design: .rounded).weight(.bold))
                    Text(document.effective)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(section.heading)
                            .font(.headline)
                            .foregroundStyle(theme.deep)
                        RichText(text: section.body, font: .callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                Link(destination: Legal.mailtoURL) {
                    Label("Write to \(Legal.supportEmail)", systemImage: "envelope.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(theme.primary)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .padding(.bottom, 32)
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// La sezione "Informazioni" del profilo: i link che l'App Store si aspetta di
/// trovare dentro l'app, più versione e marchi citati.
struct AboutSection: View {
    var body: some View {
        Section {
            NavigationLink {
                LegalDocumentView(document: Legal.privacy)
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            NavigationLink {
                LegalDocumentView(document: Legal.terms)
            } label: {
                Label("Terms of Use", systemImage: "doc.text.fill")
            }
            Link(destination: Legal.appleEULAURL) {
                Label {
                    HStack {
                        Text("Apple's standard EULA")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    // Non il simbolo `applelogo`: la licenza di SF Symbols non
                    // consente di usare i marchi Apple dentro un'app di terzi.
                    Image(systemName: "scroll.fill")
                }
            }
            Link(destination: Legal.mailtoURL) {
                Label {
                    HStack {
                        Text("Contact support")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "envelope.fill")
                }
            }
        } header: {
            Text("About")
        } footer: {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(Legal.versionString) · © 2026 \(Legal.developer)")
                Text(Legal.trademarks)
            }
            .font(.caption2)
            .padding(.top, 4)
        }
        .tint(.primary)
    }
}

/// La riga sotto l'ultimo bottone dell'onboarding. I documenti si aprono in un
/// foglio, non nel browser: devono essere leggibili anche senza connessione.
struct LegalConsentNote: View {
    var tint: Color
    @State private var shown: LegalDocument?

    private func link(_ title: String, _ document: LegalDocument) -> some View {
        Button(title) { shown = document }
            .buttonStyle(.plain)
            .foregroundStyle(tint)
            .underline()
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("By continuing you accept")
            HStack(spacing: 4) {
                link("the Terms of Use", Legal.terms)
                Text("and")
                link("the Privacy Policy", Legal.privacy)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.top, 4)
        .sheet(item: $shown) { document in
            NavigationStack {
                LegalDocumentView(document: document)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Close") { shown = nil }
                        }
                    }
            }
        }
    }
}
