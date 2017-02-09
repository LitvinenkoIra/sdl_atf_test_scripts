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

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: Send OnHMIStatus("deviceRank") when the device status-------------
---------------------------changes between "driver's" and "passenger's"----------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 2==========================================================--
  --Begin Test suit CommonRequestCheck.2 for Req.#2

  --Description: Check OnHMIStatus("deviceRank": <appropriate_value>, params) after RegisterAppInterface_response successfully


  --Begin Test case CommonRequestCheck.2
  --Description:  --RSDL must send OnHMIStatus("deviceRank: DRIVER", params) notification to application(s) registered with REMOTE_CONTROL appHMIType from <deviceID> device
              --in case RSDL has treated <deviceID> as passenger's
              --AND RSDL gets OnDeviceRankChanged ("DRIVER", <deviceID>) notification from HMI
              --(meaning, in case the device the rc-apps are running from is set as driver's)


    --Requirement/Diagrams id in jira:
        --Requirement
        --https://adc.luxoft.com/jira/secure/attachment/121953/121953_Req_2_of_Requirement.png

    --Verification criteria:
        --RSDL must send OnHMIStatus("deviceRank: DRIVER", params) notification to application(s) registered with REMOTE_CONTROL appHMIType from <deviceID> device
              --in case RSDL has treated <deviceID> as passenger's
              --AND RSDL gets OnDeviceRankChanged ("DRIVER", <deviceID>) notification from HMI
              --(meaning, in case the device the rc-apps are running from is set as driver's)

    -----------------------------------------------------------------------------------------

      --Begin Test case CommonRequestCheck.2.1
      --Description: Set device1 to Driver's device
        function Test:OnHMIStatus_OnDeviceRankChanged()

          --hmi side: send request RC.OnDeviceRankChanged
          self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
                              {deviceRank = "DRIVER", device = {name = "127.0.0.1", id = 1, isSDLAllowed = true}})

          --mobile side: Expect OnPermissionsChange notification for Driver's device
          EXPECT_NOTIFICATION("OnPermissionsChange", arrayGroups_PrimaryRC )

          --mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
          EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", deviceRank = "DRIVER" })

        end
      --End Test case CommonRequestCheck.2.1

    -----------------------------------------------------------------------------------------

  --End Test case CommonRequestCheck.2

--=================================================END TEST CASES 2==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end