#!/opt/homebrew/bin/bash
# tmux 啟動時載入當前 active theme
# state 讀自統一檔 ~/.config/active-theme（由 ~/.config/switch-theme.sh 維護）
# 對應 theme conf 在 ~/.config/tmux/themes/<theme>.conf
set -euo pipefail

state_file="$HOME/.config/active-theme"
themes_dir="$HOME/.config/tmux/themes"

if [ ! -f "$state_file" ]; then
  echo "horizon" > "$state_file"
fi

theme="$(cat "$state_file")"
conf="$themes_dir/$theme.conf"

if [ -f "$conf" ]; then
  tmux source-file "$conf"
else
  tmux display-message "Theme not found: $theme"
fi
