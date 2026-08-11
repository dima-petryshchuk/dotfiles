{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  # pkgs.playwright ships no bin/ (it's the raw npm package, meant for other
  # nix derivations to consume) - wrap its cli.js ourselves and point it at
  # nix-built browsers (pkgs.playwright-driver.browsers) so there's no npx
  # cache and no runtime browser download, ever.
  playwright-cli = pkgs.writeShellScriptBin "playwright" ''
    export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
    exec ${pkgs.nodejs}/bin/node ${pkgs.playwright}/cli.js "$@"
  '';
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    gh        # GitHub CLI - git's credential.helper for github.com shells out to this
    railway   # Railway CLI - deploy logs/status for the apps hosted there
    neovim
    tree-sitter # CLI nvim-treesitter shells out to for parsers without prebuilt binaries (e.g. luadoc)
    nodejs   # node + npm
    playwright-cli # `playwright screenshot <url> <file>` - browser verification for any app, see cleardesk-technical/patterns/browser-verification.md
    opencode  # opencode CLI
    ollama    # run LLMs locally
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  # Keeps `ollama serve` running in the background so opencode's local
  # provider (see home/.config/opencode/opencode.jsonc) always has
  # something to talk to at localhost:11434.
  launchd.agents.ollama = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ollama.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ollama.log";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".config/opencode/opencode.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/opencode.jsonc";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
