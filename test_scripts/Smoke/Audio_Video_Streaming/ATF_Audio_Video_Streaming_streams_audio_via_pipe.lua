--  Requirement summary:
--  [Services]: SDL must open Audio Service in case navigation app sends StartService_request with appropriate serviceType
--
--  Description:
--  Check that SDL streams audio to web HMI via pipe.
--  
--  1. Used precondition
--  StartStreamRetry = 3, 1000
--  VideoStreamConsumer = pipe in .ini file.
--  SDL, HMI are started.
--  Register Navi isMedia = false app. 
--  Activate to FULL on HMI.
--
--  2. Performed steps
--  app_1 -> SDL: StartService ("serviceType" = 10)
--
--  Expected behavior:
--  SDL -> app_1: StartService_ACK
--  SDL opens Audio service for app_1

--[[ General Precondition before ATF start ]]
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"} 
config.application1.registerAppInterfaceParams.isMediaApplication = false

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()
commonPreconditions:BackupFile("smartDeviceLink.ini")

function Test:Start_SDL_With_One_Registered_App()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          self:startSession():Do(function ()
            commonFunctions:userPrint(35, "App is registered")
            commonSteps:ActivateAppInSpecificLevel(self, 
            self.applications[default_app_params.appName])
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
          end)
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Start_Audio_Service()
  --commonFunctions:write_parameter_to_smart_device_link_ini("AudioStreamConsumer", "pipe") 
  self.mobileSession:StartService(10)
  EXPECT_HMICALL("Navigation.StartAudioStream"):Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})  
    local function to_run()
      self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
    end
    RUN_AFTER(to_run, 300)
  end)
  EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})
end

function Test:Stop_Audio_Streaming()
  self.mobileSession:StopStreaming("files/Kalimba.mp3")
  EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = false})
end

function Test:StopService()
  self.mobileSession:StopService(10)
  EXPECT_HMICALL("Navigation.StopAudioStream"):Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
  end)
  commonTestCases:DelayedExp(20000)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
  StopSDL()
end

return Test