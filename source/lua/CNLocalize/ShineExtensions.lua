if Shine then
    if Client then
        Shared.Message("[CNCE] Shine Localize Hooked")
        Script.Load("lua/CNLocalize/ShineStrings.lua")
        function Shine.Locale:GetLocalisedString( Source, Lang, Key )
            
            local finalValue = rawget(kShineTranslations,Key)
            if finalValue then
                return finalValue
            end
            
            local pluginStrings=  kShinePluginsTranslations[Source]
            if pluginStrings then
                finalValue = rawget(pluginStrings,Key)
                if finalValue then
                    return finalValue
                end
            end

            Shared.Message("[CNCE] ERROR Shine:|"..Source .. "|".. Key .. "|Untranslated")

            local LanguageStrings = Shine.Locale:GetLanguageStrings( Source, Lang )
            if not LanguageStrings or not LanguageStrings[ Key ] then
                LanguageStrings = Shine.Locale:GetLanguageStrings( Source, Shine.Locale.DefaultLanguage )
            end
            return LanguageStrings and LanguageStrings[ Key ] or Key
        end

        --Chat Filter
        local ICPlugin = Shine.Plugins["improvedchat"]
        if ICPlugin then
            Shared.Message("[CNCE] Shine Improved Chat Hooked")
            local ChatAPI = require "shine/core/shared/chat/chat_api"

            local ColourElement = require "shine/lib/gui/richtext/elements/colour"
            local ImageElement = require "shine/lib/gui/richtext/elements/image"
            local SpacerElement = require "shine/lib/gui/richtext/elements/spacer"
            local TextElement = require "shine/lib/gui/richtext/elements/text"

            local Hook = Shine.Hook
            local SGUI = Shine.GUI
            local Units = SGUI.Layout.Units

            local Ceil = math.ceil
            local IsType = Shine.IsType
            local OSDate = os.date
            local RoundTo = math.RoundTo
            local StringFormat = string.format
            local StringFind = string.find
            local TableRemove = table.remove
            local TableRemoveByValue = table.RemoveByValue
            local IntToColour = ColorIntToColor

            local function GetTeamPrefix( Data )
                if Data.LocationID > 0 then
                    local Location = Shared.GetString( Data.LocationID )
                    if StringFind( Location, "[^%s]" ) then
                        return StringFormat( "(??????, %s) ", Locale.ResolveLocation(Location) )
                    end
                end

                return "(??????) "
            end

            -- Overrides the default chat behaviour, adding chat tags and turning the contents into rich text.
            function ICPlugin:OnChatMessageReceived( Data )
                local Player = Client.GetLocalPlayer()
                if not Player then return true end

                if not Client.GetIsRunningServer() then
                    local Prefix = "Chat All"
                    if Data.TeamOnly then
                        Prefix = StringFormat( "Chat Team %d", Data.TeamNumber )
                    end

                    Shared.Message( StringFormat( "%s %s - %s: %s", OSDate( "[%H:%M:%S]" ), Prefix, Data.Name, Data.Message ) )
                end

                if Data.SteamID ~= 0 and ChatUI_GetSteamIdTextMuted( Data.SteamID ) then
                    return true
                end

                -- Server sends -1 for ClientID if there is no client attached to the message.
                local Entry = Data.ClientID ~= -1 and Shine.GetScoreboardEntryByClientID( Data.ClientID )
                local IsCommander = Entry and Entry.IsCommander and IsVisibleToLocalPlayer( Player, Entry.EntityTeamNumber )
                local IsRookie = Entry and Entry.IsRookie

                local Contents = {}

                local ChatTag = self.ChatTags[ Data.SteamID ]
                if ChatTag and ( not Data.TeamOnly or self.dt.DisplayChatTagsInTeamChat ) then
                    if ChatTag.Image then
                        Contents[ #Contents + 1 ] = ImageElement( {
                            Texture = ChatTag.Image,
                            AutoSize = DEFAULT_IMAGE_SIZE,
                            AspectRatio = 1
                        } )
                    end
                    Contents[ #Contents + 1 ] = ColourElement( ChatTag.Colour )
                    Contents[ #Contents + 1 ] = TextElement( ( ChatTag.Image and " " or "" )..ChatTag.Text.." " )
                end

                if IsCommander then
                    Contents[ #Contents + 1 ] = ColourElement( IntToColour( kCommanderColor ) )
                    Contents[ #Contents + 1 ] = TextElement( "[??????] " )
                end

                if IsRookie then
                    Contents[ #Contents + 1 ] = ColourElement( IntToColour( kNewPlayerColor ) )
                    Contents[ #Contents + 1 ] = TextElement( Locale.ResolveString( "??????" ).." " )
                end

                local Prefix = "(??????) "
                if Data.TeamOnly then
                    Prefix = GetTeamPrefix( Data )
                end

                Prefix = StringFormat( "%s%s: ", Prefix, Data.Name )

                Contents[ #Contents + 1 ] = ColourElement( IntToColour( GetColorForTeamNumber( Data.TeamNumber ) ) )
                Contents[ #Contents + 1 ] = TextElement( Prefix )

                Contents[ #Contents + 1 ] = ColourElement( kChatTextColor[ Data.TeamType ] )
                Contents[ #Contents + 1 ] = TextElement( Locale.ChatFilter( Data.Message ) )

                Hook.Call( "OnChatMessageParsed", Data, Contents )

                return self:AddRichTextMessage( {
                    Source = {
                        Type = ChatAPI.SourceTypeName.PLAYER,
                        ID = Data.SteamID,
                        Details = Data
                    },
                    Message = Contents
                } )
            end
        end

           
        -- local TierInfoPlugin = Shine.Plugins["tier_info"]
        -- if TierInfoPlugin then
        --     Shared.Message("[CNCE] Shine Tier Info Hooked")
        --     TierInfoPlugin.GUIScoreboardUpdateTeam = function(scoreboard, updateTeam)
        --         TierInfoPlugin._GUIScoreboardUpdateTeam(scoreboard, updateTeam)
                
        --         if (TierInfoPlugin.QueueIndexIdLast ~= TierInfoPlugin.dt.QueueIndexId) then
        --             TierInfoPlugin.QueueIndex = json.decode(TierInfoPlugin.dt.QueueIndex);
        --             TierInfoPlugin.QueueIndexIdLast = TierInfoPlugin.dt.QueueIndexId;
        --         end
                
        --         local playerList = updateTeam["PlayerList"]
        --         local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
        --         local teamSkillGUIItem = updateTeam["GUIs"]["TeamSkill"]
        --         local teamScores = updateTeam["GetScores"]()
        --         --local numPlayers = 0--table.icount(teamScores)
        --         local currentPlayerIndex = 1
            
        --         --local totalSkill = 0
        --         local isSpectator, isMarine, isAlien = updateTeam.TeamNumber == 0, updateTeam.TeamNumber == 1, updateTeam.TeamNumber == 2;
                
        --         -- Update team rows
        --         for index, player in ipairs(playerList) do
        --         local playerRecord = teamScores[currentPlayerIndex]
        --         if playerRecord == nil then return end
                
        --         local playerName = playerRecord.Name
        --         local adagradSum = playerRecord.AdagradSum
        --         local baseSkill = playerRecord.Skill
        --         local playerTierSkill = TierInfoPlugin.CalcPlayerSkill(baseSkill, adagradSum)
        --         local clientIndex = playerRecord.ClientIndex
            
        --         local playerData = TierInfoPlugin.player[tostring(clientIndex)];
        --         local marineSkill, alienSkill = TierInfoPlugin.GetTeamsAvgSkill(baseSkill, playerData and playerData.skill_offset or 0);
        --         local playerSkill = (isMarine and marineSkill) or (isAlien and alienSkill) or 0
        --         local isCommander = playerData and playerData.IsCommander or false;
            
        --         --[[if (baseSkill ~= -1) then -- Only count actual players, not bots
        --             numPlayers = numPlayers + 1;
        --             totalSkill = totalSkill + playerSkill;
        --         end--]]
            
        --         -- Insert into the badge hover action
        --         if not scoreboard.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then
        --             if MouseTracker_GetIsVisible() then
        --             local mouseX, mouseY = Client.GetCursorPosScreen()
        --             local skillIcon = player.SkillIcon
        --                 if skillIcon:GetIsVisible() and GUIItemContainsPoint(skillIcon, mouseX, mouseY) then
        --                     local _, badgeNames = Badges_GetBadgeTextures(clientIndex, "scoreboard")
        --                     local nextSkill = TierInfoPlugin.GetPlayerSkillNextSkill(playerTierSkill)
                            
        --                     local description = skillIcon.tooltipText
                
        --                     if playerData ~= nil and playerData.skill_offset ~= nil then
        --                         local marineCommSkill, alienCommSkill = TierInfoPlugin.GetTeamsAvgSkill(playerData.comm_skill, playerData.comm_skill_offset);
                
        --                         local queueIndex = TierInfoPlugin.QueueIndex[tostring(clientIndex)];
        --                         if (queueIndex) then
        --                             description = description .. string.format("\n????????????: %i", queueIndex)
        --                         end
                                
        --                         if TierInfoPlugin.dt.EnableTierSkill then
        --                             description = description .. string.format("\n*??????")

        --                             if isSpectator then
        --                                 description = description .. string.format("\n?????????: %i", playerTierSkill) -- Tier skill
        --                             end
                                
        --                             if playerTierSkill < TierInfoPlugin.Skill[table.count(TierInfoPlugin.Skill)] then
        --                                 description = description .. string.format("\n?????????: %i", nextSkill) -- Next tier skill
        --                             end
                                    
        --                             if isSpectator or (isMarine and not commander) then
        --                                 description = description .. string.format("\n????????????: %i (?????????)", marineSkill)
        --                             end
                    
        --                             if isSpectator or ( isAlien and not commander) then
        --                                 description = description .. string.format("\n????????????: %i (????????????)", alienSkill)
        --                             end
                
        --                             if isSpectator or (isMarine and isCommander) then
        --                                 description = description .. string.format("\n?????????: %i (?????????)", marineCommSkill)
        --                             end
                    
        --                             if isSpectator or (isAlien and isCommander) then
        --                                 description = description .. string.format("\n?????????: %i (????????????)", alienCommSkill)
        --                             end
        --                         end
        --                     end
                
        --                     if playerData ~= nil then
        --                         -- Fix missing data
        --                         playerData.kdr_marine = playerData.kdr_marine or 0
        --                         playerData.kdr_alien = playerData.kdr_alien or 0
        --                         playerData.accuracy_marine = playerData.accuracy_marine or 0
        --                         playerData.accuracy_alien = playerData.accuracy_alien or 0
        --                         playerData.sph_marine = playerData.sph_marine or 0
        --                         playerData.sph_alien = playerData.sph_alien or 0
                
        --                         description = description .. string.format("\n\n*????????????")
        --                         description = description .. string.format("\n??????:     %ih", playerData.time_played) 
        --                         if playerData.marine_playtime > 0 then
        --                             description = description .. string.format("\n?????????:   %ih ", playerData.marine_playtime)
        --                         end
        --                         if playerData.alien_playtime > 0 then
        --                             description = description .. string.format("\n????????????: %ih", playerData.alien_playtime)
        --                         end
        --                         if playerData.commander_time > 0 then
        --                             description = description .. string.format("\n?????????:   %ih", playerData.commander_time)
        --                         end
                                
        --                         if (TierInfoPlugin.isAdmin() or TierInfoPlugin.dt.EnableNsl) then
                                    
        --                             description = description .. string.format("\n\n*?????????(SPH)")
        --                             description = description .. string.format("\n??????:    %i", playerData.sph)
        --                             description = description .. string.format("\n?????????:   %i ", playerData.sph_marine)
        --                             description = description .. string.format("\n????????????: %i ", playerData.sph_alien)
                                    
        --                             if (playerData.kdr_marine > 0 or playerData.kdr_alien > 0) then
        --                                 description = description .. string.format("\n\n*???????????????(KD)")
        --                                 description = description .. string.format("\n?????????:   %.2f", playerData.kdr_alien)
        --                                 description = description .. string.format("\n????????????: %.2f", playerData.kdr_alien)
        --                             end
                        
        --                             if (playerData.accuracy_marine > 0 or playerData.accuracy_alien > 0) then
        --                                 description = description .. string.format("\n\n*?????????(ACC)")
        --                                 description = description .. string.format("\n?????????:   %.2f", playerData.accuracy_marine)
        --                                 description = description .. string.format("\n????????????: %.2f", playerData.accuracy_alien)
        --                             end
        --                         end
                                
                
        --                         if playerData.country and playerData.country ~= ' ' then
        --                             description = description .. string.format("\n\n*?????????: %s", playerData.country)
        --                         end
                
        --                         if (clientIndex ~= Client.GetLocalClientIndex() and TierInfoPlugin.isAdmin()) and (not TierInfoPlugin.dt.EnableNsl) then --clientIndex ~= Client.GetLocalClientIndex() or 
        --                         if playerData.familyInfo and playerData.familyInfo > 0 then                         
        --                             description = description .. string.format("\n*????????????: %s", Plugin.familyInfo[clientIndex] and "???" or "???") -- Family sharing status (needs testing)
        --                         end
                                
        --                         if playerData.vpn and playerData.vpn == 1 then
        --                             description = description .. string.format("\n*VPN: %s", '??????')
        --                         end
                                
        --                         if playerData.bans and playerData.bans ~= 0 then
        --                             description = description .. string.format("\n*????????????: %i", playerData.bans)
        --                         end
                                
        --                         local smurfs = playerData.smurfs;
        --                         if smurfs then
        --                             for _, smurf in ipairs(smurfs) do
        --                             if (smurf.skill) then -- and (smurf.skill > playerTierSkill or smurf.bans > 0)
        --                                 if (_ == 1) then
        --                                 description = description .. "\n\n????????????"
        --                                 end
                
        --                                 local insertSph = string.format("%s", smurf.sph);
        --                                 if (smurf.sph_marine ~= 0 or smurf.sph_alien ~= 0) then
        --                                 insertSph = string.format("|????????? %s| |???????????? %s|", smurf.sph_marine, smurf.sph_alien);
        --                                 end
                                    
        --                                 description = description .. string.format("\n  %s | ?????????: %s | ?????????(??????): %s", smurf.alias, smurf.skill, insertSph);
                                        
        --                                 if (smurf.bans > 0) then
        --                                 description = description .. string.format(" | ??????: %s", smurf.bans);
        --                                 end
        --                             end
        --                             end
        --                         end
        --                         end
        --                     end
                            
        --                     scoreboard.badgeNameTooltip:SetText(description)
        --                 end
        --             end
        --         end
                
        --         currentPlayerIndex = currentPlayerIndex + 1
        --         end
                
        --         -- Update team skill header
        --         if (TierInfoPlugin.dt.EnableTeamAvgSkill or (TierInfoPlugin.dt.EnableTeamAvgSkillPregame and (not GetGameInfoEntity():GetGameStarted()))) and (not TierInfoPlugin.dt.EnableNsl) then -- Display when enabled in pregame or during if configured as such
        --             if updateTeam.TeamNumber >= 1 and updateTeam.TeamNumber <= 2 then --and numPlayers > 0 then -- Display for only aliens or marines
        --                 local avgSkill = (updateTeam.TeamNumber == 1) and TierInfoPlugin.dt.marine_avg_skill or TierInfoPlugin.dt.alien_avg_skill;
        --                 local totalSkill = (updateTeam.TeamNumber == 1) and TierInfoPlugin.dt.marine_total_skill or TierInfoPlugin.dt.alien_total_skill;
        --                 local avgSph = (updateTeam.TeamNumber == 1) and TierInfoPlugin.dt.marine_avg_sph or TierInfoPlugin.dt.alien_avg_sph;
                
        --                 --
        --                 --local teamAvgSkill = totalSkill / numPlayers
        --                 local teamHeaderText = teamNameGUIItem:GetText()
        --                 teamHeaderText = string.sub(teamHeaderText, 1, string.len(teamHeaderText) - 1) -- Original header
                
        --                 teamHeaderText = teamHeaderText .. string.format(", %i ????????????", avgSkill) -- Skill Average
                
        --                 if (TierInfoPlugin:isAdmin()) then
        --                 if (TierInfoPlugin.dt.EnableTeamTotalSkill) then
        --                     teamHeaderText = teamHeaderText .. string.format(", %i ?????????(??????)", totalSkill) -- SPH Average
        --                 end
                
        --                 if (TierInfoPlugin.dt.EnableTeamAvgSph) then
        --                     teamHeaderText = teamHeaderText .. string.format(", %i ?????????(??????)", avgSph) -- SPH Average
        --                 end
        --                 end
                
        --                 teamHeaderText = teamHeaderText .. ")";
        --                 --
                
        --                 teamNameGUIItem:SetText( teamHeaderText )
                        
        --                 teamSkillGUIItem:SetPosition(Vector(teamNameGUIItem:GetTextWidth(teamNameGUIItem:GetText()) + 20, 5, 0) * GUIScoreboard.kScalingFactor)
        --             end
        --         end
        --     end
        -- end
    end
end