#!/bin/bash

# 出错即退出；未设置变量视为错误；管道中任一命令失败则整体失败。
set -euo pipefail

# 运行命令：仅在失败时输出日志
run_command() {
    local command_to_run="$*"
    local output
    local exit_code
    
    # 捕获所有输出（stdout 与 stderr）
    output=$(eval "$command_to_run" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    if [ $exit_code -ne 0 ]; then
        echo -e "\033[0;31m[错误] 命令执行失败（退出码 $exit_code）：$command_to_run\033[0m" >&2
        echo -e "\033[0;31m$output\033[0m" >&2
        
        exit $exit_code
    fi
}

# 安装基于 CLI 的 AI Agents

echo -e "\n🤖 正在安装 Copilot CLI..."
run_command "npm install -g @github/copilot@latest"
echo "✅ 完成"

echo -e "\n🤖 正在安装 Claude CLI..."
run_command "npm install -g @anthropic-ai/claude-code@latest"
echo "✅ 完成"

echo -e "\n🤖 正在安装 Codex CLI..."
run_command "npm install -g @openai/codex@latest"
echo "✅ 完成"

echo -e "\n🤖 正在安装 Gemini CLI..."
run_command "npm install -g @google/gemini-cli@latest"
echo "✅ 完成"

echo -e "\n🤖 正在安装 Augie CLI..."
run_command "npm install -g @augmentcode/auggie@latest"
echo "✅ 完成"

echo -e "\n🤖 正在安装 Qwen Code CLI..."
run_command "npm install -g @qwen-code/qwen-code@latest"
echo "✅ 完成"

echo -e "\n🤖 正在安装 OpenCode CLI..."
run_command "npm install -g opencode-ai@latest"
echo "✅ 完成"

echo -e "\n🤖 正在安装 Amazon Q CLI..."
# 👉🏾 验证与下载说明：https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-verify-download.html

run_command "curl --proto '=https' --tlsv1.2 -sSf 'https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip' -o 'q.zip'"
run_command "curl --proto '=https' --tlsv1.2 -sSf 'https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip.sig' -o 'q.zip.sig'"
cat > amazonq-public-key.asc << 'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEZig60RYJKwYBBAHaRw8BAQdAy/+G05U5/EOA72WlcD4WkYn5SInri8pc4Z6D
BKNNGOm0JEFtYXpvbiBRIENMSSBUZWFtIDxxLWNsaUBhbWF6b24uY29tPoiZBBMW
CgBBFiEEmvYEF+gnQskUPgPsUNx6jcJMVmcFAmYoOtECGwMFCQPCZwAFCwkIBwIC
IgIGFQoJCAsCBBYCAwECHgcCF4AACgkQUNx6jcJMVmef5QD/QWWEGG/cOnbDnp68
SJXuFkwiNwlH2rPw9ZRIQMnfAS0A/0V6ZsGB4kOylBfc7CNfzRFGtovdBBgHqA6P
zQ/PNscGuDgEZig60RIKKwYBBAGXVQEFAQEHQC4qleONMBCq3+wJwbZSr0vbuRba
D1xr4wUPn4Avn4AnAwEIB4h+BBgWCgAmFiEEmvYEF+gnQskUPgPsUNx6jcJMVmcF
AmYoOtECGwwFCQPCZwAACgkQUNx6jcJMVmchMgEA6l3RveCM0YHAGQaSFMkguoAo
vK6FgOkDawgP0NPIP2oA/jIAO4gsAntuQgMOsPunEdDeji2t+AhV02+DQIsXZpoB
=f8yY
-----END PGP PUBLIC KEY BLOCK-----
EOF
run_command "gpg --batch --import amazonq-public-key.asc"
run_command "gpg --verify q.zip.sig q.zip"
run_command "unzip -q q.zip"
run_command "chmod +x ./q/install.sh"
run_command "./q/install.sh --no-confirm"
run_command "rm -rf ./q q.zip q.zip.sig amazonq-public-key.asc"
echo "✅ 完成"

echo -e "\n🤖 正在安装 CodeBuddy CLI..."
run_command "npm install -g @tencent-ai/codebuddy-code@latest"
echo "✅ 完成"

# 安装 UV（Python 包管理器）
echo -e "\n🐍 正在安装 UV（Python 包管理器）..."
run_command "pipx install uv"
echo "✅ 完成"

# 安装 DocFx（用于文档站点）
echo -e "\n📚 正在安装 DocFx..."
run_command "dotnet tool update -g docfx"
echo "✅ 完成"

echo -e "\n🧹 正在清理缓存..."
run_command "sudo apt-get autoclean"
run_command "sudo apt-get clean"

echo "✅ 环境初始化完成。祝编码顺利！"
