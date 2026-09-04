return function(mod)

  local ListMenu = require("src.ui.ListMenu")
  local Sound = require("src.core.Sound")
  local Bag = require("src.inventory.Bag")
  local Pokemon = require("src.pokemon.Pokemon")
  local TextBox = require("src.render.TextBox")

  -- ============================================================
  -- CODE STATE
  -- ============================================================

  local nextWildSpecies = nil
  local expMultiplier = 1
  local walkThroughWalls = false
  local shinyEnabled = false
  local genderMode = "RANDOM"

  -- ============================================================
  -- HELPERS
  -- ============================================================

  local function cleanName(name)
    if type(name) ~= "string" then
      return tostring(name)
    end

    return name:gsub("^Poke ", "")
  end

  local function playSound(game, sound)
    if game and game.data then
      pcall(Sound.play, game.data, sound)
    end
  end

  local function toggleLabel(name, enabled)
    if enabled then
      return name .. ": ON"
    end

    return name .. ": OFF"
  end

  -- ============================================================
  -- GIVE ITEM
  -- ============================================================

  local function giveItem(game, itemId, count)

    if not game
      or not game.save
      or not game.data
      or not game.data.items
      or not game.data.items[itemId] then

      return false
    end

    count = count or 1

    local ok, result = pcall(
      Bag.add,
      game.save,
      itemId,
      count,
      game.data
    )

    if not ok then

      if mod.log and mod.log.error then

        mod.log:error(
          "Codes: Bag.add failed for "
          .. tostring(itemId)
          .. ": "
          .. tostring(result)
        )

      end

      return false
    end

    return result ~= false
  end

  -- ============================================================
  -- MONEY
  -- ============================================================

  local function setMoney(game, amount)

    if not game or not game.save then
      return false
    end

    amount = math.floor(
      tonumber(amount) or 0
    )

    if amount < 0 then
      amount = 0
    end

    if amount > 999999 then
      amount = 999999
    end

    game.save.money = amount

    if type(game.save.player) == "table"
      and game.save.player.money ~= nil then

      game.save.player.money = amount
    end

    local primaryOK =
      tonumber(game.save.money) == amount

    local playerOK = true

    if type(game.save.player) == "table"
      and game.save.player.money ~= nil then

      playerOK =
        tonumber(game.save.player.money) == amount
    end

    return primaryOK and playerOK
  end

  -- ============================================================
  -- GENERIC LIST MENU
  -- ============================================================

  local function openList(
    game,
    title,
    items,
    onChoose
  )

    if not items or #items == 0 then
      return
    end

    game.stack:push(
      ListMenu.new(
        game,
        title,
        items,
        {
          rows = 7,
          pageJump = true,
          keyRepeat = true,

          onChoose = function(item, menu)

            if item and onChoose then
              onChoose(item, menu)
            end

          end,

          onCancel = function()
          end
        }
      )
    )
  end

  -- ============================================================
  -- WILD POKEMON LIST
  -- ============================================================

  local function buildWildPokemonList(game)

    local pokemonData =
      game
      and game.data
      and game.data.pokemon

    if type(pokemonData) ~= "table" then
      return {}
    end

    local species = {}

    for id, def in pairs(pokemonData) do

      if type(def) == "table" then

        local dex =
          tonumber(def.dex)

        if dex
          and dex >= 1
          and dex <= 251
          and type(def.name) == "string" then

          species[#species + 1] = {
            id = id,
            dex = dex,
            name = def.name
          }

        end
      end
    end

    table.sort(
      species,
      function(a, b)

        if a.dex ~= b.dex then
          return a.dex < b.dex
        end

        return tostring(a.id)
          < tostring(b.id)

      end
    )

    local rows = {}

    for _, mon in ipairs(species) do

      rows[#rows + 1] = {
        label = ("%03d %s"):format(
          mon.dex,
          cleanName(mon.name)
        ),

        value = mon.id
      }

    end

    return rows
  end

  -- ============================================================
  -- WILD POKEMON MENU
  -- ============================================================

  local function openWildPokemonMenu(game)

    local rows =
      buildWildPokemonList(game)

    if #rows == 0 then
      return
    end

    openList(
      game,
      "WILD POKEMON",
      rows,

      function(item, menu)

        if not item
          or not item.value then

          return
        end

        nextWildSpecies =
          item.value

        menu:close()

        local def =
          game.data.pokemon[item.value]

        local name =
          def
          and cleanName(def.name)
          or tostring(item.value)

        game.stack:push(
          TextBox.new(
            game,
            ("NEXT WILD POKEMON:\n%s"):format(
              name
            )
          )
        )

      end
    )
  end

  -- ============================================================
  -- ITEM CATEGORIES
  -- ============================================================

  local function buildItemCategories(game)

    local balls = {}
    local items = {}
    local tms = {}
    local hms = {}
    local keyItems = {}

    local data =
      game
      and game.data
      and game.data.items

    if type(data) ~= "table" then
      return balls, items, tms, hms, keyItems
    end

    for id, def in pairs(data) do

      if type(def) == "table" then

        local name =
          cleanName(def.name or id)

        local upper =
          tostring(id):upper()

        -- ======================================================
        -- POKEBALLS
        -- ======================================================

        local isBall =

          upper == "POKE_BALL"
          or upper == "GREAT_BALL"
          or upper == "ULTRA_BALL"
          or upper == "MASTER_BALL"
          or upper == "SAFARI_BALL"

          -- Kurt's Apricorn Balls
          or upper == "FAST_BALL"
          or upper == "LEVEL_BALL"
          or upper == "LURE_BALL"
          or upper == "MOON_BALL"
          or upper == "FRIEND_BALL"
          or upper == "LOVE_BALL"
          or upper == "HEAVY_BALL"

          -- Crystal Park Ball
          or upper == "PARK_BALL"

        if isBall then

          balls[#balls + 1] = {
            label = name,
            value = id,
            sortName = name
          }

        elseif upper:match("^TM[_%d]") then

          tms[#tms + 1] = {
            label = name,
            value = id,
            sortName = name
          }

        elseif upper:match("^HM[_%d]") then

          hms[#hms + 1] = {
            label = name,
            value = id,
            sortName = name
          }

        elseif def.keyItem == true then

          keyItems[#keyItems + 1] = {
            label = name,
            value = id,
            sortName = name
          }

        else

          items[#items + 1] = {
            label = name,
            value = id,
            sortName = name
          }

        end
      end
    end

    local function sortRows(a, b)

      return tostring(a.sortName)
        < tostring(b.sortName)

    end

    table.sort(
      balls,
      sortRows
    )

    table.sort(
      items,
      sortRows
    )

    table.sort(
      tms,
      sortRows
    )

    table.sort(
      hms,
      sortRows
    )

    table.sort(
      keyItems,
      sortRows
    )

    return balls, items, tms, hms, keyItems
  end

  -- ============================================================
  -- POKEBALL MENU
  -- ============================================================

  local function openPokeballsMenu(game)

    local balls =
      buildItemCategories(game)

    openList(
      game,
      "POKEBALLS",
      balls,

      function(item)

        if giveItem(
          game,
          item.value,
          1
        ) then

          playSound(
            game,
            "Get_Item1"
          )

        end

      end
    )
  end

  -- ============================================================
  -- ITEMS MENU
  -- ============================================================

  local function openItemsMenu(game)

    local _, items =
      buildItemCategories(game)

    openList(
      game,
      "ITEMS",
      items,

      function(item)

        if giveItem(
          game,
          item.value,
          1
        ) then

          playSound(
            game,
            "Get_Item1"
          )

        end

      end
    )
  end

  -- ============================================================
  -- TM / HM MENU
  -- ============================================================

  local function openTmHmMenu(game)

    local _, _, tms, hms =
      buildItemCategories(game)

    local rows = {}

    for _, item in ipairs(tms) do
      rows[#rows + 1] = item
    end

    for _, item in ipairs(hms) do
      rows[#rows + 1] = item
    end

    openList(
      game,
      "TMS / HMS",
      rows,

      function(item)

        if giveItem(
          game,
          item.value,
          1
        ) then

          playSound(
            game,
            "Get_Item1"
          )

        end

      end
    )
  end

  -- ============================================================
  -- KEY ITEMS MENU
  -- ============================================================

  local function openKeyItemsMenu(game)

    local _, _, _, _, keyItems =
      buildItemCategories(game)

    openList(
      game,
      "KEY ITEMS",
      keyItems,

      function(item)

        if giveItem(
          game,
          item.value,
          1
        ) then

          playSound(
            game,
            "Get_Key_Item"
          )

        end

      end
    )
  end

  -- ============================================================
  -- EXP MULTIPLIER MENU
  -- ============================================================

  local function openExpMenu(game)

    local rows = {

      {
        label = "1X",
        value = 1
      },

      {
        label = "2X",
        value = 2
      },

      {
        label = "10X",
        value = 10
      },

      {
        label = "50X",
        value = 50
      },

      {
        label = "100X",
        value = 100
      }

    }

    openList(
      game,
      "EXP MULT",
      rows,

      function(item)

        expMultiplier =
          item.value

      end
    )
  end

  -- ============================================================
  -- MONEY MENU
  -- ============================================================

  local function openMoneyMenu(game)

    local rows = {

      {
        label = "$10000",
        value = 10000
      },

      {
        label = "$50000",
        value = 50000
      },

      {
        label = "$100000",
        value = 100000
      },

      {
        label = "$999999",
        value = 999999
      }

    }

    openList(
      game,
      "MONEY",
      rows,

      function(item)

        local success =
          setMoney(
            game,
            item.value
          )

        if success then

          playSound(
            game,
            "Press_AB"
          )

        end

      end
    )
  end

  -- ============================================================
  -- HEAL PARTY
  --
  -- Restores:
  --   * Full HP
  --   * Status
  --   * Full move PP
  --
  -- PP is restored directly from game.data.moves so the mod
  -- uses the same move data currently loaded by the game.
  -- ============================================================

  local function healParty(game)

    if not game
      or not game.save
      or type(game.save.party) ~= "table" then

      return false
    end

    local healed = false

    local moves =
      game.data
      and game.data.moves

    for _, mon in ipairs(game.save.party) do

      if type(mon) == "table"
        and not mon.isEgg then

        -- ======================================================
        -- RESTORE HP
        -- ======================================================

        if mon.stats
          and mon.stats.hp then

          mon.hp =
            mon.stats.hp

        end

        -- ======================================================
        -- CLEAR STATUS
        -- ======================================================

        mon.status = nil

        -- ======================================================
        -- RESTORE MOVE PP
        -- ======================================================

        if type(mon.moves) == "table"
          and type(moves) == "table" then

          for _, mv in ipairs(mon.moves) do

            if type(mv) == "table"
              and mv.id then

              local moveDef =
                moves[mv.id]

              if type(moveDef) == "table"
                and moveDef.pp then

                local ppUps =
                  tonumber(mv.ppUps) or 0

                mv.pp =
                  moveDef.pp
                  + ppUps * math.floor(
                      moveDef.pp / 5
                    )

              end

            end
          end
        end

        healed = true
      end
    end

    return healed
  end

  -- ============================================================
  -- ALL BADGES
  -- ============================================================

  local function giveAllBadges(game)

    if not game
      or not game.save then

      return false
    end

    game.save.inventory =
      game.save.inventory or {}

    local count = 0

    -- Preferred source:
    -- Gen1Recomp exposes the badge definitions through
    -- data.constants.badges.

    local constants =
      game.data
      and game.data.constants

    local badges =
      constants
      and constants.badges

    if type(badges) == "table" then

      for _, badge in ipairs(badges) do

        local id

        if type(badge) == "table" then
          id = badge.id
        else
          id = badge
        end

        if id then

          game.save.inventory[id] = 1
          count = count + 1

        end
      end
    end

    -- Fallback for data sets where badge IDs are directly
    -- represented in the item table.

    if count == 0
      and game.data
      and type(game.data.items) == "table" then

      for id, def in pairs(
        game.data.items
      ) do

        if type(id) == "string"
          and id:upper():find(
            "BADGE",
            1,
            true
          ) then

          game.save.inventory[id] = 1
          count = count + 1

        elseif type(def) == "table"
          and type(def.name) == "string"
          and def.name:upper():find(
            "BADGE",
            1,
            true
          ) then

          game.save.inventory[id] = 1
          count = count + 1

        end
      end
    end

    return count > 0
  end

  -- ============================================================
  -- GENDER MODIFIER MENU
  -- ============================================================

  local function openGenderMenu(game)

    local rows = {

      {
        label = "MALE",
        value = "MALE"
      },

      {
        label = "FEMALE",
        value = "FEMALE"
      },

      {
        label = "RANDOM",
        value = "RANDOM"
      }

    }

    openList(
      game,
      "GENDER MOD",
      rows,

      function(item)

        genderMode =
          item.value

      end
    )
  end

  -- ============================================================
  -- CODES MENU ROWS
  -- ============================================================

  local function buildCodesRows(game)

    return {

      {
        label = "HEAL PARTY",
        value = "heal"
      },

      {
        label = "WILD POKEMON",
        value = "wild"
      },

      {
        label = toggleLabel(
          "WTW",
          walkThroughWalls
        ),
        value = "walls"
      },

      {
        label = ("EXP MULT: %dX")
          :format(expMultiplier),
        value = "exp"
      },

      {
        label = "MONEY",
        value = "money"
      },

      {
        label = "ALL BADGES",
        value = "badges"
      },

      {
        label = toggleLabel(
          "SHINY",
          shinyEnabled
        ),
        value = "shiny"
      },

      {
        label = "MASTER BALL",
        value = "master_ball"
      },

      {
        label = "RARE CANDY",
        value = "rare_candy"
      },

      {
        label = "POKEBALLS",
        value = "pokeballs"
      },

      {
        label = "ITEMS",
        value = "items"
      },

      {
        label = "TMS / HMS",
        value = "tm_hm"
      },

      {
        label = "KEY ITEMS",
        value = "key_items"
      },

      {
        label = ("GENDER: %s")
          :format(genderMode),
        value = "gender"
      }

    }
  end

  -- ============================================================
  -- CODES MENU
  -- ============================================================

  local function openCodesMenu(game)

    local rows =
      buildCodesRows(game)

    openList(
      game,
      "CODES",
      rows,

      function(item, menu)

        -- ======================================================
        -- HEAL PARTY
        -- ======================================================

        if item.value == "heal" then

          local success =
            healParty(game)

          menu:close()

          if success then

            playSound(
              game,
              "Press_AB"
            )

            game.stack:push(
              TextBox.new(
                game,
                "PARTY FULLY HEALED!"
              )
            )

          else

            game.stack:push(
              TextBox.new(
                game,
                "HEAL FAILED!"
              )
            )

          end

          return
        end

        -- ======================================================
        -- WILD POKEMON
        -- ======================================================

        if item.value == "wild" then

          menu:close()

          openWildPokemonMenu(game)

          return
        end

        -- ======================================================
        -- WALK THROUGH WALLS
        -- ======================================================

        if item.value == "walls" then

          walkThroughWalls =
            not walkThroughWalls

          menu:close()

          openCodesMenu(game)

          return
        end

        -- ======================================================
        -- EXP MULT
        -- ======================================================

        if item.value == "exp" then

          menu:close()

          openExpMenu(game)

          return
        end

        -- ======================================================
        -- MONEY
        -- ======================================================

        if item.value == "money" then

          menu:close()

          openMoneyMenu(game)

          return
        end

        -- ======================================================
        -- ALL BADGES
        -- ======================================================

        if item.value == "badges" then

          local success =
            giveAllBadges(game)

          if success then

            playSound(
              game,
              "Press_AB"
            )

          end

          return
        end

        -- ======================================================
        -- SHINY
        -- ======================================================

        if item.value == "shiny" then

          shinyEnabled =
            not shinyEnabled

          menu:close()

          openCodesMenu(game)

          return
        end

        -- ======================================================
        -- MASTER BALL - 99
        -- ======================================================

        if item.value == "master_ball" then

          if giveItem(
            game,
            "MASTER_BALL",
            99
          ) then

            playSound(
              game,
              "Get_Item1"
            )

          end

          return
        end

        -- ======================================================
        -- RARE CANDY - 99
        -- ======================================================

        if item.value == "rare_candy" then

          if giveItem(
            game,
            "RARE_CANDY",
            99
          ) then

            playSound(
              game,
              "Get_Item1"
            )

          end

          return
        end

        -- ======================================================
        -- POKEBALLS
        -- ======================================================

        if item.value == "pokeballs" then

          menu:close()

          openPokeballsMenu(game)

          return
        end

        -- ======================================================
        -- ITEMS
        -- ======================================================

        if item.value == "items" then

          menu:close()

          openItemsMenu(game)

          return
        end

        -- ======================================================
        -- TMS / HMS
        -- ======================================================

        if item.value == "tm_hm" then

          menu:close()

          openTmHmMenu(game)

          return
        end

        -- ======================================================
        -- KEY ITEMS
        -- ======================================================

        if item.value == "key_items" then

          menu:close()

          openKeyItemsMenu(game)

          return
        end

        -- ======================================================
        -- GENDER
        -- ======================================================

        if item.value == "gender" then

          menu:close()

          openGenderMenu(game)

          return
        end

      end
    )
  end

  -- ============================================================
  -- ADD CODES TO START MENU
  -- ============================================================

  mod.hooks:wrap(
    "ui.start_menu.items",

    function(next, game, items)

      mod.ui.insertBefore(
        items,
        "OPTION",
        {
          label = "CODES",

          onSelect = function()
            openCodesMenu(game)
          end
        }
      )

      return next(
        game,
        items
      )
    end
  )

  -- ============================================================
  -- WILD POKEMON MODIFIER
  -- ============================================================

  mod.hooks:wrap(
    "encounter.species",

    function(next, enc, ctx)

      local result =
        next(enc, ctx)

      if nextWildSpecies == nil then
        return result
      end

      if result == nil then
        return result
      end

      local species =
        nextWildSpecies

      nextWildSpecies = nil

      local modified = {}

      for key, value in pairs(result) do
        modified[key] = value
      end

      modified.species =
        species

      return modified
    end
  )

  -- ============================================================
  -- EXP MULTIPLIER
  -- ============================================================

  mod.hooks:wrap(
    "exp.gain",

    function(next, exp, ctx)

      local result =
        next(
          exp,
          ctx
        )

      if expMultiplier <= 1 then
        return result
      end

      return math.floor(
        result * expMultiplier
      )
    end
  )

  -- ============================================================
  -- WALK THROUGH WALLS
  -- ============================================================

  mod.hooks:wrap(
    "movement.collision",

    function(next, allowed, ctx)

      if walkThroughWalls then
        return true
      end

      return next(
        allowed,
        ctx
      )
    end
  )

  -- ============================================================
  -- EXPORTS
  -- ============================================================

  mod.exports =
    mod.exports or {}

  mod.exports.setNextWild =
    function(species)

      local game =
        mod.game

      if not game
        or not game.data
        or not game.data.pokemon
        or not game.data.pokemon[species] then

        return false
      end

      local def =
        game.data.pokemon[species]

      local dex =
        tonumber(def.dex)

      if not dex
        or dex < 1
        or dex > 251 then

        return false
      end

      nextWildSpecies =
        species

      return true
    end

  mod.exports.clearNextWild =
    function()

      nextWildSpecies = nil

    end

  mod.exports.getNextWild =
    function()

      return nextWildSpecies

    end

  mod.exports.getExpMultiplier =
    function()

      return expMultiplier

    end

  mod.exports.getWalkThroughWalls =
    function()

      return walkThroughWalls

    end

  mod.exports.getShiny =
    function()

      return shinyEnabled

    end

  mod.exports.getGenderMode =
    function()

      return genderMode

    end

end