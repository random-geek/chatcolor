# chatcolor

[![](https://img.shields.io/badge/Minetest%20Forums-chatcolor-4E9A06)](https://forum.minetest.net/viewtopic.php?f=53&t=20345)

A Minetest client-side mod (CSM) which adds custom chat message coloring based on player name or message type.

## Features

* Colors regular, /me, and join/leave messages
* Colors names in server status messages
* Set any color for any name
* Set default colors for each type of message
* Use either chat commands or GUI

## How to Use

### Installation

See [this great forum post](https://forum.minetest.net/viewtopic.php?f=53&t=17830) on how to install CSMs.

### Colors

Colors can be either a hex color (such as `#00FF00`) or a HTML color name (such as `plum`).

For a full list of HTML colors, see [this page](https://html-color-codes.info/color-names/).

### `.colors`

Displays a GUI for modifying colors.

### `.setcolor <name> <color>`

Color messages from player `<name>` as `<color>`. To set a default for a certain type of message, use the names `default_chat`, `default_me`, or `default_join`.

Examples:

`.setcolor lizzy123 #00FFFF`

`.setcolor default_me grey`

### `.delcolor <name>`

Delete a color setting for a player. Their messages will then appear in a default color.

Examples:

`.delcolor joe15`

### `.listcolors`

Shows a list of all player and default colors in chat.

## Screenshots

![Colored names in chat](https://github.com/random-geek/Chat-color/blob/master/screenshots/Capture20.PNG "Colored names in chat")

![Main GUI](https://github.com/random-geek/Chat-color/blob/master/screenshots/Capture21.PNG "Main GUI")

![Modification view](https://github.com/random-geek/Chat-color/blob/master/screenshots/Capture22.PNG "Modification view")
