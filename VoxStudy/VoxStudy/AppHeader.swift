import SwiftUI

@MainActor
struct AppHeader: View {
    let onSettings: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette { AppPalette(colorScheme: colorScheme) }

    var body: some View {
        HStack {
            Label("VoxStudy", systemImage: "book.closed.fill")
                .font(.title2.bold())
                .foregroundStyle(palette.accent)

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 46, height: 46)
                    .background(palette.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Abrir ajustes")
        }
    }
}

