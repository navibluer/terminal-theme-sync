#!/opt/homebrew/bin/bash
# Master theme switcher — 一鍵同步切換 Ghostty + tmux + Starship + nvim
# 當前 active 狀態寫在 ~/.config/active-theme（horizon / tokyo-night / gruvbox）
#
# 觸發：tmux 綁 `prefix + T` 呼叫此腳本
#
# 各組件如何生效：
#   - Ghostty  : 翻 symlink active.conf → 新主題；**需按 Cmd+Shift+, 重載**
#   - tmux     : source-file 新主題 conf → 立即生效
#   - Starship : 翻 ~/.config/starship.toml symlink → 下個 prompt 即時生效
#   - nvim     : 廣播 :colorscheme 給所有 listening nvim instance（~/.cache/nvim/sockets/*.sock）
#                未開的 nvim 下次啟動會讀 active-theme 自動套上
#   - Claude   : 用 dark-ansi，動態讀 terminal ANSI；Ghostty 重載後當前 session 即時跟上，免重啟

set -euo pipefail

state_file="$HOME/.config/active-theme"
ghostty_themes="$HOME/.config/ghostty/themes"
tmux_themes="$HOME/.config/tmux/themes"
starship_themes="$HOME/.config/starship"
starship_active="$HOME/.config/starship.toml"

# 三主題輪替：horizon → tokyo-night → gruvbox → horizon → ...
current="$(cat "$state_file" 2>/dev/null || echo "horizon")"
case "$current" in
  "horizon")     next="tokyo-night" ;;
  "tokyo-night") next="gruvbox" ;;
  "gruvbox")     next="horizon" ;;
  *)             next="horizon" ;;
esac

echo "$next" > "$state_file"

# 1. Ghostty: 翻 symlink
ln -sf "$ghostty_themes/$next.conf" "$ghostty_themes/active.conf"

# 2. Starship: 翻 symlink → 各主題完整定義 directory / git_branch / character 識別色
ln -sf "$starship_themes/$next.toml" "$starship_active"

# 3. tmux: 立即套新主題（只有在 tmux session 內才會成功）
if [ -n "${TMUX:-}" ] || tmux info >/dev/null 2>&1; then
  tmux source-file "$tmux_themes/$next.conf" 2>/dev/null || true
  tmux display-message "Theme → $next (Ghostty: Cmd+Shift+,)"
fi

# 4. nvim: 對所有 listener socket 廣播 :colorscheme（外部主題名 → nvim colorscheme 名）
case "$next" in
  "horizon")     nvim_cs="horizon" ;;
  "tokyo-night") nvim_cs="tokyonight" ;;
  "gruvbox")     nvim_cs="gruvbox" ;;
esac
shopt -s nullglob
for sock in "$HOME"/.cache/nvim/sockets/*.sock; do
  [ -S "$sock" ] || continue
  nvim --server "$sock" --remote-expr "execute('colorscheme $nvim_cs')" >/dev/null 2>&1 || true
done
shopt -u nullglob

echo "Theme switched to: $next"
echo "  Ghostty   : Cmd+Shift+, 重載（或關閉重開視窗）"
echo "  Starship  : 下個 prompt 即時生效"
echo "  tmux      : 已即時套用"
echo "  nvim      : 已 broadcast :colorscheme 給所有運行中的 instance"
echo "  Claude    : dark-ansi 動態吃 ANSI，Ghostty 重載後即時跟上（免重啟 session）"
