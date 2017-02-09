local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
commonPreconditions:ReplaceFile("sdl_preloaded_pt.json", "./test_scripts/RC/TestData/sdl_preloaded_pt.json")

local commonSteps = require("user_modules/shared_testcases/commonSteps")
commonSteps:DeleteLogsFileAndPolicyTable()

local revsdl = require("user_modules/revsdl")

revsdl.AddUnknownFunctionIDs()
revsdl.SubscribeToRcInterface()
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.appID = "8675311"

Test = require('connecttest')
require('cardinalities')

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
-----------Requirement: Validation: RPC with mismatched control-params and-------------------
----------------------moduleType from mobile app must get INVALID_DATA-----------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 4==========================================================--
  --Begin Test suit CommonRequestCheck.4 for Req.#4

  --Description: 4. In case application registered with REMOTE_CONTROL AppHMIType sends SetInteriorVehicleData RPC with "radioControlData" and CLIMATE moduleType
              -- RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.

  --Begin Test case CommonRequestCheck.4.1
  --Description:  RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.

    --Requirement/Diagrams id in jira:
        --Requirement

    --Verification criteria:
        --In case application registered with REMOTE_CONTROL AppHMIType sends SetInteriorVehicleData RPC with "radioControlData" and CLIMATE moduleType

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.1
      --Description: application sends SetInteriorVehicleData as Driver and ModuleType = CLIMATE (auto allow case)
        function Test:SetInterior_CLIMATE_RadioControlData()
          --mobile sends request for precondition
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                colspan = 2,
                row = 0,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0
              },
              radioControlData = {
                frequencyInteger = 99,
                frequencyFraction = 3,
                band = "FM",
                rdsData = {
                  PS = "name",
                  RT = "radio",
                  CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                  PI = "Sign",
                  PTY = 1,
                  TP = true,
                  TA = true,
                  REG = "Murica"
                },
                availableHDs = 3,
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
            }
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.4.1.1

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.4.1.2
      --Description: application sends SetInteriorVehicleData as Driver and ModuleType = CLIMATE (for Driver allow case)
        function Test:SetInterior_CLIMATE_LeftRadioControlData()
          --mobile sends request for precondition
          local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
          {
            moduleData =
            {
              moduleType = "CLIMATE",
              moduleZone =
              {
                colspan = 2,
                row = 1,
                rowspan = 2,
                col = 0,
                levelspan = 1,
                level = 0
              },
              radioControlData = {
                frequencyInteger = 99,
                frequencyFraction = 3,
                band = "FM",
                rdsData = {
                  PS = "name",
                  RT = "radio",
                  CT = "YYYY-MM-DDThh:mm:ss.sTZD",
                  PI = "Sign",
                  PTY = 1,
                  TP = true,
                  TA = true,
                  REG = "Murica"
                },
                availableHDs = 3,
                hdChannel = 1,
                signalStrength = 50,
                signalChangeThreshold = 60,
                radioEnable = true,
                state = "ACQUIRING"
              }
            }
          })

          --hmi side: not transferring this RPC to the vehicle.
          EXPECT_HMICALL("RC.SetInteriorVehicleData")
          :Times(0)

          --RSDL must respond with "resultCode: INVALID_DATA, success: false" to this mobile app, not transferring this RPC to the vehicle.
          EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

        end
      --End Test case CommonRequestCheck.4.1.2

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.4.1


--=================================================END TEST CASES 4==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end