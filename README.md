[![Health Check](../../actions/workflows/health-check.yml/badge.svg)](../../actions/workflows/health-check.yml)

# 开源状态页面

我尝试了许多现有的状态页面工具，并将其作为一个有趣的小项目来构建，目标是使状态页面尽可能简单。其它现有工具需要依靠第三方或者免费版 API，接着以来开源的状态前端，很可惜这两者我找到的都是捆绑在一起使用的。

我现在能否自己实现一个更简单高效的版本呢？这个开源应运而生～

## 演示

- https://status.bornforthis.cn

## 设置说明

1. Fork [模板仓库](https://github.com/AndersonHJB/site_status)。
2. 更新 `urls.cfg` 文件以包含您的网址。

```cfg
key1=https://example.com
key2=https://class1v1.com
AI悦创=https://bornforthis.cn
```

3. 更新 `index.html` 文件并修改标题。

```html
<title>我的状态页面</title>
<h1>服务状态</h1>
```

4. 为您的仓库设置 GitHub Pages。

![image](https://user-images.githubusercontent.com/74588208/121419015-5f4dc200-c920-11eb-9b14-a275ef5e2a19.png)

## 它如何工作？

此项目使用 GitHub Actions 每小时运行一次 shell 脚本 (`health-check.sh`)。该脚本通过 `curl` 检查配置文件中的每个 URL 的状态，将运行结果附加到日志文件中并提交到仓库中。然后，这些日志会动态从 `index.html` 中加载，并以易于消费的方式显示。您还可以从自己的基础设施运行此脚本，以更频繁地更新状态页面。

## 它目前不支持哪些功能？

1. 事件管理。
2. 中断持续时间跟踪。
3. 状态根本原因更新。

## 有新想法？

提交 PR 吧！我很乐意集成您的想法。
