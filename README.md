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

## RunPod テンプレート設定

RunPod Console > Templates > New Template:

| 項目 | 値 |
|------|-----|
| Template Name | `KaggleGPU-cu12.8.1` |
| Container Image | `ghcr.io/prgckwb/kaggle-gpu-image:cu12.8.1` |
| Container Disk | 20 GB |
| Volume Disk | 50-100 GB |
| Volume Mount Path | `/workspace` |
| HTTP Ports | `8888` |
| TCP Ports | `22` |

### 環境変数

| 変数名 | 値 | Secret |
|--------|-----|--------|
| `GITHUB_TOKEN` | GitHub Fine-grained PAT | Yes |
| `JUPYTER_PASSWORD` | 任意のパスワード | Yes |
| `GIT_USER_NAME` | GitHub ユーザー名 | No |
| `GIT_USER_EMAIL` | メールアドレス | No |

`GITHUB_TOKEN` は Fine-grained token を推奨:
Settings > Developer settings > Personal access tokens > Fine-grained tokens > Generate new token

- **Repository access**: Only select repositories → 対象リポジトリを選択
- **Permissions > Contents**: Read and write

## 使い方

1. RunPod で `KaggleGPU-cu12.8.1` テンプレートから Pod を起動
2. SSH or JupyterLab に接続
3. リポジトリをクローン:
   ```bash
   cd /workspace
   gh repo clone prgckwb/my-competition
   cd my-competition
   ```
4. 依存関係をインストールして学習開始:
   ```bash
   uv sync
   uv run python train.py
   ```
