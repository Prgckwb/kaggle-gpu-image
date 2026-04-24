# kaggle-gpu-image

Kaggle コンペ用の RunPod カスタム Docker イメージ。

ベースイメージに `runpod/base`（CUDA + cuDNN + RunPod インフラ）を使用。
PyTorch は含まず、各プロジェクトで `uv sync` により管理する。

## 含まれるツール (ベースイメージに追加)

| ツール | 用途 |
|--------|------|
| gh | GitHub CLI |
| starship | プロンプト |
| zoxide | cd 代替 (`z`) |
| dust | du 代替 |
| just | コマンドランナー |
| Claude Code | AI アシスタント |

ベースイメージ (`runpod/base`) に元から入っているもの: vim, tmux, build-essential, uv, Python 3.9-3.13, JupyterLab, SSH, CUDA toolkit, cuDNN 等

## ビルド & プッシュ

```bash
# 初回のみ: GHCR にログイン
make login

# ビルド (linux/amd64)
make build

# プッシュ
make push

# まとめて実行
make all
```

初回プッシュ後、GitHub Web UI でパッケージを Public に変更:
Settings > Packages > kaggle-gpu-image > Change visibility > Public

## イメージタグ

CI は以下のタグを毎ビルドで publish する。**本番運用は immutable タグを推奨**。

| タグ | 例 | mutable / immutable | 用途 |
|------|------|---------------------|------|
| `latest` | `:latest` | mutable | 最新検証 |
| `cu<CUDA_VERSION>` | `:cu12.8.1` | mutable | CUDA バージョン別最新 |
| `cu<CUDA_VERSION>-<short-sha>` | `:cu12.8.1-9bdc1f8` | **immutable** | **本番 / RunPod テンプレート推奨** |
| `sha-<short-sha>` | `:sha-9bdc1f8` | **immutable** | デバッグ / ロールバック用 |

`latest` / `cu12.8.1` は毎ビルドで上書きされる点に注意。RunPod テンプレートは同じテンプレート名でも中身が変わるので、再現性が必要な運用では immutable タグ（例 `cu12.8.1-9bdc1f8`）を指定する。

## RunPod テンプレート設定

RunPod Console > Templates > New Template:

| 項目 | 値 |
|------|-----|
| Template Name | `KaggleGPU-cu12.8.1-<sha>`（immutable タグに合わせる） |
| Container Image | `ghcr.io/<username>/kaggle-gpu-image:cu12.8.1-<short-sha>` (例: `ghcr.io/prgckwb/kaggle-gpu-image:cu12.8.1-9bdc1f8`) |
| Container Disk | 20 GB |
| Volume Disk | 50-100 GB |
| Volume Mount Path | `/workspace` |
| HTTP Ports | `8888` |
| TCP Ports | `22` |

> 検証用に毎回最新を引きたい場合は `ghcr.io/<username>/kaggle-gpu-image:cu12.8.1` も可。ただし同じ template 名で実体が変わるので注意。

### 環境変数

| 変数名 | 値 | Secret |
|--------|-----|--------|
| `GITHUB_TOKEN` or `GH_TOKEN` | GitHub Fine-grained PAT (どちらでも可) | Yes |
| `JUPYTER_PASSWORD` | 任意のパスワード | Yes |
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code 長期 OAuth トークン (Pro/Max サブスク用、任意) | Yes |
| `ANTHROPIC_API_KEY` | Anthropic API キー (API 課金用、任意) | Yes |
| `GIT_USER_NAME` | GitHub ユーザー名 | No |
| `GIT_USER_EMAIL` | メールアドレス | No |

`GITHUB_TOKEN` は Fine-grained token を推奨:
Settings > Developer settings > Personal access tokens > Fine-grained tokens > Generate new token

- **Repository access**: Only select repositories → 対象リポジトリを選択
- **Permissions > Contents**: Read and write

#### Claude Code 認証 (任意)

Pod 起動時に Claude Code の手動ログインを省きたい場合は、以下いずれかを RunPod Secret として登録する。どちらも未設定なら `claude /login` を pod 内で実行する形になる。

- **`CLAUDE_CODE_OAUTH_TOKEN`** (Pro/Max サブスク): ローカルで `claude setup-token` を実行して発行される長期トークンを登録
- **`ANTHROPIC_API_KEY`** (API 課金): [console.anthropic.com](https://console.anthropic.com) で発行した API キーを登録

両方設定した場合は OAuth トークンが優先される。Claude Code がこれらを起動時に自動で読み込むため、`pre_start.sh` では検出ログを出すだけで追加のログイン処理は不要。

## 使い方

1. RunPod で `KaggleGPU-cu12.8.1` テンプレートから Pod を起動
2. SSH or JupyterLab に接続
3. リポジトリをクローン:
   ```bash
   cd /workspace
   gh repo clone <username>/my-competition  # 例: gh repo clone prgckwb/my-competition
   cd my-competition
   ```
4. 依存関係をインストールして学習開始:
   ```bash
   uv sync
   uv run python train.py
   ```

## PyTorch の CUDA wheel 設定

このイメージは CUDA 12.8.1 を搭載している。`uv add torch` のデフォルトでは PyPI から CUDA 13.0 用の wheel がインストールされ、ドライバーの不一致で GPU が使えない場合がある。

### プロジェクトの `pyproject.toml` で指定する（推奨）

`uv add` / `uv sync` を使う場合、各プロジェクトの `pyproject.toml` に以下を追加する:

```toml
[tool.uv.sources]
torch = [
  { index = "pytorch-cpu", marker = "sys_platform != 'linux'" },
  { index = "pytorch-cu128", marker = "sys_platform == 'linux'" },
]
torchvision = [
  { index = "pytorch-cpu", marker = "sys_platform != 'linux'" },
  { index = "pytorch-cu128", marker = "sys_platform == 'linux'" },
]

[[tool.uv.index]]
name = "pytorch-cpu"
url = "https://download.pytorch.org/whl/cpu"
explicit = true

[[tool.uv.index]]
name = "pytorch-cu128"
url = "https://download.pytorch.org/whl/cu128"
explicit = true
```

これにより Linux (RunPod) では CUDA 12.8 wheel、macOS/Windows ではCPU wheel が自動で選ばれる。

### `uv pip` を使う場合

イメージに `UV_TORCH_BACKEND=cu128` が設定済みなので、`uv pip install torch` で自動的に CUDA 12.8 wheel がインストールされる。
