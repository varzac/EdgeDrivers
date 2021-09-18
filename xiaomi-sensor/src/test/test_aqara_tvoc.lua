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
local data_types = require "st.zigbee.data_types"
local capabilities = require "st.capabilities"
local t_utils = require "integration_test.utils"
local report_attr = require "st.zigbee.zcl.global_commands.report_attribute"
local zcl_messages = require "st.zigbee.zcl"

local mock_device = test.mock_device.build_test_zigbee_device({ profile = t_utils.get_profile_definition("tvoc-temperature-humidity.yml"), zigbee_endpoints ={ [1] = {id = 1, manufacturer ="LUMI", model ="lumi.airmonitor.acn01", server_clusters = {}} } })
zigbee_test_utils.prepare_zigbee_env_info()
local function test_init()
  test.mock_device.add_test_device(mock_device)
  zigbee_test_utils.init_noop_health_check_timer()
end
test.set_test_init_function(test_init)

local ANALOG_INPUT_CLUSTER = 0x000C
local ANALOG_INPUT_PRESENT_VALUE = 0x0055

local spf = data_types.SinglePrecisionFloat

local reported_tvoc_good = spf(0, 5, .56)
local reported_tvoc_vunhealthy = spf(0, 11, .36718)
local reported_tvoc_hazardous = spf(0, 12, .36718)


test.register_message_test(
        "Reported tvoc should be handled good",
        {
            {
                channel = "zigbee",
                direction = "receive",
                message = { mock_device.id, zigbee_test_utils.build_attribute_report(mock_device, ANALOG_INPUT_CLUSTER, {{ANALOG_INPUT_PRESENT_VALUE, spf.ID, reported_tvoc_good}})}
            },
            {
                channel = "capability",
                direction = "send",
                message = mock_device:generate_test_message("main", capabilities.tvocMeasurement.tvocLevel(.05))
            },
            {
                channel = "capability",
                direction = "send",
                message = mock_device:generate_test_message("main", capabilities.tvocHealthConcern.tvocHealthConcern("good"))
            },

        }
)

test.register_message_test(
        "Reported tvoc should be handled very unhealthy",
        {
            {
                channel = "zigbee",
                direction = "receive",
                message = { mock_device.id, zigbee_test_utils.build_attribute_report(mock_device, ANALOG_INPUT_CLUSTER, {{ANALOG_INPUT_PRESENT_VALUE, spf.ID, reported_tvoc_vunhealthy}})}
            },
            {
                channel = "capability",
                direction = "send",
                message = mock_device:generate_test_message("main", capabilities.tvocMeasurement.tvocLevel(2.8))
            },
            {
                channel = "capability",
                direction = "send",
                message = mock_device:generate_test_message("main", capabilities.tvocHealthConcern.tvocHealthConcern("veryUnhealthy"))
            },

        }
)

test.register_message_test(
        "Reported tvoc should be handled very unhealthy",
        {
            {
                channel = "zigbee",
                direction = "receive",
                message = { mock_device.id, zigbee_test_utils.build_attribute_report(mock_device, ANALOG_INPUT_CLUSTER, {{ANALOG_INPUT_PRESENT_VALUE, spf.ID, reported_tvoc_hazardous}})}
            },
            {
                channel = "capability",
                direction = "send",
                message = mock_device:generate_test_message("main", capabilities.tvocMeasurement.tvocLevel(5.6))
            },
            {
                channel = "capability",
                direction = "send",
                message = mock_device:generate_test_message("main", capabilities.tvocHealthConcern.tvocHealthConcern("hazardous"))
            },

        }
)

test.run_registered_tests()
