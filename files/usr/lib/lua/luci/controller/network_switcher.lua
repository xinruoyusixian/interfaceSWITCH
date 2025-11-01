module("luci.controller.network_switcher", package.seeall)

function index()
    entry({"admin", "services", "network_switcher"}, firstchild(), _("网络切换器"), 60).dependent = false
    entry({"admin", "services", "network_switcher", "overview"}, template("network_switcher/overview"), _("概览"), 1)
    entry({"admin", "services", "network_switcher", "settings"}, cbi("network_switcher/network_switcher"), _("设置"), 2)
    entry({"admin", "services", "network_switcher", "logs"}, template("network_switcher/logs"), _("日志"), 3)
    
    -- AJAX接口
    entry({"admin", "services", "network_switcher", "status"}, call("action_status"))
    entry({"admin", "services", "network_switcher", "service_control"}, call("action_service_control"))
    entry({"admin", "services", "network_switcher", "switch"}, call("action_switch"))
    entry({"admin", "services", "network_switcher", "test"}, call("action_test"))
    entry({"admin", "services", "network_switcher", "get_logs"}, call("action_get_logs"))
    entry({"admin", "services", "network_switcher", "clear_logs"}, call("action_clear_logs"))
    entry({"admin", "services", "network_switcher", "get_configured_interfaces"}, call("action_get_configured_interfaces"))
end

function action_status()
    local LuciUtil = require "luci.util"
    local LuciSys = require "luci.sys"
    
    local result = {
        service = "unknown",
        status_output = "",
        interfaces = {}
    }
    
    -- 检查服务状态
    local service_status = LuciSys.init.enabled("network_switcher") and "enabled" or "disabled"
    local running = LuciSys.call("pgrep -f 'network_switcher.sh daemon' >/dev/null") == 0
    
    if running then
        result.service = "running"
    else
        result.service = "stopped"
    end
    
    -- 获取状态输出
    local status_output = LuciUtil.exec("/usr/bin/network_switcher.sh status 2>/dev/null")
    result.status_output = status_output or "无法获取状态信息"
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_service_control()
    local LuciSys = require "luci.sys"
    local action = luci.http.formvalue("action")
    local result = { success = false, message = "" }
    
    if action == "start" then
        result.success = LuciSys.call("/etc/init.d/network_switcher start >/dev/null 2>&1") == 0
        result.message = result.success and "服务启动成功" or "服务启动失败"
    elseif action == "stop" then
        result.success = LuciSys.call("/etc/init.d/network_switcher stop >/dev/null 2>&1") == 0
        result.message = result.success and "服务停止成功" or "服务停止失败"
    elseif action == "restart" then
        result.success = LuciSys.call("/etc/init.d/network_switcher restart >/dev/null 2>&1") == 0
        result.message = result.success and "服务重启成功" or "服务重启失败"
    elseif action == "enable" then
        result.success = LuciSys.call("/etc/init.d/network_switcher enable >/dev/null 2>&1") == 0
        result.message = result.success and "服务已启用开机启动" or "启用开机启动失败"
    elseif action == "disable" then
        result.success = LuciSys.call("/etc/init.d/network_switcher disable >/dev/null 2>&1") == 0
        result.message = result.success and "服务已禁用开机启动" or "禁用开机启动失败"
    else
        result.message = "未知操作"
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_switch()
    local LuciUtil = require "luci.util"
    local interface = luci.http.formvalue("interface")
    local result = { success = false, message = "" }
    
    if not interface or interface == "" then
        result.message = "未指定接口"
    else
        local command
        if interface == "auto" then
            command = "/usr/bin/network_switcher.sh auto"
        else
            command = "/usr/bin/network_switcher.sh switch " .. interface
        end
        
        local output = LuciUtil.exec(command .. " 2>&1")
        result.success = true  -- 命令执行成功，但切换可能失败
        result.message = output or "切换操作完成"
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_test()
    local LuciUtil = require "luci.util"
    local output = LuciUtil.exec("/usr/bin/network_switcher.sh test 2>&1")
    
    local result = {
        output = output or "测试完成"
    }
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_get_logs()
    local LuciUtil = require "luci.util"
    local logs = LuciUtil.exec("tail -50 /var/log/network_switcher.log 2>/dev/null") or "日志文件为空或不存在"
    
    local result = {
        logs = logs
    }
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_clear_logs()
    local LuciUtil = require "luci.util"
    LuciUtil.exec("echo '' > /var/log/network_switcher.log 2>/dev/null")
    
    local result = {
        success = true,
        message = "日志已清空"
    }
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_get_configured_interfaces()
    local LuciUtil = require "luci.util"
    local LuciSys = require "luci.sys"
    local interfaces = {}
    
    -- 从UCI配置读取启用的接口
    local uci = require "luci.model.uci".cursor()
    uci:foreach("network_switcher", "interface",
        function(section)
            if section.enabled == "1" and section.interface then
                table.insert(interfaces, section.interface)
            end
        end
    )
    
    -- 如果没有配置接口，返回默认值
    if #interfaces == 0 then
        interfaces = {"wan", "wwan"}
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(interfaces)
end
