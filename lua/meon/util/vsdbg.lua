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

function M.find_vsdbg()
  local handle = io.popen("find ~/.vscode/extensions -path '*/ms-dotnettools.csharp-*/.debugger/arm64/vsdbg' 2>/dev/null | sort -V -r | head -1")
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    if result ~= "" then return result end
  end
  return nil
end

function M.get_adapter()
  local vsdbg_path = M.find_vsdbg()
  if not vsdbg_path then return nil end

  return {
    id = "coreclr",
    type = "executable",
    command = vsdbg_path,
    args = { "--interpreter=vscode" },
    reverse_request_handlers = {
      handshake = M.handshake,
    },
  }
end

return M
