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
local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local battery_defaults = require "st.zigbee.defaults.battery_defaults"
--- @type st.zigbee.zcl.clusters
local zcl_clusters = require "st.zigbee.zcl.clusters"
local OccupancySensing = zcl_clusters.OccupancySensing
local OnOff = zcl_clusters.OnOff
local xiaomi_utils = require "xiaomi-utils"

local XIAOMI_MOTION_TIMER_KEY = "xiaomi_motion_timer"

local function build_timer_callback(driver, device)
  local motion_timer_callback = function()
    device:set_field(XIAOMI_MOTION_TIMER_KEY, nil)
    device:emit_event(capabilities.motionSensor.motion.inactive())
  end
  return motion_timer_callback
end

local function on_off_contact_handler(self, device, value)
  device:emit_event(value.value and capabilities.contactSensor.contact.open() or capabilities.contactSensor.contact.closed())
end

-- The way xiaomi motion sensors work is that they report the occupancy sensing cluster occupancy value
-- as true (or 0x01 in the bitmap value) when it senses motion.  It will then continue to report that
-- value every 60 seconds.  When it stops sensing motion, it doesn't report 0 for the bitmap value instead
-- it just stops reporting the attribute value of 0x01.  So this method will start a timer on a given
-- device of 75 seconds every time it hears the occupancy report (cancelling any previous timer) and
-- if that timer gets hit, we then report motion inactive.
local function occupancy_handler(self, device, value)
  if value.value == 0x01 then
    local motion_timer = device:get_field(XIAOMI_MOTION_TIMER_KEY)
    if motion_timer ~= nil then
      device.thread:cancel_timer(motion_timer)
      device:set_field(XIAOMI_MOTION_TIMER_KEY, nil)
    end
    device:emit_event(capabilities.motionSensor.motion.active())
    local no_motion_timeout = device.preferences.noMotionTimeout or 75
    device:set_field(XIAOMI_MOTION_TIMER_KEY, device.thread:call_with_delay(no_motion_timeout, build_timer_callback(self, device)))
  end
end

local xiaomi_devices_prototype = {
  supported_capabilities = {
    capabilities.button,
    capabilities.motionSensor,
    capabilities.contactSensor,
    capabilities.battery,
    capabilities.temperatureMeasurement,
    capabilities.relativeHumidityMeasurement,
    capabilities.tvocMeasurement,
    capabilities.tvocHealthConcern,
  },
  zigbee_handlers = {
    global = {},
    cluster = {},
    attr = {
      [OnOff.ID] = {
        [OnOff.attributes.OnOff.ID] = on_off_contact_handler
      },
      [OccupancySensing.ID] = {
        [OccupancySensing.attributes.Occupancy.ID] = occupancy_handler
      },
      [zcl_clusters.basic_id] = {
        [0xFF02] = xiaomi_utils.battery_handler,
        [0xFF01] = xiaomi_utils.battery_handler
      }
    },
  },
  sub_drivers = { require("xiaomi_button"), require("aqara_air_sensor") }
}

defaults.register_for_default_handlers(
    xiaomi_devices_prototype,
    {
      capabilities.temperatureMeasurement,
      capabilities.relativeHumidityMeasurement,
      capabilities.battery
    }
)
local xiaomi_sensors = ZigbeeDriver("xiaomi-devices", xiaomi_devices_prototype)
xiaomi_sensors:run()
