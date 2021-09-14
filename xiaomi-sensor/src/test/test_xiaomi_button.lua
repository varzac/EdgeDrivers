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
local test = require "integration_test"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local OnOff = (require "st.zigbee.zcl.clusters").OnOff
local data_types = require "st.zigbee.data_types"
local t_utils = require "integration_test.utils"
local capabilities = require "st.capabilities"

local mock_device = test.mock_device.build_test_zigbee_device(
    {
      profile =  t_utils.get_profile_definition("button-battery.yml"),
      zigbee_endpoints = {
        [1] = {
          id = 1,
          client_clusters = {0x0000, 0x0004, 0xFFFF},
          server_clusters = {0x0000, 0x0006, 0xFFFF},
          manufacturer = "LUMI",
          model = "lumi.sensor_switch.aq2",
        }
      }
    }
)
zigbee_test_utils.prepare_zigbee_env_info()
local function test_init()
  test.mock_device.add_test_device(mock_device)
  zigbee_test_utils.init_noop_health_check_timer()
end
test.set_test_init_function(test_init)


test.register_message_test(
    "Reported pressed should turn on",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_device, true) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.button.button.pushed({state_change = true}))
      }
    }
)

test.register_coroutine_test(
    "Reported pressed should turn on two values",
    function()
      --attr_id, data_type, value
      local zb_mess = zigbee_test_utils.build_attribute_report(
          mock_device, 0x0006,
          {
            { 0x0000, data_types.Boolean.ID, false },
            { 0x0000, data_types.Boolean.ID, true }
          }
      )
      test.socket.zigbee:__queue_receive({mock_device.id, zb_mess})
      test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.button.button.pushed({state_change = true})))
    end
)


----------------------------------------------------------------
--- Battery handling
----------------------------------------------------------------
local char_string_body = (
    data_types.Uint8(1):_serialize() ..
        data_types.ZigbeeDataType(data_types.Uint32.ID):_serialize() ..
        data_types.Uint32(25):_serialize() ..
        data_types.Uint8(2):_serialize() ..
        data_types.ZigbeeDataType(data_types.Uint16.ID):_serialize() ..
        data_types.Uint16(2700):_serialize()
)
local custom_xiaomi_attr = data_types.CharString(char_string_body)

test.register_message_test(
    "Battery should be handled for 0xFF02",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, zigbee_test_utils.build_attribute_report(mock_device, 0x0000, { { 0xFF02, data_types.CharString.ID, custom_xiaomi_attr } }) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.battery.battery(40))
      }
    }
)

test.register_message_test(
    "Battery should be handled for 0xFF01",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, zigbee_test_utils.build_attribute_report(mock_device, 0x0000, { { 0xFF01, data_types.CharString.ID, custom_xiaomi_attr } }) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.battery.battery(40))
      }
    }
)

local struct_value = data_types.Structure({
                                            data_types.Uint32(25),
                                            data_types.Uint16(2700),
                                          })
local zb_mess = zigbee_test_utils.build_attribute_report(mock_device, 0x0000, { { 0xFF01, data_types.Structure.ID, struct_value } })
test.register_message_test(
    "Battery should be handled for Structure type",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, zb_mess }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.battery.battery(40))
      }
    }
)

test.run_registered_tests()
