# Propeller Rat
Source code for my Playdate game "Propeller Rat", a game where you pilot a propeller-strapped rat through increasingly challenging, hazard-filled worlds with crank-based movement! Features a total of 80 action packed levels spread across 8 different worlds, and leaderboards to compete for the fastest times in each world! You can get it [on Catalog](https://play.date/games/propeller-rat), or on [Itch IO](https://squidgod.itch.io/propeller-rat).

![5XmqNL](https://github.com/user-attachments/assets/22681be5-72bf-43ad-bec0-1d249f12f181)
![Pvizp6](https://github.com/user-attachments/assets/7108e9ce-0862-4f1f-80e5-fdc2811a9ab0)
![8Vn9WA](https://github.com/user-attachments/assets/8f300b6e-6a39-45bd-90fa-1488bba71798)
![jJMUZo](https://github.com/user-attachments/assets/4e4bc5e2-32cd-496b-8c90-b7b34fda7835)


## Project Structure
- `mockups/`: contains all the .aseprite files used in the project
- `source/`: contains all the source code and assets
  - `data/`: contains font + [LDtk](https://ldtk.io/) world data
    - `fonts/`: contains the fonts used: [m6x11](https://managore.itch.io/m6x11) by managore
    - `LDtk_lua_levels/`: auto-generated by LDtk.lua, contains cached level data
    - `tileset-table-16-16.png`: tileset used by LDtk world
    - `world.ldtk`: [LDtk](https://ldtk.io/) world file
  - `images/`: contains all game images
  - `launcherImages/`: contains all images used by Playdate launcher
  - `scripts/`: contains all source code
    - `audio/`: contains audio manager
      - `audioManager.lua`: handles all SFX and Music in one place
    - `game/`: contains game scene
      - `gameScene.lua`: manager for all game elements (player, hazards, tilemap, etc.)
    - `hazards/`: code for all the hazard elements
    - `levels/`: handles spawning all the level elements (walls, hazards, etc.)
    - `libraries/`: contains all the libraries used in this project
      - `Assets.lua`: [Lazy Loading Assets](https://devforum.play.date/t/best-practices-for-managing-lots-of-assets/395/2) by Shaun Inman
      - `LDtk.lua`: [Playdate LDtk Importer](https://github.com/NicMagnier/PlaydateLDtkImporter) by Nic Magnier
      - `SceneManager.lua`: Scene Management, by me
      - `Utilites.lua`: Generic Utilities, by me
    - `pickups/`: contains code for keys and the teleporter
    - `player/`: contains player controller
    - `story/`: contains dialog/story code
    - `title/`: contains all non-game scenes
      - `gameCompletedScene.lua`: unused game end scene
      - `levelSelectScene.lua`: level select + level preview generation
      - `scoreboardScene.lua`: scoreboard display
      - `starfield.lua`: generates random starfield background
      - `titleScene.lua`: title + disabled cheat code
      - `worldSelectScene.lua`: world select + unlocking
    - `globals.lua`: game data, tags, z indexes, all script imports
    - `tests.lua`: sanity checks for valid levels
  - `sound/`: contains all sfx and music files
  - `main.lua`: only imports globals and sets the starting scene

## License
All code is under the MIT License, with the exception of the `Assets.lua` library by Shaun Inman. The `LDtk.lua` library by Nic Magnier is licensed under the MIT license. 
