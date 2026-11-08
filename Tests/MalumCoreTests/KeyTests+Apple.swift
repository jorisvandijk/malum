#if canImport(Carbon)
    import Carbon
    import IOKit.hid
    import Testing

    @testable import MalumCore

    /// The key table checked against Apple's own names for the codes, on macOS only.
    extension KeyTests {
        /// Each key's codes by its name: its `kVK_` constant and its `kHIDUsage_` constant on the keyboard page. fn
        /// is on Apple's vendor pages, which have no public constant, so its usage isn't checked here.
        private static let apple: [String: (keyCode: Int, usage: Int?)] = [
            "a": (kVK_ANSI_A, kHIDUsage_KeyboardA), "b": (kVK_ANSI_B, kHIDUsage_KeyboardB),
            "c": (kVK_ANSI_C, kHIDUsage_KeyboardC), "d": (kVK_ANSI_D, kHIDUsage_KeyboardD),
            "e": (kVK_ANSI_E, kHIDUsage_KeyboardE), "f": (kVK_ANSI_F, kHIDUsage_KeyboardF),
            "g": (kVK_ANSI_G, kHIDUsage_KeyboardG), "h": (kVK_ANSI_H, kHIDUsage_KeyboardH),
            "i": (kVK_ANSI_I, kHIDUsage_KeyboardI), "j": (kVK_ANSI_J, kHIDUsage_KeyboardJ),
            "k": (kVK_ANSI_K, kHIDUsage_KeyboardK), "l": (kVK_ANSI_L, kHIDUsage_KeyboardL),
            "m": (kVK_ANSI_M, kHIDUsage_KeyboardM), "n": (kVK_ANSI_N, kHIDUsage_KeyboardN),
            "o": (kVK_ANSI_O, kHIDUsage_KeyboardO), "p": (kVK_ANSI_P, kHIDUsage_KeyboardP),
            "q": (kVK_ANSI_Q, kHIDUsage_KeyboardQ), "r": (kVK_ANSI_R, kHIDUsage_KeyboardR),
            "s": (kVK_ANSI_S, kHIDUsage_KeyboardS), "t": (kVK_ANSI_T, kHIDUsage_KeyboardT),
            "u": (kVK_ANSI_U, kHIDUsage_KeyboardU), "v": (kVK_ANSI_V, kHIDUsage_KeyboardV),
            "w": (kVK_ANSI_W, kHIDUsage_KeyboardW), "x": (kVK_ANSI_X, kHIDUsage_KeyboardX),
            "y": (kVK_ANSI_Y, kHIDUsage_KeyboardY), "z": (kVK_ANSI_Z, kHIDUsage_KeyboardZ),
            "0": (kVK_ANSI_0, kHIDUsage_Keyboard0), "1": (kVK_ANSI_1, kHIDUsage_Keyboard1),
            "2": (kVK_ANSI_2, kHIDUsage_Keyboard2), "3": (kVK_ANSI_3, kHIDUsage_Keyboard3),
            "4": (kVK_ANSI_4, kHIDUsage_Keyboard4), "5": (kVK_ANSI_5, kHIDUsage_Keyboard5),
            "6": (kVK_ANSI_6, kHIDUsage_Keyboard6), "7": (kVK_ANSI_7, kHIDUsage_Keyboard7),
            "8": (kVK_ANSI_8, kHIDUsage_Keyboard8), "9": (kVK_ANSI_9, kHIDUsage_Keyboard9),
            "f1": (kVK_F1, kHIDUsage_KeyboardF1), "f2": (kVK_F2, kHIDUsage_KeyboardF2),
            "f3": (kVK_F3, kHIDUsage_KeyboardF3), "f4": (kVK_F4, kHIDUsage_KeyboardF4),
            "f5": (kVK_F5, kHIDUsage_KeyboardF5), "f6": (kVK_F6, kHIDUsage_KeyboardF6),
            "f7": (kVK_F7, kHIDUsage_KeyboardF7), "f8": (kVK_F8, kHIDUsage_KeyboardF8),
            "f9": (kVK_F9, kHIDUsage_KeyboardF9), "f10": (kVK_F10, kHIDUsage_KeyboardF10),
            "f11": (kVK_F11, kHIDUsage_KeyboardF11), "f12": (kVK_F12, kHIDUsage_KeyboardF12),
            "f13": (kVK_F13, kHIDUsage_KeyboardF13), "f14": (kVK_F14, kHIDUsage_KeyboardF14),
            "f15": (kVK_F15, kHIDUsage_KeyboardF15), "f16": (kVK_F16, kHIDUsage_KeyboardF16),
            "f17": (kVK_F17, kHIDUsage_KeyboardF17), "f18": (kVK_F18, kHIDUsage_KeyboardF18),
            "f19": (kVK_F19, kHIDUsage_KeyboardF19), "f20": (kVK_F20, kHIDUsage_KeyboardF20),
            "return": (kVK_Return, kHIDUsage_KeyboardReturnOrEnter), "tab": (kVK_Tab, kHIDUsage_KeyboardTab),
            "space": (kVK_Space, kHIDUsage_KeyboardSpacebar),
            "delete": (kVK_Delete, kHIDUsage_KeyboardDeleteOrBackspace),
            "delete_forward": (kVK_ForwardDelete, kHIDUsage_KeyboardDeleteForward),
            "escape": (kVK_Escape, kHIDUsage_KeyboardEscape),
            "left": (kVK_LeftArrow, kHIDUsage_KeyboardLeftArrow),
            "right": (kVK_RightArrow, kHIDUsage_KeyboardRightArrow),
            "up": (kVK_UpArrow, kHIDUsage_KeyboardUpArrow), "down": (kVK_DownArrow, kHIDUsage_KeyboardDownArrow),
            "home": (kVK_Home, kHIDUsage_KeyboardHome), "end": (kVK_End, kHIDUsage_KeyboardEnd),
            "page_up": (kVK_PageUp, kHIDUsage_KeyboardPageUp),
            "page_down": (kVK_PageDown, kHIDUsage_KeyboardPageDown),
            "minus": (kVK_ANSI_Minus, kHIDUsage_KeyboardHyphen),
            "equal": (kVK_ANSI_Equal, kHIDUsage_KeyboardEqualSign),
            "open_bracket": (kVK_ANSI_LeftBracket, kHIDUsage_KeyboardOpenBracket),
            "close_bracket": (kVK_ANSI_RightBracket, kHIDUsage_KeyboardCloseBracket),
            "backslash": (kVK_ANSI_Backslash, kHIDUsage_KeyboardBackslash),
            "semicolon": (kVK_ANSI_Semicolon, kHIDUsage_KeyboardSemicolon),
            "quote": (kVK_ANSI_Quote, kHIDUsage_KeyboardQuote),
            "grave": (kVK_ANSI_Grave, kHIDUsage_KeyboardGraveAccentAndTilde),
            "comma": (kVK_ANSI_Comma, kHIDUsage_KeyboardComma), "period": (kVK_ANSI_Period, kHIDUsage_KeyboardPeriod),
            "slash": (kVK_ANSI_Slash, kHIDUsage_KeyboardSlash),
            "non_us_backslash": (kVK_ISO_Section, kHIDUsage_KeyboardNonUSBackslash),
            "caps_lock": (kVK_CapsLock, kHIDUsage_KeyboardCapsLock), "fn": (kVK_Function, nil),
            "left_control": (kVK_Control, kHIDUsage_KeyboardLeftControl),
            "right_control": (kVK_RightControl, kHIDUsage_KeyboardRightControl),
            "left_shift": (kVK_Shift, kHIDUsage_KeyboardLeftShift),
            "right_shift": (kVK_RightShift, kHIDUsage_KeyboardRightShift),
            "left_option": (kVK_Option, kHIDUsage_KeyboardLeftAlt),
            "right_option": (kVK_RightOption, kHIDUsage_KeyboardRightAlt),
            "left_command": (kVK_Command, kHIDUsage_KeyboardLeftGUI),
            "right_command": (kVK_RightCommand, kHIDUsage_KeyboardRightGUI),
        ]

        @Test func everyKeyHasApplesCodes() {
            #expect(Set(Self.apple.keys) == Set(Key.all.map(\.name)))
            for (name, codes) in Self.apple {
                let key = Key.named(name)
                #expect(key.map { Int($0.keyCode) } == codes.keyCode, "\(name)")
                guard let usage = codes.usage else { continue }
                let paged = (UInt64(kHIDPage_KeyboardOrKeypad) << 32) | UInt64(usage)
                #expect(key?.hidUsages == [paged], "\(name)")
            }
        }
    }
#endif
