-- Copyright 2022 Zach Varberg, SmartThings
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
local clusters = require "st.zigbee.zcl.clusters"
local OnOff = clusters.OnOff
local capabilities = require "st.capabilities"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local profile = t_utils.get_profile_definition("simple-switch.yml")
local mock_parent_device = test.mock_device.build_test_zigbee_device(
    {
      profile = profile,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "two_child",
          model = "two_child",
          server_clusters = { 0x0006, 0x0008 }
        },
        [2] = {
          id = 2,
          manufacturer = "two_child",
          model = "two_child",
          server_clusters = { 0x0006, 0x0008 }
        },
      },
      fingerprinted_endpoint_id = 0x01
    }
)

local mock_first_child = test.mock_device.build_test_child_device({
  profile = profile,
  device_network_id = string.format("%04X:%02X", mock_parent_device:get_short_address(), 1),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 1)
})

local mock_second_child = test.mock_device.build_test_child_device({
  profile = profile,
  device_network_id = string.format("%04X:%02X", mock_parent_device:get_short_address(), 2),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 2)
})

local mock_parent_2_device = test.mock_device.build_test_zigbee_device(
    {
      profile = profile,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "two_child_plus_one",
          model = "two_child_plus_one",
          server_clusters = { 0x0006, 0x0008 }
        },
        [2] = {
          id = 3,
          manufacturer = "two_child_plus_one",
          model = "two_child_plus_one",
          server_clusters = { 0x0006, 0x0008 }
        },
        [3] = {
          id = 3,
          manufacturer = "two_child_plus_one",
          model = "two_child_plus_one",
          server_clusters = { 0x0006, 0x0008 }
        },
      },
      fingerprinted_endpoint_id = 0x01
    }
)

local mock_first_2_child = test.mock_device.build_test_child_device({
  profile = profile,
  device_network_id = string.format("%04X:%02X", mock_parent_2_device:get_short_address(), 2),
  parent_device_id = mock_parent_2_device.id,
  parent_assigned_child_key = string.format("%02X", 2)
})

local mock_second_2_child = test.mock_device.build_test_child_device({
  profile = profile,
  device_network_id = string.format("%04X:%02X", mock_parent_2_device:get_short_address(), 3),
  parent_device_id = mock_parent_2_device.id,
  parent_assigned_child_key = string.format("%02X", 3)
})

zigbee_test_utils.prepare_zigbee_env_info()

local function test_init()
  test.mock_device.add_test_device(mock_parent_device)
  test.mock_device.add_test_device(mock_first_child)
  test.mock_device.add_test_device(mock_second_child)
  test.mock_device.add_test_device(mock_parent_2_device)
  test.mock_device.add_test_device(mock_first_2_child)
  test.mock_device.add_test_device(mock_second_2_child)
  zigbee_test_utils.init_noop_health_check_timer()
end

test.set_test_init_function(test_init)

test.register_message_test(
    "Reported on off status should be handled: on ep 1",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_parent_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_parent_device,
            true):from_endpoint(0x01) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_first_child:generate_test_message("main",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Reported on off status should be handled: on ep 2",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_parent_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_parent_device,
            true):from_endpoint(0x02) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_second_child:generate_test_message("main",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "Capability command switch on child 1 should be handled",
    {
      {
        channel = "capability",
        direction = "receive",
        message = { mock_first_child.id, { capability = "switch", component = "main", command = "on", args = { } } }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = { mock_parent_device.id, OnOff.server.commands.On(mock_parent_device):to_endpoint(0x01) }
      }
    }
)

test.register_message_test(
    "Capability command switch on child 2 should be handled",
    {
      {
        channel = "capability",
        direction = "receive",
        message = { mock_second_child.id, { capability = "switch", component = "main", command = "on", args = { } } }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = { mock_parent_device.id, OnOff.server.commands.On(mock_parent_device):to_endpoint(0x02) }
      }
    }
)

test.register_message_test(
    "2 Reported on off status should be handled: on ep 1",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_parent_2_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_parent_2_device,
            true):from_endpoint(0x02) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_first_2_child:generate_test_message("main",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "2 Reported on off status should be handled: on ep 2",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_parent_2_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_parent_2_device,
            true):from_endpoint(0x03) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_second_2_child:generate_test_message("main",  capabilities.switch.switch.on())
      }
    }
)

test.register_message_test(
    "2 Capability command switch on child 1 should be handled",
    {
      {
        channel = "capability",
        direction = "receive",
        message = { mock_first_2_child.id, { capability = "switch", component = "main", command = "on", args = { } } }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = { mock_parent_2_device.id, OnOff.server.commands.On(mock_parent_2_device):to_endpoint(0x02) }
      }
    }
)

test.register_message_test(
    "2 Capability command switch on child 2 should be handled",
    {
      {
        channel = "capability",
        direction = "receive",
        message = { mock_second_2_child.id, { capability = "switch", component = "main", command = "on", args = { } } }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = { mock_parent_2_device.id, OnOff.server.commands.On(mock_parent_2_device):to_endpoint(0x03) }
      }
    }
)


test.run_registered_tests()