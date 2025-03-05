-- Font
surface.CreateFont("Scoreboard_Arial_20", {
	font = "Arial",
	size = 20,
    weight = 1200,
})

surface.CreateFont("Scoreboard_Arial_28", {
    font = "Arial",
    size = 28,
    weight = 1000,
    antialias = true
})

surface.CreateFont("Scoreboard_Verdana_ping", {
	font = "Verdana",
	size = 12,
    weight = 1200,
})

-- Color
local color_palette = {
    background = Color(23, 25, 35, 220),        -- Primary background color
    header = Color(32, 34, 46, 250),            -- Title bar color
    accent = Color(255, 255, 255, 255),         -- Accent Color
    text_primary = Color(245, 246, 250, 255),   -- Primary text color
    text_secondary = Color(200, 200, 210),      -- Secondary text color
    panel = Color(35, 37, 47, 250),             -- Panel background color
    panel_hover = Color(45, 47, 57, 250),       -- Panel mouseover color

    superadmin = Color(255, 195, 0 , 200),      -- SuperAdmin color
    admin = Color(255, 0, 0 , 200),             -- Admin color
    user = Color(65, 140, 230, 200),            -- User color

    voice_active = Color(0, 255, 0, 255),       -- Voice on color
    voice_muted = Color(255, 50, 50, 255),      -- Voice off color
    voice_default = Color(255, 255, 255, 255)   -- Default Voice color
}

-- Select Title
concommand.Add("simple_scoreboard_title", function(ply, cmd, args)
    if #args == 1 then
        local state = tonumber(args[1])
        if state == 1 then
            simpleScoreboardTitle = false
        elseif state == 0 then
            simpleScoreboardTitle = true
        end
    end
end)

-- Receive player user group information sent by the server.
net.Receive("UpdatePlayerUserGroup", function()
    local user_group = net.ReadString()
    LocalPlayer().UserGroup = user_group
end)

-- The client receives the kill count sent by the server.
net.Receive("UpdateKillCount", function()
    local attacker = net.ReadEntity()
    local newKillCount = net.ReadInt(32)
    if IsValid(attacker) then
        attacker:SetNWInt("KillCount", newKillCount)
    end
end)

-- The client receives the number of deaths sent by the server.
net.Receive("UpdateDeathCount", function()
    local victim = net.ReadEntity()
    local newDeathCount = net.ReadInt(32)
    if IsValid(victim) then
        victim:SetNWInt("DeathCount", newDeathCount)
    end
end)

-- Initialize local storage.
local mutedPlayers = mutedPlayers or {}

--[[ 
The system fetches the player's preferred language and checks for its 
presence in the translation mapping table. If the language is not supported, 
English is used as the fallback option.
--]]
local function GetLanguage()
    local languageselection = GetConVar("gmod_language"):GetString()
    if languageselection ==  "en" or languageselection ==  "zh-CN" or languageselection ==  "zh-TW"
        or languageselection ==  "ko" or languageselection ==  "ja" or languageselection ==  "ru" then
        return languageselection
    else
        return "en"
    end
end

-- Show Scoreboard.
local function SimplelScoreboard(toggle)
    if toggle then

        -- Scoreboard main window.
        local scrw, scrh = ScrW(), ScrH()
        Scoreboards = vgui.Create("DFrame")
        Scoreboards:SetTitle("")
        Scoreboards:SetSize(scrw * 0.4, math.min(scrh * 0.8, 800))
        Scoreboards:Center()
        Scoreboards:MakePopup()
        Scoreboards:ShowCloseButton(false)
        Scoreboards:SetDraggable(false)
        Scoreboards.Paint = function(self, w, h)
            -- Blurred Background.
            local x, y = self:LocalToScreen(0, 0)
            surface.SetMaterial(Material("pp/blurscreen"))
            surface.SetDrawColor(255, 255, 255, 255)
            for i = 1, 5 do
                Material("pp/blurscreen"):SetFloat("$blur", i * 0.5)
                Material("pp/blurscreen"):Recompute()
                render.UpdateScreenEffectTexture()
                surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
            end

            -- Translucent background.
            draw.RoundedBox(16, 0, 0, w, h, Color(23, 25, 35, 180))
            
            -- Title Bar.
            draw.RoundedBoxEx(15, 0, 0, w, 50, color_palette.header, true, true, false, false)
            
            -- Title bar text.
            if simpleScoreboardTitle then
                draw.SimpleText(GetHostName(), "Scoreboard_Arial_28", w/2, 15, color_palette.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(engine.ActiveGamemode(), "Scoreboard_Arial_20", w/2, 38, color_palette.text_secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText(SIMPLE_SCOREBOARD_LANGUAGES.player_list[GetLanguage()], "Scoreboard_Arial_28", w/2 + 2, 32 + 2, Color(0,0,0,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(SIMPLE_SCOREBOARD_LANGUAGES.player_list[GetLanguage()], "Scoreboard_Arial_28", w/2, 25, color_palette.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- description text.
            if GetConVar("gmod_language"):GetString() == "en" then
                draw.SimpleText(SIMPLE_SCOREBOARD_LANGUAGES.columns.name[GetLanguage()], "Scoreboard_Arial_20", w - 643, 70, color_palette.text_secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else 
                draw.SimpleText(SIMPLE_SCOREBOARD_LANGUAGES.columns.name[GetLanguage()], "Scoreboard_Arial_20", w - 650, 70, color_palette.text_secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            draw.SimpleText(SIMPLE_SCOREBOARD_LANGUAGES.columns.kills[GetLanguage()], "Scoreboard_Arial_20", w - 410, 70, color_palette.text_secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) 
            draw.SimpleText(SIMPLE_SCOREBOARD_LANGUAGES.columns.death[GetLanguage()], "Scoreboard_Arial_20", w - 300, 70, color_palette.text_secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Ping", "Scoreboard_Arial_20", w - 190, 70, color_palette.text_secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Scrollbars
        local scroll = vgui.Create("DScrollPanel", Scoreboards)
        scroll:SetPos(0, Scoreboards:GetTall() * 0.10)
        scroll:SetSize(Scoreboards:GetWide(), Scoreboards:GetTall() - 100)
        local ypos = 0
        
        -- Sort by permissions.
        local players = player.GetAll()
        table.sort(players, function(a, b)
            local function getPriority(ply)
                if ply:IsSuperAdmin() then return 3
                elseif ply:IsAdmin() then return 2
                else return 1 end
            end
            return getPriority(a) > getPriority(b)
        end)

        local ypos = 0
        for i, v in pairs(players) do
            local playerPanel = vgui.Create("DPanel", scroll)
            playerPanel:SetPos(0, ypos)
            playerPanel:SetSize(Scoreboards:GetWide(), Scoreboards:GetTall() * 0.074)
            playerPanel.player = v

            -- Scroll bar beautification.
            scroll.VBar:SetWidth(8)
            scroll.VBar:SetHideButtons(true)
            scroll.VBar.Paint = function(self, w, h)
                draw.RoundedBox(4, w/2 - 2, 0, 4, h, Color(45, 47, 57, 150))
            end
            scroll.VBar.btnGrip.Paint = function(self, w, h)
                local hover = self:IsHovered() or self.Depressed
                local color = hover and Color(65, 140, 230, 200) or Color(65, 140, 230, 120)  
                local radius = hover and 4 or 3
                draw.RoundedBox(radius, w/2 - 2, 0, 4, h, color)
                if hover then
                    self:LerpColor("color", color, 0.15)
                else
                    self:LerpColor("color", color, 0.25)
                end
            end


            --[[ avatar --]]
            -- Creating a Button.
            local avatarButton = vgui.Create("DButton", playerPanel)
            avatarButton:SetSize(32, 32)
            avatarButton:SetPos(50, 13)
            avatarButton:SetText("")

            -- Create an avatar.
            local avatarImg = vgui.Create("AvatarImage", avatarButton)
            avatarImg:SetSize(32, 32)
            avatarImg:SetPlayer(v, 64)
            avatarImg:SetPaintedManually(true)
            avatarImg:SetMouseInputEnabled(false)

            -- Draw an avatar.
            avatarButton.Paint = function(self, w, h)
                avatarImg:PaintManual()
            end

            -- On click, navigate to the user's Steam profile page.
            avatarButton.DoClick = function()
                if IsValid(v) and v:IsPlayer() then
                    local steamID = v:SteamID64()
                    gui.OpenURL("https://steamcommunity.com/profiles/"..steamID)
                end
            end


            --[[ voice --]]
            --Creating a Voice Button.
            local voiceButton = vgui.Create("DButton", playerPanel)
            voiceButton:SetSize(24, 24)
            voiceButton:SetText("")
            voiceButton:SetTooltip(SIMPLE_SCOREBOARD_LANGUAGES.voice_tooltip[GetLanguage()])
            voiceButton.playerSteamID = v:SteamID()
            voiceButton:SetPos(Scoreboards:GetWide() - 55, playerPanel:GetTall()/2 - 12)
            
            -- When clicked, switch the button's voice state and trigger a sound effect.
            voiceButton.DoClick = function(self)
                local ply = self:GetParent().player
                if IsValid(ply) then
                    mutedPlayers[self.playerSteamID] = not mutedPlayers[self.playerSteamID]
                    ply:SetMuted(mutedPlayers[self.playerSteamID])
                    surface.PlaySound("buttons/button14.wav")
                end
            end
            
            -- Draw the button.
            voiceButton.Paint = function(self, w, h)
                local radius = w / 2
                local centerX, centerY = w / 2, h / 2
                local segments = 24
                local circle = {}
                
                -- Compute the coordinates of the circle's boundary points.
                for i = 0, segments - 1 do
                    local angle = (i / segments) * math.pi * 2
                    table.insert(circle, {
                        x = centerX + math.cos(angle) * radius,
                        y = centerY + math.sin(angle) * radius
                    })
                end
                
                --[[The voice function button is initially white.
                It changes to green when the microphone is activated and 
                to red when the voice function is deactivated.--]]
                local buttonColor = color_palette.voice_active
                if mutedPlayers[self.playerSteamID] then
                    buttonColor = color_palette.voice_muted     
                else
                    if IsValid(v) and v:IsSpeaking() then
                        buttonColor = color_palette.voice_active
                    else
                        buttonColor = color_palette.voice_default   
                    end
                end
            
                -- Render a circular shape.
                surface.SetDrawColor(buttonColor)
                draw.NoTexture()
                surface.DrawPoly(circle)
            end
            
            -- Set up the initial mute status.
            if mutedPlayers[voiceButton.playerSteamID] == nil then
                mutedPlayers[voiceButton.playerSteamID] = false
            end


            -- Store the kill and death counts.
            local playerKills = v:GetNWInt("KillCount", 0)
            local playerDeaths = v:GetNWInt("DeathCount", 0)

            
            -- Save the name.
            local playernames = v:Name()


            -- Record the current ping value.
            local playerpings = v:Ping()


            playerPanel.Paint = function(self, w, h)
                if IsValid(v) then

                    -- Hover interaction with the mouse.
                    if self:IsHovered() then
                        draw.RoundedBox(16, 28, 5, w, h - 10, color_palette.panel_hover)
                    else
                        draw.RoundedBox(16, 28, 5, w, h - 10, color_palette.panel)
                    end
                    
                    --[[
                        The decorative strips are color-coded: 
                        yellow for super admins, 
                        red for admins, 
                        and blue for regular users.
                    --]]
                    local user_group = v:GetUserGroup() or "user"
                    if user_group == "superadmin" then
                        draw.RoundedBox(30, 10, 5, 10, h - 10, color_palette.superadmin)
                    elseif user_group == "admin" then
                        draw.RoundedBox(30, 10, 5, 10, h - 10, color_palette.admin)
                    else
                        draw.RoundedBox(30, 10, 5, 10, h - 10, color_palette.user)
                    end
                    
                    -- Player name.
                    draw.SimpleText(playernames, "Scoreboard_Arial_20", w - 665, h / 2 - 1, color_palette.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                   
                    -- Visual representation of ping values through bars and accompanying text.
                    draw.RoundedBox(16, w - 207, h/2 - 8, 80, 16, Color(0, 0, 50))
                    if playerpings <= 50 then
                        draw.RoundedBox(16, w - 205, h/2 - 6, playerpings / 4, 12, Color(0 ,255, 0, 200))
                    elseif playerpings > 50 and playerpings <= 150 then
                        draw.RoundedBox(16, w - 205, h/2 - 6, playerpings / 4, 12, Color(150, 255, 0, 200))
                    elseif playerpings > 150 and playerpings <= 200 then
                        draw.RoundedBox(16, w - 205, h/2 - 6, playerpings / 4, 12, Color(221, 221, 36, 200))     
                    elseif playerpings > 200 and playerpings <= 300 then
                        draw.RoundedBox(16, w - 205, h/2 - 6, playerpings / 4, 12, Color(255, 130, 0, 200))           
                    else
                        draw.RoundedBox(16, w - 205, h/2 - 6, 76, 12, Color(255, 0, 0))
                    end 
                    draw.SimpleText(playerpings.."ms", "Scoreboard_Verdana_ping", w - 105, h / 2, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                    -- Show the count of kills and deaths.
                    draw.SimpleText(playerKills, "Scoreboard_Arial_20", w - 415, h / 2 - 1, color_palette.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(playerDeaths, "Scoreboard_Arial_20", w - 305, h / 2 - 1, color_palette.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                end
            end
            ypos = ypos + playerPanel:GetTall() * 1.2
        end
    else
        if IsValid(Scoreboards) then
            -- Close Scoreboard
            Scoreboards:Remove()
        end
    end
end

hook.Add("ScoreboardShow", "SimplelScoreboard_Open", function()
    SimplelScoreboard(true)
    return false
end)

hook.Add("ScoreboardHide", "SimplelScoreboard_Close", function()
	SimplelScoreboard(false)
end)
