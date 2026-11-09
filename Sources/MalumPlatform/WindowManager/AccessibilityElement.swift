import ApplicationServices
import CoreGraphics
import Foundation

/// Typed reads and writes of one Accessibility element's attributes.
struct AccessibilityElement {
    /// The element.
    let element: AXUIElement

    /// The value of `attribute`, or nil when the element doesn't answer.
    func value(_ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    /// The text in `attribute`, or nil.
    func string(_ attribute: String) -> String? {
        value(attribute) as? String
    }

    /// The true or false in `attribute`, or nil.
    func bool(_ attribute: String) -> Bool? {
        value(attribute) as? Bool
    }

    /// The elements in `attribute`, or nil.
    func elements(_ attribute: String) -> [AXUIElement]? {
        value(attribute) as? [AXUIElement]
    }

    /// The point in `attribute`, or nil.
    func point(_ attribute: String) -> CGPoint? {
        var point = CGPoint.zero
        guard let value = axValue(attribute), AXValueGetValue(value, .cgPoint, &point) else { return nil }
        return point
    }

    /// The size in `attribute`, or nil.
    func size(_ attribute: String) -> CGSize? {
        var size = CGSize.zero
        guard let value = axValue(attribute), AXValueGetValue(value, .cgSize, &size) else { return nil }
        return size
    }

    /// Whether `attribute` can be changed.
    func isSettable(_ attribute: String) -> Bool {
        var settable: DarwinBoolean = false
        guard AXUIElementIsAttributeSettable(element, attribute as CFString, &settable) == .success else {
            return false
        }
        return settable.boolValue
    }

    /// Sets `attribute` to `value`.
    func set(_ attribute: String, _ value: Bool) {
        AXUIElementSetAttributeValue(element, attribute as CFString, value as CFTypeRef)
    }

    /// Sets `attribute` to the point `point`.
    func set(_ attribute: String, point: CGPoint) {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return }
        AXUIElementSetAttributeValue(element, attribute as CFString, value)
    }

    /// Sets `attribute` to the size `size`.
    func set(_ attribute: String, size: CGSize) {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(element, attribute as CFString, value)
    }

    /// The `AXValue` in `attribute`, or nil when it holds something else.
    private func axValue(_ attribute: String) -> AXValue? {
        guard let value = value(attribute), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return unsafeDowncast(value, to: AXValue.self)
    }
}
