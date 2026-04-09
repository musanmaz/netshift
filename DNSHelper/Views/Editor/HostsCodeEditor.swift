import SwiftUI
import AppKit

struct HostsCodeEditor: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool
    var fontSize: Double
    var showLineNumbers: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = HighlightingTextView()

        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindPanel = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .controlAccentColor
        textView.textContainerInset = NSSize(width: showLineNumbers ? 50 : 12, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        textView.string = text
        textView.applyHighlighting()

        if showLineNumbers {
            let lineNumberView = LineNumberRulerView(textView: textView)
            scrollView.verticalRulerView = lineNumberView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? HighlightingTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        textView.isEditable = isEditable
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: showLineNumbers ? 50 : 12, height: 8)

        if showLineNumbers {
            if scrollView.verticalRulerView == nil {
                let rulerView = LineNumberRulerView(textView: textView)
                scrollView.verticalRulerView = rulerView
                scrollView.hasVerticalRuler = true
            }
            scrollView.rulersVisible = true
        } else {
            scrollView.rulersVisible = false
        }

        textView.applyHighlighting()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: HostsCodeEditor

        init(_ parent: HostsCodeEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? HighlightingTextView else { return }
            parent.text = textView.string
            textView.applyHighlighting()
        }
    }
}

// MARK: - Syntax Highlighting

class HighlightingTextView: NSTextView {
    func applyHighlighting() {
        guard let textStorage = self.textStorage else { return }
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let content = textStorage.string

        textStorage.beginEditing()

        textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        if let font = self.font {
            textStorage.addAttribute(.font, value: font, range: fullRange)
        }

        let lines = content.components(separatedBy: .newlines)
        var location = 0

        for line in lines {
            let lineRange = NSRange(location: location, length: line.count)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("#") {
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemGray, range: lineRange)
                if let italicFont = NSFont.monospacedSystemFont(ofSize: self.font?.pointSize ?? 13, weight: .regular)
                    .withTraits(.italicFontMask) {
                    textStorage.addAttribute(.font, value: italicFont, range: lineRange)
                }
            } else if !trimmed.isEmpty {
                if let firstSpace = trimmed.firstIndex(of: " ") ?? trimmed.firstIndex(of: "\t") {
                    let ipLength = trimmed.distance(from: trimmed.startIndex, to: firstSpace)
                    let ipRange = NSRange(location: location + (line.count - trimmed.count), length: ipLength)
                    textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: ipRange)
                    textStorage.addAttribute(
                        .font,
                        value: NSFont.monospacedSystemFont(ofSize: self.font?.pointSize ?? 13, weight: .semibold),
                        range: ipRange
                    )
                }

                if trimmed.contains("localhost") {
                    textStorage.addAttribute(.backgroundColor, value: NSColor.systemGreen.withAlphaComponent(0.08), range: lineRange)
                }
            }

            location += line.count + 1
        }

        textStorage.endEditing()
    }
}

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(needsDisplayUpdate),
            name: NSText.didChangeNotification,
            object: textView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(needsDisplayUpdate),
            name: NSView.boundsDidChangeNotification,
            object: textView.enclosingScrollView?.contentView
        )
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    @objc private func needsDisplayUpdate() {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let content = textView.string as NSString
        var lineNumber = 1
        content.substring(to: charRange.location).enumerateLines { _, _ in lineNumber += 1 }
        lineNumber -= 1
        if lineNumber < 1 { lineNumber = 1 }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]

        var index = charRange.location
        while index < NSMaxRange(charRange) {
            let lineRange = content.lineRange(for: NSRange(location: index, length: 0))
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            lineRect.origin.y += textView.textContainerInset.height - visibleRect.origin.y

            let lineStr = "\(lineNumber)" as NSString
            let strSize = lineStr.size(withAttributes: attrs)
            let drawPoint = NSPoint(
                x: ruleThickness - strSize.width - 6,
                y: lineRect.origin.y + (lineRect.height - strSize.height) / 2
            )
            lineStr.draw(at: drawPoint, withAttributes: attrs)

            lineNumber += 1
            index = NSMaxRange(lineRange)
        }
    }
}

// MARK: - Font Traits Helper

private extension NSFont {
    func withTraits(_ traits: NSFontTraitMask) -> NSFont? {
        NSFontManager.shared.convert(self, toHaveTrait: traits)
    }
}
