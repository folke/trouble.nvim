local M = {}

local links = {
    Error = "LspDiagnosticsDefaultError",
    Warning = "LspDiagnosticsDefaultWarning",
    Information = "LspDiagnosticsDefaultInformation",
    Hint = "LspDiagnosticsDefaultHint",
    SignError = "LspDiagnosticsSignError",
    SignWarning = "LspDiagnosticsSignWarning",
    SignInformation = "LspDiagnosticsSignInformation",
    SignHint = "LspDiagnosticsSignHint",
    TextError = "LspTroubleText",
    TextWarning = "LspTroubleText",
    TextInformation = "LspTroubleText",
    TextHint = "LspTroubleText",
    Text = "Normal",
    File = "Directory",
    Source = "Comment",
    Code = "Comment",
    Location = "LineNr",
    FoldIcon = "CursorLineNr",
    Normal = "Normal",
    Count = "TabLineSel",
    Preview = "Search",
    Indent = "LineNr"
}

-- for key, value in pairs(links) do
--     print("| **LspTrouble" .. key .. "* | " .. value .. " |")
-- end

function M.setup()
    for k, v in pairs(links) do
        vim.api.nvim_command('hi def link LspTrouble' .. k .. ' ' .. v)
    end
end

return M
