#!/bin/bash
#===============================================
# Description: DIY script
# File name: diy-script.sh
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#===============================================

# 修改uhttpd配置文件，启用nginx
# sed -i "/.*uhttpd.*/d" .config
# sed -i '/.*\/etc\/init.d.*/d' package/network/services/uhttpd/Makefile
# sed -i '/.*.\/files\/uhttpd.init.*/d' package/network/services/uhttpd/Makefile
sed -i "s/:80/:81/g" package/network/services/uhttpd/files/uhttpd.config
sed -i "s/:443/:4443/g" package/network/services/uhttpd/files/uhttpd.config
cp -a $GITHUB_WORKSPACE/configfiles/etc/* package/base-files/files/etc/
# ls package/base-files/files/etc/


# 追加自定义内核配置项
echo "CONFIG_PSI=y
CONFIG_KPROBES=y" >> target/linux/rockchip/armv8/config-6.6


# 集成CPU性能跑分脚本
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64 package/base-files/files/bin/coremark-arm64
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64.sh package/base-files/files/bin/coremark.sh
chmod 755 package/base-files/files/bin/coremark-arm64
chmod 755 package/base-files/files/bin/coremark.sh


# 复制dts设备树文件到指定目录下
cp -a $GITHUB_WORKSPACE/configfiles/dts/rk3588/* target/linux/rockchip/dts/rk3588/
[ -d "$GITHUB_WORKSPACE/configfiles/dts/rk3399" ] && cp -a $GITHUB_WORKSPACE/configfiles/dts/rk3399/* target/linux/rockchip/dts/rk3399/


# 添加 EMB3531 设备定义到 armv8.mk
if ! grep -q "rockchip_emb3531" target/linux/rockchip/image/armv8.mk; then
    cat >> target/linux/rockchip/image/armv8.mk << 'EOF'

define Device/rockchip_emb3531
  DEVICE_VENDOR := Rockchip
  DEVICE_MODEL := EMB3531
  SOC := rk3399
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS = rk3399/rk3399-emb3531
  DEVICE_PACKAGES := kmod-r8169
endef
TARGET_DEVICES += rockchip_emb3531
EOF
fi


# iStoreOS-settings
git clone --depth=1 -b main https://github.com/xiaomeng9597/istoreos-settings package/default-settings


# 定时限速插件
git clone --depth=1 https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus
