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
local capabilities = require "st.capabilities"

local xiaomi_contact_profile = {
  components = {
    main = {
      capabilities = {
        [capabilities.contactSensor.ID] = { id = capabilities.contactSensor.ID },
        [capabilities.battery.ID] = { id = capabilities.battery.ID },
      },
      id = "main"
    }
  }
}

local mock_device = test.mock_device.build_test_zigbee_device({profile = xiaomi_contact_profile })
zigbee_test_utils.prepare_zigbee_env_info()
local function test_init()
  test.mock_device.add_test_device(mock_device)
  zigbee_test_utils.init_noop_health_check_timer()
end
test.set_test_init_function(test_init)


test.register_message_test(
    "Reported contact should be handled: open",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_device, true) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.contactSensor.contact.open())
      }
    }
)

test.register_message_test(
    "Reported contact should be handled: closed",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_device, false) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.contactSensor.contact.closed())
      }
    }
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
