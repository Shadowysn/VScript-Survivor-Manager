# VScript Survivor Manager
A VScript-based addon based on spawning and managing the current number count of survivors.
Currently buggy for actual multiplayer purposes due to inability to host multiplayer on my end.

### Chat Commands (use with / or !)
`!survbot <number, leave empty for 1>` - Manually add survivor bots.

`!survkick` - Remove a bot in your crosshair, or nearest to it.

`!survcount <number>` - Set the survCount setting and refresh it in-game. This handles the auto-management of number of survivors and saves permanently across all games in it's settings file.

`!survorder <character list>` - Change the survivor order the Auto-Manager spawns bots in. Leave empty to reset to default survivor order.

Example: `!survorder b z e f n c l r z l`

`!survswap` - Takeover control to your crosshair's nearest survivor bot. Will not work if you or the bot are pinned, downed, or dead.

`!survfix` - Re-enables the Auto-Manager if you screw up the bot count.