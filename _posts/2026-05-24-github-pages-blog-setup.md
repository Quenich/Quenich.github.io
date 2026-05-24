---
title: "GitHub Pages + Jekyll（Chirpy）で無料ブログを作る方法【Windows向け完全マニュアル】"
date: 2026-05-24 00:00:00 +0000
categories: [ブログ, チュートリアル]
tags: [GitHub Pages, Jekyll, Chirpy, Windows, ブログ構築]
---

GitHub Pages と Jekyll（Chirpy テーマ）を使って、完全無料でブログを公開するまでの手順をまとめます。サーバー代ゼロ、セキュリティも堅牢、記事は Markdown で書けます。

## 必要なもの

- Windows PC
- GitHub アカウント（無料）
- Git（インストール済みであること）

---

## Step 1: Ruby 3.3 をインストール

Jekyll は Ruby で動くため、まず Ruby をインストールします。

1. [https://rubyinstaller.org/downloads/](https://rubyinstaller.org/downloads/) を開く
2. **Ruby+Devkit 3.3.X (x64)** をダウンロード
3. インストーラーを実行
   - **"Add Ruby executables to your PATH"** にチェックが入っていることを確認
   - 完了後、MSYS2 の黒い画面が開いたら **Enter** を押す（デフォルト設定でOK）

> **注意**: Ruby 4.x は Chirpy テーマと互換性がありません。必ず **3.3.x** をインストールしてください。

インストール後、**新しいターミナルを開いて**確認します：

```bash
ruby --version
# ruby 3.3.x と表示されればOK
```

---

## Step 2: Jekyll をインストール

```bash
gem install jekyll bundler
jekyll --version
# jekyll 4.x と表示されればOK
```

---

## Step 3: GitHub でリポジトリを作成

1. [https://github.com/cotes2020/chirpy-starter](https://github.com/cotes2020/chirpy-starter) を開く
2. **"Use this template"** → **"Create a new repository"** をクリック
3. リポジトリ名を **`<あなたのGitHubユーザー名>.github.io`** にする
4. **Public** を選択して **"Create repository"** をクリック

---

## Step 4: ローカルにクローン

```bash
git clone https://github.com/<ユーザー名>/<ユーザー名>.github.io.git
cd <ユーザー名>.github.io
bundle install
```

`bundle install` は数分かかります。

---

## Step 5: 基本設定を編集

`_config.yml` を開いて以下の項目を編集します：

```yaml
lang: ja                          # 言語を日本語に変更
timezone: Asia/Tokyo              # タイムゾーンを設定

title: "ブログ名"                  # ブログのタイトル
tagline: "サブタイトル"            # サブタイトル
description: >-
  ブログの説明                     # SEO に使われる説明文

url: "https://<ユーザー名>.github.io"  # 自分の URL に変更

github:
  username: <ユーザー名>           # GitHub ユーザー名

social:
  name: "あなたの名前"
  email: your@email.com
  links:
    - https://github.com/<ユーザー名>
```

編集後、ファイルを保存します。

---

## Step 6: ローカルで確認

```bash
bundle exec jekyll serve --future
```

ブラウザで `http://localhost:4000` を開いてブログが表示されれば成功です。

> `_config.yml` を変更した場合は **Ctrl+C** でサーバーを停止してから再起動してください。

---

## Step 7: 最初の記事を書く

`_posts/` フォルダに以下の形式でファイルを作成します：

**ファイル名**: `YYYY-MM-DD-タイトル.md`

```markdown
---
title: "はじめての投稿"
date: 2026-05-24 00:00:00 +0000
categories: [カテゴリ]
tags: [タグ1, タグ2]
---

## 見出し

本文をここに書きます。

Markdown 記法が使えます。
```

> **日付について**: `date` は UTC で指定します。日本時間（JST）の場合は9時間引いた時刻か、`+0000` で UTC 時刻を指定してください。

---

## Step 8: GitHub にプッシュ

```bash
git add .
git commit -m "ブログ初期設定・最初の記事追加"
git push
```

---

## Step 9: GitHub Pages の公開設定

1. `https://github.com/<ユーザー名>/<ユーザー名>.github.io/settings/pages` を開く
2. **Source** を **"GitHub Actions"** に変更して Save

数分後、`https://github.com/<ユーザー名>/<ユーザー名>.github.io/actions` でビルドが完了（緑のチェックマーク）したら公開完了です。

---

## 記事の追加方法（日常的な運用）

記事を書くたびに以下の流れを繰り返すだけです：

1. `_posts/` に `YYYY-MM-DD-タイトル.md` を作成
2. Front Matter（`---` で囲まれた冒頭部分）を書く
3. 本文を Markdown で書く
4. プッシュする

```bash
git add .
git commit -m "記事追加: 記事タイトル"
git push
```

---

## セキュリティ設定（必須）

GitHub アカウントの乗っ取りを防ぐため、**2要素認証（2FA）を必ず有効化**してください。

1. GitHub の **Settings → Password and authentication** を開く
2. **Two-factor authentication** を有効化
3. 認証アプリ（Google Authenticator など）を設定

---

## まとめ

| 項目 | 内容 |
|------|------|
| ホスティング費用 | 無料 |
| ドメイン | `<ユーザー名>.github.io`（無料） |
| SSL/HTTPS | 自動（無料） |
| 記事の書き方 | Markdown |
| デプロイ | `git push` するだけ |
| セキュリティ | サーバーレスのため攻撃面が極小 |

静的サイトなのでデータベースや PHP は存在せず、SQL インジェクションや不正ログインのリスクがありません。GitHub のインフラで動くため、サーバー管理も不要です。
