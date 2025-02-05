# SiteStatus V1.0.0

我很高兴地宣布发布版本 v1.0.0！此版本包含以下主要功能和改进：

## 新功能
- 添加了健康检查脚本 `health-check.sh`，每小时运行一次，检查配置文件中的每个 URL 的状态。
- 支持通过 GitHub Actions 自动运行健康检查脚本，并将结果提交到仓库。
- 提供了一个简单易用的状态页面，显示各个服务的运行状态和历史记录。
- 支持自定义配置文件 `urls.cfg`，用户可以添加自己的服务 URL 进行监控。
- 提供了详细的设置说明和使用指南。

## 改进
- 优化了日志记录机制，确保日志文件大小在合理范围内。
- 提供了更友好的用户界面，显示服务状态和运行时间。
- 增加了工具提示功能，显示每个服务的详细状态信息。

## Bug 修复
- 修复了一些小的界面问题和性能问题。

如果你有任何问题或建议，请提交 Issue 或 PR。

[查看演示](https://status.bornforthis.cn)
