-- Copyright 2021 Zach Varberg, SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
local capabilities = require 'st.capabilities'
local Driver = require 'st.driver'
local log = require 'log'
local dkjson = require "dkjson"

local cosock = require "cosock"
local discovery = require 'disco'
local utils = require 'st.utils'
local http = cosock.asyncify "socket.http"
local socket = require "socket"
local ltn12 = require "ltn12"

local blockPercent = capabilities["pianobook11249.blockPercent"]
local blockedQueries = capabilities["pianobook11249.blockedQueries"]
local totalQueries = capabilities["pianobook11249.totalQueries"]

local function validate_ip_pref(device)
    local ip_addr = device.preferences.ipAddress
    if ip_addr == nil or ip_addr == "" then
        log.warn("Please set pihole IP address preference")
        return false
    else
        -- currently ipv4 only
        local parts = {string.match(ip_addr, "^(%d+)%.(%d+)%.(%d+)%.(%d+)$")}
        if #parts ~= 4 then
            log.warn("IP address does not appear valid " .. ip_addr)
            return false
        end
        for pos, part in ipairs(parts) do
            if tonumber(part) < 0 or tonumber(part) > 255 then
                log.warn("IP address does not appear valid " .. ip_addr)
                return false
            end
        end
    end
    return true
end

local function validate_webpassword_pref(device)
    if device.preferences.webpassword == nil or device.preferences.webpassword == "" then
        log.warn("Please set pihole webpassword preference")
        return false
    end
    return true
end

local function send_query(device, command)
    if not validate_ip_pref(device) or not validate_webpassword_pref(device) then
        return
    end
    local query = string.format("http://%s/admin/api.php?%s&auth=%s", device.preferences.ipAddress, command, socket.url.escape(device.preferences.webpassword))
    local response_body = {}
    local resp, code_or_err, _, status_line = http.request {
        url = query,
        method = "GET",
        sink = ltn12.sink.table(response_body),
        headers = {}
    }
    if code_or_err == 200 then
        return dkjson.decode(response_body[1])
    else
        log.warn("Received unexpected http response code: " .. (status_line or tostring(code_or_err)))
        log.warn(response_body[1])
    end
end

local function emit_status_events(device, response)
    if response == nil then
        return
    end
    log.info(string.format("Device: %s received response: %s", tostring(device), utils.stringify_table(response, "status", true)))
    if response["status"] == "enabled" then
        device:emit_event(capabilities.switch.switch.on())
    elseif response["status"] == "disabled" then
        device:emit_event(capabilities.switch.switch.off())
    end
end

local handle_switch_on = function(driver, device, command)
    emit_status_events(device, send_query(device, "enable"))
end

local handle_switch_off = function(driver, device, command)
    emit_status_events(device, send_query(device, "disable"))
end

local function emit_summaryRaw_events(device, response)
    if response == nil then
        return
    end
    log.info("Received " .. utils.stringify_table(response, "summaryRaw", true))
    local level = utils.clamp_value(utils.round(response["ads_percentage_today"]), 0, 100)
    device:emit_event(blockPercent.blockPercent(level))
    device:emit_event(blockedQueries.blockedQueries(response["ads_blocked_today"] or 0))
    device:emit_event(totalQueries.totalQueries(response["dns_queries_today"] or 0))
end

local handle_data_refresh = function(driver, device, command)
    -- Get Block percentage
    emit_summaryRaw_events(device, send_query(device, "summaryRaw"))
    -- Get Status
    emit_status_events(device, send_query(device, "status"))
end

local function device_status_check(driver)
    log.debug("Performing periodic device status check")
    for id, device in pairs(driver.device_cache) do
        handle_data_refresh(driver, device, {})
    end
end

local function device_added(driver, device)
    device:emit_event(capabilities.switch.switch.on())
    device:emit_event(blockPercent.blockPercent(0))
    device:emit_event(blockedQueries.blockedQueries(0))
    device:emit_event(totalQueries.totalQueries(0))
end

local function device_init(driver, device)
    device_status_check(driver)
end


local driver = Driver('pi_hole', {
    lifecycle_handlers = {
        added = device_added,
        init = device_init,
    },
    capability_handlers = {
        [capabilities.switch.ID] = {
            [capabilities.switch.commands.on.NAME] = handle_switch_on,
            [capabilities.switch.commands.off.NAME] = handle_switch_off
        },
        [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = handle_data_refresh
        }
    },

    discovery = discovery.disco_handler,
})

driver.device_level_timer = driver:call_on_schedule(600, device_status_check, "PiHole stats check")
driver:run()
