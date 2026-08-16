--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type Config = {
	Enabled: boolean,
	TestMode: boolean,
	Duration: number,
	ApplyToUniverse: boolean,
	ExcludeAltAccounts: boolean,
	ApplyDeviceBlock: boolean,
	FolderName: string,
	ScoreToBan: number,
	DetectionCooldown: number,
	MaxEvidence: number,
}

export type Evidence = {
	Reason: string,
	Score: number,
	Time: number,
	Source: string,
}

type PlayerState = {
	Score: number,
	LastDetection: number,
	Evidence: {Evidence},
	Banning: boolean,
}

type HoneypotAPI = {
	Config: Config,
	Detect: (self: HoneypotAPI, player: Player, reason: string, score: number, source: string?) -> (),
	Ban: (self: HoneypotAPI, player: Player, reason: string) -> boolean,
	Create: (self: HoneypotAPI, name: string, score: number) -> RemoteEvent,
	CreateMultiple: (self: HoneypotAPI, remotes: {[string]: number}) -> (),
	GetScore: (self: HoneypotAPI, player: Player) -> number,
	GetEvidence: (self: HoneypotAPI, player: Player) -> {Evidence},
	Reset: (self: HoneypotAPI, player: Player) -> (),
}

local Honeypot = {} :: HoneypotAPI

Honeypot.Config = {
	Enabled = true,
	TestMode = false,
	Duration = -1,
	ApplyToUniverse = true,
	ExcludeAltAccounts = false,
	ApplyDeviceBlock = true,
	FolderName = "_Network",
	ScoreToBan = 100,
	DetectionCooldown = 2,
	MaxEvidence = 20,
}

local states: {[Player]: PlayerState} = {}

local existing = ReplicatedStorage:FindFirstChild(
	Honeypot.Config.FolderName
)

if existing and not existing:IsA("Folder") then
	existing:Destroy()
	existing = nil
end

local folder: Folder

if existing and existing:IsA("Folder") then
	folder = existing
else
	local newFolder = Instance.new("Folder")
	newFolder.Name = Honeypot.Config.FolderName
	newFolder.Parent = ReplicatedStorage
	folder = newFolder
end

local function getState(player: Player): PlayerState
	local state = states[player]

	if state then
		return state
	end

	local newState: PlayerState = {
		Score = 0,
		LastDetection = 0,
		Evidence = {},
		Banning = false,
	}

	states[player] = newState

	return newState
end

local function addEvidence(
	state: PlayerState,
	reason: string,
	score: number,
	source: string
): ()
	table.insert(state.Evidence, {
		Reason = reason,
		Score = score,
		Time = os.time(),
		Source = source,
	})

	while #state.Evidence > Honeypot.Config.MaxEvidence do
		table.remove(state.Evidence, 1)
	end
end

function Honeypot:Detect(
	player: Player,
	reason: string,
	score: number,
	source: string?
): ()
	if not Honeypot.Config.Enabled then
		return
	end

	if not player:IsDescendantOf(Players) then
		return
	end

	if score <= 0 then
		return
	end

	local state = getState(player)
	local now = os.clock()

	if now - state.LastDetection < Honeypot.Config.DetectionCooldown then
		return
	end

	state.LastDetection = now
	state.Score += score

	addEvidence(
		state,
		reason,
		score,
		source or "Unknown"
	)

	warn(
		"[HONEYPOT]",
		player.Name,
		"(" .. tostring(player.UserId) .. ")",
		"Score:",
		state.Score,
		"Reason:",
		reason
	)

	if state.Score >= Honeypot.Config.ScoreToBan then
		Honeypot:Ban(player, reason)
	end
end

function Honeypot:Ban(
	player: Player,
	reason: string
): boolean
	local state = getState(player)

	if state.Banning then
		return false
	end

	state.Banning = true

	local evidenceText = ""

	for _, evidence in ipairs(state.Evidence) do
		evidenceText ..= string.format(
			"[%s +%d] %s; ",
			evidence.Source,
			evidence.Score,
			evidence.Reason
		)
	end

	if Honeypot.Config.TestMode then
		warn(
			"[HONEYPOT][TEST]",
			player.Name,
			evidenceText
		)

		if player.Parent then
			player:Kick("[TEST] Security detection")
		end

		state.Banning = false

		return true
	end

	local success, err = pcall(function()
		Players:BanAsync({
			UserIds = {player.UserId},
			Duration = Honeypot.Config.Duration,
			ApplyToUniverse = Honeypot.Config.ApplyToUniverse,
			ExcludeAltAccounts = Honeypot.Config.ExcludeAltAccounts,
			ApplyDeviceBlock = Honeypot.Config.ApplyDeviceBlock,
			DisplayReason = "You have been banned for violating the game rules.",
			PrivateReason = string.sub(
				"Honeypot | Player="
					.. player.Name
					.. " | UserId="
					.. tostring(player.UserId)
					.. " | Score="
					.. tostring(state.Score)
					.. " | "
					.. evidenceText,
				1,
				1000
			),
		})
	end)

	if not success then
		warn(
			"[HONEYPOT] BanAsync failed:",
			err
		)

		state.Banning = false

		if player.Parent then
			player:Kick("Security violation detected.")
		end

		return false
	end

	return true
end

function Honeypot:Create(
	name: string,
	score: number
): RemoteEvent
	local existingRemote = folder:FindFirstChild(name)

	if existingRemote then
		if existingRemote:IsA("RemoteEvent") then
			return existingRemote
		end

		existingRemote:Destroy()
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder

	remote.OnServerEvent:Connect(function(player: Player)
		Honeypot:Detect(
			player,
			"Unauthorized honeypot invocation",
			score,
			name
		)
	end)

	return remote
end

function Honeypot:CreateMultiple(
	remotes: {[string]: number}
): ()
	for name, score in pairs(remotes) do
		Honeypot:Create(name, score)
	end
end

function Honeypot:GetScore(
	player: Player
): number
	return getState(player).Score
end

function Honeypot:GetEvidence(
	player: Player
): {Evidence}
	return getState(player).Evidence
end

function Honeypot:Reset(
	player: Player
): ()
	states[player] = nil
end

Players.PlayerRemoving:Connect(function(player: Player)
	states[player] = nil
end)

return Honeypot
