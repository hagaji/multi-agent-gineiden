#!/bin/bash
# ============================================================
# first_setup.sh - 銀河英雄伝説マルチエージェント 初回セットアップ
# Ubuntu / WSL / Mac 用環境構築ツール
# ============================================================

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RESULTS=()
HAS_ERROR=false

echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  銀河英雄伝説マルチエージェント インストーラー                 ║"
echo "  ║  multi-agent-gineiden Initial Setup                          ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  インストール先: $SCRIPT_DIR"
echo ""

# ============================================================
# STEP 1: システム環境チェック
# ============================================================
log_step "STEP 1: システム環境チェック"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    log_info "OS: $NAME $VERSION_ID"
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
    log_info "環境: WSL"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    log_info "環境: macOS"
else
    log_info "環境: Linux"
fi

RESULTS+=("システム環境: OK")

# ============================================================
# STEP 2: tmux チェック
# ============================================================
log_step "STEP 2: tmux チェック"

if command -v tmux &> /dev/null; then
    TMUX_VERSION=$(tmux -V | awk '{print $2}')
    log_success "tmux がインストール済みです (v$TMUX_VERSION)"
    RESULTS+=("tmux: OK (v$TMUX_VERSION)")
else
    log_warn "tmux がインストールされていません"
    if command -v apt-get &> /dev/null; then
        read -p "  tmux をインストールしますか? [Y/n]: " REPLY
        REPLY=${REPLY:-Y}
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get update -qq && sudo apt-get install -y tmux
            RESULTS+=("tmux: インストール完了")
        fi
    elif command -v brew &> /dev/null; then
        read -p "  tmux をインストールしますか? [Y/n]: " REPLY
        REPLY=${REPLY:-Y}
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install tmux
            RESULTS+=("tmux: インストール完了")
        fi
    else
        log_error "パッケージマネージャが見つかりません。手動でtmuxをインストールしてください"
        RESULTS+=("tmux: 未インストール")
        HAS_ERROR=true
    fi
fi

# ============================================================
# STEP 3: Node.js チェック
# ============================================================
log_step "STEP 3: Node.js チェック"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    log_success "Node.js がインストール済みです ($NODE_VERSION)"
    RESULTS+=("Node.js: OK ($NODE_VERSION)")
else
    log_warn "Node.js がインストールされていません"
    log_info "nvm を使用してインストールすることを推奨します"
    echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
    echo "  source ~/.bashrc && nvm install 20"
    RESULTS+=("Node.js: 未インストール")
    HAS_ERROR=true
fi

# ============================================================
# STEP 4: Claude Code CLI チェック
# ============================================================
log_step "STEP 4: Claude Code CLI チェック"

if command -v claude &> /dev/null; then
    log_success "Claude Code CLI がインストール済みです"
    RESULTS+=("Claude Code CLI: OK")
else
    log_warn "Claude Code CLI がインストールされていません"
    if command -v npm &> /dev/null; then
        read -p "  今すぐインストールしますか? [Y/n]: " REPLY
        REPLY=${REPLY:-Y}
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            npm install -g @anthropic-ai/claude-code
            RESULTS+=("Claude Code CLI: インストール完了")
        fi
    else
        log_error "npm がインストールされていません"
        RESULTS+=("Claude Code CLI: 未インストール")
        HAS_ERROR=true
    fi
fi

# ============================================================
# STEP 5: ディレクトリ構造作成
# ============================================================
log_step "STEP 5: ディレクトリ構造作成"

DIRECTORIES=(
    "queue/tasks"
    "queue/reports"
    "config"
    "instructions"
    "memory"
    "context"
    "templates"
    "skills"
    "logs"
)

for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
        mkdir -p "$SCRIPT_DIR/$dir"
        log_info "作成: $dir/"
    fi
done

RESULTS+=("ディレクトリ構造: OK")

# ============================================================
# STEP 6: 設定ファイル初期化
# ============================================================
log_step "STEP 6: 設定ファイル確認"

if [ ! -f "$SCRIPT_DIR/config/settings.yaml" ]; then
    cat > "$SCRIPT_DIR/config/settings.yaml" << 'EOF'
# 銀河英雄伝説マルチエージェント 設定ファイル

# 言語設定
language: ja

# ログ設定
logging:
  level: info
  path: "./logs/"
EOF
    log_success "settings.yaml を作成しました"
fi

if [ ! -f "$SCRIPT_DIR/memory/global_context.md" ]; then
    cat > "$SCRIPT_DIR/memory/global_context.md" << 'EOF'
# グローバルコンテキスト
最終更新: (未設定)

## システム方針
- コンサル・PM向けの戦略分析支援

## 決定事項
- (決定事項をここに記載)

## 注意事項
- (注意点をここに記載)
EOF
    log_success "global_context.md を作成しました"
fi

RESULTS+=("設定ファイル: OK")

# ============================================================
# STEP 7: 実行権限設定
# ============================================================
log_step "STEP 7: 実行権限設定"

for script in shutsugeki.sh first_setup.sh; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        chmod +x "$SCRIPT_DIR/$script"
        log_info "$script に実行権限を付与しました"
    fi
done

RESULTS+=("実行権限: OK")

# ============================================================
# 結果サマリー
# ============================================================
echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  セットアップ結果サマリー                                     ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""

for result in "${RESULTS[@]}"; do
    if [[ $result == *"未インストール"* ]] || [[ $result == *"失敗"* ]]; then
        echo -e "  ${RED}✗${NC} $result"
    else
        echo -e "  ${GREEN}✓${NC} $result"
    fi
done

echo ""

if [ "$HAS_ERROR" = true ]; then
    echo "  ⚠️  一部の依存関係が不足しています"
else
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║  ✅ セットアップ完了！                                       ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
fi

echo ""
echo "  次のステップ:"
echo "  ┌──────────────────────────────────────────────────────────────┐"
echo "  │  出陣（全エージェント起動）:                                  │"
echo "  │     ./shutsugeki.sh                                          │"
echo "  └──────────────────────────────────────────────────────────────┘"
echo ""
echo "  ════════════════════════════════════════════════════════════════"
echo "   銀河の歴史がまた1ページ..."
echo "  ════════════════════════════════════════════════════════════════"
echo ""

if [ "$HAS_ERROR" = true ]; then
    exit 1
fi
