#!/bin/bash
# ============================================================
# 銀河英雄伝説マルチエージェント 出陣スクリプト
# multi-agent-gineiden Deployment Script
# ============================================================
# 使用方法:
#   ./shutsugeki.sh           # 全エージェント起動（通常）
#   ./shutsugeki.sh -s        # セットアップのみ（Claude起動なし）
#   ./shutsugeki.sh -h        # ヘルプ表示
# ============================================================

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 言語設定を読み取り（デフォルト: ja）
LANG_SETTING="ja"
if [ -f "./config/settings.yaml" ]; then
    LANG_SETTING=$(grep "^language:" ./config/settings.yaml 2>/dev/null | awk '{print $2}' || echo "ja")
fi

# 色付きログ関数（銀河帝国風）
log_info() {
    echo -e "\033[1;33m【情報】\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m【完了】\033[0m $1"
}

log_war() {
    echo -e "\033[1;31m【作戦】\033[0m $1"
}

# プロンプト生成関数
generate_prompt() {
    local label="$1"
    local color="$2"
    local color_code
    case "$color" in
        red)     color_code="1;31" ;;
        green)   color_code="1;32" ;;
        yellow)  color_code="1;33" ;;
        blue)    color_code="1;34" ;;
        magenta) color_code="1;35" ;;
        cyan)    color_code="1;36" ;;
        *)       color_code="1;37" ;;
    esac
    echo "(\[\033[${color_code}m\]${label}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ "
}

# ═══════════════════════════════════════════════════════════════════════════════
# オプション解析
# ═══════════════════════════════════════════════════════════════════════════════
SETUP_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--setup-only)
            SETUP_ONLY=true
            shift
            ;;
        -h|--help)
            echo ""
            echo "  銀河英雄伝説マルチエージェント 出陣スクリプト"
            echo ""
            echo "使用方法: ./shutsugeki.sh [オプション]"
            echo ""
            echo "オプション:"
            echo "  -s, --setup-only    tmuxセッションのセットアップのみ（Claude起動なし）"
            echo "  -h, --help          このヘルプを表示"
            echo ""
            echo "例:"
            echo "  ./shutsugeki.sh              # 全エージェント起動"
            echo "  ./shutsugeki.sh -s           # セットアップのみ"
            echo ""
            exit 0
            ;;
        *)
            echo "不明なオプション: $1"
            echo "./shutsugeki.sh -h でヘルプを表示"
            exit 1
            ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════════════════
# 出陣バナー表示
# ═══════════════════════════════════════════════════════════════════════════════
show_battle_cry() {
    clear
    echo ""
    echo -e "\033[1;33m╔══════════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║\033[0m                                                                                  \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m   \033[1;37m██████╗ ██╗███╗   ██╗███████╗██╗██████╗ ███████╗███╗   ██╗\033[0m                    \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m   \033[1;37m██╔════╝ ██║████╗  ██║██╔════╝██║██╔══██╗██╔════╝████╗  ██║\033[0m                    \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m   \033[1;37m██║  ███╗██║██╔██╗ ██║█████╗  ██║██║  ██║█████╗  ██╔██╗ ██║\033[0m                    \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m   \033[1;37m██║   ██║██║██║╚██╗██║██╔══╝  ██║██║  ██║██╔══╝  ██║╚██╗██║\033[0m                    \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m   \033[1;37m╚██████╔╝██║██║ ╚████║███████╗██║██████╔╝███████╗██║ ╚████║\033[0m                    \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m   \033[1;37m ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝\033[0m                    \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m                                                                                  \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m            \033[1;36m銀 河 英 雄 伝 説   マルチエージェントシステム\033[0m                      \033[1;33m║\033[0m"
    echo -e "\033[1;33m║\033[0m                                                                                  \033[1;33m║\033[0m"
    echo -e "\033[1;33m╠══════════════════════════════════════════════════════════════════════════════════╣\033[0m"
    echo -e "\033[1;33m║\033[0m                    \033[1;35m「 銀河の歴史がまた1ページ 」\033[0m                                \033[1;33m║\033[0m"
    echo -e "\033[1;33m╚══════════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""

    # 布陣図
    echo -e "\033[1;34m  ╔═════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;34m  ║\033[0m                         \033[1;37m【 帝 国 軍 布 陣 図 】\033[0m                            \033[1;34m║\033[0m"
    echo -e "\033[1;34m  ╚═════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "                            \033[1;33m┌─────────────┐\033[0m"
    echo -e "                            \033[1;33m│   元 帥     │\033[0m  ← 人間（命令者）"
    echo -e "                            \033[1;33m│  (Gensui)   │\033[0m"
    echo -e "                            \033[1;33m└──────┬──────┘\033[0m"
    echo -e "                                   │"
    echo -e "                            \033[1;35m┌──────▼──────┐\033[0m     \033[1;33m┌─────────────────┐\033[0m"
    echo -e "                            \033[1;35m│   副 官     │\033[0m◀───▶\033[1;33m│   秘 書 官      │\033[0m"
    echo -e "                            \033[1;35m│ (Fukukan)   │\033[0m     \033[1;33m│  (Hishokan)     │\033[0m"
    echo -e "                            \033[1;35m│キルヒアイス型│\033[0m     \033[1;33m│  ヒルダ型(改善) │\033[0m"
    echo -e "                            \033[1;35m└──────┬──────┘\033[0m     \033[1;33m└─────────────────┘\033[0m"
    echo -e "                     ┌──────────────┼──────────────┐"
    echo -e "              \033[1;32m┌──────▼──────┐\033[0m       \033[1;31m┌──────▼──────┐\033[0m       \033[1;34m┌──────▼──────┐\033[0m"
    echo -e "              \033[1;32m│   大将A     │\033[0m       \033[1;31m│   大将B     │\033[0m       \033[1;34m│   中 将     │\033[0m"
    echo -e "              \033[1;32m│ミッターマイヤー│\033[0m      \033[1;31m│ロイエンタール│\033[0m      \033[1;34m│  ミュラー   │\033[0m"
    echo -e "              \033[1;32m│  (堅実)     │\033[0m       \033[1;31m│  (挑戦)     │\033[0m       \033[1;34m│  (調査)     │\033[0m"
    echo -e "              \033[1;32m└──────┬──────┘\033[0m       \033[1;31m└──────┬──────┘\033[0m       \033[1;34m└──────┬──────┘\033[0m"
    echo -e "                     └──────────────┬──────────────┘              │"
    echo -e "                            \033[1;36m┌──────▼──────┐\033[0m              │"
    echo -e "                            \033[1;36m│   参 謀     │\033[0m◀─────────────┘"
    echo -e "                            \033[1;36m│  (Sanbo)    │\033[0m  ← オーベルシュタイン型"
    echo -e "                            \033[1;36m└─────────────┘\033[0m"
    echo ""
    echo -e "                    \033[1;36m「 我が征くは星の大海！ 」\033[0m"
    echo ""
}

# バナー表示実行
show_battle_cry

echo -e "  \033[1;33m作戦開始！陣形を構築いたします\033[0m"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1: 既存セッションクリーンアップ
# ═══════════════════════════════════════════════════════════════════════════════
log_info "既存の陣を撤収中..."
tmux kill-session -t multiagent 2>/dev/null && log_info "  └─ multiagent陣、撤収完了" || log_info "  └─ multiagent陣は存在せず"
tmux kill-session -t gineiden 2>/dev/null && log_info "  └─ gineiden本陣、撤収完了" || log_info "  └─ gineiden本陣は存在せず"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2: キューファイルリセット
# ═══════════════════════════════════════════════════════════════════════════════
log_info "前回の軍議記録を破棄中..."

# queue ディレクトリが存在しない場合は作成
[ -d ./queue/reports ] || mkdir -p ./queue/reports
[ -d ./queue/tasks ] || mkdir -p ./queue/tasks

# 元帥→副官 キューファイルリセット
cat > ./queue/gensui_to_fukukan.yaml << 'EOF'
queue: []
EOF

# 副官→大将 キューファイルリセット
cat > ./queue/fukukan_to_taisho.yaml << 'EOF'
command: null
EOF

# 大将A提案ファイルリセット
cat > ./queue/reports/taisho_a_proposal.yaml << 'EOF'
proposal:
  id: null
  timestamp: null
  from: taisho_a
  approach: conservative
  summary: null
  status: idle
EOF

# 大将B提案ファイルリセット
cat > ./queue/reports/taisho_b_proposal.yaml << 'EOF'
proposal:
  id: null
  timestamp: null
  from: taisho_b
  approach: innovative
  summary: null
  status: idle
EOF

# 参謀評価ファイルリセット
cat > ./queue/reports/sanbo_evaluation.yaml << 'EOF'
evaluation:
  id: null
  timestamp: null
  from: sanbo
  status: idle
  proposal_a_evaluation: null
  proposal_b_evaluation: null
EOF

# 中将命令ファイルリセット
cat > ./queue/fukukan_to_chujou.yaml << 'EOF'
command: null
sanbo_review: false
EOF

# 中将報告ファイルリセット
cat > ./queue/reports/chujou_report.yaml << 'EOF'
report:
  id: null
  timestamp: null
  from: chujou
  type: investigation
  status: idle
  command_summary: null
  conclusion: null
EOF

# 秘書官改善報告ファイルリセット
cat > ./queue/reports/hishokan_kaizen.yaml << 'EOF'
kaizen:
  id: null
  timestamp: null
  from: hishokan
  trigger: null
  status: idle
  analysis: null
  modifications: null
EOF

log_success "陣払い完了"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3: ダッシュボード初期化
# ═══════════════════════════════════════════════════════════════════════════════
log_info "戦況報告板を初期化中..."
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

cat > ./dashboard.md << EOF
# 銀河英雄伝説 戦況報告
最終更新: ${TIMESTAMP}

## 現在の命令
なし

## 進行状況

### 副官（Fukukan）- キルヒアイス型
状態: 待機中

### 大将A（ミッターマイヤー型）
状態: 待機中
提案: なし

### 大将B（ロイエンタール型）
状態: 待機中
提案: なし

### 中将（ミュラー型）
状態: 待機中
報告: なし

### 参謀（オーベルシュタイン型）
状態: 待機中
評価: なし

### 秘書官（ヒルダ型）
状態: 待機中
最終改善: なし

## 最終報告
なし

---
*銀河の歴史がまた1ページ*
EOF

log_success "ダッシュボード初期化完了"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: tmux チェック
# ═══════════════════════════════════════════════════════════════════════════════
if ! command -v tmux &> /dev/null; then
    echo ""
    echo "  ╔════════════════════════════════════════════════════════╗"
    echo "  ║  [ERROR] tmux not found!                              ║"
    echo "  ║  tmux が見つかりません                                 ║"
    echo "  ╠════════════════════════════════════════════════════════╣"
    echo "  ║  Run first_setup.sh first:                            ║"
    echo "  ║  まず first_setup.sh を実行してください:               ║"
    echo "  ║     ./first_setup.sh                                  ║"
    echo "  ╚════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4.5: tmux グローバル設定（マウス・スクロール）
# ═══════════════════════════════════════════════════════════════════════════════
log_info "tmux グローバル設定を適用中..."

# マウス操作を有効化（スクロール、ペイン選択、リサイズ）
tmux set-option -g mouse on

# スクロールバッファを拡大（デフォルト2000行 → 50000行）
tmux set-option -g history-limit 50000

log_success "  └─ マウス操作・スクロール有効化完了"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: gineidenセッション作成（副官用）
# ═══════════════════════════════════════════════════════════════════════════════
log_war "副官の本陣を構築中..."
if ! tmux new-session -d -s gineiden 2>/dev/null; then
    echo "  [ERROR] tmux セッション 'gineiden' の作成に失敗しました"
    exit 1
fi
FUKUKAN_PROMPT=$(generate_prompt "副官" "magenta")
tmux send-keys -t gineiden "cd \"$(pwd)\" && export PS1='${FUKUKAN_PROMPT}' && clear" Enter
tmux select-pane -t gineiden:0.0 -P 'bg=#1a1a2e'

log_success "  └─ 副官の本陣、構築完了"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6: multiagentセッション作成（大将A, 大将B, 参謀）
# ═══════════════════════════════════════════════════════════════════════════════
log_war "大将・中将・参謀・秘書官の陣を構築中（5名配備）..."

if ! tmux new-session -d -s multiagent -n "agents" 2>/dev/null; then
    echo "  [ERROR] tmux セッション 'multiagent' の作成に失敗しました"
    exit 1
fi

# 5ペイン作成（上3+下2）
# 上下に分割 → 上を3分割 → 下を2分割
tmux split-window -v -t "multiagent:0"
tmux split-window -h -t "multiagent:0.0"
tmux split-window -h -t "multiagent:0.1"
tmux split-window -h -t "multiagent:0.3"

# ペイン設定（上3+下2）
# 0: 大将A（ミッターマイヤー） | 1: 大将B（ロイエンタール） | 2: 中将（ミュラー）
# 3: 参謀（オーベルシュタイン）                | 4: 秘書官（ヒルダ）

PANE_TITLES=("大将A" "大将B" "中将" "参謀" "秘書官")
PANE_COLORS=("green" "red" "blue" "cyan" "yellow")

for i in {0..4}; do
    tmux select-pane -t "multiagent:0.$i" -T "${PANE_TITLES[$i]}"
    PROMPT_STR=$(generate_prompt "${PANE_TITLES[$i]}" "${PANE_COLORS[$i]}")
    tmux send-keys -t "multiagent:0.$i" "cd \"$(pwd)\" && export PS1='${PROMPT_STR}' && clear" Enter
done

log_success "  └─ 大将・中将・参謀・秘書官の陣、構築完了"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 7: Claude Code 起動（--setup-only でスキップ）
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SETUP_ONLY" = false ]; then
    if ! command -v claude &> /dev/null; then
        log_info "claude コマンドが見つかりません"
        echo "  first_setup.sh を実行してください:"
        echo "    ./first_setup.sh"
        exit 1
    fi

    log_war "全軍に Claude Code を召喚中..."

    # 副官（Opus使用、思考トークン制限なし）
    tmux send-keys -t gineiden "claude --model opus --dangerously-skip-permissions"
    tmux send-keys -t gineiden Enter
    log_info "  └─ 副官、召喚完了"

    sleep 1

    # 大将A, 大将B, 中将, 参謀, 秘書官
    for i in {0..4}; do
        tmux send-keys -t "multiagent:0.$i" "claude --dangerously-skip-permissions"
        tmux send-keys -t "multiagent:0.$i" Enter
    done
    log_info "  └─ 大将・中将・参謀・秘書官、召喚完了"

    log_success "全軍 Claude Code 起動完了"
    echo ""

    # 指示書読み込み
    log_war "各エージェントに指示書を伝達中..."

    echo "  Claude Code の起動を待機中（最大30秒）..."

    # 副官の起動を確認
    for i in {1..30}; do
        if tmux capture-pane -t gineiden -p | grep -q "bypass permissions"; then
            echo "  └─ 副官の Claude Code 起動確認完了（${i}秒）"
            break
        fi
        sleep 1
    done

    # 副官に指示書
    sleep 2
    log_info "  └─ 副官に指示書を伝達中..."
    tmux send-keys -t gineiden "instructions/fukukan.md を読んで役割を理解せよ。汝は副官である。"
    sleep 0.5
    tmux send-keys -t gineiden Enter

    # 大将Aに指示書
    sleep 2
    log_info "  └─ 大将Aに指示書を伝達中..."
    tmux send-keys -t "multiagent:0.0" "instructions/taisho_a.md を読んで役割を理解せよ。汝は大将Aである。"
    sleep 0.5
    tmux send-keys -t "multiagent:0.0" Enter

    # 大将Bに指示書
    sleep 2
    log_info "  └─ 大将Bに指示書を伝達中..."
    tmux send-keys -t "multiagent:0.1" "instructions/taisho_b.md を読んで役割を理解せよ。汝は大将Bである。"
    sleep 0.5
    tmux send-keys -t "multiagent:0.1" Enter

    # 中将に指示書
    sleep 2
    log_info "  └─ 中将に指示書を伝達中..."
    tmux send-keys -t "multiagent:0.2" "instructions/chujou.md を読んで役割を理解せよ。汝は中将である。"
    sleep 0.5
    tmux send-keys -t "multiagent:0.2" Enter

    # 参謀に指示書
    sleep 2
    log_info "  └─ 参謀に指示書を伝達中..."
    tmux send-keys -t "multiagent:0.3" "instructions/sanbo.md を読んで役割を理解せよ。汝は参謀である。"
    sleep 0.5
    tmux send-keys -t "multiagent:0.3" Enter

    # 秘書官に指示書
    sleep 2
    log_info "  └─ 秘書官に指示書を伝達中..."
    tmux send-keys -t "multiagent:0.4" "instructions/hishokan.md を読んで役割を理解せよ。汝は秘書官である。"
    sleep 0.5
    tmux send-keys -t "multiagent:0.4" Enter

    log_success "全軍に指示書伝達完了"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 8: 完了メッセージ
# ═══════════════════════════════════════════════════════════════════════════════
log_info "陣容を確認中..."
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  Tmux陣容 (Sessions)                                     │"
echo "  └──────────────────────────────────────────────────────────┘"
tmux list-sessions | sed 's/^/     /'
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  布陣図 (Formation)                                      │"
echo "  └──────────────────────────────────────────────────────────┘"
echo ""
echo "     【gineidenセッション】副官の本陣"
echo "     ┌─────────────────────────────┐"
echo "     │  Pane 0: 副官 (Fukukan)     │  ← キルヒアイス型・調整役"
echo "     └─────────────────────────────┘"
echo ""
echo "     【multiagentセッション】大将・中将・参謀・秘書官の陣（5ペイン 上3+下2）"
echo "     ┌──────────┬──────────┬──────────┐"
echo "     │  大将A   │  大将B   │  中将    │"
echo "     │ミッター  │ロイエン  │ ミュラー │"
echo "     │マイヤー  │タール    │ (調査)   │"
echo "     │ (堅実)   │ (挑戦)   │          │"
echo "     ├──────────┴────┬─────┴──────────┤"
echo "     │   参謀        │   秘書官       │"
echo "     │オーベルシュタイン│   ヒルダ       │"
echo "     │   (正論)      │   (改善)       │"
echo "     └───────────────┴────────────────┘"
echo ""

echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║  作戦準備完了！我が征くは星の大海！                       ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""

if [ "$SETUP_ONLY" = true ]; then
    echo "  セットアップのみモード: Claude Codeは未起動です"
    echo ""
fi

echo "  次のステップ:"
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  副官の本陣にアタッチして命令を開始:                      │"
echo "  │     tmux attach-session -t gineiden                     │"
echo "  │                                                          │"
echo "  │  大将・参謀の陣を確認する:                                │"
echo "  │     tmux attach-session -t multiagent                   │"
echo "  │                                                          │"
echo "  │  ※ 各エージェントは指示書を読み込み済み。                 │"
echo "  │    すぐに命令を開始できます。                             │"
echo "  └──────────────────────────────────────────────────────────┘"
echo ""
echo "  ════════════════════════════════════════════════════════════"
echo "   銀河の歴史がまた1ページ..."
echo "  ════════════════════════════════════════════════════════════"
echo ""
