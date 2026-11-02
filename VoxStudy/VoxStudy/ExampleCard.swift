import SwiftUI

@MainActor
struct ExampleCard: View {
    let example: StudyExample
    let isEnabled: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette { AppPalette(colorScheme: colorScheme) }

    private var fill: Color {
        switch example.tone {
        case .peach: return palette.peach
        case .sage: return palette.sage
        case .lilac: return palette.lilac
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: example.symbol)
                    .font(.title2)
                    .foregroundStyle(palette.accent)
                    .frame(width: 48, height: 48)
                    .background(palette.surface.opacity(0.8), in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 5) {
                    Text(example.title)
                        .font(.headline)
                        .foregroundStyle(palette.mainText)
                    Text(example.subtitle)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                    Text("Abrir en el lector")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.accent)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(palette.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(fill, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

