util.AddNetworkString("UpdateKillCount")
util.AddNetworkString("UpdateDeathCount")
util.AddNetworkString("PlayerStatsUpdate")
util.AddNetworkString("UpdatePlayerUserGroup")

-- Send user group information to the client
hook.Add("PlayerInitialSpawn", "SendUserGroup", function(ply)
    net.Start("UpdatePlayerUserGroup")
    net.WriteString(ply:GetUserGroup())
    net.Send(ply)
end)


-- The server-side has added NPC kill statistics.
hook.Add("OnNPCKilled", "TrackNPCKills", function(npc, attacker)
    if IsValid(attacker) and attacker:IsPlayer() then
        local newKillCount = attacker:GetNWInt("KillCount", 0) + 1
        attacker:SetNWInt("KillCount", newKillCount)

        -- Synchronized to the client.
        net.Start("UpdateKillCount")
            net.WriteEntity(attacker)
            net.WriteInt(newKillCount, 32)
        net.Broadcast()
    end
end)

-- Server-side general entity kill statistics
hook.Add("EntityKilled", "TrackEntityKills", function(ent, attacker)
    if ent:IsNPC() or ent:IsNextBot() then
        if IsValid(attacker) and attacker:IsPlayer() then
            attacker:SetNWInt("KillCount", attacker:GetNWInt("KillCount", 0) + 1)
            net.Start("UpdateKillCount")
                net.WriteEntity(attacker)
                net.WriteInt(attacker:GetNWInt("KillCount"), 32)
            net.Broadcast()
        end
    end
end)

-- The server receives kill and death events and updates the kill and death counts
hook.Add("PlayerDeath", "UpdatePlayerStatsOnDeath", function(victim, inflictor, attacker)
    -- Make sure the injured person is a player
    if not IsValid(victim) or not victim:IsPlayer() then return end
    
    -- Update the number of deaths
    local newDeathCount = victim:GetNWInt("DeathCount", 0) + 1
    victim:SetNWInt("DeathCount", newDeathCount)
    
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        local newKillCount = attacker:GetNWInt("KillCount", 0) + 1
        attacker:SetNWInt("KillCount", newKillCount)
        
        -- Simultaneous kills
        net.Start("UpdateKillCount")
            net.WriteEntity(attacker)
            net.WriteInt(newKillCount, 32)
        net.Broadcast()
    end

    net.Start("UpdateDeathCount")
        net.WriteEntity(victim)
        net.WriteInt(newDeathCount, 32)
    net.Broadcast()
end)

-- Set initial kill and death counts
hook.Add("PlayerInitialSpawn", "InitializePlayerStats", function(ply)
    ply:SetNWInt("KillCount", 0)
    ply:SetNWInt("DeathCount", 0)
end)