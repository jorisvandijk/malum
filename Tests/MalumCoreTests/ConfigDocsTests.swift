import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct ConfigDocsTests {
    private let header = """
        <!-- Made from the modules' schemas by `swift run MalumDocs`. Edit the schemas, not this page. -->

        # Config reference

        Every setting `malum.toml` takes, by module. Each module's settings go in a table named after \
        the module, such as `[window_manager]`. A module is off until its table sets `enabled = true`. \
        A setting that's left out takes its default, when it has one.

        """

    @Test func noModulesSaysThereAreNoSettings() {
        #expect(
            ConfigDocs.page(for: [:]) == header + "\nNo module takes settings, so `malum.toml` has nothing to set.\n")
    }

    @Test func modulesAndSettingsAreSortedByName() {
        let schemas = [
            "window_manager": ConfigSchema(
                about: "Tiles windows.",
                settings: [
                    "gap": Setting(.integer, "Space between windows.", default: .integer(4)),
                    "floating": Setting(.strings, "Apps left alone."),
                ]),
            "launcher": ConfigSchema(about: "Opens apps.", settings: [:]),
        ]
        #expect(ConfigDocs.page(for: schemas) == header + sortedModules)
    }

    /// The page's modules for `modulesAndSettingsAreSortedByName`.
    private let sortedModules = """

        ## `launcher`

        Opens apps.

        ### `launcher.enabled`

        Switches the module on. The module stays off until this is set to true.

        - Value: true or false
        - Default: `false`

        ## `window_manager`

        Tiles windows.

        ### `window_manager.enabled`

        Switches the module on. The module stays off until this is set to true.

        - Value: true or false
        - Default: `false`

        ### `window_manager.floating`

        Apps left alone.

        - Value: a list of text

        ### `window_manager.gap`

        Space between windows.

        - Value: a whole number
        - Default: `4`

        """

    @Test func oddNamesAreQuoted() {
        let schemas = ["dock": ConfigSchema(about: "The Dock.", settings: ["app name": Setting(.string, "An app.")])]
        #expect(ConfigDocs.page(for: schemas).contains("### `dock.\"app name\"`"))
    }
}
