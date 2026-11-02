import SwiftUI
import UIKit

@MainActor
struct ReadingTextView: UIViewRepresentable {
    let text: String
    let highlightedRange: NSRange?

    @Environment(\.colorScheme) private var colorScheme

    @MainActor
    final class Coordinator {
        var text = ""
        var highlightedRange: NSRange?
        var colorScheme: ColorScheme?
        var fontSize: CGFloat = 0
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = false
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.adjustsFontForContentSizeCategory = true
        view.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.textContainer.lineFragmentPadding = 0
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.accessibilityLabel = "Texto del párrafo"
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let coordinator = context.coordinator
        let palette = AppPalette(colorScheme: colorScheme)
        let normalColor = UIColor(palette.mainText)
        let font = UIFont.preferredFont(forTextStyle: .title3)
        let needsRebuild = coordinator.text != text
            || coordinator.colorScheme != colorScheme
            || coordinator.fontSize != font.pointSize

        if needsRebuild {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            uiView.attributedText = NSAttributedString(
                string: text,
                attributes: [
                    .font: font,
                    .foregroundColor: normalColor,
                    .paragraphStyle: paragraphStyle
                ]
            )
            uiView.accessibilityValue = text
            uiView.setContentOffset(.zero, animated: false)
            coordinator.text = text
            coordinator.colorScheme = colorScheme
            coordinator.fontSize = font.pointSize
            coordinator.highlightedRange = nil
        }

        guard needsRebuild || coordinator.highlightedRange != highlightedRange else { return }

        let storage = uiView.textStorage
        storage.beginEditing()

        if let oldRange = coordinator.highlightedRange,
           oldRange.location <= storage.length,
           oldRange.length <= storage.length - oldRange.location {
            storage.removeAttribute(.backgroundColor, range: oldRange)
            storage.addAttribute(.foregroundColor, value: normalColor, range: oldRange)
        }

        var validRange: NSRange?
        if let range = highlightedRange,
           range.location != NSNotFound, range.length > 0,
           range.location <= storage.length,
           range.length <= storage.length - range.location {
            let highlight = colorScheme == .dark
                ? UIColor(red: 0.914, green: 0.718, blue: 0.576, alpha: 1)
                : UIColor(red: 0.945, green: 0.855, blue: 0.808, alpha: 1)
            storage.addAttributes([
                .backgroundColor: highlight,
                .foregroundColor: UIColor(red: 0.188, green: 0.157, blue: 0.188, alpha: 1)
            ], range: range)
            validRange = range
        }

        storage.endEditing()
        coordinator.highlightedRange = validRange

        if let validRange {
            uiView.layoutIfNeeded()
            uiView.scrollRangeToVisible(validRange)
        }
    }
}

