import Carbon
import Cocoa
import Combine

struct InputSourceItem: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: NSImage?
    let tisSource: TISInputSource

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: InputSourceItem, rhs: InputSourceItem) -> Bool {
        lhs.id == rhs.id
    }

    func select() {
        TISSelectInputSource(tisSource)
    }
}

final class InputSourceManager: ObservableObject {
    static let shared = InputSourceManager()

    @Published private(set) var sources: [InputSourceItem] = []
    @Published private(set) var currentSourceId: String = ""

    private init() {
        reload()
        setupNotificationObserver()
    }

    func reload() {
        sources = Self.fetchSources()
        updateCurrentSource()
    }

    func updateCurrentSource() {
        if let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() {
            currentSourceId = current.id
        }
    }

    private func setupNotificationObserver() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrentSource()
        }
    }

    static func fetchSources() -> [InputSourceItem] {
        guard let list = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        return list
            .filter { $0.category == TISInputSource.Category.keyboardInputSource && $0.isSelectable }
            .map { tisSource in
                var iconImage: NSImage? = nil

                if let url = tisSource.iconImageURL {
                    iconImage = NSImage(contentsOf: url)
                    if iconImage == nil {
                        // Try with tiff extension
                        let base = url.deletingPathExtension()
                        let retinaURL = base.appendingPathExtension("tiff")
                        iconImage = NSImage(contentsOf: retinaURL)
                    }
                }

                if iconImage == nil, let iconRef = tisSource.iconRef {
                    iconImage = InputSourceManager.image(from: iconRef)
                }

                return InputSourceItem(
                    id: tisSource.id,
                    name: tisSource.name,
                    icon: iconImage,
                    tisSource: tisSource
                )
            }
    }

    static func image(from iconRef: IconRef, size: NSSize = NSSize(width: 32, height: 32)) -> NSImage {
        return NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            var r = CGRect(origin: .zero, size: rect.size)
            let status = PlotIconRefInContext(
                ctx,
                &r,
                IconAlignmentType(kAlignAbsoluteCenter),
                IconTransformType(kTransformNone),
                nil,
                PlotIconRefFlags(kPlotIconRefNormalFlags),
                iconRef
            )
            return status == noErr
        }
    }
}
