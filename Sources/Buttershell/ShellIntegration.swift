import Foundation

enum ShellIntegration {
    private static var integrationDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Buttershell/Zsh", isDirectory: true)
    }

    static func environment(for shell: String, suggestions: [String]) -> [String] {
        var environment = ProcessInfo.processInfo.environment
        environment["TERM"] = "xterm-256color"
        environment["COLORTERM"] = "truecolor"
        if environment["LANG"] == nil { environment["LANG"] = "en_US.UTF-8" }

        guard URL(fileURLWithPath: shell).lastPathComponent == "zsh" else {
            return environment.map { "\($0.key)=\($0.value)" }
        }

        let originalZdotdir = environment["ZDOTDIR"] ?? NSHomeDirectory()
        guard let wrapper = prepareZsh(suggestions: suggestions) else {
            return environment.map { "\($0.key)=\($0.value)" }
        }
        environment["ZDOTDIR"] = wrapper.path
        environment["BUTTERSHELL_USER_ZDOTDIR"] = originalZdotdir
        environment["BUTTERSHELL_WRAPPER_ZDOTDIR"] = wrapper.path
        return environment.map { "\($0.key)=\($0.value)" }
    }

    private static func prepareZsh(suggestions: [String]) -> URL? {
        let directory = integrationDirectory
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            let integration = directory.appendingPathComponent("integration.zsh")
            try integrationSource(suggestions: suggestions).write(to: integration, atomically: true, encoding: .utf8)

            for file in [".zshenv", ".zprofile", ".zshrc", ".zlogin"] {
                var source = "export ZDOTDIR=\"$BUTTERSHELL_USER_ZDOTDIR\"\n"
                source += "if [[ -r \"$ZDOTDIR/\(file)\" ]]; then source \"$ZDOTDIR/\(file)\"; fi\n"
                source += "export BUTTERSHELL_USER_ZDOTDIR=\"$ZDOTDIR\"\n"
                source += "export ZDOTDIR=\"$BUTTERSHELL_WRAPPER_ZDOTDIR\"\n"
                if file == ".zshrc" {
                    source += "source \"$ZDOTDIR/integration.zsh\"\n"
                }
                try source.write(to: directory.appendingPathComponent(file), atomically: true, encoding: .utf8)
            }
            return directory
        } catch {
            return nil
        }
    }

    private static func integrationSource(suggestions: [String]) -> String {
        let commands = suggestions.map { "  \"\(escapeZshDoubleQuotes($0))\"" }.joined(separator: "\n")
        return """
        # Buttershell's integration is kept in Application Support; user dotfiles stay untouched.
        typeset -ga _BUTTERSHELL_STARTERS
        _BUTTERSHELL_STARTERS=(
        \(commands)
        )

        autoload -Uz add-zsh-hook
        autoload -Uz add-zle-hook-widget
        zmodload -i zsh/zleparameter 2>/dev/null
        if (( ! $+_comps )); then
          autoload -Uz compinit
          compinit -i -C
        fi

        _buttershell_report_directory() {
          local path="${PWD:A}"
          path="${path// /%20}"
          printf '\\e]7;file://%s%s\\a' "${HOST%%:*}" "$path"
        }
        add-zsh-hook chpwd _buttershell_report_directory
        add-zsh-hook precmd _buttershell_report_directory

        _buttershell_suggest() {
          POSTDISPLAY=''
          [[ -n "$BUFFER" ]] || return
          local candidate
          for candidate in "${_BUTTERSHELL_STARTERS[@]}"; do
            if [[ "$candidate" == "$BUFFER"* && "$candidate" != "$BUFFER" ]]; then
              POSTDISPLAY="${candidate#$BUFFER}"
              return
            fi
          done
          [[ "$BUFFER" != *' '* ]] || return
          for candidate in ${(k)commands}; do
            if [[ "$candidate" == "$BUFFER"* && "$candidate" != "$BUFFER" ]]; then
              POSTDISPLAY="${candidate#$BUFFER}"
              return
            fi
          done
        }

        _buttershell_accept_suggestion() {
          if [[ -n "$POSTDISPLAY" && $CURSOR -eq ${#BUFFER} ]]; then
            BUFFER+="$POSTDISPLAY"
            CURSOR=${#BUFFER}
            POSTDISPLAY=''
          else
            zle .forward-char
          fi
        }
        add-zle-hook-widget line-pre-redraw _buttershell_suggest
        zle -N _buttershell_accept_suggestion
        bindkey '^[[C' _buttershell_accept_suggestion
        """
    }

    private static func escapeZshDoubleQuotes(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")
    }
}
