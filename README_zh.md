# OpenClaw + OpenViking 官方 Local 方案

[English README](./README.md)

这个仓库现在记录的是一套**已经修复、已经过最小业务验收**的 **OpenClaw + OpenViking official local** 基线。

它不是“AI 记忆革命”的营销页。
它是基于真实排障、真实翻车、真实修复后沉淀出来的实战整合说明。

---

## 当前状态

**状态：已修复，并完成最小业务验收。**

目前 official local 主路径已经在最小有用运行层被验证打通：

- OpenClaw 插件能在 local 模式下拉起 OpenViking
- runtime auth 已打通
- recall/search 请求成功
- capture/session message 写入成功
- commit/extraction 请求成功
- 重启后的日志窗口里没有新的 `401`、`UNAUTHENTICATED`、`Missing API Key`

这比“`/health` 绿了”强得多。

---

## 这个仓库现在聚焦什么

当前主路径是：

- **OpenClaw** 使用官方 **`local`** 模式插件
- **OpenViking** 固定为 **`0.3.3`**
- **Python** 固定为 **`3.13`**
- gateway 只通过官方命令管理：
  - `openclaw gateway install --force`
  - `openclaw gateway start`
  - `openclaw gateway restart`

这个仓库不再把旧的 **remote 接线** 当成主叙事。

---

## 这次真正验证通过了什么

当前已验证通过的稳定基线是：

- OpenClaw 插件模式：**`local`**
- OpenViking 版本：**`0.3.3`**
- Python 解释器：**`3.13`**
- OpenViking 端口：**`1933`**
- OpenViking 配置文件：**`~/.openviking/ov.conf`**
- OpenViking 日志输出：**`stderr`**
- Python 持久覆盖文件：**`~/.openclaw/openviking.env`**
- runtime auth：**已通过**
- 最小业务链路验收：**已通过**

最终验收中，以下真实 API 路由已确认成功：

- `POST /api/v1/search/find` → `200`
- `POST /api/v1/sessions/<id>/messages` → `200`
- `POST /api/v1/sessions/<id>/commit` → `200`

并且在 commit accepted 之后，日志里继续确认到了 extraction 完成。

---

## 这次必须写进仓库的两个关键修复点

### 修复点 1：持久固定正确的 Python

**不要**把手改 LaunchAgent plist 当成长期方案。

应该使用：

- `~/.openclaw/openviking.env`

示例：

```bash
OPENVIKING_PYTHON="/Users/sean/venvs/openviking-py313-v033-py313/bin/python"
```

这一步是 local 模式避免掉回错误 Python 的关键持久修复。

### 修复点 2：不要漏掉插件侧 API 认证

如果你的 OpenViking 服务端使用：

- `server.auth_mode = api_key`

那么 OpenClaw 插件侧也必须显式拿到 API key，方式二选一：

- `plugins.entries.openviking.config.apiKey`
- `OPENVIKING_API_KEY`

**重点：**

> `ov.conf.root_api_key` 不会自动被 OpenClaw 插件继承。

这次真实排障里第二个大坑就在这里。
即使 local 服务已经正常起来，`/health` 也已经是绿色，真实业务请求依然可能全部 `401 Missing API Key`。

---

## OpenViking 配置要求

你的 `~/.openviking/ov.conf` 至少应满足：

```json
{
  "server": {
    "port": 1933,
    "auth_mode": "api_key"
  },
  "log": {
    "output": "stderr"
  }
}
```

如果启用了认证，别忘了插件侧也要补 key。

### 为什么 `stderr` 很重要

这次验证里，如果保留：

- `log.output = stdout`

local 子进程监管会不稳。

所以在这个仓库里，`stderr` 不是“个人偏好”，而是**当前已验证可复现的稳定基线**。

---

## 推荐的 OpenClaw 插件配置形态

你的 `~/.openclaw/openclaw.json` 相关结构建议至少是：

```json
{
  "plugins": {
    "allow": ["openviking"],
    "entries": {
      "openviking": {
        "enabled": true,
        "config": {
          "mode": "local",
          "configPath": "~/.openviking/ov.conf",
          "port": 1933,
          "agentId": "main",
          "apiKey": "<与服务端一致的 key>",
          "autoRecall": true,
          "autoCapture": true,
          "emitStandardDiagnostics": true,
          "logFindRequests": true,
          "bypassSessionPatterns": ["agent:*:cron:**"]
        }
      }
    },
    "slots": {
      "contextEngine": "openviking"
    }
  }
}
```

重点看这些：

- `mode = local`
- `configPath = ~/.openviking/ov.conf`
- `port = 1933`
- 如果服务端开了认证，`apiKey` 必须存在
- `plugins.allow` 包含 `openviking`
- `plugins.slots.contextEngine = openviking`

---

## 迁移步骤

### Step 1：确认 OpenClaw 侧已经是 local 模式

确认：

- `mode = local`
- `configPath` 正确
- `port` 显式设置
- `contextEngine = openviking`

### Step 2：修 OpenViking 配置

确保 `~/.openviking/ov.conf` 至少有：

- `server.port = 1933`
- `log.output = stderr`

如果服务端启用了认证，记住：插件侧认证要单独配。

### Step 3：写入正确的 Python 持久配置

创建或更新：

- `~/.openclaw/openviking.env`

示例：

```bash
OPENVIKING_PYTHON="/Users/sean/venvs/openviking-py313-v033-py313/bin/python"
```

### Step 4：在启用认证时补上插件侧 API key

二选一：

```bash
openclaw config set plugins.entries.openviking.config.apiKey your-api-key
```

或者提供：

```bash
OPENVIKING_API_KEY="your-api-key"
```

再说一遍：插件**不会**自动从 `ov.conf.root_api_key` 继承 key。

### Step 5：让旧独立 OpenViking 服务退出主路径

如果你之前有独立 launchd OpenViking 服务，切换 final state 之前，要先让它退出主路径。

最终目标是：

- OpenClaw gateway 正常运行
- OpenViking 由插件按 official local 拉起
- 不再依赖旧 standalone 服务作为主路径

### Step 6：只用官方 gateway 命令管理服务

执行：

```bash
openclaw gateway install --force
openclaw gateway restart
```

不要再把“长期手改 plist”当方案。

### Step 7：验 startup，也验 runtime auth

执行：

```bash
openclaw gateway status
lsof -nP -iTCP:1933 -sTCP:LISTEN
curl http://127.0.0.1:1933/health
```

然后继续看日志，确认真实 API 路由不再报 `401`。

预期结果：

- gateway 正常运行
- `1933` 正在监听
- `/health` 返回 healthy
- runtime 路由里不再出现 `Missing API Key`

---

## 快速验收清单

- [ ] `openclaw gateway status` 正常
- [ ] `1933` 正在监听
- [ ] `curl http://127.0.0.1:1933/health` 返回 OK
- [ ] OpenViking 版本是 `0.3.3`
- [ ] `~/.openclaw/openviking.env` 存在
- [ ] `OPENVIKING_PYTHON` 指向 Python 3.13
- [ ] `~/.openviking/ov.conf` 使用 `log.output=stderr`
- [ ] 如果 `auth_mode=api_key`，插件 `apiKey` 或 `OPENVIKING_API_KEY` 已配置
- [ ] `POST /api/v1/search/find` 成功
- [ ] `POST /api/v1/sessions/<id>/messages` 成功
- [ ] `POST /api/v1/sessions/<id>/commit` 成功

---

## 这个仓库现在能可靠证明什么

在上面这套基线成立后，这个仓库现在能比较诚实地帮助你证明：

- OpenClaw 已经按 official local 接入 OpenViking
- 插件已作为 context engine 生效
- local OpenViking 子进程已能被稳定托管
- Python 运行时已正确固定
- runtime authentication 已打通
- 最小有用业务链路已通过验收

---

## 这个仓库还不能自动替你证明什么

它**不能自动证明**：

- 所有业务场景下的长期记忆抽取质量
- 跨会话记忆质量
- rerank / retrieval 质量
- 检索回来的记忆是不是有用而不是垃圾
- 你的具体业务场景已经完全 production-ready

所以最诚实的说法是：

> 接线、local runtime，以及最小 runtime auth / 业务链路验收都已经通过，但长期记忆质量和抽取效果仍需单独验证。

这句话不性感，但起码不是瞎吹。

---

## 仓库内相关文档

- [docs/architecture.md](./docs/architecture.md)
- [docs/verification.md](./docs/verification.md)
- [docs/troubleshooting.md](./docs/troubleshooting.md)
- [CHANGELOG.md](./CHANGELOG.md)
- [ROADMAP.md](./ROADMAP.md)

---

## 结论

如果你想要一个稳定的 **official local** 方案，当前最小可靠基线是：

- OpenViking `0.3.3`
- Python `3.13`
- `OPENVIKING_PYTHON` 持久写入 `~/.openclaw/openviking.env`
- `log.output = stderr`
- 插件模式 `local`
- 显式 local `port`
- 当服务端启用认证时，插件侧显式提供 `apiKey`

这套组合现在已经不是“理论可行”。
而是已经被真实运行验证和最小业务验收打通过的组合。
