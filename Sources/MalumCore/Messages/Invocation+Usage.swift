/// The help text.
extension Invocation {
    /// How to use the command, as `--help` shows it.
    public static let usage = """
        usage: \(Project.command) [--version | --help]
               \(Project.command) init <path to dots>
               \(Project.command) reload
               \(Project.command) safe
               \(Project.command) disable <module>
               \(Project.command) permissions
               \(Project.command) run [--force]
               \(Project.command) rollback
               \(Project.command) status
               \(Project.command) token [--remove]

          init         record where dots is checked out and link ~/\(Paths.binRoot)/\(Project.command)
          reload       ask the running app to reload
          safe         keep every module off until you leave safe mode from the menu bar
          disable      keep one module off until you enable it from the menu bar
          permissions  check that this terminal has Full Disk Access
          run          make the Mac match dots, then update \(Project.name) to its latest release
                       (--force installs it even when it's older)
          rollback     put back the version of \(Project.name) the last update replaced
          status       show what \(Project.name) manages and what doesn't match dots
          token        ask for the GitHub token and keep it in the login keychain
                       (--remove deletes it)
          --version    show the version
          --help       show this help
        """
}

extension Invocation {
    /// What `disable` needs when it's given nothing.
    static let needsModule = "a module"
    /// What `init` needs when it's given nothing.
    static let needsDots = "the path to dots"
}
