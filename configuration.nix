{
  user,
  nixpkgs-unstable,
  ...
}:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      # unstable's node_modules hash for 2.2.5 does not match what bun fetches on darwin; pin the fetched one
      opencode = nixpkgs-unstable.legacyPackages.${prev.system}.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs { outputHash = "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc="; };
      });
      # >= 1.116: older ones wedge a process when a `process logs` reader hangs up mid-backlog
      process-compose = nixpkgs-unstable.legacyPackages.${prev.system}.process-compose;
      # railway/iac needs CLI >= 5.42.1, ahead of nixpkgs unstable - bump to upstream release
      railway = nixpkgs-unstable.legacyPackages.${prev.system}.railway.overrideAttrs (old: rec {
        version = "5.63.1";
        src = old.src.override { rev = "v${version}"; hash = "sha256-2VL7TDbjkSH92ayk68miyXhIa3mYpWN6TPwAJT9jR/k="; };
        cargoDeps = prev.rustPlatform.fetchCargoVendor { inherit src; hash = "sha256-6WVbstup2Y0mu+ah7XqAnn+EEF2TL3nv7kNsPT4RIHA="; };
        doCheck = false; # cloud_agent tests write to $HOME and spawn local tools, sandbox blocks both
      });
    })
  ];
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;   # keep casks/brews current on rebuild
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
      "postgresql@16"
      "rtk"
      "wget"
    ];
    casks = [
      "wezterm"
      "claude-code@latest"
      "ollama-app" # official build ships libmlx, which nix ollama lacks (nvfp4 models need it); runs its own server on :11434
    ];
    masApps = {
      Xcode = 497799835; # installed via mas; needs App Store sign-in
    };
  };
}
