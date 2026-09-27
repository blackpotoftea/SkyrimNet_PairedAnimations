# SkyrimNet_PairedAnimations

SkyrimNet actions that let characters act on each other physically, with a real two-actor
animation playing for it.

## Actions

| Action | What it does |
| --- | --- |
| `HugTarget` | One character hugs another. |
| `ExecuteTarget` | A strong enough attacker kills a target outright, openly or from stealth. |
| `VampireBiteTarget` | A vampire feeds on a character who has verbally agreed to it. |

All three are driven by the `SPA_Main` script on the `SN_PairedAnim_Main` quest.

## SkyrimNet plugin

The actions ship as a SkyrimNet plugin, `potoftea.paired-animations`, in
`SKSE/Plugins/SkyrimNet/external/`. It appears on SkyrimNet's Installed Plugins page with an
External badge. Removing the mod removes the actions.

**Upgrading from 1.0:** SkyrimNet Beta 25 no longer reads the old action location
(`SKSE/Plugins/SkyrimNet/config/actions/`), and this release no longer ships it. The action
names are unchanged, so any per-action enabled and cooldown settings you changed carry over.
If you copied the old action files with Plugins > Import Old Content, remove those imported
copies from your overlay, or they will hide this mod's action updates.

## Requirements

* SkyrimNet Beta 25 (0.25.0) or newer, for the actions. Older betas won't load them.
* [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048) - for println
