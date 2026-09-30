# cmux-setup

[cmux](https://cmux.com/) の見た目とシェルプロンプトを、どの Mac でも一発で揃えるための設定リポジトリ。

- 黒背景 + ネオン（Aura ベース）のターミナル配色
- ネオンパープルのサイドバー、ワークスペースごとのネオン左レール
- [starship](https://starship.rs/) プロンプト（フルパス表示・毎秒更新の時計）
- コマンド完了ごとに `[完了時刻] [cost 秒] コマンド` を表示（成功=ミント / 失敗=ピンク）

## セットアップ

前提: macOS、[cmux](https://cmux.com/) と [Homebrew](https://brew.sh) がインストール済み、シェルは zsh。

```sh
git clone https://github.com/otajisan/cmux-setup.git ~/cmux-setup && ~/cmux-setup/install.sh
```

完了後、cmux で `Cmd+Shift+,`（設定の再読み込み）を押し、開いているタブで `exec zsh` を実行する。

## install.sh がやること

| 対象 | 内容 |
|---|---|
| starship | 未インストールなら `brew install starship` |
| `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` | `ghostty/config.ghostty` へのシンボリックリンク（配色・フォント） |
| `~/.config/cmux/cmux.json` | `cmux/cmux.json` へのシンボリックリンク（サイドバー・外観） |
| `~/.config/starship.toml` | `starship/starship.toml` へのシンボリックリンク |
| `~/.zshrc` | `ZSH_THEME` を `""` に変更（oh-my-zsh 利用時）し、末尾に `zsh/cmux-prompt.zsh` の `source` ブロックを追加 |

- 既存ファイルは `*.bak-<日時>` に退避してから置き換える
- 何度実行しても安全（リンク済み・追記済みのものはスキップ）
- `.zshrc` 本体は管理しない（Mac ごとの設定はそのまま残る）

## 設定の変更・同期

設定ファイルはすべてこのリポジトリへのシンボリックリンクなので、リポジトリ内のファイルを編集してコミットすればよい。他の Mac では `git pull` するだけで反映される。

リポジトリを別の場所へ移動した場合は、移動先で `install.sh` を再実行するとリンクと `source` 行が張り替わる。

## 元に戻す

1. `~/.zshrc` の `# >>> cmux-setup >>>` 〜 `# <<< cmux-setup <<<` を削除し、`ZSH_THEME` を元に戻す
2. 各設定ファイルのシンボリックリンクを削除し、必要なら `*.bak-<日時>` を元の名前に戻す
