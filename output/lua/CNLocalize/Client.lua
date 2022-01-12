Script.Load("lua/CNLocalize/CNStrings.lua")
local baseResolveString = Locale.ResolveString

function CNLocalizeResolve(input)
    if not input then return "" end

    local lang = Locale.GetLocale()
    local resolvedString = kTranslateMessage[input] 
    if resolvedString  then
        return resolvedString
    end
    return input

end
Locale.ResolveString = CNLocalizeResolve

ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")

if Shine then

    Script.Load("lua/CNLocalize/ShineStrings.lua")
    function Shine.Locale:GetLocalisedString( Source, Lang, Key )
        local LanguageStrings = Shine.Locale:GetLanguageStrings( Source, Lang )
        if not LanguageStrings or not LanguageStrings[ Key ] then
            LanguageStrings = Shine.Locale:GetLanguageStrings( Source, Shine.Locale.DefaultLanguage )
        end
        
        local finalKey=LanguageStrings and LanguageStrings[Key] or Key
        local finalValue=kShineTranslations[finalKey]
        if not finalValue then
            Shared.Message("Shine:{" .. finalKey .."} Untranslated")
            finalValue=finalKey
        end
        return finalValue
    end
    
end
