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
               \(Project.command) run
               \(Project.command) status

          init         record where dots is checked out and link ~/.local/bin/\(Project.command)
          reload       ask the running app to reload
          safe         keep every module off until you leave safe mode from the menu bar
          disable      keep one module off until you enable it from the menu bar
          permissions  check that this terminal has Full Disk Access
          run          make the Mac match dots: install the packages it lists
          status       show what \(Project.name) manages and what doesn't match dots
          --version    show the version
          --help       show this help
        """
}
