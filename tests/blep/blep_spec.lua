
local stub = require("luassert.stub")

require("plenary.reload").reload_module("blep")
local blep = require("blep")

describe("blep", function()
    local notify_stub
    local keymap_stub

    before_each(function()
        blep.reset()
        notify_stub = stub(vim, "notify")
        keymap_stub = stub(vim.keymap, "set")
        vim.bo = { buftype = "" }
        vim.v = { count = 0 }

        vim.uv = {
            new_timer = function()
                return {
                    start = function() end
                }
            end,
            now = function() return 0 end
        }

        vim.log = { levels = { WARN = 2 } }
    end)

    after_each(function()
        notify_stub:revert()
        keymap_stub:revert()
    end)

    it("works with default config", function()
        blep.setup()
        -- print("keymap calls:", vim.inspect(keymap_stub.calls))
        assert.equals(6, #keymap_stub.calls)
    end)

    it("respects custom thresholds", function()
        blep.setup({
            keys = {
                j = {
                    threshold = 15,
                    message = "Custom message",
                }
            }
        })
        assert.stub(keymap_stub).was_called()
    end)

    it("blocks keys when enforce is enabled", function()
        -- setup with just one key to test
        blep.setup({
            keys = {
                j = {
                    threshold = 3,
                    enforce = true
                }
            },
            default_threshold = 3,
            enforce = true
        })

        -- get mapping function for "j" key
        local key_handler = nil
        assert.stub(keymap_stub).was.called()
        for _, call in ipairs(keymap_stub.calls) do
            if call.refs[1] == "n" and call.refs[2] == "j" then
                key_handler = call.refs[3]
                break
            end
        end
        assert(key_handler, "Key handler not found")

        -- press key until threshold
        for _ = 1, 3 do key_handler() end

        -- next press should be blocked
        assert.equals("", key_handler())
    end)

    it("tracks statistics correctly", function()
        blep.setup({
            keys = {
                j = {
                    threshold = 3,
                    enforce = false
                }
            }
        })

        -- get mapping function for "j" key
        local key_handler = nil
        for _, call in ipairs(keymap_stub.calls) do
            if call.refs[1] == "n" and call.refs[2] == "j" then
                key_handler = call.refs[3]
                break
            end
        end
        assert(key_handler, "Key handler not found")

        -- press key, check stats
        key_handler()
        local stats = blep.get_stats()
        assert.equals(1, stats.presses.j)
    end)

    it("adds new keys dynamically", function()
        blep.setup()
        blep.add_key("w", { threshold = 5 })
        assert.equals(7, #keymap_stub.calls)
    end)

    it("resets statistics", function()
        blep.setup({ keys = { j = { threshold = 3 } } })
        blep.reset_stats()
        local stats = blep.get_stats()
        assert.equals(nil, stats.presses.j)
        assert.equals(nil, stats.bleps.j)
    end)
end)
