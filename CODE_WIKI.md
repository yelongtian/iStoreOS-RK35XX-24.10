# iStore OS 固件项目 - Code Wiki 文档

## 1. 项目概述

### 1.1 项目简介
这是一个基于 GitHub Actions 的 iStore OS 固件自动编译项目，支持多种硬件设备的固件编译，包括 Rockchip 系列 ARMv8 设备和 x86 架构设备。

### 1.2 主要特性
- 支持多种设备固件编译（Rockchip ARMv8、x86）
- 定时自动编译（每天 0:00 北京时间）
- 支持固件自动发布到 GitHub Releases
- 自动同步 iStore OS 官方最新配置
- 集成丰富的网络和存储功能
- 支持 Docker 容器化

### 1.3 默认配置
- 默认管理地址：`http://192.168.100.1` 或 `http://iStoreOS.lan/`
- 默认用户名：`root`
- 默认密码：`password`
- 网口配置：单网口默认 LAN，多网口第一个为 WAN，其余为 LAN

---

## 2. 项目架构

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Actions                          │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Workflow 1: Sync Files (定时同步配置)                    │ │
│  │  - 下载官方 feeds.conf 和 config.buildinfo                │ │
│  │  - 合并自定义配置到 config_data-6.x.txt                 │ │
│  │  - 更新 armv8/ 和 x86/ 目录的配置文件                    │ │
│  └───────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Workflow 2: Build iStoreOS (固件编译)                     │ │
│  │  - 准备编译环境 (Ubuntu 22.04)                           │ │
│  │  - 克隆 iStoreOS 源码 (istoreos-24.10 分支)              │ │
│  │  - 应用自定义 DIY 脚本                                   │ │
│  │  - 编译固件 (ARMv8 / x86)                                │ │
│  │  - 发布固件到 Releases                                    │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      项目文件结构                                │
│  .github/workflows/       # GitHub Actions 工作流              │
│  armv8/                   # ARMv8 架构配置                     │
│  x86/                     # x86 架构配置                       │
│  configfiles/             # 自定义配置和文件                   │
│  diy-part1-*.sh           # 自定义脚本 Part 1                 │
│  diy-part2-*.sh           # 自定义脚本 Part 2                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 工作流说明

#### 2.2.1 Sync Files 工作流 (`.github/workflows/sync-files.yml`)
- **触发条件**：定时触发 (每天 15:55 UTC)，支持手动触发
- **主要功能**：
  - 从 iStore OS 官方源下载最新的 `feeds.conf` 和 `config.buildinfo`
  - 将自定义配置（`config_data-6.x.txt`）合并到配置中
  - 更新 `armv8/` 和 `x86/` 目录下的配置文件
  - 自动提交并推送到仓库

#### 2.2.2 Build iStoreOS 6.x 工作流 (`.github/workflows/build-istoreos-6.x.yml`)
- **触发条件**：定时触发 (每天 16:00 UTC)，支持手动触发
- **主要功能**：
  - 准备编译环境 (Ubuntu 22.04)
  - 克隆 iStore OS 源码
  - 应用 DIY 脚本进行定制
  - 编译固件
  - 上传固件到 GitHub Releases
  - 清理旧的 Releases 和工作流记录

---

## 3. 主要模块与文件说明

### 3.1 目录结构详解

```
/workspace/
├── .github/workflows/              # GitHub Actions 工作流目录
│   ├── build-istoreos-6.x.yml      # 6.x 版本固件编译工作流
│   ├── build-istoreos-x86.yml      # x86 固件编译工作流
│   └── sync-files.yml              # 配置文件同步工作流
├── armv8/                          # ARMv8 (Rockchip) 架构配置
│   ├── .config                     # OpenWrt 编译配置
│   └── feeds.conf                  # 软件源配置
├── x86/                            # x86 架构配置
│   ├── .config                     # OpenWrt 编译配置
│   └── feeds.conf                  # 软件源配置
├── configfiles/                    # 自定义配置文件
│   ├── coremark/                   # CPU 性能测试工具
│   │   ├── coremark-arm64         # ARM64 二进制文件
│   │   ├── coremark-arm64.sh      # ARM64 测试脚本
│   │   └── coremark-x86.sh        # x86 测试脚本
│   ├── dts/                        # 设备树文件
│   │   └── rk3588/                # RK3588 SoC 设备树
│   ├── etc/                        # 系统配置文件
│   │   ├── config/nginx           # Nginx 配置
│   │   └── nginx/                 # Nginx 模板
│   ├── packages/                   # 自定义软件包目录
│   └── config_data-6.x.txt        # 自定义编译配置项
├── diy-part1-6.x.sh                # 第一阶段 DIY 脚本
├── diy-part2-6.x.sh                # 第二阶段 DIY 脚本 (ARMv8)
├── diy-part2-6.x-x86.sh            # 第二阶段 DIY 脚本 (x86)
└── depends/ubuntu-22.04            # Ubuntu 22.04 依赖包列表
```

### 3.2 关键文件说明

#### 3.2.1 `diy-part1-6.x.sh` - 第一阶段自定义脚本
**功能**：在更新 feeds 前执行，主要用于修复内核配置问题。

**主要功能点**：
1. **内核 MD5 校验码修复**：从官方源获取正确的内核 vermagic 值，解决模块兼容性问题
2. **版本定制**：将固件版本号设置为编译时间戳
3. **作者标识**：在固件版本信息中添加作者标识

**关键代码逻辑**：
```bash
# 从多个官方镜像源获取内核版本 hash
hash_value=""
Releases_version=$(cat include/version.mk | sed -n 's|.*releases/\([^)]*\)).*|\1|p')

# 依次尝试多个镜像源
sources=(
    "https://downloads.openwrt.org/releases/${Releases_version}/targets/rockchip/armv8/kmods/"
    "https://archive.openwrt.org/releases/${Releases_version}/targets/rockchip/armv8/kmods/"
    "https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/${Releases_version}/targets/rockchip/armv8/kmods/"
    # ... 更多镜像源
)

for url in "${sources[@]}"; do
    http_value=$(wget -qO- "$url")
    hash_value=$(echo "$http_value" | sed -n 's/^.*-\([0-9a-f]\{32\}\)\/.*/\1/p' | head -1)
    [ -n "$hash_value" ] && break
done

# 保存 hash 值到 .vermagic
echo "$hash_value" > .vermagic

# 修改版本号和作者信息
date_version=$(date +"%Y%m%d%H")
echo $date_version > version
sed -i "s/DISTRIB_DESCRIPTION.*/DISTRIB_DESCRIPTION='%D %V ${date_version} by ${author}'/g" package/base-files/files/etc/openwrt_release
```

#### 3.2.2 `diy-part2-6.x.sh` - 第二阶段自定义脚本 (ARMv8)
**功能**：在加载配置后、编译前执行，用于定制固件功能。

**主要功能点**：
1. **Web 服务器配置**：将 uhttpd 端口改为 81/4443，启用 Nginx 作为默认 Web 服务器
2. **内核配置增强**：添加 PSI 和 KPROBES 内核配置
3. **集成性能测试工具**：复制 CoreMark 测试工具到固件
4. **设备树支持**：添加 Orange Pi 5 Plus 和 Radxa Rock 5T 的设备树文件
5. **自定义软件包**：集成 istoreos-settings 和 luci-app-eqosplus 等插件

**关键代码逻辑**：
```bash
# 修改 uhttpd 端口，为 Nginx 让出 80/443 端口
sed -i "s/:80/:81/g" package/network/services/uhttpd/files/uhttpd.config
sed -i "s/:443/:4443/g" package/network/services/uhttpd/files/uhttpd.config

# 复制 Nginx 配置文件
cp -a $GITHUB_WORKSPACE/configfiles/etc/* package/base-files/files/etc/

# 追加内核配置
echo "CONFIG_PSI=y" >> target/linux/rockchip/armv8/config-6.6
echo "CONFIG_KPROBES=y" >> target/linux/rockchip/armv8/config-6.6

# 集成 CoreMark
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64 package/base-files/files/bin/coremark-arm64
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64.sh package/base-files/files/bin/coremark.sh
chmod 755 package/base-files/files/bin/coremark-arm64
chmod 755 package/base-files/files/bin/coremark.sh

# 复制设备树文件
cp -a $GITHUB_WORKSPACE/configfiles/dts/rk3588/* target/linux/rockchip/dts/rk3588/

# 克隆自定义软件包
git clone --depth=1 -b main https://github.com/xiaomeng9597/istoreos-settings package/default-settings
git clone --depth=1 https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus
```

#### 3.2.3 `configfiles/config_data-6.x.txt` - 自定义编译配置
**功能**：定义需要添加到编译配置中的自定义项。

**主要配置项**：
```bash
# 目标设备
CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_xunlong_orangepi-5-plus=y
CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_radxa_rock-5t=y

# 硬件监控
CONFIG_PACKAGE_lm-sensors=y
CONFIG_PACKAGE_lm-sensors-detect=y

# WiFi 支持
CONFIG_PACKAGE_hostapd-common=y
CONFIG_PACKAGE_hostapd-openssl=y
CONFIG_PACKAGE_kmod-cfg80211=y
CONFIG_PACKAGE_kmod-mac80211=y

# 散热控制
CONFIG_PACKAGE_kmod-thermal=y
CONFIG_PACKAGE_kmod-hwmon-pwmfan=y

# 硬盘管理
CONFIG_PACKAGE_hd-idle=y
CONFIG_PACKAGE_luci-app-hd-idle=y

# Web 服务器 (Nginx)
CONFIG_PACKAGE_nginx=y
CONFIG_PACKAGE_nginx-ssl=y
CONFIG_PACKAGE_nginx-mod-luci=y
CONFIG_PACKAGE_luci-nginx=y

# 工具软件
CONFIG_PACKAGE_jq=y
CONFIG_PACKAGE_ntpdate=y
CONFIG_PACKAGE_hdparm=y
CONFIG_PACKAGE_stress-ng=y
CONFIG_PACKAGE_coreutils=y

# iStore OS 应用
CONFIG_PACKAGE_default-settings=y
CONFIG_PACKAGE_luci-app-store=y

# 定时限速
CONFIG_PACKAGE_luci-app-eqosplus=y
CONFIG_PACKAGE_luci-i18n-eqosplus-zh-cn=y
```

#### 3.2.4 `.github/workflows/build-istoreos-6.x.yml` - 固件编译工作流
**功能**：定义完整的固件编译流程。

**关键步骤**：
1. **合并磁盘**：使用 `easimon/maximize-build-space` 增加可用空间
2. **准备完成**：检出仓库代码
3. **创建工作目录**：设置工作区
4. **检查服务器配置**：显示 CPU、内存、磁盘信息
5. **初始化编译环境**：安装依赖包，清理系统
6. **克隆源码**：从 iStore OS 官方仓库克隆源码
7. **缓存构建**：使用 ccache 加速编译
8. **加载自定义 feeds**：应用 diy-part1 脚本
9. **更新 feeds**：更新软件包源
10. **安装 feeds**：安装软件包
11. **加载自定义配置**：应用 diy-part2 脚本
12. **下载软件包**：下载编译所需的源码包
13. **编译固件**：执行 make 编译
14. **上传 bin 文件夹**：上传编译产物
15. **整理固件文件**：准备发布文件
16. **上传固件目录**：上传固件工件
17. **生成发布标签**：创建版本号和发布说明
18. **自动发布固件**：发布到 GitHub Releases
19. **删除运行记录**：清理旧的工作流记录
20. **删除旧固件**：保留最近 60 个 Releases

**环境变量**：
```yaml
env:
  REPO_URL: https://github.com/istoreos/istoreos
  FEEDS_CONF: feeds.conf
  CONFIG_FILE: .config
  DIY_P1_SH: diy-part1-6.x.sh
  DIY_P2_SH: diy-part2-6.x.sh
  UPLOAD_BIN_DIR: true
  UPLOAD_FIRMWARE: true
  UPLOAD_RELEASE: true
  TZ: Asia/Shanghai
  GITHUB_TOKEN: ${{ secrets.ACCESS_TOKEN }}
```

#### 3.2.5 `.github/workflows/sync-files.yml` - 配置同步工作流
**功能**：自动同步官方配置文件。

**关键步骤**：
1. **准备完成**：检出仓库代码
2. **下载架构编译配置文件**：
   - 下载 `feeds.conf` 和 `config.buildinfo`
   - 合并 `config_data-6.x.txt` 到配置中
   - 清理重复配置项
3. **同步配置**：提交并推送更新
4. **删除运行记录**：清理旧记录

---

## 4. 支持设备与架构

### 4.1 支持的架构

| 架构 | 说明 | 分支 |
|------|------|------|
| ARMv8 (Rockchip) | RK33xx / RK35xx 系列 SoC | istoreos-24.10 |
| x86_64 | 通用 x86 64位设备 | istoreos-24.10 |

### 4.2 ARMv8 (Rockchip) 支持设备

#### 4.2.1 RK33xx 系列
- NanoPi R2S
- NanoPi R4S
- NanoPi R4SE
- Rock Pi 4A
- RockPro64

#### 4.2.2 RK35xx 系列
- Hinlink H66K / H68K / H69K
- Hinlink H88K
- NanoPi R5S
- NanoPi R6S
- FastRhino R66S / R68S
- Station P2
- T68M
- **Orange Pi 5 Plus** (本项目重点支持)
- **Radxa Rock 5T** (本项目重点支持)

### 4.3 x86 支持设备
- 通用 x86_64 设备 (BIOS 启动)
- 通用 x86_64 设备 (UEFI 启动)

---

## 5. 依赖关系

### 5.1 编译环境依赖 (Ubuntu 22.04)
依赖包列表位于 `depends/ubuntu-22.04`，主要包括：
- 编译工具链 (gcc, make, etc.)
- 库文件 (libssl, libelf, etc.)
- 开发工具 (git, python, etc.)

### 5.2 固件软件包依赖

#### 5.2.1 核心系统包
- `base-files` - 系统基础文件
- `busybox` - 嵌入式工具集
- `uhttpd` / `nginx` - Web 服务器
- `luci` - Web 管理界面

#### 5.2.2 网络功能包
- `dnsmasq-full` - DNS 和 DHCP 服务
- `firewall` - 防火墙管理
- `docker` / `dockerd` - 容器运行时
- `samba4` - 文件共享
- `nfs-kernel-server` - NFS 服务

#### 5.2.3 存储功能包
- `diskman` - 磁盘管理
- `mergerfs` - 联合文件系统
- `hd-idle` - 硬盘空闲管理
- `smartmontools` - 硬盘健康监测

#### 5.2.4 硬件支持包
- `lm-sensors` - 硬件监控
- `kmod-thermal` - 散热管理
- 各种网卡驱动 (kmod-r8125, kmod-igb, etc.)
- 各种 WiFi 驱动 (kmod-mt76*, kmod-rtl8xxx, etc.)

---

## 6. 开发与使用指南

### 6.1 自定义固件配置

#### 6.1.1 添加新设备支持
1. 在 `configfiles/config_data-6.x.txt` 中添加目标设备配置
2. 如果需要自定义设备树，放置在 `configfiles/dts/<soc>/` 目录
3. 在 `diy-part2-*.sh` 中添加复制设备树的代码

#### 6.1.2 添加自定义软件包
**方式一：通过配置文件**（推荐）
1. 编辑 `configfiles/config_data-6.x.txt`
2. 添加 `CONFIG_PACKAGE_<package-name>=y`
3. 等待 Sync Files 工作流运行或手动触发

**方式二：通过 DIY 脚本**
1. 编辑 `diy-part2-*.sh`
2. 使用 `git clone` 克隆软件包到 `package/` 目录
3. 在 `config_data-6.x.txt` 中添加启用配置

#### 6.1.3 修改系统配置文件
1. 将自定义文件放置在 `configfiles/etc/` 目录，保持目录结构
2. 在 `diy-part2-*.sh` 中确保有复制文件的代码：
   ```bash
   cp -a $GITHUB_WORKSPACE/configfiles/etc/* package/base-files/files/etc/
   ```

### 6.2 本地编译 (可选)

如果需要在本地编译而非使用 GitHub Actions，可以按以下步骤：

```bash
# 1. 准备 Ubuntu 22.04 环境
sudo apt update
sudo apt install -y $(cat depends/ubuntu-22.04)

# 2. 克隆 iStore OS 源码
git clone https://github.com/istoreos/istoreos -b istoreos-24.10 openwrt
cd openwrt

# 3. 复制配置文件
cp ../armv8/feeds.conf .
cp ../armv8/.config .

# 4. 应用 DIY 脚本
cp ../diy-part1-6.x.sh .
cp ../diy-part2-6.x.sh .
chmod +x diy-part1-6.x.sh diy-part2-6.x.sh
./diy-part1-6.x.sh

# 5. 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 6. 再次应用 DIY 脚本
./diy-part2-6.x.sh

# 7. 编译
make defconfig
make download -j8
make -j$(nproc) || make -j1 || make -j1 V=s
```

### 6.3 密钥配置
使用此项目需要在 GitHub 仓库设置中配置 Secrets：
- `ACCESS_TOKEN`: GitHub Personal Access Token，用于工作流推送代码和发布 Releases

---

## 7. 维护与常见问题

### 7.1 如何更新 iStore OS 源码分支？
编辑 `.github/workflows/build-istoreos-6.x.yml`，修改 `REPO_BRANCH` 的值：
```yaml
strategy:
  matrix:
    REPO_BRANCH:
      - istoreos-24.10  # 修改这里
```

### 7.2 编译失败怎么办？
1. 检查 Actions 日志，定位错误原因
2. 常见原因：
   - 磁盘空间不足 → 检查 `easimon/maximize-build-space` 配置
   - 源码包下载失败 → 重新运行工作流，或配置镜像源
   - 内核模块不兼容 → 检查 `diy-part1` 脚本获取的 vermagic 是否正确
3. 启用 SSH 调试（取消工作流中 SSH 相关注释），连接到 Actions 运行器调试

### 7.3 如何只编译特定设备？
编辑 `armv8/.config` 或 `configfiles/config_data-6.x.txt`，只保留需要的设备：
```bash
# 禁用不需要的设备
# CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_xxx is not set

# 启用需要的设备
CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_orangepi-5-plus=y
```

### 7.4 如何添加自定义内核模块？
1. 在 `diy-part2-*.sh` 中添加内核配置：
   ```bash
   echo "CONFIG_XXX=y" >> target/linux/rockchip/armv8/config-6.6
   ```
2. 在 `config_data-6.x.txt` 中添加相应的 kmod 包：
   ```bash
   CONFIG_PACKAGE_kmod-xxx=y
   ```

---

## 8. 参考资源

### 8.1 相关项目
- [iStore OS 官方](https://github.com/istoreos/istoreos)
- [OpenWrt 官方](https://github.com/openwrt/openwrt)
- [Lean's OpenWrt](https://github.com/coolsnowwolf/lede)

### 8.2 文档
- [iStore OS 使用文档](https://doc.linkease.com/zh/guide/istoreos)
- [OpenWrt 开发者文档](https://openwrt.org/docs/guide-developer/start)

---

## 9. 版本历史

- **当前版本**：基于 iStore OS 24.10 分支
- **编译频率**：每日自动编译
- **版本号格式**：`YYYY.MM.DD-HH.MM-<architecture>`

---

*本 Code Wiki 文档最后更新时间：2026-05-07*
