# AlwaysBuffed 1.2.0

- Shift-left-click the bar grip to open the buff wheel. Right-click the grip for settings. Right-clicking a buff icon still opens its category or upgrade.
- The wheel fades in over a quarter of a second and accepts input immediately. Slices show the buff icon, a gold border and timer while active, and MH or OH on weapon buffs. Hover a slice to see its details in the center.
- Fishing, Herbalism Tea, and Mage Comprehension tracking start off for each profile. Existing explicit choices are preserved.
- In Automatic mode, a fishing pole or registered fishing gear switches the bar, wheel, and shopping list to Fishing only when the current profile has a Fishing buff enabled. Disabling the last Fishing buff restores Combat.

# AlwaysBuffed 1.1.1

- Fishing items now appear in one **Utility** group. Lures are still ranked by Fishing bonus, and tracked items keep priority.
- Enabled **Herbalism Tea** appears on the default Combat bar. Learning Herbalism enables it by default, and the category checkbox overrides that choice. Find Herbs can be on or off. Equipping a fishing pole in Automatic mode still selects Fishing.
- Removed the hidden-herb and hidden-mining reminders. Characters who had selected the old Herbalism or Mining bar return to Automatic.

# AlwaysBuffed 1.1.0

- Open settings with `/alwaysbuffed` or `/ab` and select **Professions** to track Fishing, Herbalism, Mining, or Mage Comprehension. In **Automatic** mode, equipping a fishing pole switches the bar and wheel to Fishing. Putting the pole away restores Combat.
- The Fishing bar tracks lures, fishing food, the Shiny Silver Coin, and Fishing Rack or Hut bonuses. Use `/ab fishgear <item link or ID>` to register an extra item that selects the Fishing bar when equipped.
- In **General → Icons grow**, choose Left, Right, Up, or Down. The grip stays in place as icons expand or collapse.
- The interface follows the WoW client language. Translation files cover German, Spanish, French, Italian, Korean, Brazilian Portuguese, Russian, Simplified Chinese, and Traditional Chinese, with English as the fallback.

# AlwaysBuffed 1.0.4

- Release packaging for CurseForge. Gameplay is unchanged from 1.0.3.

# AlwaysBuffed 1.0.3

- Tracking an item keeps it assigned. The **+** returns when a newly available purchase would improve on both your tracked choice and what you carry. Right-click to inspect it. **Keep current item** dismisses the upgrades available now.
- The checklist and its shortcut expand or fold the buff bar immediately in combat. Both use the actions prepared before combat.

# AlwaysBuffed 1.0.2

- A spell checklist now marks the buff bar, minimap button, and addon list. When the bar is folded, the missing and active counts sit in the lower corners so the checklist stays visible.

# AlwaysBuffed 1.0.1

- The download now includes the GNU General Public License, version 3 only, for the AlwaysBuffed code. This license also covers v1.0.0. The bundled Barlow fonts use the SIL Open Font License 1.1.

# AlwaysBuffed 1.0.0

First public release for World of Warcraft: Forever 1.60.1.

- See which leveling buffs suit your spec, which items you already carry, and what to buy next. An optional Auctionator scan adds unit prices.
- Use your chosen consumables from the buff bar, a shortcut, or the radial wheel. Track each weapon hand independently and see when an eligible upgrade is missing from your bags.
- Track Camp Benefits and Well-Rested, including remaining time and sleeping bag stacks.

# AlwaysBuffed 0.5.2

- The collapse button and buff icons now share one outer border and even spacing in both bar orientations. The button keeps its size and position when you toggle the bar.

# AlwaysBuffed 0.5.1

- The sidebar starts with Food and Elixir, followed by buffs recommended for the selected spec. Class weapon buffs appear near the top when the corresponding hand is equipped. Situational buffs and camp reminders appear farther down.
- Removed Buff Drinks from the catalog and keybindings.
- The expand/collapse icon fills the same area as the other buff icons and follows the bar size setting. The folded grip shows missing buffs in soft red, with a neutral zero when every tracked buff is active.

# AlwaysBuffed 0.5.0

- Added a small + to tracked buff buttons when a stronger, usable item is available to buy and missing from your bags. Right-click the button to jump to the highlighted upgrade. Left-click keeps using your carried item. Manually tracking the carried item silences that suggestion.
- Category rankings hide unusable items by default. Each category and profile remembers its **Show unusable items** checkbox, including during searches.
- Added a bindable bar toggle in General and WoW Keybindings. Buff buttons show counts at bottom left, timers in the center, and MH or OH at bottom right.
- Added an original purple elixir icon to the minimap, bar grip and addon list.
- The collapsed grip is one buff-icon square. It always shows missing and active counts in that order. Enable **Glow when buffs are missing** for a subtle reminder around the grip.

# AlwaysBuffed 0.4.1

- Made Sleeping Bag and Campfire the same size as the other bar buttons. Well-Rested shows the buff icon, time left and stack count. The bag cooldown takes over when Well-Rested expires.
- Campfire stays gray until Camp Benefits is active. Clicking it uses the highest-capacity carried kit your Cooking skill allows, with support for a manually tracked kit. Hover for the kit name and campfire details.

# AlwaysBuffed 0.4.0

- Added horizontal and vertical bar layouts and mouseover-only visibility. The draggable grip keeps its position when changing layout or collapsing the bar.
- Added independent shortcuts for all 29 buff categories, including separate main-hand and off-hand actions. Bind a shortcut on its category page or in WoW’s Keybindings. Shortcuts use the same bag selection as the bar and work with the bar hidden.
- Added a static gold border for active buffs on the bar and wheel. Weapon tooltips and shortcuts use the class-specific labels, including Rogue Poison and Shaman Weapon Imbue.
- Moved Campfire and Sleeping Bag to the bottom of the category list. Tracked reminders show the earned buff’s icon, name and remaining time, including Well-Rested stacks and the Violet Dust version of Camp Benefits. The sleeping bag shows its cooldown when the buff has worn off.

# AlwaysBuffed 0.3.0

- Expanded the leveling catalog to 353 distinct items and spells across 29 categories. Additions include Mage Comprehension scrolls and familiars, Dragonbreath Chili, Winterspring Jujus, Un'Goro crystals, Blasted Lands draughts and water mobility buffs.
- Grouped item rankings by spec benefit, utility and low relevance. Each group starts open and can be collapsed. Search matches item names, stats and effects within the selected category.
- Named each class's weapon buff in settings and on the wheel, including Rogue poisons on both hands.
- Anchored the buff tray to a fixed-size draggable icon. It stays put through collapse and expansion and keeps its optional missing-count badge.

# AlwaysBuffed 0.2.0

- Added separate main-hand and off-hand recommendations, actions and timers for weapon enhancements and class imbues, including independently tracked Rogue poisons.
- Redesigned the wheel with directional slices. Hold the shortcut, move toward a slice, then release to use it. Releasing in the center cancels.
- Added class-color accents, a dark slate theme, bold Barlow typography, custom accent and background colors, and independent text, bar and wheel sizing.
- Added a collapsible bar with an optional missing-buff indicator. The bar starts expanded and the indicator starts off.
- Moved Campfire and Cozy Sleeping Bag into a dedicated Reminders section and replaced item pinning labels with tracking controls. Existing character preferences carry forward.

# AlwaysBuffed 0.1.0

- Added Forever leveling food, elixir, scroll and main-hand enhancement rankings with class and talent-tree presets.
- Added per-character, per-profile shopping preferences, item pins and optional Auctionator prices.
- Added a moveable action bar, a bindable consumable wheel, a minimap button and optional campfire and Cozy Sleeping Bag reminders.
