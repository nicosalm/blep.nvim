# blep.nvim

A Neovim plugin that prevents excessive key mashing through cat-themed notifications and optional key blocking.

![Tests](https://github.com/github/docs/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/yourusername/blazingly-fast-dev/issues)

## Installation

```lua
{
    "nicosalm/blep.nvim",
    config = function()
        require("blep").setup()
    end
}
```

## Features

- Blocks or warns on rapid key repetition
- Configurable thresholds and timeouts per key
- Statistics tracking for key usage
- Custom messages and callbacks

## Default Configuration

```lua
{
    keys = {
        h = {
            threshold = 10,      -- Presses before warning
            timeout = 2000,      -- Reset window (ms)
            message = "Mrrp! Too much left!",
            icon = "😺"
        },
        j = { threshold = 10, timeout = 2000, message = "Moving too fast!" },
        k = { threshold = 10, timeout = 2000, message = "Slow down!" },
        l = { threshold = 10, timeout = 2000, message = "Easy there!" },
        ["+"] = { threshold = 5, timeout = 2000, message = "Window too big!" },
        ["-"] = { threshold = 5, timeout = 2000, message = "Window too small!" }
    },
    default_threshold = 10,
    default_timeout = 2000,
    default_message = "Slow down!",
    statistics = true,    -- Track usage stats
    debug = false,       -- Debug logging
    enforce = false      -- Block keys after threshold
}
```

## Usage

Add a new key to monitor:
```lua
require("blep").add_key("w", {
    threshold = 5,
    message = "Stop word jumping!"
})
```

Enable key blocking:
```lua
require("blep").setup({
    keys = {
        j = {
            threshold = 15,
            message = "Too fast!",
            enforce = true,  -- Block only j
        }
    },
    enforce = false    -- Don't block other keys
})
```

## Commands

`:BlepStats` - Show key usage statistics

## API

- `setup(config)` - Initialize with config
- `add_key(key, config)` - Monitor new key
- `get_stats()` - Get usage statistics
- `reset_stats()` - Reset statistics

Execute callbacks on threshold:
```lua
require("blep").setup({
    keys = {
        j = {
            threshold = 10,
            callback = function(count, key)
                vim.notify("Pressed " .. key .. " " .. count .. " times")
            end
        }
    }
})
```

## License

MIT
