# Windows 原生运行 Usage Service

这个仓库的统计服务是 Go 程序，可以在 Windows 上原生运行，不需要 Docker。

## 一键构建

需要先安装 Go 1.24 或更新版本，并确保 `go` 在 `PATH` 中。

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-windows.ps1
```

构建产物会输出到：

```text
release\windows
```

## 前台运行

```powershell
cd .\release\windows
powershell -ExecutionPolicy Bypass -File .\start-windows.ps1
```

打开：

```text
http://localhost:18317/management.html
```

第一次进入面板时填写 CPA 地址和 Management Key。也可以启动时直接传入：

```powershell
powershell -ExecutionPolicy Bypass -File .\start-windows.ps1 `
  -CpaUrl "http://127.0.0.1:8317" `
  -ManagementKey "你的 Management Key"
```

SQLite 数据默认保存在 `release\windows\data\usage.sqlite`。服务日志保存在 `release\windows\data\cpa-manager.log`。

## 安装成 Windows 服务

用管理员权限打开 PowerShell，然后执行：

```powershell
cd .\release\windows
powershell -ExecutionPolicy Bypass -File .\install-windows-service.ps1
```

带 CPA 地址和 Management Key 安装：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows-service.ps1 `
  -CpaUrl "http://127.0.0.1:8317" `
  -ManagementKey "你的 Management Key"
```

安装后打开：

```text
http://localhost:18317/management.html
```

常用管理命令：

```powershell
Get-Service CPAManagerUsageService
Restart-Service CPAManagerUsageService
Stop-Service CPAManagerUsageService
Start-Service CPAManagerUsageService
```

卸载服务：

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall-windows-service.ps1
```

## CPA 必需配置

CPA 里需要启用用量发布：

```yaml
usage-statistics-enabled: true
```

同一个 CPA 实例只运行一个 Usage Service。Usage Service 停止太久后，超过 CPA 队列保留时间的统计无法补回。

## 环境变量

脚本会设置这些变量：

| 变量 | 默认值 | 说明 |
|---|---:|---|
| `HTTP_ADDR` | `0.0.0.0:18317` | Usage Service HTTP 监听地址 |
| `USAGE_DATA_DIR` | `.\data` | SQLite 数据目录 |
| `USAGE_DB_PATH` | `.\data\usage.sqlite` | SQLite 数据库路径 |
| `CPA_UPSTREAM_URL` | 空 | CPA 地址 |
| `CPA_MANAGEMENT_KEY` | 空 | CPA Management Key |
| `USAGE_CORS_ORIGINS` | `*` | CPA 自带面板访问 Usage Service 时的 CORS 来源 |
| `CPA_MANAGER_SERVICE_NAME` | `CPAManagerUsageService` | Windows 服务名 |
