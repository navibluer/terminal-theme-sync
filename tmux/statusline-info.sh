#!/opt/homebrew/bin/bash
# tmux status line 的 cwd + git 雙 pill 片段（coralline 風格）
# 由 themes/*.conf 的 status-right 以 #() 呼叫；主題色用參數傳入，腳本本身不含色票
#
# 用法：statusline-info.sh <pane_path> <dir_bg> <git_ok_bg> <git_dirty_bg> <text_fg> <bar_bg>
# 色碼為 hex「不含 #」（避免在 tmux format 字串中與 # 特殊字元衝突），由本腳本補上
set -euo pipefail

path="${1:-}"
dir_bg="#${2}"
git_ok_bg="#${3}"
git_dirty_bg="#${4}"
text_fg="#${5}"
bar_bg="#${6}"

CAP_L=$(printf '\xee\x82\xb6')   # U+E0B6 左圓角端蓋
CAP_R=$(printf '\xee\x82\xb4')   # U+E0B4 右圓角端蓋
SEP=$(printf '\xee\x82\xb0')     # U+E0B0 powerline 分隔

# --- cwd：$HOME → ~，深度 > 4 時摺疊成 前兩層/…/最後一層 ---
short="${path/#$HOME/\~}"
IFS='/' read -r -a parts <<< "$short"
n=${#parts[@]}
if (( n > 4 )); then
  short="${parts[0]}/${parts[1]}/…/${parts[n-1]}"
fi

# --- git：單次 status 呼叫取 branch + 髒污標記（+ staged / ! unstaged / ? untracked）---
branch="" marks="" oid="" head="" staged=0 unstaged=0 untracked=0
while IFS= read -r line; do
  case "$line" in
    "# branch.oid "*)  oid="${line#\# branch.oid }" ;;
    "# branch.head "*) head="${line#\# branch.head }" ;;
    "? "*)             untracked=1 ;;
    [12]" "*)          [ "${line:2:1}" != "." ] && staged=1
                       [ "${line:3:1}" != "." ] && unstaged=1 ;;
    "u "*)             unstaged=1 ;;
  esac
done < <(git -C "$path" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null || true)

if [ -n "$oid" ]; then
  if [ -z "$head" ] || [ "$head" = "(detached)" ]; then
    branch="${oid:0:7}"
  else
    branch="$head"
  fi
  [ "$staged" -eq 1 ]    && marks="${marks}+"
  [ "$unstaged" -eq 1 ]  && marks="${marks}!"
  [ "$untracked" -eq 1 ] && marks="${marks}?"
fi

# --- 輸出：cwd pill（+ 可選 git pill），非 git 目錄時 git pill 整顆消失 ---
out="#[fg=${dir_bg},bg=${bar_bg}]${CAP_L}#[bg=${dir_bg},fg=${text_fg},bold] ${short} #[nobold]"
if [ -n "$branch" ]; then
  git_bg="$git_ok_bg"
  [ -n "$marks" ] && git_bg="$git_dirty_bg"
  out+="#[fg=${dir_bg},bg=${git_bg}]${SEP}#[bg=${git_bg},fg=${text_fg},bold] ⎇ ${branch}${marks} #[nobold]#[fg=${git_bg},bg=${bar_bg}]${CAP_R}"
else
  out+="#[fg=${dir_bg},bg=${bar_bg}]${CAP_R}"
fi
printf '%s' "$out"
