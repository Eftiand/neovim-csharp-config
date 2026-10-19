local M = {}

local rpc = require("dap.rpc")

local function send_payload(client, payload)
  local msg = rpc.msg_with_content_length(vim.json.encode(payload))
  client.write(msg)
end

function M.handshake(self, request_payload)
  local sign_script = vim.fn.stdpath("config") .. "/lua/meon/util/vsdbg-sign.js"
  local handle = io.popen("node " .. sign_script .. " " .. request_payload.arguments.value)
  if not handle then return end
  local signature = handle:read("*a"):gsub("%s+$", "")
  handle:close()

  send_payload(self.client, {
    type = "response",
    seq = 0,
    command = "handshake",
    request_seq = request_payload.seq,
    success = true,
    body = { signature = signature },
  })
end

--- Compare two extension dir names by their embedded version, newest first.
--- Plain string order is wrong here: "csharp-2.9.x" would beat "csharp-2.140.x".
local function newer(a, b)
  local a_parts, b_parts = {}, {}
  for n in a:gmatch("%d+") do a_parts[#a_parts + 1] = tonumber(n) end
  for n in b:gmatch("%d+") do b_parts[#b_parts + 1] = tonumber(n) end
  for i = 1, math.max(#a_parts, #b_parts) do
    local x, y = a_parts[i] or 0, b_parts[i] or 0
    if x ~= y then return x > y end
  end
  return false
end

local vsdbg_path = nil
local searched = false

--- Locate the vsdbg binary shipped with the VS Code C# extension.
--- Uses a glob rather than shelling out to `find`: the old `io.popen("find
--- ~/.vscode/extensions ...")` walked the whole extensions tree synchronously
--- and cost ~870ms of startup on a cold cache. The result is cached, so a
--- failed lookup is not retried on every debug session either.
function M.find_vsdbg()
  if searched then return vsdbg_path end
  searched = true

  -- The extension lays the binary out per platform: macOS arm64 under
  -- `.debugger/arm64`, macOS intel under `.debugger/x86_64`, Linux under
  -- `.debugger/vsdbg` (and `.debugger/<arch>/vsdbg` on newer builds). Glob
  -- both shapes rather than hardcoding one.
  local root = vim.fn.expand("~") .. "/.vscode/extensions/ms-dotnettools.csharp-*/.debugger/"
  -- macOS ships both arch dirs side by side, so restrict to this machine's.
  local arch = vim.uv.os_uname().machine == "x86_64" and "x86_64" or "arm64"
  local matches = vim.fn.glob(root .. arch .. "/vsdbg", true, true)
  vim.list_extend(matches, vim.fn.glob(root .. "vsdbg", true, true))
  table.sort(matches, newer)
  vsdbg_path = matches[1]

  return vsdbg_path
end

function M.get_adapter()
  local path = M.find_vsdbg()
  if not path then return nil end

  return {
    id = "coreclr",
    type = "executable",
    command = path,
    args = { "--interpreter=vscode" },
    reverse_request_handlers = {
      handshake = M.handshake,
    },
  }
end

return M
