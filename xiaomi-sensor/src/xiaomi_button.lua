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
local zcl_clusters = require "st.zigbee.zcl.clusters"
local OnOff = zcl_clusters.OnOff
local ReportAttribute = require "st.zigbee.zcl.global_commands.report_attribute".ReportAttribute

-- Use a global attribute handler to work around limitation of multiple attribute records from the same
-- attribute being reported in a single message
local report_attribute_handler = function(self, device, zb_rx)
  for _, record in ipairs(zb_rx.body.zcl_body.attr_records) do
    if record.attr_id.value == OnOff.attributes.OnOff.ID and record.data.value == true then
      device:emit_event(capabilities.button.button.pushed({state_change = true}))
    end
  end
end

local function can_handle(opts, driver, device)
  return device:get_model() == "lumi.sensor_switch.aq2"
end

local xiaomi_button_subdriver = {
  NAME = "Xiaomi/Aqara Button",
  zigbee_handlers = {
    global = {
      [OnOff.ID] = {
        [ReportAttribute.ID] = report_attribute_handler
      }
    },
    cluster = {},
    attr = {
      [OnOff.ID] = {
        -- include no-op handler to override the contact default of the parent
        [OnOff.attributes.OnOff.ID] = function(...)end,
      }
    }
  },
  can_handle = can_handle
}

return xiaomi_button_subdriver
