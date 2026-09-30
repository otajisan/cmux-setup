# cmux-setup: starship プロンプト + passion テーマ相当の時刻表示
# install.sh が ~/.zshrc の末尾（oh-my-zsh 読み込み後）から source する

command -v starship >/dev/null 2>&1 || return 0

eval "$(starship init zsh)"

# コマンド完了ごとに [完了時刻] [cost 秒] コマンド を表示
zmodload zsh/datetime
autoload -Uz add-zsh-hook
__cmdlog_preexec() {
  __cmdlog_start=$EPOCHREALTIME
  __cmdlog_cmd=$1
}
__cmdlog_precmd() {
  [[ -z $__cmdlog_start ]] && return
  local cost=$(( EPOCHREALTIME - __cmdlog_start ))
  # starship の precmd が先に走るため、終了コードはそちらが保存した値を使う
  local cmd_color='97;255;202'
  (( ${STARSHIP_CMD_STATUS:-0} != 0 )) && cmd_color='249;42;173'
  # print -P はコマンド文字列内の $() を再評価しうるので、生の ANSI で出力する
  print -r -- $'\e[38;2;54;249;246m'"[$(strftime '%H:%M:%S' $EPOCHSECONDS)] [cost $(printf '%.3f' $cost)s]"$'\e[0m '$'\e[38;2;'"${cmd_color}m${__cmdlog_cmd}"$'\e[0m'
  unset __cmdlog_start __cmdlog_cmd
}
add-zsh-hook preexec __cmdlog_preexec
add-zsh-hook precmd __cmdlog_precmd

# プロンプトの時刻を毎秒更新（TRAPALRM を定義すると TMOUT は自動ログアウトではなく SIGALRM になる）
# 補完メニューや入力途中で再描画すると崩れるため、入力前/Enter 直後だけ更新する
TRAPALRM() {
  if [[ -z $WIDGET || $WIDGET == accept-line ]]; then
    zle reset-prompt
  fi
}
TMOUT=1
