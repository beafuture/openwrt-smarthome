#!/usr/bin/lua

require 'daemon'

daemon.daemonize()

uci=require("uci").cursor()
local util= require "luci.util"
local socket = require("socket")
local host = "239.255.255.250"
local port = 1982

local scan_socket

local detected_bulbs={}
local bulb_idx2ip = {}
local current_command_id=0

local members = {}

-- home status: 0 not at home, 1 at home, 2 start running init status
local status=2

function log_info( info )
    util.exec("logger smarthome:" .. info)
end

function sleep(n)
   socket.select(nil, nil, n)
end

function  send_search_broadcast () 
    scan_socket = socket.udp()
    scan_socket:settimeout(2)
    scan_socket:setoption("ip-multicast-loop",false)
    print("scanning Yeelight device...")
    local msg = "M-SEARCH * HTTP/1.1\r\n" 
    msg = msg .. "HOST: 239.255.255.250:1982\r\n"
    msg = msg .. "MAN: \"ssdp:discover\"\r\n"
    msg = msg .. "ST: wifi_bulb"
    scan_socket:sendto(msg, host, port)
end

function bulbs_detection()
    local data=''
    send_search_broadcast()
    local data, err = scan_socket:receive()
    if data then
       -- print (data)
    else
       print (err)
    end
    handle_search_response(data)
end

function handle_search_response(data)
    if not data then
        return false
    end
    local model
    local power
    local bright
    local rgb
    local host_ip
    local host_port
    local bulb_id
    for k,v in string.gmatch(data,"(%a+): (%C*)") do
        if (k == "model") then
            model = v
        elseif (k == "power") then
            power = v
        elseif (k == "bright") then
            bright = v
        elseif (k == "rgb") then
            rgb = v
        elseif (k == "Location") then
            host_ip = string.match(v,"%d+\.%d+\.%d+\.%d+")
            host_port = string.match(v,"%d+$")
        end
    end
    if detected_bulbs[host_ip] then
        bulb_id = detected_bulbs[host_ip][1]
    else
        bulb_id = table.getn(bulb_idx2ip)+1
    end
    detected_bulbs[host_ip] = { bulb_id, model, power, bright, rgb, host_port}
    bulb_idx2ip[bulb_id] = host_ip
end

function display_bulb(idx)
    if not bulb_idx2ip[idx] then
        print ("error: invalid bulb idx")
        return
    end
    local bulb_ip = bulb_idx2ip[idx]
    local model = detected_bulbs[bulb_ip][2]
    local power = detected_bulbs[bulb_ip][3]
    local bright = detected_bulbs[bulb_ip][4]
    local rgb = detected_bulbs[bulb_ip][5]
    print (idx .. ": ip="  .. bulb_ip .. ":" .. host_port .. ",model=" .. model ..",power=" .. power .. ",bright=" .. bright .. ",rgb=" .. rgb)
end

function display_bulbs()
    print (table.getn(bulb_idx2ip) .. " managed bulbs")
    for i in pairs(bulb_idx2ip) do
        display_bulb(i)
    end
end

function next_cmd_id()
    current_command_id = current_command_id+1
    return current_command_id
end

function operate_on_bulb(idx, method, params)
    if not bulb_idx2ip[idx] then
        print ("error: invalid bulb idx")
        return
    end
    
    local bulb_ip=bulb_idx2ip[idx]
    local port=detected_bulbs[bulb_ip][6]
    local tcp_socket = socket.tcp()
    tcp_socket:settimeout(2)
    print ("connect ",bulb_ip, port ,"...")
    tcp_socket:connect(bulb_ip, tonumber(port))
    local  msg="{\"id\":" .. next_cmd_id() .. ",\"method\":\""
    msg = msg .. method .. "\",\"params\":[" .. params .. "]}\r\n"
    tcp_socket:send(msg)
    local data=tcp_socket:receive("*l")
    if data then
        print (data)
        log_info (data)
    else
        print ("Can't get result")
        log_info ("Can't get result")
    end
    tcp_socket:close()
end

function set_power(idx, status)
    operate_on_bulb(idx, "set_power", '"' .. status .. '"')
end

function set_scene(idx)
    operate_on_bulb(idx, "set_scene", '"ct",6500,100')
end

function power_on()
    bulbs_detection()
    local host_ip =  bulb_idx2ip[1] or ''
    if host_ip == '' then
        print ("no Yeelight device founded.")
        return
    end
    local power = detected_bulbs[host_ip][3]
    if power == 'off' then
        operate_on_bulb(1, "set_power", '"on"')
        operate_on_bulb(1, "set_scene", '"ct",6500,100')
    end
end

function power_off()
    bulbs_detection()
    local host_ip =  bulb_idx2ip[1] or ''
    if host_ip == '' then
        print ("no Yeelight device founded.")
        return
    end
    local power = detected_bulbs[host_ip][3]
    if power == 'on' then
        operate_on_bulb(1, "set_power", '"off"')
    end
end

function check_online()
    local ntm = require "luci.model.network".init()
    local online_mac={}
    for _, dev in ipairs(ntm:get_wifidevs()) do
        for _, net in ipairs(dev:get_wifinets()) do
            for mac, _ in pairs(net:assoclist()) do
              if mac then
                  online_mac[string.lower(mac)]=true
              end
            end
        end
    end

    if online_mac then
        for k,v in pairs(members) do
            if online_mac[string.lower(v)] then
                return true, ''
            end
        end
    else
        return nil, ''
    end
    return false, ''
end

list_members = uci:get("smarthome", "config", "members")
if list_members then
    for _, v in pairs(list_members) do
        table.insert(members, v)
        log_info('add member: ' .. v)
    end
end

while 1 do
    at_home, err = check_online()
    if at_home==true then
        if status == 0 then
            print ("Welcome back to home")
            log_info ("Welcome back to home",'smarthome')
            status=1
            power_on()
        elseif status==2 then
            print ("Start: Welcome back to home")
            log_info ("Start: Welcome back to home",'smarthome')
            status=1
            power_on()
        else
            print ("Please enjoy the wonderful time at home")
        end
    elseif at_home==false then
        if status == 0 then
            print ("I will wait for you to come home")
        elseif status==2 then
            print ("Start: You left home")
            log_info ("Start: You left home",'smarthome')
            status = 0
            power_off()
        else
            print ("You left home")
            log_info ("You left home",'smarthome')
            status = 0
            power_off()
        end
    else
        print ("error:",err)
    end
    sleep(1)
end
