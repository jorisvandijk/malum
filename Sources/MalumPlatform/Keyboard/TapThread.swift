import CoreGraphics
import Foundation
import MalumCore

/// One event tap and the thread it runs on, from creating the tap until it's stopped.
///
/// The callback runs on the tap's own thread with its own run loop, so a busy main actor never slows
/// typing. It hands each event to the session and carries out its decision. It does no
/// Accessibility work or I/O and never logs.
final class TapThread: @unchecked Sendable {  // SAFETY: port, runLoop and stopped are only used under lock.
    /// The events the tap catches.
    private static let events: [CGEventType] = [.keyDown, .keyUp, .flagsChanged]
    /// The bit an event type's raw value shifts into a mask.
    private static let typeBit: CGEventMask = 1

    /// Decides what to do with each event.
    private let session: TapSession
    /// Guards what the callback and `stop` share across threads.
    private let lock = NSLock()
    /// The tap, until it's stopped.
    private var port: CFMachPort?
    /// The run loop of the tap's thread, once it runs.
    private var runLoop: CFRunLoop?
    /// Whether `stop` was called, so a thread that starts late doesn't run.
    private var stopped = false

    /// A tap that hands its events to `session`.
    init(session: TapSession) {
        self.session = session
    }

    /// Whether the tap is catching keys. macOS switches it off for good when Accessibility is taken away.
    var isRunning: Bool {
        lock.withLock { port.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }
    }

    /// Creates the tap and starts its thread. False when macOS refuses the tap, which means
    /// Accessibility is missing.
    func start() -> Bool {
        let mask = Self.events.reduce(CGEventMask()) { $0 | Self.typeBit << CGEventMask($1.rawValue) }
        // The callback gets `self` unretained. It stays alive while callbacks arrive: they only come
        // inside the run loop, and `run()` holds a strong reference until that loop stops.
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard
            let port = CGEvent.tapCreate(
                tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask,
                callback: tapCallback, userInfo: context)
        else { return false }
        lock.withLock { self.port = port }
        let thread = Thread { [weak self] in self?.run() }
        thread.qualityOfService = .userInteractive
        thread.start()
        return true
    }

    /// Stops the tap and its thread, and lets go of whatever it held.
    func stop() {
        lock.withLock {
            stopped = true
            if let port {
                CGEvent.tapEnable(tap: port, enable: false)
                CFMachPortInvalidate(port)
            }
            if let runLoop {
                CFRunLoopStop(runLoop)
            }
            port = nil
            runLoop = nil
        }
        letGo(session.end())
    }

    /// What to send on in place of `event`, or nil to drop it.
    fileprivate func handle(_ type: CGEventType, _ event: CGEvent) -> CGEvent? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            switchBackOn()
            letGo(session.decide(.switchedOff))
            return event
        case .keyDown, .keyUp:
            guard !SyntheticKeys.isOwn(event) else { return event }
            return carryOut(session.decide(.key(press(type, event))), on: event)
        case .flagsChanged:
            guard !SyntheticKeys.isOwn(event) else { return event }
            return carryOut(session.decide(.modifiersChanged(Modifier.held(in: event.flags))), on: event)
        default:
            return event
        }
    }

    /// Runs the tap's run loop on this thread until `stop`.
    private func run() {
        let loop = CFRunLoopGetCurrent()
        let source: CFRunLoopSource? = lock.withLock {
            guard !stopped, let port else { return nil }
            runLoop = loop
            return CFMachPortCreateRunLoopSource(nil, port, 0)
        }
        guard let source else { return }
        CFRunLoopAddSource(loop, source, .commonModes)
        CFRunLoopRun()
    }

    /// Switches the tap back on after macOS switched it off for being slow, unless it was stopped.
    private func switchBackOn() {
        lock.withLock {
            guard let port else { return }
            CGEvent.tapEnable(tap: port, enable: true)
        }
    }

    /// Carries out `decision` for `event`: what to send on in its place, or nil to drop it.
    private func carryOut(_ decision: TapDecision, on event: CGEvent) -> CGEvent? {
        switch decision {
        case .pass:
            return event
        case .passAs(let modifiers):
            event.flags = Modifier.flags(event.flags, holding: modifiers)
            return event
        case .swallow, .run:
            return nil
        case .openSwitcher(let modifiers):
            SyntheticKeys.openSwitcher(modifiers)
            return nil
        case .closeSwitcher:
            SyntheticKeys.closeSwitcher()
            return nil
        }
    }

    /// Closes the app switcher when `decision`, from letting go of everything, says it's still open.
    private func letGo(_ decision: TapDecision) {
        guard decision == .closeSwitcher else { return }
        SyntheticKeys.closeSwitcher()
    }

    /// The key press in `event`, a key-down when `type` is one.
    private func press(_ type: CGEventType, _ event: CGEvent) -> KeyPress {
        KeyPress(
            keyCode: UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode)),
            isDown: type == .keyDown,
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
            modifiers: Modifier.held(in: event.flags))
    }
}

/// What macOS calls for each event, on the tap's thread, with the `TapThread` as `context`.
private func tapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, context: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let context else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<TapThread>.fromOpaque(context).takeUnretainedValue()
    return tap.handle(type, event).map { Unmanaged.passUnretained($0) }
}
