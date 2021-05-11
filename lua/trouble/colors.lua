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
    Indent = "LineNr",
    SignOther = "LspTroubleSignInformation"
}

function M.setup()
    for k, v in pairs(links) do
        vim.api.nvim_command('hi def link LspTrouble' .. k .. ' ' .. v)
        vim.api.nvim_command('hi def link Trouble' .. k .. ' LspTrouble' .. k)
    end
end

return M
