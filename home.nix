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

  # `jp status`: June production questions from any folder, Claude Code's `!` included
  jp = pkgs.writeShellScriptBin "jp" ''
    exec bash ${config.home.homeDirectory}/Documents/Snap/lab/prod/prod.sh "$@"
  '';

  # nixpkgs marks abctl broken on Darwin because its telemetry test suite
  # reads real free-memory stats, which the sandboxed build can't do here -
  # the binary itself builds and runs fine, so skip checks instead.
  abctl-darwin = pkgs.abctl.overrideAttrs (old: {
    doCheck = false;
    meta = old.meta // { broken = false; };
  });
  # pi isn't in nixpkgs - build it from the lockfile in pkgs/pi.
  # bump: edit the version in pkgs/pi/package.json, `npm install --package-lock-only` there
  pi = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = (builtins.fromJSON (builtins.readFile ./pkgs/pi/package.json)).dependencies."@earendil-works/pi-coding-agent";
    src = ./pkgs/pi;
    npmDeps = pkgs.importNpmLock { npmRoot = ./pkgs/pi; };
    npmConfigHook = pkgs.importNpmLock.npmConfigHook;
    dontNpmBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      mkdir -p $out/lib $out/bin
      cp -r node_modules $out/lib/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/pi \
        --add-flags $out/lib/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js
    '';
  };
  # nixpkgs trails upstream by weeks - build it from the lockfile in pkgs/gemini-cli, same as pi.
  # bump: edit the version in pkgs/gemini-cli/package.json, `npm install --package-lock-only` there
  gemini-cli = pkgs.buildNpmPackage {
    pname = "gemini-cli";
    version = (builtins.fromJSON (builtins.readFile ./pkgs/gemini-cli/package.json)).dependencies."@google/gemini-cli";
    src = ./pkgs/gemini-cli;
    npmDeps = pkgs.importNpmLock { npmRoot = ./pkgs/gemini-cli; };
    npmConfigHook = pkgs.importNpmLock.npmConfigHook;
    dontNpmBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # vertex on the org's gcp project, set here so no other tool sees these vars
    installPhase = ''
      mkdir -p $out/libexec/gemini-cli $out/bin
      cp -r node_modules $out/libexec/gemini-cli/
      # vertex auth grants preview models, which the BAA excludes; build fails if upstream moves this
      files=$(grep -l 'this.setHasAccessToPreviewModel(true);' $out/libexec/gemini-cli/node_modules/@google/gemini-cli/bundle/*.js)
      substituteInPlace $files --replace-fail 'this.setHasAccessToPreviewModel(true);' 'this.setHasAccessToPreviewModel(false);'
      # its update notice names the command that updates this install
      substituteInPlace $out/libexec/gemini-cli/node_modules/@google/gemini-cli/bundle/*.js \
        --replace-quiet "npm install -g @google/gemini-cli@latest" "~/dotfiles/rebuild.sh"
      # it only trusts an rg beside its bundle or in system dirs, never one under /nix/store on PATH
      ln -s ${pkgs.ripgrep}/bin/rg $out/libexec/gemini-cli/node_modules/@google/gemini-cli/bundle/rg-darwin-${if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x64"}
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/gemini \
        --add-flags $out/libexec/gemini-cli/node_modules/@google/gemini-cli/bundle/gemini.js \
        --set-default GOOGLE_GENAI_USE_VERTEXAI true \
        --set-default GOOGLE_CLOUD_PROJECT june-510220 \
        --set-default GOOGLE_CLOUD_LOCATION global
    '';
  };
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    ast-grep  # structural search - matches syntax trees, not lines
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    gh        # GitHub CLI - git's credential.helper for github.com shells out to this
    railway   # Railway CLI - deploy logs/status for the apps hosted there
    google-cloud-sdk # gcloud - the Vertex project, service accounts and keys June's model calls ride on
    neovim
    tree-sitter # CLI nvim-treesitter shells out to for parsers without prebuilt binaries (e.g. luadoc)
    nodejs   # node + npm
    jp
    playwright-cli # `playwright screenshot <url> <file>` - browser verification for any app, see cleardesk-technical/patterns/browser-verification.md
    playwright-mcp # browser tools over MCP - the only hands Junebug (Snap's overnight QA) has
    agent-browser # driven browser for QA - open/snapshot/click/screenshot. what /ce-dogfood runs on
    opencode  # opencode CLI
    pi        # pi coding agent CLI
    gemini-cli # Google's coding agent CLI, on Vertex in the org's gcp project
    uv        # Python package/venv manager - wshobson/agents' generator scripts shell out to `uv run`
    ngrok     # local tunnel - exposes localhost webhooks (e.g. Twilio inbound SMS) to the public internet
    twilio-cli # Twilio CLI - manage numbers/messaging, tail the debugger, from the terminal
    infisical # secrets CLI - `infisical run -- just up` injects Snap's credentials from the self-hosted instance on Railway, so backend/.env need not exist
    just # command runner - Snap's verb surface (`just up`), see Snap/justfile
    process-compose # supervises a Snap stack's processes (db, api, console, panel, tunnel)
    gitleaks  # secret scanner - Snap's pre-push hook refuses a push that carries a key
    graphviz  # `dot` - renders mingrammer/diagrams (Python) architecture diagrams
    ffmpeg    # chunks recordings and pulls frames - Riffrec capture analysis
    abctl-darwin
    tun2socks  # userspace tun->socks5: laptop half of the pairvpn-clone tunnel (utun + gvisor netstack)
    xcodegen   # generates the pairvpn-clone phone app's .xcodeproj from project.yml
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

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
      j = "just";
      gy = "gemini --yolo";
      cc = "claude --dangerously-skip-permissions --append-system-prompt-file ~/.claude/sr_opus_5_system_prompt.md";
      # cc on the okf account, same config as cc
      cc-okf = "CLAUDE_CONFIG_DIR=$HOME/.claude-okf claude --dangerously-skip-permissions --append-system-prompt-file ~/.claude/sr_opus_5_system_prompt.md";
      co = "codex --full-auto";
      # key stays in the keychain, only opencode sees it
      opencode = "OPENROUTER_API_KEY=$(security find-generic-password -ws openrouter) opencode";
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
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/CLAUDE.md";
  home.file.".claude/sr_opus_5_system_prompt.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/sr_opus_5_system_prompt.md";
  home.file.".claude/RTK.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/RTK.md";
  # okf account: own login, everything else shared with ~/.claude
  home.file.".claude-okf/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude-okf/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/CLAUDE.md";
  home.file.".claude-okf/RTK.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/RTK.md";
  home.file.".claude-okf/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.claude/skills";
  home.file.".claude-okf/plugins".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.claude/plugins";
  home.file."Library/Application Support/rtk/filters.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/rtk/filters.toml";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".gemini/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".gemini/GEMINI.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/sr_opus_5_system_prompt.md";
  home.file.".gemini/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/settings.json";
  home.file.".gemini/policies".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/policies";
  home.file.".pi/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
}
