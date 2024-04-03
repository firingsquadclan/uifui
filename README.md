# UIFUI 2.4
## Requirements
- Moonloader
- SAMP.Lua
- SAMPFUNCS
- CLEO 4

## Features
- You receive death messages only near your player (to avoid death screen flood)
- Moves player DMG message from the top of your screen to the right side of the radar
- Moves all generic gametexts/textdraw messages from the middle of the screen to the bottom left corner
- Scores textdraw reworked
- Shows the name of the players near you with additional info like HP/ARMOUR/GOD

## Required Libraries
- local sampev = require "lib.samp.events"
- local raknet = require "lib.samp.raknet"
- local ev     = require "lib.samp.events.core"
- local vk     = require "vkeys"
- local memory = require "memory"
- local inicfg = require 'inicfg'

Example image:
![sa-mp-046](https://user-images.githubusercontent.com/10908255/160299456-5324bd57-4875-44cf-9f75-1cfea48c1598.png)
