
# make.nvim

# Purpose

Provide a basic API for Make functionality
- build_project()
- make_clean()
- set_build_type(build_type)
- set_build_target(build_target)
- get_target_binary_path(build_target)

Suggested companion plugins
- [telescope-build](https://github.com/thefoxery/telescope-build.nvim)
    - Telescope powered pickers for build type/target
    - Configurable for any build system
- [lualine-build](https://github.com/thefoxery/lualine-build.nvim)
    - Displays build configuration in lualine
    - Configurable for any build system

If you are looking for a similar plugin for CMake, then check out: [cmake.nvim](https://github.com/thefoxery/cmake.nvim)

## Goal

To get up and running as fast as possible with Make in neovim
- install -> setup (with sensible defaults) -> custom setup (optional) -> start working

## Project status

In very early development. Public API may be subject to change etc. You know the drill!

As soon as the plugin gets into a state where it may be more useful for the public, tags will
be introduced to lock down stability.

## Install

```
# lazy

{
    'thefoxery/make.nvim",
}
```

## Setup

```
# plugin setup

# default configuration
require("make").setup({
    build_types = { "debug", "release" }
    build_type = "debug", -- default to this if build system reports ""
    make = {
        targets_target_name = "targets", -- the Makefile target that provides the build targets list
    },
})
```

Note the 'targets' build target that provides a list of the available build targets using Make.

Add the following to your Makefile:

```
TARGETS := $(wildcard dist/*/${TARGET_NAME})

# list build targets for neovim
targets:
	@for t in $(TARGETS); do echo $$t; done
```

Here my build output directory is set to ./dist and * refers to debug/release folder

In case you need to use another target name for this, make sure to pass the new name in your setup()

## Example DAP configuration

```
dap.configurations.cpp = {
    {
        name = "Debug",
        type = "codelldb",
        request = "launch",
        program = function()
            if make.is_project_directory() then
                return make.get_target_binary_path(make.get_build_target())
            end
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        terminal = "integrated",
    },
```

## Limitations / Known issues

