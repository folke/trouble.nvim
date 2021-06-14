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
  TextWarning = "TroubleText",
  TextInformation = "TroubleText",
  TextHint = "TroubleText",
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
  SignOther = "TroubleSignInformation",
}

function M.setup()
  for k, v in pairs(links) do
    if vim.fn.hlexists("LspTrouble" .. k) == 1 then
      vim.api.nvim_command("hi def link Trouble" .. k .. " LspTrouble" .. k)
    else
      vim.api.nvim_command("hi def link Trouble" .. k .. " " .. v)
    end
  end
end

return M
