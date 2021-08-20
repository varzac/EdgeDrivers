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
local log = require 'log'
local utils = require "st.utils"

local function add_device(driver)
    log.trace('add_devices')
    local device_network_id = utils.generate_uuid_v4()
    local device_info = {
        type = 'LAN',
        device_network_id = device_network_id,
        label = 'PiHole',
        profile = 'pi-hole',
        vendor_provided_label = 'PiHole',
    }
    local success, msg = driver:try_create_device(device_info)
    if success then
        log.debug('successfully created device')
        return 'PiHole', device_network_id
    end
    log.error(string.format('unsuccessful create_device %s', msg))
    return nil, nil, msg
end

local function disco_handler(driver, opts, cont)
    log.trace('disco')
    local device_list = driver.device_api.get_device_list()
    log.trace('starting discovery')
    if #device_list > 0 then
        log.debug('stopping discovery with ' .. #device_list .. ' devices')
        return
    end
    log.debug('Adding ' .. driver.NAME .. ' device')
    local device_name, device_id, err = add_device(driver)
    if err ~= nil then
        log.error(err)
        return
    end
    log.info('Added ' .. device_name)
end

return {
    disco_handler = disco_handler,
    add_device = add_device,
}
