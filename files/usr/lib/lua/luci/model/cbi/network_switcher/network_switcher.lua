m = Map("network_switcher", translate("网络切换器配置"), 
    translate("配置网络接口的自动切换和故障转移功能。"))

-- 全局设置部分
s = m:section(NamedSection, "settings", "settings", translate("全局设置"))

enabled = s:option(Flag, "enabled", translate("启用服务"), 
    translate("启用网络切换器服务，将在后台监控网络状态并自动切换"))
enabled.default = "1"
enabled.rmempty = false

check_interval = s:option(Value, "check_interval", translate("检查间隔(秒)"), 
    translate("自动检查网络状态的间隔时间，单位：秒"))
check_interval.default = "60"
check_interval.datatype = "range(10,3600)"
check_interval.rmempty = false

ping_count = s:option(Value, "ping_count", translate("Ping次数"), 
    translate("每次测试发送的Ping包数量"))
ping_count.default = "3"
ping_count.datatype = "range(1,10)"
ping_count.rmempty = false

ping_timeout = s:option(Value, "ping_timeout", translate("Ping超时(秒)"), 
    translate("Ping操作的超时时间，单位：秒"))
ping_timeout.default = "3"
ping_timeout.datatype = "range(1,10)"
ping_timeout.rmempty = false

ping_success_count = s:option(Value, "ping_success_count", translate("成功阈值"), 
    translate("需要成功Ping通的最小目标数量"))
ping_success_count.default = "1"
ping_success_count.datatype = "range(1,10)"
ping_success_count.rmempty = false

switch_wait_time = s:option(Value, "switch_wait_time", translate("切换等待(秒)"), 
    translate("切换接口后的等待时间，单位：秒"))
switch_wait_time.default = "3"
switch_wait_time.datatype = "range(1,10)"
switch_wait_time.rmempty = false

-- Ping目标动态列表
ping_targets = s:option(DynamicList, "ping_targets", translate("Ping目标"), 
    translate("用于测试网络连通性的目标IP地址，每行一个"))
ping_targets.default = {"8.8.8.8", "1.1.1.1", "223.5.5.5", "114.114.114.114"}
ping_targets.datatype = "ipaddr"

-- 接口配置部分
s2 = m:section(TypedSection, "interface", translate("接口配置"), 
    translate("配置参与切换的网络接口及其优先级"))
s2.addremove = true
s2.anonymous = false
s2.template = "cbi/tblsection"

enabled_if = s2:option(Flag, "enabled", translate("启用"))
enabled_if.default = "1"
enabled_if.rmempty = false

-- 获取系统网络接口列表
local LuciSys = require "luci.sys"
local net = require "luci.model.network".init()

interface_name = s2:option(ListValue, "interface", translate("接口名称"))
for _, iface in ipairs(net:get_networks()) do
    if iface:name() ~= "loopback" then
        interface_name:value(iface:name(), iface:name())
    end
end
interface_name.rmempty = false

metric = s2:option(Value, "metric", translate("优先级"), 
    translate("数值越小优先级越高，主接口应该设置较小的值"))
metric.default = "10"
metric.datatype = "uinteger"
metric.rmempty = false

primary = s2:option(Flag, "primary", translate("主接口"), 
    translate("设置为主接口，自动切换时将优先使用此接口"))
primary.default = "0"

-- 定时任务部分
s3 = m:section(TypedSection, "schedule", translate("定时任务"), 
    translate("配置定时执行的网络切换任务"))
s3.addremove = true
s3.anonymous = false

enabled_sch = s3:option(Flag, "enabled", translate("启用"))
enabled_sch.default = "0"

schedule_time = s3:option(Value, "time", translate("执行时间"), 
    translate("格式: HH:MM (24小时制)"))
schedule_time.datatype = "timehhmm"
schedule_time.rmempty = false

schedule_action = s3:option(ListValue, "action", translate("执行动作"))
schedule_action:value("auto", translate("自动切换"))
schedule_action:value("switch wan", translate("切换到WAN"))
schedule_action:value("switch wwan", translate("切换到WWAN"))
schedule_action.default = "auto"
schedule_action.rmempty = false

return m
