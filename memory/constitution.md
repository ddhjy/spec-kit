# [PROJECT_NAME] Constitution（项目宪章）
<!-- 示例：Spec Constitution、TaskFlow Constitution 等 -->

## 核心原则

### [PRINCIPLE_1_NAME]
<!-- 示例：I. 库优先（Library-First） -->
[PRINCIPLE_1_DESCRIPTION]
<!-- 示例：每个功能都应以独立库开始；库必须自包含、可独立测试、具备文档；必须有清晰目的——不允许仅为组织结构而存在的“空壳库” -->

### [PRINCIPLE_2_NAME]
<!-- 示例：II. CLI 接口（CLI Interface） -->
[PRINCIPLE_2_DESCRIPTION]
<!-- 示例：每个库都通过 CLI 暴露功能；文本输入输出协议：stdin/args → stdout，错误 → stderr；支持 JSON 与人类可读格式 -->

### [PRINCIPLE_3_NAME]
<!-- 示例：III. 测试优先（不可协商） -->
[PRINCIPLE_3_DESCRIPTION]
<!-- 示例：TDD 强制：先写测试 → 用户批准 → 测试失败 → 再实现；严格执行红-绿-重构循环 -->

### [PRINCIPLE_4_NAME]
<!-- 示例：IV. 集成测试（Integration Testing） -->
[PRINCIPLE_4_DESCRIPTION]
<!-- 示例：需要集成测试的关注点：新库的 contract 测试、合同变更、服务间通信、共享 schema -->

### [PRINCIPLE_5_NAME]
<!-- 示例：V. 可观测性、VI. 版本与破坏性变更、VII. 简洁性 -->
[PRINCIPLE_5_DESCRIPTION]
<!-- 示例：文本 I/O 保证可调试性；要求结构化日志；或：使用 MAJOR.MINOR.BUILD 格式；或：先从简单开始，遵循 YAGNI -->

## [SECTION_2_NAME]
<!-- 示例：额外约束、安全要求、性能标准等 -->

[SECTION_2_CONTENT]
<!-- 示例：技术栈要求、合规标准、部署策略等 -->

## [SECTION_3_NAME]
<!-- 示例：开发工作流、评审流程、质量门禁等 -->

[SECTION_3_CONTENT]
<!-- 示例：代码评审要求、测试门禁、部署审批流程等 -->

## Governance
<!-- 示例：宪章高于其他所有实践；修订需要文档、审批与迁移计划 -->

[GOVERNANCE_RULES]
<!-- 示例：所有 PR/评审必须验证合规；复杂度必须被论证；运行期开发指导使用 [GUIDANCE_FILE] -->

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
<!-- 示例：Version: 2.1.1 | Ratified: 2025-06-13 | Last Amended: 2025-07-16 -->
