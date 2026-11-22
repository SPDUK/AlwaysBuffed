# Profession buffs

Type `/alwaysbuffed` or `/ab` in chat, select **Professions** in the sidebar, and choose a **Bar mode**. The buff bar, wheel, and shopping list follow the selected loadout. All profession categories start unchecked. Open a category to enable tracking for your profile and set its shortcut.

## Fishing

Each Fishing category lists its items under **Utility** for every spec. Lures are ranked by Fishing bonus. A usable lure you explicitly track takes priority.

In **Automatic**, your current profile must have at least one Fishing buff enabled for fishing gear to switch the bar to Fishing. A main-hand fishing pole qualifies. To register one extra item for your character, use `/alwaysbuffed fishgear <item link or ID>` or `/ab fishgear <item link or ID>`. The registered item qualifies in any equipped slot. Use `fishgear clear` with either command to remove the extra trigger. Applying a lure still requires a pole in your main hand.

These records use the Forever client data for build `1.60.1.70959`. The fishing pole is weapon class `2`, subclass `20`, equipped in the main hand. Lure spells require subclass mask `1048576` and apply a temporary enchant through spell effect `54`. The table lists the item requirement separately from the skill gained after the lure is applied. [ItemSparse](https://wago.tools/db2/ItemSparse?build=1.60.1.70959), [SpellEquippedItems](https://wago.tools/db2/SpellEquippedItems?build=1.60.1.70959), [SpellEffect](https://wago.tools/db2/SpellEffect?build=1.60.1.70959), [SpellItemEnchantment](https://wago.tools/db2/SpellItemEnchantment?build=1.60.1.70959)

| Lure source | Item ID | Use spell | Enchant | Fishing required | Bonus | Duration |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Shiny Bauble | 6529 | 8087 | 263 | 0 | +25 | 10 min |
| "Secret" Bait | 268880 | 8087 | 263 | 0 | +25 | 10 min |
| Wide-Brimmed Fishing Hat | 259846 | 1265220 | 263 | 1 | +25 | 10 min |
| Nightcrawlers | 6530 | 8088 | 264 | 50 | +50 | 10 min |
| Aquadynamic Fish Lens | 6811 | 8532 | 264 | 50 | +50 | 10 min |
| Bright Baubles | 6532 | 8090 | 265 | 100 | +75 | 10 min |
| Flesh Eating Worm | 7307 | 9092 | 265 | 100 | +75 | 10 min |
| Aquadynamic Fish Attractor | 6533 | 8089 | 266 | 100 | +100 | 5 min |

A lure enchant identifies the bonus, so an active +25 enchant can come from any of the three +25 sources. The Wide-Brimmed Fishing Hat is a reusable bind-on-pickup item in the head slot, inventory slot `1`. Its use has a 10-minute cooldown. While the hat is on cooldown, the bar can offer an eligible lure from your bags. The client flags "Secret" Bait as conjured and its acquisition remains unverified. The catalog offers it only when carried. [Wide-Brimmed Fishing Hat item record](https://outof.games/realms/forever/item/259846-wide-brimmed-fishing-hat/), ["Secret" Bait client item record](https://wowazeroth.com/en-us/database/forever/items/268880-secret-bait/)

The fishing foods all trigger the 15-minute Well Fed aura `1249521` after 10 seconds of eating. Their individual use spells set the bonus. These foods also grant the usual 5% kill XP effect below the level cap. The client contains a +25 Fishing variant of Nutritious Food, spell `1249517`, with no linked item in this build. [ItemXItemEffect](https://wago.tools/db2/ItemXItemEffect?build=1.60.1.70959), [ItemEffect](https://wago.tools/db2/ItemEffect?build=1.60.1.70959), [SpellEffect](https://wago.tools/db2/SpellEffect?build=1.60.1.70959), [SpellDuration](https://wago.tools/db2/SpellDuration?build=1.60.1.70959)

| Food | Item ID | Use spell | Required level | Fishing bonus |
| --- | ---: | ---: | ---: | ---: |
| Loch Frenzy Delight | 6316 | 1249502 | 5 | +3 |
| Fillet of Frenzy | 5476 | 1249505 | 5 | +5 |
| Bristle Whisker Catfish | 4593 | 1249508 | 15 | +8 |
| Rockscale Cod | 4594 | 1249511 | 25 | +12 |
| Filet of Redgill | 13930 | 1249514 | 35 | +18 |
| Spinefin Halibut | 8957 | 1249514 | 45 | +18 |

The Shiny Silver Coin is a bind-on-pickup reward from the Alliance quest Bottles and Baubles. Item `286732` casts `1321320`, which targets water and triggers the separate player aura `1321323` for +30 Fishing for 30 minutes. [Bottles and Baubles quest record](https://www.wowhead.com/forever/quest=99143/bottles-and-baubles), [Shiny Silver Coin item record](https://www.wowhead.com/forever/item=286732/shiny-silver-coin), [Client spell effects](https://wago.tools/db2/SpellEffect?build=1.60.1.70959)

A Fishing Rack or Hut requires a nearby campfire. Their Fishing bonuses are catch-quality effects with their own one-hour auras. Their shared Fish Bowl benefit is an 8% stat increase, which overlaps Blessing of Kings. Blizzard's November 16 hotfix made Fishing Racks provide lures to everyone. [Blizzard's camping guide](https://news.blizzard.com/en-us/article/24301516/gather-around-the-campfire-in-world-of-warcraft-forever), [Blizzard's November 16 hotfix](https://worldofwarcraft.blizzard.com/en-us/news/24315281/wow-forever-hotfixes-november-16-2026), [Client spells](https://wago.tools/db2/Spell?build=1.60.1.70959)

| Camp feature | Item ID | Use spell | Fishing to place | Fishing aura |
| --- | ---: | ---: | ---: | --- |
| Fishing Rack | 279965 | 1307247 | 140 | Uncommon Fishing `1280341` |
| Fishing Hut | 279966 | 1307246 | 300 | Rare Fishing `1280342` |

The Lucky Fishing Hat, Arcanite Fishing Pole, and Eternium Fishing Line provide passive equipment bonuses. The Fishing rank spells `7620`, `7731`, `7732`, and `18248` all require the fishing-pole subclass. The druid's Idol of Shifting Tides, item `263411`, is a ranged-slot relic whose equipped effect `1270470` reduces shapeshifting mana cost. The reviewed client item and spell records do not establish a separate Bear Form fishing item or a pole-free Fishing spell. [SpellEquippedItems](https://wago.tools/db2/SpellEquippedItems?build=1.60.1.70959), [Idol of Shifting Tides client record](https://forever-xp.com/items/263411/)

## Herbalism

Version 1.1.1 removed the hidden-herb and hidden-mining reminders. Characters upgrading with the old Herbalism or Mining bar selected return to **Automatic**.

Select **Professions → Herbalism Tea** to show or hide the reminder on your default Combat bar. The checkbox works with Find Herbs on or off. In Automatic mode, putting your fishing pole away brings the default bar back.

From level 25, carry Goldthorn Tea (`10841`) to use it from the bar. Drink for 10 seconds to gain +15 Herbalism for 15 minutes. The addon tracks the tea’s Well Fed aura (`1249907`), including when the last tea has been used. [ItemEffect](https://wago.tools/db2/ItemEffect?build=1.60.1.70959), [SpellEffect](https://wago.tools/db2/SpellEffect?build=1.60.1.70959)

## Mage Comprehension

**Comprehension** is available to Mages. Its bar tracks Scroll of Comprehension `215257`, which grants +15 Comprehension skill for one hour through aura `435563`. Mage familiar scrolls and weapon imbues remain in the Combat loadout. [Blizzard's Mage class notes](https://news.blizzard.com/en-us/article/24302097/world-of-warcraft-forever-class-deep-dives-mage-and-shaman), [Comprehension spell record](https://www.wowhead.com/forever/spell=435563/comprehension)

## Other professions

The catalog includes timed buffs for Fishing, Herbalism, and Mage Comprehension. Permanent tool and enchant bonuses stay active while equipped. Deft Digits, a crafting-speed effect, has no expiry in the client data. [Client spell effects](https://wago.tools/db2/SpellEffect?build=1.60.1.70959), [Client spell durations](https://wago.tools/db2/SpellDuration?build=1.60.1.70959)
