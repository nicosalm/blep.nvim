
local M = {}

---@class BlepCounter
---@field count number current count of key presses
---@field timer userdata timer to reset the count
---@field last_press_ms number timestamp of last key press

---@class BlepKeyConfig
---@field threshold number maximum number of presses before blep
---@field timeout_ms number time window for counting presses
---@field message string notification message
---@field icon string notification icon
---@field callback function? optional callback on threshold exceeded
---@field enforce boolean whether to block key presses after threshold

-- internal state uses static allocation for predictable performance:
local counters = {}
local stats = {
    bleps = {},     -- number of times each key exceeded threshold
    presses = {},   -- total number of presses per key
}

-- constants:
local MAX_KEYS = 32           -- Maximum number of keys we can monitor
local MAX_THRESHOLD = 100     -- Maximum threshold value
local MIN_TIMEOUT_MS = 100    -- Minimum timeout window
local MAX_TIMEOUT_MS = 10000  -- Maximum timeout window

-- compile-time consistency checks:
assert(MAX_THRESHOLD > 0)
assert(MAX_TIMEOUT_MS > MIN_TIMEOUT_MS)

local default_config = {
    keys = {
        h = {
            threshold = 10,
            timeout_ms = 2000,
            message = "Mrrp! Too much left!",
            icon = "😺",
            enforce = false,
        },
        j = {
            threshold = 10,
            timeout_ms = 2000,
            message = "Purrr... Scrolling down too fast!",
            icon = "😸",
            enforce = false,
        },
        k = {
            threshold = 10,
            timeout_ms = 2000,
            message = "Mrow! Easy on the up scroll!",
            icon = "😺",
            enforce = false,
        },
        l = {
            threshold = 10,
            timeout_ms = 2000,
            message = "Mew! Too much right!",
            icon = "😸",
            enforce = false,
        },
        ["+"] = {
            threshold = 5,
            timeout_ms = 2000,
            message = "Hiss! Window too big!",
            icon = "🐱",
            enforce = false,
        },
        ["-"] = {
            threshold = 5,
            timeout_ms = 2000,
            message = "Meow! Window too small!",
            icon = "😺",
            enforce = false,
        },
    },
    default_threshold = 10,
    default_timeout_ms = 2000,
    default_message = "*blep* Slow down hooman!",
    default_icon = "😛",
    statistics = true,
    debug = false,
    enforce = false,
}

local function validate_timeout(timeout_ms)
    assert(timeout_ms >= MIN_TIMEOUT_MS)
    assert(timeout_ms <= MAX_TIMEOUT_MS)
end

local function validate_threshold(threshold)
    assert(threshold > 0)
    assert(threshold <= MAX_THRESHOLD)
end

local function validate_key_config(key, config)
    assert(type(key) == "string", "Key must be a string")
    assert(type(config) == "table", "Config must be a table")
    validate_threshold(config.threshold)
    validate_timeout(config.timeout_ms)
    assert(type(config.message) == "string", "Message must be a string")
    assert(type(config.icon) == "string", "Icon must be a string")
end

local function update_stats(key, exceeded_threshold)
    if not M.config.statistics then
        return
    end

    stats.presses[key] = (stats.presses[key] or 0) + 1

    if exceeded_threshold then
        stats.bleps[key] = (stats.bleps[key] or 0) + 1
    end
end

local function create_counter(key)
    assert(counters[key] == nil, "Counter already exists")

    counters[key] = {
        count = 0,
        timer = vim.uv.new_timer(),
        last_press_ms = 0,
    }
    return counters[key]
end

local function reset_counter(counter)
    assert(counter ~= nil, "Counter must not be nil")
    counter.count = 0
    counter.last_press_ms = 0
end

-- setup key mapping
local function setup_key(key, config)
    validate_key_config(key, config)
    local counter = create_counter(key)

    vim.keymap.set("n", key, function()
        -- reset count if explicit count is given
        if vim.v.count > 0 then
            reset_counter(counter)
            return key
        end

        local current_ms = vim.uv.now()

        -- start timer to reset count
        counter.timer:start(config.timeout_ms, 0, function()
            reset_counter(counter)
        end)

        -- count
        counter.count = counter.count + 1
        counter.last_press_ms = current_ms

        -- check threshold
        if counter.count >= config.threshold and vim.bo.buftype ~= "nofile" then
            update_stats(key, true)

            -- show popup
            local ok = pcall(vim.notify, config.message, vim.log.levels.WARN, {
                icon = config.icon,
                id = "blep_" .. key,
                keep = function()
                    return counter.count >= config.threshold
                end,
            })

            -- execute callback if defined
            if config.callback then
                config.callback(counter.count, key)
            end

            if not ok then
                return key
            end

            -- block the keypress if enforcement
            if config.enforce or M.config.enforce then
                vim.notify("Kitty blocks your way! 🐱", vim.log.levels.WARN)
                return ""
            end
        else
            update_stats(key, false)
        end

        return key
    end, { expr = true, silent = true })
end

-- setup
function M.setup(user_config)
    -- validate user config
    assert(#vim.tbl_keys(default_config.keys) <= MAX_KEYS, "Too many default keys")

    -- merge configs
    M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

    -- validate merged configs
    assert(#vim.tbl_keys(M.config.keys) <= MAX_KEYS, "Too many configured keys")

    -- key setup
    for key, key_config in pairs(M.config.keys) do
        -- merge w/ defaults for each key
        key_config.threshold = key_config.threshold or M.config.default_threshold
        key_config.timeout_ms = key_config.timeout_ms or M.config.default_timeout_ms
        key_config.message = key_config.message or M.config.default_message
        key_config.icon = key_config.icon or M.config.default_icon
        key_config.enforce = key_config.enforce or M.config.enforce

        setup_key(key, key_config)
    end
end

-- get current stats
function M.get_stats()
    return stats
end

-- reset all stats
function M.get_counter(key)
    return counters[key]
end

function M.reset()
    stats = {
        bleps = {},
        presses = {},
    }
    counters = {}
    M.config = nil
end

M.reset_stats = M.reset  -- for backwards compat.

-- + new key to monitor
function M.add_key(key, config)
    assert(M.config ~= nil, "Please run setup() before adding keys")
    assert(#vim.tbl_keys(M.config.keys) < MAX_KEYS, "Maximum number of keys reached")

    -- merge with defaults
    M.config.keys[key] = vim.tbl_deep_extend("force", {
        threshold = M.config.default_threshold,
        timeout_ms = M.config.default_timeout_ms,
        message = M.config.default_message,
        icon = M.config.default_icon,
        enforce = M.config.enforce,
    }, config or {})

    setup_key(key, M.config.keys[key])
end

return M
