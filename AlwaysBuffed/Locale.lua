local _, A = ...

-- The English source string doubles as the key and the fallback.
local locale = GetLocale and GetLocale() or "enUS"
local aliases = { enGB = "enUS", esMX = "esES", ptPT = "ptBR" }
A.locale = aliases[locale] or locale
A.L = setmetatable({}, { __index = function(_, english) return english end })
