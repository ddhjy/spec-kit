---
description: 解析并执行 tasks.md 中定义的所有任务，以落实实现计划。
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，你 **必须** 先考虑用户输入（如果不为空）。

## 大纲

1. 在仓库根目录运行 `{SCRIPT}`，并解析 FEATURE_DIR 与 AVAILABLE_DOCS 列表。所有路径必须是绝对路径。参数中若包含单引号（例如 "I'm Groot"），请使用转义：例如 'I'\''m Groot'（或尽量用双引号："I'm Groot"）。

2. **检查 checklists 状态**（如果存在 FEATURE_DIR/checklists/）：
   - 扫描 checklists/ 目录下所有清单文件
   - 对每个清单统计：
     - 总条目：匹配 `- [ ]` 或 `- [X]` 或 `- [x]` 的行
     - 已完成：匹配 `- [X]` 或 `- [x]` 的行
     - 未完成：匹配 `- [ ]` 的行
   - 生成状态表：

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - 计算总体状态：
     - **PASS**：所有清单未完成项为 0
     - **FAIL**：存在一个或多个清单有未完成项

   - **如果存在未完成清单**：
     - 展示包含未完成项数量的表格
     - **停止**并询问："有些检查清单未完成。你仍要继续实现吗？（yes/no）"
     - 等待用户回复后再继续
     - 若用户回复 "no" / "wait" / "stop"，则停止执行
     - 若用户回复 "yes" / "proceed" / "continue"，则继续到步骤 3

   - **如果所有清单都完成**：
     - 展示所有清单通过的表格
     - 自动继续到步骤 3

3. 加载并分析实现上下文：
   - **必需**：读取 tasks.md 获取完整任务清单与执行计划
   - **必需**：读取 plan.md 获取技术栈、架构与文件结构
   - **若存在**：读取 data-model.md 获取实体与关系
   - **若存在**：读取 contracts/ 获取 API 规格与测试要求
   - **若存在**：读取 research.md 获取技术决策与约束
   - **若存在**：读取 quickstart.md 获取集成场景

4. **项目搭建校验**：
   - **必需**：基于实际项目搭建情况创建/校验 ignore 文件：

   **检测与创建逻辑**：
   - 通过以下命令是否成功判断是否为 git 仓库（若是则创建/校验 .gitignore）：

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - 若存在 Dockerfile* 或 plan.md 中提到 Docker → 创建/校验 .dockerignore
   - 若存在 .eslintrc* → 创建/校验 .eslintignore
   - 若存在 eslint.config.* → 确保配置里的 `ignores` 覆盖所需模式
   - 若存在 .prettierrc* → 创建/校验 .prettierignore
   - 若存在 .npmrc 或 package.json → 创建/校验 .npmignore（如需发布）
   - 若存在 terraform 文件（*.tf）→ 创建/校验 .terraformignore
   - 若需要 .helmignore（存在 helm chart）→ 创建/校验 .helmignore

   **若 ignore 文件已存在**：验证是否包含关键模式，仅追加缺失的关键模式
   **若 ignore 文件不存在**：按检测到的技术创建完整模式集合

   **按技术划分的常见模式**（来自 plan.md 技术栈）：
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **通用**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **工具专用模式**：
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

5. 解析 tasks.md 结构并提取：
   - **任务阶段**：Setup、Tests、Core、Integration、Polish
   - **任务依赖**：串行 vs 并行的执行规则
   - **任务详情**：ID、描述、文件路径、并行标记 [P]
   - **执行流程**：顺序与依赖要求

6. 按任务计划执行实现：
   - **按阶段执行**：每个阶段完成后再进入下一阶段
   - **遵守依赖**：串行任务按顺序执行；标注 [P] 的并行任务可一起执行  
   - **遵循 TDD**：测试任务应先于其对应的实现任务
   - **按文件协调**：影响同一文件的任务必须串行执行
   - **校验检查点**：每个阶段完成后先校验再继续

7. 实现执行规则：
   - **先做 Setup**：初始化项目结构、依赖与配置
   - **先写测试再写代码**：若需要为 contracts、entities 与集成场景编写测试
   - **核心开发**：实现 models、services、CLI 命令、endpoints
   - **集成工作**：数据库连接、中间件、日志、外部服务
   - **打磨与校验**：单元测试、性能优化、文档

8. 进度跟踪与错误处理：
   - 每完成一个任务就汇报进度
   - 任何非并行任务失败都应停止执行
   - 对并行任务 [P]：继续执行成功的任务，并汇报失败任务
   - 提供带上下文的清晰错误信息，便于排障
   - 若实现无法继续，给出下一步建议
   - **重要**：完成任务后，务必在 tasks 文件中将其勾选为 [X]。

9. 完成校验：
   - 校验所有必需任务都已完成
   - 检查实现功能是否匹配原始规格说明
   - 验证测试是否通过、覆盖率是否满足要求
   - 确认实现是否遵循技术计划
   - 汇报最终状态与已完成工作摘要

说明：该命令假设 tasks.md 中已存在完整任务拆分。若任务不完整或缺失，请建议先运行 `/speckit.tasks` 重新生成任务清单。
