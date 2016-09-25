# OpenWrt Smarthome


## 简介

这是一个我自娱自乐的小项目。通过在 OpenWrt 路由器上判断指定MAC地址是否在线，实现了两个场影：到家和离家。设备上线时（到家）执行开灯操作，设备离线时（离家）执行关灯操作，目前只支持Yeelight智能灯。开灯时会设置灯光为日光模式，亮度最亮。


## 安装配置

核心代码用Lua写成，用lua的daemon模块实现以deamon模式运行，所以需要区分硬件平台。目前编译好了三个平台的ipk包，从ipk目录下载对应的ipk包。具体平台和包名的对应关系：
 * smarthome_x.x.x-x_ar71xx.ipk 适用于 Atheros AR7xxx/AR9xxx 硬件平台，主要以TP-Link，水星品牌的路由器为主
 * smarthome_x.x.x-x_ramips_24kec.ipk 适用于 Ralink RT288x/RT3xxx 硬件平台，国内各家智能路由器大多属于此类
 * smarthome_x.x.x-x_x86.ipk 适用于Intel X86 硬件平台，不用多说了

把下载的ipk包上传到路由器，进行安装：  

    opkg update  
    opkg install <ipk 包名>
然后打开openwrt Web管理页面，进入 “Services” -> “Smart Home” ，添加家庭成员的手机的MAC地址，保存应用即可。

## 编译

不在上述列表的硬件平台，需要您自行编译。
将 smarthome 文件夹放到 Openwrt 项目 package/network/services/ 目录下。在openwrt 项目根目录执行make menuconfig，根据您的设备选择好硬件平台，再选中Network下的smarthome，保存退出。执行 make package/smarthome/compile 进行编译。完成之后在bin/目录下相应子文件夹中找到生成的ipk包，按照“安装配置”中的描述进行安全配置。

## TODO
 * 实现灯光参数的配置
 * 实现多灯的支持
 * 支持智能插座
