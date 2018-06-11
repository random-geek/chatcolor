# Colored-Chat

A Minetest CSM which adds functionality for colouring messages from specific players.

## Features

* Colours regular, /me, and join/leave messages
* Colours names in server status messages
* Set any colour for any name
* Set default colours for each type of message
* Use either commands or user-interface

## How to Use

### Colours

Colours can be either a hex colour (such as `#00FF00`) or a HTML colour name (such as `plum`).

For a full list of HTML colours, see [this page](https://html-color-codes.info/color-names/).

### .setcolor <name> <color>

Colour messages from player `<name>` as `<color>`. To set a default for a certain type of message, use the names `default_chat`, `default_me`, or `default_join`.

**Examples:**

`.setcolor lizzy123 #00FFFF`

`.setcolor default_me grey`

### .delcolor <name>

Delete a colour setting for a player. Their messages will then appear in a default colour.

**Examples:**

`.delcolor joe15`

### .listcolors

Shows a list of all player and default colours in chat.

### .gui

Displays a user-interface which allows easier modification of colours.

## Screenshots

![alt text](https://github.com/random-geek/Chat-color/blob/master/screenshots/Capture20.PNG "Coloured names is chat")

![alt text](https://github.com/random-geek/Chat-color/blob/master/screenshots/Capture21.PNG "Main user-interface")

![alt text](https://github.com/random-geek/Chat-color/blob/master/screenshots/Capture22.PNG "Modification view")