---
description: 根据交互输入或提供的原则内容创建/更新项目 constitution，并确保所有依赖模板保持同步。
handoffs: 
  - label: 生成规格说明
    agent: speckit.specify
    prompt: 请基于更新后的 constitution 生成功能规格说明。我想要构建……
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，你 **必须** 先考虑用户输入（如果不为空）。

## 大纲

你正在更新 `/memory/constitution.md` 中的项目 constitution。该文件是一个模板，包含方括号占位符（例如 `[PROJECT_NAME]`、`[PRINCIPLE_1_NAME]`）。你的任务是：(a) 收集/推导具体值，(b) 精确填充模板，(c) 将修订同步到所有依赖产物中。

按以下执行流程：

1. 加载 `/memory/constitution.md` 现有模板。
   - 识别所有形如 `[ALL_CAPS_IDENTIFIER]` 的占位符。
   **重要**：用户可能需要的原则条数少于或多于模板默认条数。如果用户指定了数量，请遵循该数量，并基于通用模板结构更新文档。

2. 为占位符收集/推导值：
   - 若用户输入（对话）提供了值，则使用该值。
   - 否则从仓库上下文推断（README、docs、如存在则参考历史 constitution 版本）。
   - 治理日期：`RATIFICATION_DATE` 为首次通过日期（未知则询问或标 TODO）；`LAST_AMENDED_DATE` 若有改动则为今天，否则保持原值。
   - `CONSTITUTION_VERSION` 必须按语义化版本规则递增：
     - MAJOR：不向后兼容的治理/原则移除或重定义。
     - MINOR：新增原则/章节，或对指导进行实质性扩展。
     - PATCH：澄清、措辞调整、拼写修复等非语义改动。
   - 若无法判断应提升哪一位版本号，请在定稿前先说明理由。

3. 起草更新后的 constitution 内容：
   - 用具体文本替换每个占位符（除非项目刻意保留某些尚未定义的模板槽位；若保留必须明确说明原因）。
   - 保持标题层级；注释在被替换后可删除，除非仍能提供澄清价值。
   - 确保每条 Principle（原则）包含：简洁名称、一段说明（或要点列表）表达不可协商规则，必要时给出明确理由。
   - 确保 Governance（治理）章节包含修订流程、版本策略与合规评审期望。

4. 一致性同步清单（将此前“清单”变为实际校验步骤）：
   - 阅读 `/templates/plan-template.md`，确保其中的 “Constitution Check” 与规则与更新后的原则一致。
   - 阅读 `/templates/spec-template.md`，确保范围/需求对齐——若 constitution 增删了必填章节或约束，则同步更新模板。
   - 阅读 `/templates/tasks-template.md`，确保任务分类反映新增/移除的“原则驱动型任务类型”（例如可观测性、版本策略、测试纪律）。
   - 阅读 `/templates/commands/*.md` 下的每个命令文件（包括本文件），确保在需要通用指导时不会残留过时引用（例如只写 CLAUDE 等 agent 特定名称）。
   - 阅读运行时指导文档（例如 `README.md`、`docs/quickstart.md`，或存在的话 agent 专用指导文件），更新对原则的引用。

5. 生成同步影响报告（更新后作为 HTML 注释插入到 constitution 文件顶部）：
   - 版本变更：old → new
   - 修改过的原则列表（若重命名则写 old title → new title）
   - 新增章节
   - 移除章节
   - 需要更新的模板（✅ 已更新 / ⚠ 待处理）及文件路径
   - 若有刻意延后处理的占位符，列出后续 TODO。

6. 输出前校验：
   - 不残留任何未解释的方括号占位符。
   - 版本行与报告一致。
   - 日期使用 ISO 格式 YYYY-MM-DD。
   - 原则以陈述句表达、可测试，避免含糊措辞（例如将 “should” 在需要时替换为 MUST/SHOULD 并给出理由）。

7. 将完成后的 constitution 覆写回 `/memory/constitution.md`。

8. 向用户输出最终摘要，包括：
   - 新版本号与升级理由。
   - 任何需要手动跟进的文件。
   - 建议的提交信息（例如 `docs: amend constitution to vX.Y.Z (principle additions + governance update)`）。

格式与风格要求：

- Use Markdown headings exactly as in the template (do not demote/promote levels).
- Wrap long rationale lines to keep readability (<100 chars ideally) but do not hard enforce with awkward breaks.
- Keep a single blank line between sections.
- Avoid trailing whitespace.

如果用户只提供部分更新（例如只改一条原则），也必须执行校验与版本决策步骤。

如果缺少关键信息（例如无法得知 ratification date），插入 `TODO(<FIELD_NAME>): explanation`，并在同步影响报告中列入“延后项”。

不要创建新模板；始终基于现有的 `/memory/constitution.md` 文件进行操作。
