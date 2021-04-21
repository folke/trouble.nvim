local M = {}

M.folded = {}

function M.is_folded(filename) return M.folded[filename] == true end

function M.toggle(filename) M.folded[filename] = not M.is_folded(filename) end

function M.close(filename) M.folded[filename] = true end

function M.open(filename) M.folded[filename] = false end

return M
