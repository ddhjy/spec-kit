# 本地开发指南

本指南说明如何在本地迭代 `specify` CLI，而无需先发布 release 或提交到 `main`。

> 脚本现在同时提供 Bash（`.sh`）与 PowerShell（`.ps1`）版本。CLI 会根据操作系统自动选择，除非你显式传入 `--script sh|ps`。

## 1. 克隆并切换分支

```bash
git clone https://github.com/github/spec-kit.git
cd spec-kit
# 在 feature 分支上工作
git checkout -b your-feature-branch
```

## 2. 直接运行 CLI（反馈最快）

你可以通过模块入口直接执行 CLI，无需安装任何东西：

```bash
# 从仓库根目录执行
python -m src.specify_cli --help
python -m src.specify_cli init demo-project --ai claude --ignore-agent-tools --script sh
```

如果你更喜欢以脚本文件形式调用（使用 shebang）：

```bash
python src/specify_cli/__init__.py init demo-project --script ps
```

## 3. 使用可编辑安装（隔离环境）

使用 `uv` 创建隔离环境，以确保依赖解析方式与终端用户一致：

```bash
# 创建并激活虚拟环境（uv 会自动管理 .venv）
uv venv
source .venv/bin/activate  # or on Windows PowerShell: .venv\Scripts\Activate.ps1

# 以可编辑模式安装项目
uv pip install -e .

# 现在 'specify' 入口可用
specify --help
```

由于可编辑模式，修改代码后无需重新安装即可反复运行。

## 4. 通过 uvx 直接从 Git（当前分支）调用

`uvx` 可以从本地路径（或某个 Git ref）运行，用于模拟用户流程：

```bash
uvx --from . specify init demo-uvx --ai copilot --ignore-agent-tools --script sh
```

你也可以让 uvx 指向某个特定分支而无需合并：

```bash
# 先推送你的工作分支
git push origin your-feature-branch
uvx --from git+https://github.com/github/spec-kit.git@your-feature-branch specify init demo-branch-test --script ps
```

### 4a. 使用绝对路径的 uvx（在任意目录运行）

如果你在其他目录里，请使用绝对路径而不是 `.`：

```bash
uvx --from /mnt/c/GitHub/spec-kit specify --help
uvx --from /mnt/c/GitHub/spec-kit specify init demo-anywhere --ai copilot --ignore-agent-tools --script sh
```

（可选）设置环境变量以方便使用：

```bash
export SPEC_KIT_SRC=/mnt/c/GitHub/spec-kit
uvx --from "$SPEC_KIT_SRC" specify init demo-env --ai copilot --ignore-agent-tools --script ps
```

（可选）定义一个 shell 函数：

```bash
specify-dev() { uvx --from /mnt/c/GitHub/spec-kit specify "$@"; }
# 然后
specify-dev --help
```

## 5. 测试脚本权限逻辑

运行一次 `init` 后，检查在 POSIX 系统上 shell 脚本是否具有可执行权限：

```bash
ls -l scripts | grep .sh
# 期望拥有者具有执行位（例如 -rwxr-xr-x）
```

在 Windows 上你将使用 `.ps1` 脚本（无需 chmod）。

## 6. 运行 lint / 基础检查（可自行扩展）

目前未内置强制 lint 配置，但你可以快速检查是否可导入：

```bash
python -c "import specify_cli; print('导入 OK')"
```

## 7. 本地构建 wheel（可选）

在发布前验证打包是否正常：

```bash
uv build
ls dist/
```

如有需要，可以把构建产物安装到一个全新临时环境中验证。

## 8. 使用临时工作区

在一个“脏目录”里测试 `init --here` 时，建议先创建临时工作区：

```bash
mkdir /tmp/spec-test && cd /tmp/spec-test
python -m src.specify_cli init --here --ai claude --ignore-agent-tools --script sh  # if repo copied here
```

如果你只想要更轻量的沙盒，也可以仅复制修改过的 CLI 部分。

## 9. 调试网络 / 跳过 TLS

如果你在实验时需要绕过 TLS 校验：

```bash
specify check --skip-tls
specify init demo --skip-tls --ai gemini --ignore-agent-tools --script ps
```

（仅用于本地实验。）

## 10. 快速迭代循环总结

| 操作 | 命令 |
|--------|---------|
| 直接运行 CLI | `python -m src.specify_cli --help` |
| 可编辑安装 | `uv pip install -e .` 然后 `specify ...` |
| 本地 uvx 运行（仓库根目录） | `uvx --from . specify ...` |
| 本地 uvx 运行（绝对路径） | `uvx --from /mnt/c/GitHub/spec-kit specify ...` |
| Git 分支 uvx | `uvx --from git+URL@branch specify ...` |
| 构建 wheel | `uv build` |

## 11. 清理

快速移除构建产物/虚拟环境：

```bash
rm -rf .venv dist build *.egg-info
```

## 12. 常见问题

| 现象 | 解决方案 |
|---------|-----|
| `ModuleNotFoundError: typer` | 运行 `uv pip install -e .` |
| 脚本不可执行（Linux） | 重新运行 init，或执行 `chmod +x scripts/*.sh` |
| Git 步骤被跳过 | 你传入了 `--no-git`，或未安装 Git |
| 下载了错误的脚本类型 | 显式传入 `--script sh` 或 `--script ps` |
| 企业网络下 TLS 报错 | 尝试 `--skip-tls`（不要用于生产） |

## 13. 下一步

- 更新文档，并用你修改后的 CLI 跑一遍快速开始流程
- 满意后提交 PR
- （可选）当变更合入 `main` 后打一个 release tag
