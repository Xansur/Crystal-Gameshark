# Codes

GameShark-style codes for Pokemon Crystal running in Gen1Recomp.

## Current version

0.1.1

Target:

Gen1Recomp 0.2.24
Pokemon Crystal

## Menu

The Start menu contains:

CODES

Selecting it opens:

CODES
├── HEAL PARTY
└── WILD POKEMON

## Heal Party

HEAL PARTY restores the player's current party.

The code attempts to use the engine's full party healing behavior first,
then falls back to restoring HP, clearing status, and restoring move PP.

## Wild Pokemon

WILD POKEMON contains the Pokemon found in the game's Pokemon registry.

Only National Dex numbers 001 through 251 are included.

The list is sorted by National Dex number.

Example:

#001 BULBASAUR
#002 IVYSAUR
#003 VENUSAUR

...

#150 MEWTWO

...

#249 LUGIA
#250 HO-OH
#251 CELEBI

Selecting a Pokemon changes the next wild encounter.

Example:

CODES
> WILD POKEMON

WILD POKEMON
> #150 MEWTWO

After selecting MEWTWO, the next wild encounter becomes MEWTWO.

The selected Pokemon is automatically cleared after the encounter.

The normal encounter tables are not permanently changed.

## Navigation

The Pokemon list uses:

UP / DOWN
LEFT / RIGHT page jump
A select
B cancel

## Installation

Place this directory in the Gen1Recomp mods directory:

mods/
└── crystal_gameshark/
    ├── manifest.json
    ├── main.lua
    └── README.md

Enable the mod from the Gen1Recomp mod manager.

## Future codes

Planned additions:

- Walk Through Walls
- Infinite Money
- All Badges
- Shiny Pokemon
- Max EXP
- Level 100
- Max DVs
- Pokerus
- Infinite Master Balls
- Item Modifier
- Key Item Modifier
- Instant Egg Hatch
- Gender Modifier
- Other Pokemon Crystal GameShark codes