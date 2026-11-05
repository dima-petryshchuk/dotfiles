#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
nix flake update --flake "$DIR"
# gemini-cli rides npm, not the flake - pin its latest release before building
(cd "$DIR/pkgs/gemini-cli" &&
	npm pkg set "dependencies.@google/gemini-cli=$(npm view @google/gemini-cli version)" &&
	npm install --package-lock-only --ignore-scripts --silent)

LOG_DIR="$DIR/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/rebuild-$(date +%Y%m%d-%H%M%S).log"

dock_state() {
	echo "--- $(date '+%H:%M:%S') Dock agent ---"
	launchctl print "gui/$(id -u)/com.apple.Dock.agent" 2>&1 | grep -E "state|last exit code|runs ="
	echo "--- Caskroom ---"
	ls /opt/homebrew/Caskroom/ 2>&1
}

{
	echo "=== rebuild start $(date) ==="
	dock_state
	echo "=== darwin-rebuild switch ==="
	sudo darwin-rebuild switch --flake ~/.dotfiles#mac
	echo "=== darwin-rebuild done $(date) ==="
	dock_state
	echo "=== rebuild end $(date) ==="
} 2>&1 | tee "$LOG"

# nix-darwin's activation kills Dock and expects launchd to auto-respawn it;
# on this machine that respawn reliably fails, so kick it back to life.
if ! pgrep -qf "CoreServices/Dock.app"; then
	echo "Dock didn't come back after activation, kickstarting it..." | tee -a "$LOG"
	launchctl kickstart -k "gui/$(id -u)/com.apple.Dock.agent"
fi

echo "log: $LOG"
