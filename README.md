# AlwaysBuffed

<img align="right" width="96" height="96" src="docs/alwaysbuffed-icon.png" alt="AlwaysBuffed spell checklist icon">

AlwaysBuffed ranks food, elixirs, weapon buffs, and other consumables for your spec in **World of Warcraft: Forever**. See what to buy, what you already carry, and which buffs are running out. Use items from the bar or radial wheel.

## Install

1. Download the ZIP ending in `-forever.zip` from the latest release. [Download AlwaysBuffed](https://github.com/SPDUK/AlwaysBuffed/releases/latest)
2. Close WoW and extract the `AlwaysBuffed` folder into `World of Warcraft/_forever_/Interface/AddOns/`. Check that `AlwaysBuffed/AlwaysBuffed.toc` sits directly inside `AddOns`.
3. Start Forever, enable **AlwaysBuffed** in the character screen’s **AddOns** menu, and enter the world. Type `/ab` and open **Food** to see your first recommendation.

For auction prices, install the Forever version of Auctionator and run **Full Scan** from its tab at the auction house. AlwaysBuffed uses the cached unit prices. All other features work on their own. [Auctionator](https://www.curseforge.com/wow/addons/auctionator)

## In game

Open **/ab**, **/alwaysbuffed**, or left-click the minimap button. The shopping list shows the recommended item for each tracked category, how many you carry, and the last known auction price. A dash means there is no cached price.

| Control | Behavior |
| --- | --- |
| Profile | **Auto** follows the talent group with the most committed points. Choose a named profile to plan for another build. Before spending points, each class has a leveling default. |
| Food or consumable category | **Food** and **Elixir** come first in the sidebar. **For your spec** lists your profile’s recommended categories. Browse ranked choices, required levels, bag counts and unit prices. Tick **Show unusable items** to include items with an unmet requirement. This choice is saved per category and profile. Open or collapse **Best for your spec**, **Utility** and **Not useful** separately, or search by name, stat or effect. |
| Track an item | Gives your chosen item priority when eligible. If you carry it, the bar will use it first. Clear that choice to resume automatic selection. |
| Lowest price | Recommends the cheapest eligible, purchasable item with a known Auctionator price. If there are no prices, it falls back to the profile ranking. |
| Buff bar | A solid gold border means the buff is active. Each hand has its own border and timer. Click an icon to use the best eligible item in your bags. Food falls back through lower-ranked buff food to plain recovery food. Click the grip to collapse or expand, drag it to move, or Shift-click it for settings. |
| Upgrade marker | A **+** marks a stronger eligible purchase. Tracking an item remembers the options available at that point. A newly unlocked upgrade can bring back the **+** while your item stays assigned. Right-click to see the highlighted upgrade. **Keep current item** dismisses the current suggestions. Carrying an equally strong or better option also clears the marker. |
| Bar layout | Click the checklist or press the **Bar toggle shortcut** to expand or fold the list, including in combat. In **General**, set the shortcut, choose **Horizontal** or **Vertical**, or enable **Show on mouseover**. The grip scales with the other buff icons. When collapsed, it shows **missing \| active**. A soft red number means at least one buff is missing. **Glow when buffs are missing** adds a subtle glow and starts off. |
| Buff shortcuts | Open a buff category and choose **Set shortcut**, then press a key or key combination. Choose **Clear** to remove it. Each shortcut uses that category’s current bag choice or spell, even with the bar collapsed, hidden, or set to mouseover. Each hand can have its own shortcut. WoW’s native keybinding menu also lists the actions. Changes to secure actions take effect outside combat. |
| Buff wheel | Set a shortcut in **General**. Hold it, move toward a slice and release to use the item. Return to the center or press Escape to cancel. The wheel opens at screen center and starts unbound. Right-click the grip or minimap, or use **/ab wheel**, for the clickable version. |
| Button labels | The timer sits in the center. The lower-left count shows items in your bags or stacks of Well-Rested. Weapon buttons show **MH** or **OH** at bottom right. Hover to look up a shortcut. |
| Reminders | Enable **Campfire** or **Sleeping Bag** at the bottom of the category list. Well-Rested shows the buff icon, time left and stacks. The bag cooldown appears when Well-Rested has worn off. Click the gray campfire to place your highest-capacity usable kit, or a kit you’ve chosen to track. It lights up when you earn Camp Benefits. |

**Appearance** sets the accent for the whole addon, the background color, and the text, bar and wheel sizes. Each character starts with its class color on slate gray. Existing item choices and category preferences carry forward by profile.

The leveling catalog covers 346 distinct items and spells across 28 categories. The spec presets distinguish combat output from situational value. For example, a Survival hunter prioritizes agility and melee procs, while a Holy priest prioritizes healing and mana regeneration. The catalog notes list stackable layers, acquisition limits and which effects share a selector. [Spec rankings](docs/spec-rankings.md) · [Consumable coverage](docs/catalog.md)

Dual wielders get separate main-hand and off-hand choices for stones, oils and applicable class imbues. A rogue sees **Main-Hand Poison** and **Off-Hand Poison** and can track a different poison on each hand alongside the weapon enhancement. The same slots use class-specific names for Shaman weapon imbues, Mage weapon scrolls and Warlock stones. Switching to a shield or unequipping a weapon removes that hand from the bar while preserving its choices. Shaman spells that automatically choose a hand follow the client's casting rules. The wheel opens outside combat. The bar keeps its assigned actions during combat and refreshes them afterward.

## License

Copyright (C) 2026 SPDUK. The AlwaysBuffed code is licensed under the GNU General Public License, version 3 only (`GPL-3.0-only`). This grant includes the code released as v1.0.0. [Full license](LICENSE)

The bundled Barlow SemiBold and Bold typefaces are licensed under the SIL Open Font License 1.1. Russian, Korean, and both Chinese locales use Blizzard's locale font. [Barlow license](AlwaysBuffed/Media/Barlow/OFL.txt)

## Feedback

For a bug or a ranking that looks wrong, include your addon version, Forever client version, class and spec, the item or buff, and what happened. [GitHub Issues](https://github.com/SPDUK/AlwaysBuffed/issues)

## Build from source

Run these commands from the repository root with Python 3.9 or newer.

```powershell
py tools/addon.py build AlwaysBuffed
py tools/addon.py install AlwaysBuffed
```

Build writes `dist/AlwaysBuffed-<version>-forever.zip`. Install copies that same package into your Forever client. To use another installation, pass `--game "D:\Games\World of Warcraft\_forever_"`.

Run the Lua 5.1 checks from the repository root. They cover the catalog, all 28 ranking presets, login and migration, secure actions, bar positioning, search, settings, and wheel gestures.

```powershell
Get-ChildItem tests/*.lua | ForEach-Object { lua $_.FullName; if ($LASTEXITCODE) { throw "Failed $($_.Name)" } }
```
