---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Exception 1
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #2
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with allowed:true
-- 2) and with any "accessMode" or without "accessMode" parameter at all
-- 3) and RC_module on HMI is alreay in control by RC-application_1
-- 4) and another RC_application_2 is in HMILevel other than FULL (either LIMITED or BACKGROUND)
-- SDL must:
-- 1) deny access to RC_module for another RC_application_2 after it sends control RPC
-- (either SetInteriorVehicleData or ButtonPress) for the same RC_module without asking a driver
-- 2) not process the request from RC_application_2 and respond with result code REJECTED, success:false
-- 3) leave RC_application_1 in control of the RC_module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }
local access_modes = { nil, "AUTO_ALLOW", "AUTO_DENY", "ASK_DRIVER" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App1", commonRC.activate_app)
runner.Step("RAI2", commonRC.rai_n, { 2 })
runner.Step("Activate App2", commonRC.activate_app, { 2 })

-- App's HMI levels: 1 - BACKGROUND, 2 - FULL

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  -- set control for App2
  runner.Step("App2 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
  for i = 1, #access_modes do
    runner.Title("Access mode: " .. tostring(access_modes[i]))
    -- set RA mode
    runner.Step("Set RA mode", commonRC.defineRAMode, { true, access_modes[i] })
    -- try to set control for App1 --> Denied
    runner.Step("App1 SetInteriorVehicleData", commonRC.rpcDenied, { mod, 1, "SetInteriorVehicleData", "REJECTED" })
    runner.Step("App1 ButtonPress", commonRC.rpcDenied, { mod, 1, "ButtonPress", "REJECTED" })
    -- try to set control for App2 --> Allowed
    runner.Step("App2 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
    runner.Step("App2 ButtonPress", commonRC.rpcAllowed, { mod, 2, "ButtonPress" })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)