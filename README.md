# AlwaysBuffed

<img align="right" width="96" height="96" src="docs/alwaysbuffed-icon.png" alt="AlwaysBuffed spell checklist icon">

AlwaysBuffed ranks food, elixirs, weapon buffs, and other consumables for your spec in **World of Warcraft: Forever**. See what to buy, what you already carry, and which buffs are running out. Use items from the bar or radial wheel, with dedicated loadouts for Fishing, Herbalism, Mining, and Mage Comprehension.

## Install

1. Download the ZIP ending in `-forever.zip` from the latest release. [Download AlwaysBuffed](https://github.com/SPDUK/AlwaysBuffed/releases/latest)
2. Close WoW and extract the `AlwaysBuffed` folder into `World of Warcraft/_forever_/Interface/AddOns/`. Check that `AlwaysBuffed/AlwaysBuffed.toc` sits directly inside `AddOns`.
3. Start Forever, enable **AlwaysBuffed** in the character screen’s **AddOns** menu, and enter the world. Type `/alwaysbuffed` or `/ab` to open the addon. Select **Food** to see your first recommendation.

For auction prices, install the Forever version of Auctionator and run **Full Scan** from its tab at the auction house. AlwaysBuffed uses the cached unit prices. All other features work on their own. [Auctionator](https://www.curseforge.com/wow/addons/auctionator)

## In game

Type `/alwaysbuffed` or `/ab` in chat, or left-click the minimap button to open settings. Both commands accept the same options.

| Command | What it does |
| --- | --- |
| `/alwaysbuffed` or `/ab` | Opens settings. Using it again closes the window. |
| `/alwaysbuffed wheel` or `/ab wheel` | Opens or closes the clickable buff wheel outside combat. |
| `/ab lock` or `/ab unlock` | Locks or unlocks the buff bar’s position. |
| `/ab fishgear <item link or ID>` | Registers an extra equipped item that switches **Automatic** mode to Fishing. |
| `/ab fishgear clear` | Removes that extra item. Fishing poles still switch the bar automatically. |

The shopping list shows recommended purchases for the active bar, how many you carry, and the last known auction price. A dash means there is no cached price.

| Control | Behavior |
| --- | --- |
| Profile | **Auto** follows the talent group with the most committed points. Choose a named profile to plan for another build. Before spending points, each class has a leveling default. |
| Food or consumable category | **Food** and **Elixir** come first in the sidebar. **For your spec** lists your profile’s recommended categories. Browse ranked choices, required levels, bag counts and unit prices. Tick **Show unusable items** to include items with an unmet requirement. This choice is saved per category and profile. Open or collapse **Best for your spec**, **Utility** and **Not useful** separately, or search by name, stat or effect. |
| Track an item | Gives your chosen item priority when eligible. If you carry it, the bar will use it first. Clear that choice to resume automatic selection. |
| Lowest price | Recommends the cheapest eligible, purchasable item with a known Auctionator price. If there are no prices, it falls back to the profile ranking. |
| Buff bar | A solid gold border means the buff is active. Each hand has its own border and timer. Click an icon to use the best eligible item in your bags. Food falls back through lower-ranked buff food to plain recovery food. Click the grip to collapse or expand, drag it to move, or Shift-click it for settings. |
| Upgrade marker | A **+** marks a stronger eligible purchase. Tracking an item remembers the options available at that point. A newly unlocked upgrade can bring back the **+** while your item stays assigned. Right-click to see the highlighted upgrade. **Keep current item** dismisses the current suggestions. Carrying an equally strong or better option also clears the marker. |
| Bar layout | Open **General → Icons grow** and choose **Left**, **Right**, **Up**, or **Down**. Icons unfold from the grip and fold back into it. Near a screen edge, they wrap or use the opposite side to stay in view. Click the grip or press the **Bar toggle shortcut** to fold the bar, including in combat. The collapsed grip shows **missing \| active**. **Show on mouseover** and **Glow when buffs are missing** are optional. |
| Buff shortcuts | Open a buff category and choose **Set shortcut**, then press a key or key combination. Choose **Clear** to remove it. Each shortcut uses that category’s current bag choice or spell, even with the bar collapsed, hidden, or set to mouseover. A profession shortcut is available while its bar is active. Each hand can have its own shortcut. WoW’s native keybinding menu also lists the actions. Changes to secure actions take effect outside combat. |
| Buff wheel | Set a shortcut in **General**. Hold it, move toward a slice and release to use the item. Return to the center or press Escape to cancel. The wheel opens at screen center and starts unbound. Right-click the grip or minimap, or use **/ab wheel**, for the clickable version. |
| Button labels | The timer sits in the center. The lower-left count shows items in your bags or stacks of Well-Rested. Weapon buttons show **MH** or **OH** at bottom right. Hover to look up a shortcut. |
| Reminders | Enable **Campfire** or **Sleeping Bag** at the bottom of the category list. Well-Rested shows the buff icon, time left and stacks. The bag cooldown appears when Well-Rested has worn off. Click the gray campfire to place your highest-capacity usable kit, or a kit you’ve chosen to track. It lights up when you earn Camp Benefits. |

**Appearance** sets the accent for the whole addon, the background color, and the text, bar and wheel sizes. Each character starts with its class color on slate gray. Existing item choices and category preferences carry forward by profile.

The catalog covers 359 distinct items and spells across 36 categories, including 346 distinct entries across 28 combat categories. The spec presets distinguish combat output from situational value. A Survival hunter prioritizes agility and melee procs, while a Holy priest prioritizes healing and mana regeneration. The catalog notes explain which effects share a selector and how to get them. [Spec rankings](docs/spec-rankings.md) · [Consumable coverage](docs/catalog.md)

Dual wielders get separate main-hand and off-hand choices for stones, oils and applicable class imbues. A rogue sees **Main-Hand Poison** and **Off-Hand Poison** and can track a different poison on each hand alongside the weapon enhancement. The same slots use class-specific names for Shaman weapon imbues, Mage weapon scrolls and Warlock stones. Switching to a shield or unequipping a weapon removes that hand from the bar while preserving its choices. Shaman spells that automatically choose a hand follow the client's casting rules. The wheel opens outside combat. The bar keeps its assigned actions during combat and refreshes them afterward.

## Profession loadouts

Type `/alwaysbuffed` or `/ab` and select **Professions** in the sidebar to choose a bar or open one of its buff categories.

The active mode switches the buff bar and wheel to that loadout’s categories. **Automatic** opens the Fishing bar when you equip a fishing pole and returns to Combat when you put it away. Select **Combat** or a profession to keep that bar active until you choose another mode.

| Loadout | Buffs |
| --- | --- |
| Fishing | Pole lures, Fishing skill food, Shiny Silver Coin, and Fishing Rack or Hut catch bonuses. The Wide-Brimmed Fishing Hat can apply its reusable lure while equipped and ready. |
| Herbalism | Goldthorn Tea for +15 Herbalism and Revealing Draught for hidden herbs. |
| Mining | Revealing Draught for hidden mining nodes. |
| Comprehension (Mage) | Scroll of Comprehension for +15 Comprehension skill. |

To use another equipped item as a signal for **Automatic** fishing mode, enter `/ab fishgear <item link or ID>`. This remembers one item for your character. Use `/ab fishgear clear` to remove it. Applying a lure still requires a fishing pole in your main hand. [Profession buff details](docs/profession-buffs.md)

## Languages and translation

AlwaysBuffed follows the WoW client language. It includes English, German, French, Italian, Spanish (Spain and Latin America), Brazilian Portuguese, Russian, Korean, Simplified Chinese, and Traditional Chinese. Item and spell names come from the client when available. While item data is loading, the addon can show the English catalog name.

To edit a translation, open the UTF-8 Lua file for that language and change the text on the right. Both Spanish clients use `esES.lua`. Keep format placeholders such as `%s`, `%d`, and `%%` in order. [Translation files](AlwaysBuffed/Locales)

```lua
L["Click to use %s."] = "Haz clic para usar %s."
```

For new interface text, use a complete English phrase as the key, for example `L["Click to use %s."]:format(itemName)`. Missing translations fall back to the English phrase. To add a language, copy a locale file, update its locale check, and list it after `Locale.lua` in the addon manifest. Run `lua tests/locales.lua` to check coverage and format placeholders. [Addon manifest](AlwaysBuffed/AlwaysBuffed.toc)

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

## Website

From `website/`, run `npm ci` and `npm run dev` to work on the homepage. `npm run build` renders the homepage to static HTML in `website/dist/`, which you can check locally with `npm run preview`.

For a public build, set `SITE_URL` to the site's full homepage URL, including its path if hosted below the domain root. GitHub Actions publishes `website/dist/` to GitHub Pages when the site changes on `main`. The build uses the URL for the canonical link, social preview image, and sitemap.
