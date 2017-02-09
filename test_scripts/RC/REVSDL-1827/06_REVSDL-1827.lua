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
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
--Instruction for config multi-devcies: https://adc.luxoft.com/confluence/display/REVSDL/Connecting+Multi-Devices+with+ATF
--Declaration connected devices.
--1. Device 2:
-- local device2 = "192.168.100.199"
-- local device2Port = 12345
-- --2. Device 3:
-- local device3 = "10.42.0.1"
-- local device3Port = 12345

---------------------------------------------------------------------------------------------

--groups_nonPrimaryRC Group
local arrayGroups_nonPrimaryRC = revsdl.arrayGroups_PrimaryRC()


--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: Policies: "equipment" permissions must be checked-----------------
-------------------------- against location provided from HMI--------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 6==========================================================--
	--Begin Test suit CommonRequestCheck.6 for Req.#6

	--Description: 6. In case an RC application from <deviceID> device has driver's permission to control <moduleType> from <HMI-provided interiorZone> (via RC.OnDeviceLocationChanged from HMI)
						-- and any application from the same device sends an rc-RPC for controlling a different <moduleType>
						-- RSDL must send the RC.GetInteriorVehicleDataConsent for getting driver's allowance to control this different <moduleType> to the vehicle (HMI).


	--Begin Test case CommonRequestCheck.6.1
	--Description: 	RSDL must send the RC.GetInteriorVehicleDataConsent for getting driver's allowance to control this different <moduleType> to the vehicle (HMI).

		--Requirement/Diagrams id in jira:
				--Requirement
				--Requirement

		--Verification criteria:
				--RSDL must send the RC.GetInteriorVehicleDataConsent for getting driver's allowance to control this different <moduleType> to the vehicle (HMI).

		-----------------------------------------------------------------------------------------
		-------------------------FOR LEFT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Left Passenger) (col=0, row=1, level=0)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocationDevice1_Left()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = 1, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.6.1.1
			--Description: application sends GetInteriorVehicleData as Driver zone and ModuleType = RADIO
				function Test:GetInterior_DriverRADIO()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application"],
									moduleType = "RADIO",
									zone =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect RC.GetInteriorVehicleData request
							EXPECT_HMICALL("RC.GetInteriorVehicleData")
							:Do(function(_,data)
									--hmi side: sending RC.GetInteriorVehicleData response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
											moduleData = {
												moduleType = "RADIO",
												moduleZone = {
													col = 0,
													colspan = 2,
													level = 0,
													levelspan = 1,
													row = 0,
													rowspan = 2
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

							end)
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.6.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.6.1.2
			--Description: application sends SetInteriorVehicleData as Back Right and ModuleType = CLIMATE (different moduleType and the same app)
				function Test:SetInterior_RightCLIMATE_SamneApp()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
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
								col = 1,
								levelspan = 1,
								level = 0
							},
							climateControlData =
							{
								fanSpeed = 50,
								desiredTemp = 24,
								temperatureUnit = "CELSIUS"
							}
						}
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application"],
									moduleType = "CLIMATE",
									zone =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect RC.SetInteriorVehicleData request
							EXPECT_HMICALL("RC.SetInteriorVehicleData")
							:Do(function(_,data)
									--hmi side: sending RC.SetInteriorVehicleData response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
										moduleData =
										{
											moduleType = "CLIMATE",
											moduleZone =
											{
												colspan = 2,
												row = 1,
												rowspan = 2,
												col = 1,
												levelspan = 1,
												level = 0
											},
											climateControlData =
											{
												fanSpeed = 50,
												desiredTemp = 24,
												temperatureUnit = "CELSIUS"
											}
										}
									})

								end)
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.6.1.2

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.6.1



	--Begin Test case CommonRequestCheck.6.2
	--Description: 	For ButtonPress

		--Requirement/Diagrams id in jira:
				--Requirement
				--Requirement

		--Verification criteria:
				--RSDL must send the RC.GetInteriorVehicleDataConsent for getting driver's allowance to control this different <moduleType> to the vehicle (HMI).

		-----------------------------------------------------------------------------------------

			--Begin Test case Precondition.6.2.1
			--Description: Register new sessions
				function Test:PreconditionNewSession()
					--New session1
					self.mobileSession1 = mobile_session.MobileSession(
						self,
						self.mobileConnection)
				end
			--End Test case Precondition.6.2.1

		-----------------------------------------------------------------------------------------

			--Begin Test case Precondition.6.2.2
			--Description: Register App1 for precondition
					function Test:TC6_PassengerDevice_App1()
						self.mobileSession1:StartService(7)
						:Do(function()
								local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
								{
								  syncMsgVersion =
								  {
									majorVersion = 3,
									minorVersion = 0
								  },
								  appName = "Test Application1",
								  isMediaApplication = true,
								  languageDesired = 'EN-US',
								  hmiDisplayLanguageDesired = 'EN-US',
								  appHMIType = { "NAVIGATION", "REMOTE_CONTROL" },
								  appID = "1"
								})

								EXPECT_HMICALL("BasicCommunication.OnAppRegistered",
								{
								  application =
								  {
									appName = "Test Application1"
								  }
								})
								:Do(function(_,data)
									self.applications["Test Application1"] = data.params.application.appID
								end)

								--SDL sends RegisterAppInterface_response (success:true) with the following resultCodes: SUCCESS
								self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

								--mobile side: Expect OnPermissionsChange notification for Passenger's device
								self.mobileSession1:ExpectNotification("OnPermissionsChange", arrayGroups_nonPrimaryRC )

							end)
						end
			--End Test case Precondition.6.2.2

		-----------------------------------------------------------------------------------------

		-----------------------------------------------------------------------------------------
		-------------------------FOR LEFT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Left Passenger) (col=0, row=1, level=0)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocationDevice1_Left()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = 1, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 1,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.6.2.1
			--Description: application sends GetInteriorVehicleData as Driver zone and ModuleType = RADIO
				function Test:GetInterior_DriverRADIO()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application"],
									moduleType = "RADIO",
									zone =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect RC.GetInteriorVehicleData request
							EXPECT_HMICALL("RC.GetInteriorVehicleData")
							:Do(function(_,data)
									--hmi side: sending RC.GetInteriorVehicleData response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
											moduleData = {
												moduleType = "RADIO",
												moduleZone = {
													col = 0,
													colspan = 2,
													level = 0,
													levelspan = 1,
													row = 0,
													rowspan = 2
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

							end)
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.6.2.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.6.2.2
			--Description: application sends SetInteriorVehicleData as Back Right and ModuleType = CLIMATE (different moduleType app2)
				function Test:SetInterior_RightCLIMATE_App2()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData",
					{
						moduleData =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 1,
								rowspan = 2,
								col = 1,
								levelspan = 1,
								level = 0
							},
							climateControlData =
							{
								fanSpeed = 50,
								desiredTemp = 24,
								temperatureUnit = "CELSIUS"
							}
						}
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application1"],
									moduleType = "CLIMATE",
									zone =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect RC.SetInteriorVehicleData request
							EXPECT_HMICALL("RC.SetInteriorVehicleData")
							:Do(function(_,data)
									--hmi side: sending RC.SetInteriorVehicleData response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
										moduleData =
										{
											moduleType = "CLIMATE",
											moduleZone =
											{
												colspan = 2,
												row = 1,
												rowspan = 2,
												col = 1,
												levelspan = 1,
												level = 0
											},
											climateControlData =
											{
												fanSpeed = 50,
												desiredTemp = 24,
												temperatureUnit = "CELSIUS"
											}
										}
									})

								end)
					end)

					self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.6.2.2

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.6.2

--=================================================END TEST CASES 6==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end