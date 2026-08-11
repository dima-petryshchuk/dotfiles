# Basics

How this repo actually works, in plain terms.

## The one idea

`~/.config/nvim`, `~/.config/wezterm`, `~/.claude/CLAUDE.md`, etc. are not real
iles on your Mac. They are symlinks. They point back into this repo, into
`home/`. Editing `home/.config/nvim/...` here IS editing your live config.
No copying, no rebuild, no restart - just save the file.

`home.nix` is the file that creates those symlinks (`mkOutOfStoreSymlink`).
If you want a new symlink (say, a new app's config folder), add a line there.

## Two kinds of change

**1. Edit a symlinked file** (nvim config, wezterm config, AGENTS.md, claude
settings.json). Just edit it in `home/`. Done. Nothing to run.

**2. Change anything else** (install a package, change a system setting,
add a new symlink in `home.nix`, change shell aliases). Run:

```sh
./rebuild.sh
```

That's the only command you need day to day.

## Where things live

```
flake.nix        entry point: which Mac, which username, which nix packages
configuration.nix  macOS + Homebrew settings (dock, casks, cli tools)
home.nix         your user config: shell, packages, and the symlinks
home/            the REAL files, symlinked into place
  .config/nvim/    neovim config (plugins live in lua/plugins/*.lua)
  .config/wezterm/ terminal config
  .config/herdr/   herdr config
  .claude/         claude code settings
  AGENTS.md        shared instructions for claude/codex/opencode
```

## Neovim specifically

- Plugin manager is `lazy.nvim`. Every file in `home/.config/nvim/lua/plugins/`
  returns a list of plugins - lazy.nvim loads them all automatically. To add a
  plugin, add a new table to one of these files (or a new file), save,
  reopen nvim.
- `lazy-lock.json` pins exact plugin versions. It's auto-updated by nvim, you
  don't hand-edit it.
- `init.lua` just requires three lua modules (`vim_config`, `plugin`, `keys`)
  - that's the whole boot sequence.

## Mental model, one line

Everything under `home/` is truth. Everything else (`flake.nix`,
`configuration.nix`, `home.nix`) is plumbing that either symlinks that truth
into place or configures things that aren't files at all (packages, macOS
settings).
