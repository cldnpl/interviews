import SwiftUI

/// Il segno di ogni percorso, disegnato a mano invece di pescato fra i simboli di
/// sistema: Kotlin e Flutter hanno un proprio marchio e con `k.square.fill` o
/// `bird.fill` non si riconoscevano. Swift usa il simbolo che Apple stessa
/// fornisce; UIKit non ha un marchio, e allora mostra quello che disegna:
/// la struttura di una schermata.
struct TrackMark: View {
    let track: Track
    /// Il lato del quadrato in cui sta il segno.
    var size: CGFloat = 24
    /// Con che cosa riempirlo. Sulle tessere colorate è bianco, altrove è il
    /// colore del linguaggio.
    var fill: AnyShapeStyle = AnyShapeStyle(.white)

    init(_ track: Track, size: CGFloat = 24, fill: some ShapeStyle = Color.white) {
        self.track = track
        self.size = size
        self.fill = AnyShapeStyle(fill)
    }

    var body: some View {
        Group {
            switch track {
            case .swift:
                // Il rondone di Swift è un simbolo di sistema: nessuno lo disegna meglio.
                Image(systemName: "swift")
                    .font(.system(size: size * 0.92))
                    .foregroundStyle(fill)
            case .uikit:
                // Even-odd: la cornice è un rettangolo meno quello dentro, e il
                // riempimento normale coprirebbe anche il buco.
                UIKitMark().fill(fill, style: FillStyle(eoFill: true))
            case .kotlin:
                KotlinMark().fill(fill)
            case .flutter:
                FlutterMark().fill(fill)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Il marchio di Kotlin: un quadrato con una tacca a V sul lato destro,
/// che lascia due triangoli rivolti in avanti.
struct KotlinMark: Shape {
    func path(in rect: CGRect) -> Path {
        // Il marchio è quadrato: lo si centra nello spazio disponibile.
        let s = min(rect.width, rect.height)
        let x = rect.minX + (rect.width - s) / 2
        let y = rect.minY + (rect.height - s) / 2
        func p(_ u: CGFloat, _ v: CGFloat) -> CGPoint { CGPoint(x: x + u * s, y: y + v * s) }

        var path = Path()
        path.move(to: p(1, 1))
        path.addLine(to: p(0, 1))
        path.addLine(to: p(0, 0))
        path.addLine(to: p(1, 0))
        path.addLine(to: p(0.5, 0.5))
        path.closeSubpath()
        return path
    }
}

/// Il marchio di Flutter: la trave in diagonale e la piega sotto, come un
/// foglio ripiegato. Le proporzioni sono quelle del logo originale (256×317).
struct FlutterMark: Shape {
    func path(in rect: CGRect) -> Path {
        // Il logo è più alto che largo: lo si inscrive mantenendo le proporzioni.
        let ratio: CGFloat = 256.0 / 317.0
        var w = rect.width, h = rect.height
        if w / h > ratio { w = h * ratio } else { h = w / ratio }
        let x = rect.minX + (rect.width - w) / 2
        let y = rect.minY + (rect.height - h) / 2
        func p(_ u: CGFloat, _ v: CGFloat) -> CGPoint { CGPoint(x: x + u * w, y: y + v * h) }

        var path = Path()
        // La trave che scende da destra in alto fino in basso a sinistra.
        path.move(to: p(0.616, 0))
        path.addLine(to: p(0, 0.497))
        path.addLine(to: p(0.191, 0.651))
        path.addLine(to: p(0.997, 0))
        path.closeSubpath()
        // La piega: scende, tocca il fondo e torna su.
        path.move(to: p(0.612, 0.459))
        path.addLine(to: p(0.285, 0.723))
        path.addLine(to: p(0.612, 1))
        path.addLine(to: p(0.997, 1))
        path.addLine(to: p(0.672, 0.723))
        path.addLine(to: p(0.997, 0.459))
        path.closeSubpath()
        return path
    }
}

/// UIKit non ha un logo: questo è il mestiere di UIKit disegnato, cioè una
/// schermata di iPhone — cornice, barra di navigazione in alto, contenuto,
/// barra delle tab in fondo.
struct UIKitMark: Shape {
    func path(in rect: CGRect) -> Path {
        // Proporzioni di un telefono, non di un quadrato.
        let ratio: CGFloat = 0.62
        var w = rect.width, h = rect.height
        if w / h > ratio { w = h * ratio } else { h = w / ratio }
        let x = rect.minX + (rect.width - w) / 2
        let y = rect.minY + (rect.height - h) / 2
        func r(_ u: CGFloat, _ v: CGFloat, _ rw: CGFloat, _ rh: CGFloat, _ radius: CGFloat) -> Path {
            Path(roundedRect: CGRect(x: x + u * w, y: y + v * h, width: rw * w, height: rh * h),
                 cornerRadius: radius * w)
        }

        var path = Path()
        path.addPath(r(0, 0, 1, 1, 0.19))                 // la scocca
        path.addPath(r(0.11, 0.07, 0.78, 0.86, 0.1))      // il buco: lo schermo
        path.addPath(r(0.11, 0.07, 0.78, 0.17, 0.08))     // la barra di navigazione
        path.addPath(r(0.22, 0.36, 0.56, 0.055, 0.03))    // due righe di contenuto
        path.addPath(r(0.22, 0.49, 0.38, 0.055, 0.03))
        path.addPath(r(0.11, 0.76, 0.78, 0.17, 0.08))     // la barra delle tab
        return path
    }
}

/// Il marchio dell'app: le quattro tessere con i quattro segni.
struct AppMark: View {
    /// Senza i segni resta il mosaico di soli colori: serve all'icona piccola.
    var showsMarks = true

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.24, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.12), radius: s * 0.14, y: s * 0.07)
                Grid(horizontalSpacing: s * 0.05, verticalSpacing: s * 0.05) {
                    GridRow {
                        tile(.swift, s)
                        tile(.uikit, s)
                    }
                    GridRow {
                        tile(.kotlin, s)
                        tile(.flutter, s)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func tile(_ track: Track, _ s: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: s * 0.09, style: .continuous)
            .fill(track.theme.linear)
            .frame(width: s * 0.31, height: s * 0.31)
            .overlay {
                if showsMarks {
                    TrackMark(track, size: s * 0.155, fill: .white.opacity(0.92))
                }
            }
    }
}

#Preview {
    VStack(spacing: 30) {
        AppMark().frame(width: 140)
        HStack(spacing: 18) {
            ForEach(Track.allCases) { track in
                TrackMark(track, size: 44, fill: track.theme.linear)
            }
        }
    }
    .padding(40)
}
