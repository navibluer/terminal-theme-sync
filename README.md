# terminal-theme-sync

一鍵同步切換 **Ghostty + tmux + Starship + nvim** 主題的整套設定，內建三個主題：
`horizon` · `tokyo-night` · `gruvbox`。

tmux status line 採 [coralline](https://github.com/Nanako0129/coralline) 風格的 powerline pills：
左側 session 徽章 + prefix 指示燈，中間視窗 pills，右側顯示 active pane 的
**cwd + git branch（乾淨綠 / 髒橘，`+!?` = staged / unstaged / untracked）+ 時鐘**。

## 需求

- macOS + Homebrew `bash`（腳本 shebang 為 `/opt/homebrew/bin/bash`）
- tmux ≥ 3.2、git
- Nerd Font 終端字型（powerline 端蓋與 icon）
- Ghostty、Starship；nvim 為選用（見下）

## 安裝

```bash
git clone https://github.com/navibluer/terminal-theme-sync
cd terminal-theme-sync
cp switch-theme.sh ~/.config/
cp -R tmux ghostty starship ~/.config/      # 與既有 ~/.config/{tmux,ghostty,starship} 合併
chmod +x ~/.config/switch-theme.sh ~/.config/tmux/*.sh
echo "horizon" > ~/.config/active-theme     # 初始主題狀態
~/.config/switch-theme.sh                   # 跑一次建立 active symlinks
```

**Ghostty** 設定檔加一行（路徑須為絕對路徑）：

```
config-file = /Users/<你>/.config/ghostty/themes/active.conf
```

**`~/.tmux.conf`** 加兩行：

```tmux
bind T run-shell "~/.config/switch-theme.sh"
# 放在檔案最後（若有 TPM，須在 TPM 初始化之後，讓主題覆蓋 plugin 樣式）
run-shell '~/.config/tmux/load-theme.sh'
```

**Starship** 免設定：切換器直接翻 `~/.config/starship.toml` symlink。

**nvim（選用）**：裝好 `horizon` / `tokyonight` / `gruvbox` colorscheme，並讓 instance 在
`~/.cache/nvim/sockets/*.sock` 開 listen socket，切換時會自動廣播 `:colorscheme`；
沒有 socket 時自動跳過，無副作用。

## 使用

- tmux 內按 **`prefix + T`** 輪替：horizon → tokyo-night → gruvbox → horizon
  - tmux / Starship / nvim 立即生效；Ghostty 需按 `Cmd+Shift+,` 重載
- 改輪替順序或加主題：編輯 `switch-theme.sh` 的 case 區塊，並在三個 `themes/` 目錄補上同名設定檔
- status line 的 cwd / git 每 5 秒（`status-interval`）隨 active pane 更新

## 結構

```
switch-theme.sh            # 主切換器：翻 symlink + 寫狀態檔 + 廣播
tmux/
  load-theme.sh            # tmux 啟動時載入 active 主題
  statusline-info.sh       # cwd + git pill 渲染（主題色由 conf 傳參，腳本不含色票）
  themes/*.conf            # 各主題完整 status line 定義（自給自足，不依賴 plugin）
ghostty/themes/*.conf      # Ghostty 色票（active.conf symlink 指向其一）
starship/*.toml            # 各主題 Starship prompt（~/.config/starship.toml symlink 指向其一）
```

狀態檔 `~/.config/active-theme` 是唯一真相，內容為當前主題名。
