#!/usr/bin/env bash
# cmux-setup: cmux のテーマ / サイドバー / starship プロンプトを一括セットアップする
# 何度実行しても同じ結果になる（既に正しくリンク済みのものはスキップ）
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
STAMP="$(date +%Y%m%d%H%M%S)"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
MARK_BEGIN='# >>> cmux-setup >>>'
MARK_END='# <<< cmux-setup <<<'

info() { printf '\033[38;2;97;255;202m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;249;42;173m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[38;2;249;42;173m[error]\033[0m %s\n' "$*" >&2; exit 1; }

backup() {
  local path=$1
  mv "$path" "$path.bak-$STAMP"
  echo "  backup  $path -> $path.bak-$STAMP"
}

link() {
  local src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
    echo "  ok      $dst"
    return
  fi
  if [[ -e $dst || -L $dst ]]; then
    backup "$dst"
  fi
  ln -s "$src" "$dst"
  echo "  linked  $dst -> $src"
}

# --- 前提チェック -------------------------------------------------------------
[[ $(uname -s) == Darwin ]] || die "macOS 専用です"
[[ -d /Applications/cmux.app ]] || warn "/Applications/cmux.app が見つかりません（設定は配置しますが、cmux のインストールが必要です）"

if ! command -v brew >/dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x $b ]] && eval "$("$b" shellenv)" && break
  done
fi
command -v brew >/dev/null 2>&1 || die "Homebrew が必要です: https://brew.sh"

# --- starship -----------------------------------------------------------------
info "starship"
if command -v starship >/dev/null 2>&1; then
  echo "  ok      $(starship --version | head -1)"
else
  brew install starship
fi

# --- 設定ファイル（シンボリックリンク） -----------------------------------------
info "config files"
link "$REPO_DIR/ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
link "$REPO_DIR/cmux/cmux.json"         "$HOME/.config/cmux/cmux.json"
link "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# --- ~/.zshrc -----------------------------------------------------------------
info "zshrc ($ZSHRC)"
touch "$ZSHRC"
zshrc_backed_up=false
backup_zshrc_once() {
  if ! $zshrc_backed_up; then
    cp "$ZSHRC" "$ZSHRC.bak-$STAMP"
    echo "  backup  $ZSHRC -> $ZSHRC.bak-$STAMP"
    zshrc_backed_up=true
  fi
}

# oh-my-zsh のテーマは starship とプロンプト/precmd を奪い合うので無効化する
if grep -qE '^ZSH_THEME="[^"]+"' "$ZSHRC"; then
  backup_zshrc_once
  LC_ALL=C sed -i '' -E 's|^ZSH_THEME="([^"]+)".*$|ZSH_THEME=""  # cmux-setup: disabled for starship (was: \1)|' "$ZSHRC"
  echo "  set     ZSH_THEME=\"\""
fi

# 末尾（oh-my-zsh 読み込み後）に source 行を追加する
if grep -qF "$MARK_BEGIN" "$ZSHRC"; then
  # リポジトリを移動した場合に備えてパスを更新する
  if ! grep -qF "source \"$REPO_DIR/zsh/cmux-prompt.zsh\"" "$ZSHRC"; then
    backup_zshrc_once
    LC_ALL=C sed -i '' "/^$MARK_BEGIN\$/,/^$MARK_END\$/d" "$ZSHRC"
  else
    echo "  ok      source line already present"
  fi
fi
if ! grep -qF "$MARK_BEGIN" "$ZSHRC"; then
  backup_zshrc_once
  printf '\n%s\n[[ -f "%s" ]] && source "%s"\n%s\n' \
    "$MARK_BEGIN" "$REPO_DIR/zsh/cmux-prompt.zsh" "$REPO_DIR/zsh/cmux-prompt.zsh" "$MARK_END" >> "$ZSHRC"
  echo "  added   source $REPO_DIR/zsh/cmux-prompt.zsh"
fi

# ブロック外で starship を初期化していると二重登録になる
if LC_ALL=C sed "/^$MARK_BEGIN\$/,/^$MARK_END\$/d" "$ZSHRC" | grep -q 'starship init zsh'; then
  warn "$ZSHRC に cmux-setup 以外の 'starship init zsh' があります。二重初期化になるので削除してください"
fi

zsh -n "$ZSHRC" || die "$ZSHRC に構文エラーがあります（バックアップ: $ZSHRC.bak-$STAMP）"

info "done"
cat <<EOF

  次の手順で反映してください:
    1. cmux で Cmd+Shift+, （設定の再読み込み）
    2. 開いているタブで exec zsh （または新しいタブを開く）

EOF
