# 为 OpenClaw 安装 OpenViking

[English README](./README.md)

这个仓库现在要做的事很简单：

**给新手一份尽量直接、尽量通用的说明，教你怎么把 OpenViking 装到 OpenClaw 上。**

目标不是写成个人排障日记。
这次踩过的坑仍然有价值，但应该收进附录和 troubleshooting，而不是霸占正文主线。

---

## 这份说明适合谁

适合这些人：

- 想让 OpenClaw 用 OpenViking 做 context / memory backend
- 希望尽量走官方 **`local`** 模式，而不是自己拼 remote 架构
- 想看一个**步骤清楚、容易照做**的安装说明
- 想在装完之后有一个基本验收办法

如果只看最短版本，流程就是：

1. 安装 OpenClaw
2. 安装 OpenViking
3. 在 OpenClaw 里启用 OpenViking 插件（`local` 模式）
4. 重启 gateway
5. 做基本验证

下面只是把这几步展开讲清楚。

---

## 这份仓库现在覆盖什么

主线只覆盖这些：

- **OpenClaw**
- **OpenViking**
- 官方 **`local`** 模式插件接线
- 一套**基础验证流程**
- 少量关键注意事项，其他坑统一放附录 / troubleshooting

这是一个通用安装说明，不是“所有记忆场景都已经完美”的宣传页。

---

## 上游官方入口

正文建议和官方文档配合看。

### OpenClaw

- 文档：<https://docs.openclaw.ai>
- 安装：<https://docs.openclaw.ai/install>
- Installer：<https://docs.openclaw.ai/install/installer>
- macOS：<https://docs.openclaw.ai/platforms/macos>

### OpenViking

- GitHub：<https://github.com/volcengine/OpenViking>
- OpenClaw 插件安装文档：<https://github.com/volcengine/OpenViking/blob/v0.3.3/examples/openclaw-plugin/INSTALL.md>
- OpenClaw 插件 schema / 示例：<https://github.com/volcengine/OpenViking/blob/v0.3.3/examples/openclaw-plugin/openclaw.plugin.json>

这个仓库是用来补强新手安装说明和常见注意事项的，不是替代上游文档。

---

## 推荐基线

如果你想走一条更容易复现的路，建议直接按这个基线来：

- OpenClaw 插件模式：**`local`**
- OpenViking 版本：**`0.3.3`**
- Python：**`3.13`**
- OpenViking 配置：**`~/.openviking/ov.conf`**
- OpenViking 端口：**`1933`**
- OpenViking 日志输出：**`stderr`**
- OpenClaw gateway 只用官方命令管理

---

# 分步安装流程

## Step 1：安装 OpenClaw

如果你还没装 OpenClaw，先走官方安装文档：

- <https://docs.openclaw.ai/install>
- <https://docs.openclaw.ai/install/installer>

装完先确认 gateway 可用：

```bash
openclaw gateway status
```

如果 OpenClaw 自己都还不健康，就先别往上叠 OpenViking。
先把 OpenClaw 本身修好。

---

## Step 2：安装 OpenViking

按 OpenViking 上游说明安装：

- <https://github.com/volcengine/OpenViking>
- <https://github.com/volcengine/OpenViking/blob/v0.3.3/examples/openclaw-plugin/INSTALL.md>

为了少踩坑，建议优先使用：

- OpenViking `0.3.3`
- Python `3.13`

装完后，至少要确认：

- 你有 `~/.openviking/ov.conf`
- 你有一套真的能跑 OpenViking 的 Python 环境

一个最小配置通常像这样：

```json
{
  "server": {
    "port": 1933
  },
  "log": {
    "output": "stderr"
  }
}
```

如果你打算在 OpenViking 端启用 API-key 认证，后面还要给插件侧也补上。

---

## Step 3：在 OpenClaw 里启用 OpenViking 插件

你的 `~/.openclaw/openclaw.json` 里，OpenViking 插件应当以 `local` 模式启用。

示例结构：

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

重点看：

- `plugins.allow` 包含 `openviking`
- `plugins.entries.openviking.enabled = true`
- `mode = local`
- `configPath` 指向真实 `ov.conf`
- `port` 显式写出
- `plugins.slots.contextEngine = openviking`

---

## Step 4：持久固定正确的 Python 运行时

这一步很值钱，能帮你少掉一堆莫名其妙的问题。

创建：

- `~/.openclaw/openviking.env`

示例：

```bash
OPENVIKING_PYTHON="/path/to/your/python3.13"
```

如果你已经知道哪一个 Python 环境能正常跑 OpenViking，就把它写这里。
这样 OpenClaw 在 local 模式下会更稳定地用对解释器。

**不要**把手改生成出来的 LaunchAgent plist 当成长期方案。
长期入口应该是 `~/.openclaw/openviking.env`。

---

## Step 5：如果 OpenViking 开了 API-key 认证，插件侧也要配

如果你的 `ov.conf` 启用了：

- `server.auth_mode = api_key`

那么 OpenClaw 插件侧也必须拿到 key，方式二选一：

- `plugins.entries.openviking.config.apiKey`
- `OPENVIKING_API_KEY`

例如：

```bash
openclaw config set plugins.entries.openviking.config.apiKey your-api-key
```

**重点：**

> `ov.conf.root_api_key` 不会自动被 OpenClaw 插件继承。

如果你漏掉这一步，local 服务可能照样能起来，`/health` 也可能是绿的，但真实 API 路由会直接 `401 Missing API Key`。

---

## Step 6：重启 OpenClaw gateway

用官方命令：

```bash
openclaw gateway install --force
openclaw gateway restart
```

别自己发明一套长期服务管理流程，除非你很清楚自己在干什么。
这里追求的是简单、贴近上游、容易复现。

---

## Step 7：做基本验证

先看最基础的三项：

```bash
openclaw gateway status
lsof -nP -iTCP:1933 -sTCP:LISTEN
curl http://127.0.0.1:1933/health
```

你希望看到：

- OpenClaw gateway 正常
- OpenViking 正在监听 `1933`
- `/health` 返回成功

然后再确认插件确实挂上了：

- `plugins.slots.contextEngine = openviking`
- 日志里没有明显的插件加载报错

如果启用了 API-key 认证，还要继续确认真实路由不再报 `401`。

---

## 快速检查清单

- [ ] OpenClaw 已安装且健康
- [ ] OpenViking 已安装
- [ ] `~/.openviking/ov.conf` 存在
- [ ] OpenClaw 插件模式为 `local`
- [ ] `plugins.slots.contextEngine = openviking`
- [ ] 需要固定 Python 时，`~/.openclaw/openviking.env` 已存在
- [ ] `OPENVIKING_PYTHON` 指向正确 Python
- [ ] OpenViking 本地端口在监听
- [ ] `/health` 返回 OK
- [ ] 若 `auth_mode=api_key`，插件侧 `apiKey` 或 `OPENVIKING_API_KEY` 已配置

---

## 接下来读什么

### 核心补充文档

- [docs/architecture.md](./docs/architecture.md)
- [docs/verification.md](./docs/verification.md)
- [docs/troubleshooting.md](./docs/troubleshooting.md)

### 附录 / 深水区

如果正文安装流程不够用，再看这些：

- `docs/verification.md` —— “装好了”到底算什么
- `docs/troubleshooting.md` —— 按症状排查问题

那些复杂坑和特殊情况，应该待在这里，不该淹没正文。

---

## 最后一版一句话总结

如果你只是想**给 OpenClaw 装上 OpenViking**，最清爽的主线就是：

1. 安装 OpenClaw
2. 安装 OpenViking
3. 在 OpenClaw 里启用 `local` 模式插件
4. 在 `~/.openclaw/openviking.env` 里固定正确 Python
5. 如果启用了认证，再给插件侧补 API key
6. 重启 gateway
7. 做基本验证

主线就这些。
其他坑，统统放附录。
