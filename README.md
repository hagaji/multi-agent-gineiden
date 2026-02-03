# multi-agent-gineiden

**銀河英雄伝説ベースのAIエージェント統率システム**

*元帥の命令一つで、AIエージェントが戦略的に分析・提案*

## 概要

複数の Claude Code インスタンスを同時に実行し、銀河帝国の軍制のように統率するシステムです。コンサル・PM向けに、多角的な視点からの分析と提案を行います。

## 必要要件

- macOS / Linux / WSL
- [tmux](https://github.com/tmux/tmux)
- [Claude Code CLI](https://docs.anthropic.com/claude-code/)
- Anthropic API キー

## セットアップ

### 1. 初回セットアップ

```bash
./first_setup.sh
```

このスクリプトは以下を自動で行います:
- tmux のインストール確認
- Claude Code CLI のインストール確認
- 必要なディレクトリの作成
- 実行権限の設定

### 2. エージェント起動

```bash
./shutsugeki.sh
```

オプション:
```bash
./shutsugeki.sh -s    # セットアップのみ（Claude起動なし）
./shutsugeki.sh -h    # ヘルプ表示
```

## 使い方

### 基本フロー

1. **出撃** - `./shutsugeki.sh` でエージェントを起動
2. **命令** - 副官（gineiden セッション）に命令を入力
3. **待機** - エージェントが自動で分析・提案を作成
4. **確認** - `dashboard.md` で進捗を確認
5. **判断** - 副官からの最終報告を元に意思決定

### tmux セッション操作

```bash
# 副官セッションに接続
tmux attach -t gineiden

# マルチエージェントセッションに接続
tmux attach -t multiagent

# セッション一覧
tmux ls

# セッション切り替え（tmux内）
Ctrl+b s
```

### ペイン構成

**gineiden セッション:**
- ペイン0: 副官（キルヒアイス型）

**multiagent セッション:**
- ペイン0: 大将A（ミッターマイヤー型）
- ペイン1: 大将B（ロイエンタール型）
- ペイン2: 参謀（オーベルシュタイン型）

## システム構成

```
      元帥（あなた）
           │
           ▼ 命令
    ┌─────────────────┐
    │    副官          │  キルヒアイス型
    │   (Fukukan)      │  命令分配・最終報告
    └────────┬────────┘
             │
     ┌───────┴───────┐
     ▼               ▼
┌─────────┐   ┌─────────┐
│  大将A  │   │  大将B  │
│ミッター │   │ロイエン │
│マイヤー │   │タール型 │
│ 堅実案  │   │ 挑戦案  │
└────┬────┘   └────┬────┘
     │               │
     └───────┬───────┘
             ▼
    ┌─────────────────┐
    │    参謀          │  オーベルシュタイン型
    │   (Sanbo)        │  冷徹なレビュー
    └────────┬────────┘
             │
             ▼
        副官へ報告
             │
             ▼
        元帥へ最終報告
```

## 役割詳細

| 役職 | モデル | 特徴 |
|------|--------|------|
| 副官 | キルヒアイス | 温和・誠実、バランス感覚 |
| 大将A | ミッターマイヤー | 堅実・保守的、リスク最小化 |
| 大将B | ロイエンタール | 革新的・挑戦的、ハイリターン |
| 参謀 | オーベルシュタイン | 冷徹・論理的、正論で指摘 |

## スキル

エージェントが活用する補助スキル。

| スキル | 用途 |
|--------|------|
| `/keikaku` | 戦略立案・計画策定 |
| `/kensho` | 提案の品質検証 |
| `/gakushu` | 知見の抽出・蓄積 |
| `/checkpoint` | 進捗記録・状態保存 |

詳細は [skills/README.md](skills/README.md) を参照。

## ファイル構成

```
multi-agent-gineiden/
├── README.md              # このファイル
├── CLAUDE.md              # エージェント用プロジェクト説明
├── shutsugeki.sh          # 起動スクリプト
├── first_setup.sh         # 初回セットアップ
├── instructions/          # エージェント指示書
│   ├── fukukan.md
│   ├── taisho_a.md
│   ├── taisho_b.md
│   └── sanbo.md
├── skills/                # 補助スキル
│   ├── keikaku/          # 計画スキル
│   ├── kensho/           # 検証スキル
│   ├── gakushu/          # 学習スキル
│   └── checkpoint/       # チェックポイント
├── config/
│   └── settings.yaml      # システム設定
├── queue/                 # 通信ファイル
│   ├── gensui_to_fukukan.yaml
│   ├── fukukan_to_taisho.yaml
│   └── reports/
├── templates/             # テンプレート
├── dashboard.md           # 状況一覧
└── memory/                # 記憶保存
```

## トラブルシューティング

### セッションが見つからない

```bash
# セッション確認
tmux ls

# 再起動
tmux kill-server
./shutsugeki.sh
```

### エージェントが応答しない

1. `dashboard.md` で状態確認
2. 該当ペインに接続して確認
3. 必要に応じて再起動

## ライセンス

MIT

---

*銀河の歴史がまた1ページ*
