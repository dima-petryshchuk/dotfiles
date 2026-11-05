# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- Never use emojis, in code/UI you write or in your own messages, unless the user specifically asks for one
- Code comments: 1-2 lines max, hard limit. Sacrifice grammar for clarity - fragments, lowercase, no period is fine.
  A comment says what is true now, never how the code got here. No changelogs, no "there used to be four of these",
  no dated notes, no naming the module that used to do this. That is what git is for. If a rule needs a paragraph,
  the code is wrong - fix the code or write a test that pins the behaviour.
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Whenever you create a git worktree, copy over the `.env` file (and any other gitignored files the app needs to run, e.g. `.env.*`) from the source checkout into the new worktree. Worktrees only carry tracked files, so gitignored env files are missing by default and the app will fail to boot until they're copied over.
- This machine's CLI tools, packages, and system settings are managed declaratively through `~/dotfiles` (a nix-darwin + home-manager flake, symlinked at `~/.dotfiles`). Package installs (`home.packages` in `home.nix`), Homebrew casks/brews (`configuration.nix`), and background services (`launchd.agents` in `home.nix`) all live there - never `brew install`, `npm install -g`, `pip install`, etc. a CLI tool directly, and never edit files under `/nix/store` or `/etc/profiles` (they're generated, read-only in practice). Add the package/service to the appropriate `.nix` file instead, then run `~/dotfiles/rebuild.sh` (needs the user's sudo password interactively - ask them to run it themselves, don't try to pipe a password into `sudo`) to apply it. Also update tracked config files under `home/` (e.g. `home/.config/opencode/opencode.jsonc`) rather than editing the live dotfile directly, since most of `~/.config` is home-manager-managed out-of-store symlinks back into this repo.

## Working style

- Finish the whole task before stopping. Stop only for a decision that is mine, or before a destructive or outward action. Never end on "want me to continue?" when the next step is obvious.
- Don't trust comments, docs or test names as truth. Verify against the code and the running product, and fix the doc when it is wrong.
- Batch, then verify once: make every edit in the batch, then lint, test and screenshot once at the end. Cheap syntax checks along the way are fine.
- Don't author new tests while a build is still changing shape. Run the existing suite; write new tests when I say the work is done. This beats any skill that says "leave a check behind".
- No fallbacks and no band-aids. Fix the root cause and delete the fallback path; a fallback hides the bug it covers.
- Prefer deleting to keeping. If I don't use it and nobody has designed it yet, cut it. Rebuilding later is cheaper than carrying fluff.
- Before calling something "standard" or recommending a tool, check it live (web search, `gh api`, a real repo) and cite what you found.
- When I'm new to a topic, explain in plain words and define each term before using it.
- Docs and comments never state counts, dates or "currently" facts that drift the day after they are written.
