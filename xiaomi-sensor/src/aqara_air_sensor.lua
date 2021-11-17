-- Copyright 2021 Zach Varberg
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
local battery_defaults = require "st.zigbee.defaults.battery_defaults"
local device_management = require "st.zigbee.device_management"
local data_types = require "st.zigbee.data_types"
--- @type st.zigbee.zcl.clusters
local clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"
local utils = require "st.utils"

local ANALOG_INPUT_CLUSTER = 0x000C
local ANALOG_INPUT_PRESENT_VALUE = 0x0055

local function is_aqara_air_sensor(opts, driver, device)
  return device:get_model() == "lumi.airmonitor.acn01"
end


local function round_to(val, unit_val)
  local mult = 1/unit_val
  if mult % 1 ~= 0 then
    error("unit_val should be a power of 10")
  end
  return (utils.round(val * mult)) * unit_val
end

local function configure(self, device)
  device:configure()
  device:refresh()

  device:send(device_management.attr_refresh(device, ANALOG_INPUT_CLUSTER, ANALOG_INPUT_PRESENT_VALUE))

  device:send(device_management.build_bind_request(device, ANALOG_INPUT_CLUSTER, self.environment_info.hub_zigbee_eui))
  local analog_cluster_present_value_conf = {
    cluster = ANALOG_INPUT_CLUSTER,
    attribute = ANALOG_INPUT_PRESENT_VALUE,
    minimum_interval = 30, -- 30 seconds
    maximum_interval = 600, -- 10 minutes
    data_type = data_types.SinglePrecisionFloat,
    -- 10.0 ppb or .01 ppm
    reportable_change = data_types.SinglePrecisionFloat(0, 3, .25)
  }
  device:send(device_management.attr_config(device, analog_cluster_present_value_conf))
end

local function handle_analog_value(driver, device, value)
  local tvoc_ppm = value.value / 1000 -- Value is in ppb
  device:emit_event(capabilities.tvocMeasurement.tvocLevel(round_to(tvoc_ppm, .001)))

  local tvoc_health_concern = 0
  if tvoc_ppm < 0.065 then
    tvoc_health_concern = "good"
  elseif tvoc_ppm <= 0.220 then
    tvoc_health_concern = "moderate"
  elseif tvoc_ppm <= 0.660 then
    tvoc_health_concern = "slightlyUnhealthy"
  elseif tvoc_ppm <= 2.200 then
    tvoc_health_concern = "unhealthy"
  elseif tvoc_ppm <= 5.500 then
    tvoc_health_concern = "veryUnhealthy"
  else
    tvoc_health_concern = "hazardous"
  end
  device:emit_event(capabilities.tvocHealthConcern.tvocHealthConcern(tvoc_health_concern))
end

local function identify_handler(driver, device, zb_rx)
  device:send(device_management.attr_refresh(device, ANALOG_INPUT_CLUSTER, ANALOG_INPUT_PRESENT_VALUE))
end

local aqara_air_sensor_subdriver = {
  NAME = "AqaraAirSensor",
  lifecycle_handlers = {
    init = battery_defaults.build_linear_voltage_init(2, 3),
    doConfigure = configure
  },
  zigbee_handlers = {
    attr = {
      [ANALOG_INPUT_CLUSTER] = {
        [ANALOG_INPUT_PRESENT_VALUE] = handle_analog_value
      },
    },
    cluster = {
      [clusters.Identify.ID] = {
        [clusters.Identify.commands.IdentifyQuery.ID] = identify_handler
      }
    }
  },
  can_handle = is_aqara_air_sensor
}

return aqara_air_sensor_subdriver