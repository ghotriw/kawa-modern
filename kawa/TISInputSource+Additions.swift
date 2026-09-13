import Carbon
import Cocoa

extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }

    private func getProperty(_ key: CFString) -> AnyObject? {
        guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
    }

    var id: String {
        return (getProperty(kTISPropertyInputSourceID) as? String) ?? ""
    }

    var name: String {
        return (getProperty(kTISPropertyLocalizedName) as? String) ?? id
    }

    var category: String {
        return (getProperty(kTISPropertyInputSourceCategory) as? String) ?? ""
    }

    var isSelectable: Bool {
        return (getProperty(kTISPropertyInputSourceIsSelectCapable) as? Bool) ?? false
    }

    var iconImageURL: URL? {
        return getProperty(kTISPropertyIconImageURL) as? URL
    }

    var iconRef: IconRef? {
        guard let ptr = TISGetInputSourceProperty(self, kTISPropertyIconRef) else { return nil }
        return OpaquePointer(ptr)
    }
}
