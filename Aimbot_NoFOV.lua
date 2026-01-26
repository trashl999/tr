--[[

	Universal Aimbot Module (FOV REMOVIDO)
	Base: Exunys Aimbot V3
	Modificação: Remoção total do FOV (lógica + render)

]]

--// Cache
local game, workspace = game, workspace
local getrawmetatable, setmetatable, pcall, getgenv, next, tick =
	getrawmetatable, setmetatable, pcall, getgenv, next, tick

local Vector2new, Vector3zero, CFramenew, TweenInfonew =
	Vector2.new, Vector3.zero, CFrame.new, TweenInfo.new

local stringlower, stringsub, tablefind, tableremove, mathclamp =
	string.lower, string.sub, table.find, table.remove, math.clamp

local mousemoverel = mousemoverel or (Input and Input.MouseMove)

--// Metatable fallback
local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	__index = function(self, Index)
		return self[Index]
	end,
	__newindex = function(self, Index, Value)
		self[Index] = Value
	end
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex

local GetService = __index(game, "GetService")

--// Services
local RunService = GetService(game, "RunService")
local UserInputService = GetService(game, "UserInputService")
local TweenService = GetService(game, "TweenService")
local Players = GetService(game, "Players")

--// Service methods
local LocalPlayer = __index(Players, "LocalPlayer")
local Camera = __index(workspace, "CurrentCamera")

local FindFirstChild = __index(game, "FindFirstChild")
local FindFirstChildOfClass = __index(game, "FindFirstChildOfClass")
local GetDescendants = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetPlayers = __index(Players, "GetPlayers")

--// Variables
local Typing, Running, ServiceConnections, Animation, OriginalSensitivity =
	false, false, {}, nil, nil

local Connect = __index(game, "DescendantAdded").Connect
local Disconnect

do
	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
	Disconnect = TemporaryConnection.Disconnect
	Disconnect(TemporaryConnection)
end

--// Prevent multiple instances
if ExunysDeveloperAimbot and ExunysDeveloperAimbot.Exit then
	ExunysDeveloperAimbot:Exit()
end

--// Environment
getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor"
	},

	Settings = {
		Enabled = true,

		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,

		OffsetToMoveDirection = false,
		OffsetIncrement = 15,

		Sensitivity = 0,      -- Tween time (0 = instant)
		Sensitivity2 = 3.5,  -- mousemoverel sensitivity

		LockMode = 1,        -- 1 = CFrame | 2 = mousemoverel
		LockPart = "Head",

		TriggerKey = Enum.UserInputType.MouseButton2,
		Toggle = false
	},

	Blacklisted = {},
	Locked = nil
}

local Environment = getgenv().ExunysDeveloperAimbot

--// Utility
local ConvertVector = function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end

local FixUsername = function(String)
	local Result
	for _, Value in next, GetPlayers(Players) do
		local Name = __index(Value, "Name")
		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
			Result = Name
		end
	end
	return Result
end

local CancelLock = function()
	Environment.Locked = nil
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
	if Animation then
		Animation:Cancel()
	end
end

--// Core: closest player WITHOUT FOV
local GetClosestPlayer = function()
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	local RequiredDistance = math.huge
	local Closest = nil

	for _, Value in next, GetPlayers(Players) do
		if Value ~= LocalPlayer
			and not tablefind(Environment.Blacklisted, __index(Value, "Name")) then

			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")
			local Part = Character and FindFirstChild(Character, LockPart)

			if Character and Humanoid and Part then
				if Settings.TeamCheck then
					if __index(Value, Environment.DeveloperSettings.TeamCheckOption)
						== __index(LocalPlayer, Environment.DeveloperSettings.TeamCheckOption) then
						continue
					end
				end

				if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then
					continue
				end

				if Settings.WallCheck then
					local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
					for _, v in next, GetDescendants(Character) do
						BlacklistTable[#BlacklistTable + 1] = v
					end
					if #GetPartsObscuringTarget(Camera, {Part.Position}, BlacklistTable) > 0 then
						continue
					end
				end

				local ScreenPos, OnScreen = WorldToViewportPoint(Camera, Part.Position)
				if OnScreen then
					local Distance =
						(GetMouseLocation(UserInputService) - ConvertVector(ScreenPos)).Magnitude
					if Distance < RequiredDistance then
						RequiredDistance = Distance
						Closest = Value
					end
				end
			end
		end
	end

	Environment.Locked = Closest
end

--// Load
local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")
	local Settings = Environment.Settings

	ServiceConnections.RenderSteppedConnection =
		Connect(__index(RunService, Environment.DeveloperSettings.UpdateMode), function()

			if Running and Settings.Enabled then
				GetClosestPlayer()

				if Environment.Locked then
					local Character = __index(Environment.Locked, "Character")
					if not Character then
						CancelLock()
						return
					end

					local Part = FindFirstChild(Character, Settings.LockPart)
					if not Part then
						CancelLock()
						return
					end

					local Offset =
						Settings.OffsetToMoveDirection
						and __index(FindFirstChildOfClass(Character, "Humanoid"), "MoveDirection")
							* (mathclamp(Settings.OffsetIncrement, 1, 30) / 10)
						or Vector3zero

					local TargetPos3 = Part.Position + Offset
					local TargetPos2 = WorldToViewportPoint(Camera, TargetPos3)

					if Settings.LockMode == 2 then
						mousemoverel(
							(TargetPos2.X - GetMouseLocation(UserInputService).X) / Settings.Sensitivity2,
							(TargetPos2.Y - GetMouseLocation(UserInputService).Y) / Settings.Sensitivity2
						)
					else
						if Settings.Sensitivity > 0 then
							Animation = TweenService:Create(
								Camera,
								TweenInfonew(Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
								{ CFrame = CFramenew(Camera.CFrame.Position, TargetPos3) }
							)
							Animation:Play()
						else
							__newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, TargetPos3))
						end
						__newindex(UserInputService, "MouseDeltaSensitivity", 0)
					end
				end
			end
		end)

	ServiceConnections.InputBeganConnection =
		Connect(__index(UserInputService, "InputBegan"), function(Input)
			if Typing then return end

			local TriggerKey, Toggle = Settings.TriggerKey, Settings.Toggle
			if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey)
				or Input.UserInputType == TriggerKey then
				if Toggle then
					Running = not Running
					if not Running then
						CancelLock()
					end
				else
					Running = true
				end
			end
		end)

	ServiceConnections.InputEndedConnection =
		Connect(__index(UserInputService, "InputEnded"), function(Input)
			if Typing or Settings.Toggle then return end

			local TriggerKey = Settings.TriggerKey
			if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey)
				or Input.UserInputType == TriggerKey then
				Running = false
				CancelLock()
			end
		end)
end

--// Typing check
ServiceConnections.TypingStartedConnection =
	Connect(__index(UserInputService, "TextBoxFocused"), function()
		Typing = true
	end)

ServiceConnections.TypingEndedConnection =
	Connect(__index(UserInputService, "TextBoxFocusReleased"), function()
		Typing = false
	end)

--// API
function Environment.Exit(self)
	assert(self, "Exit: missing self")
	for _, c in next, ServiceConnections do
		Disconnect(c)
	end
	getgenv().ExunysDeveloperAimbot = nil
end

function Environment.Restart()
	for _, c in next, ServiceConnections do
		Disconnect(c)
	end
	Load()
end

function Environment.Blacklist(self, Username)
	assert(self and Username)
	Username = FixUsername(Username)
	assert(Username, "User not found")
	self.Blacklisted[#self.Blacklisted + 1] = Username
end

function Environment.Whitelist(self, Username)
	assert(self and Username)
	Username = FixUsername(Username)
	assert(Username, "User not found")
	local Index = tablefind(self.Blacklisted, Username)
	assert(Index, "User not blacklisted")
	tableremove(self.Blacklisted, Index)
end

function Environment.GetClosestPlayer()
	GetClosestPlayer()
	local v = Environment.Locked
	CancelLock()
	return v
end

Environment.Load = Load
setmetatable(Environment, { __call = Load })

return Environment
