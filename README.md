# Mod-HAMMR
Standard conversation that you will hear between SWGOH players each an every day:

A: 
  - I cannot beat Tier 3 in event xyz
  - I always lose in GA
  - My guild always loses in TW
  - My guild doesn't perform in TB
  
B: Yeah, maybe your mods ain't good enough and the teams are not well equipped.

A: Really?

B: Sure, it's  often the mods, so as I said, they may not be good enough.

A: But then I need to know: How Are My Mods Really?


This is where Mod-HAMMR (How Are My Mods Really) my be helpful to you. This tool crawls through your SWGOH roster and shows you:
- All your characters with their gear, power and how they are / should be modded
- Freely customizeable squads that reflect your squad selection within the game, helping you to keep focus und which chars to improve next
- Analysis for yourself and your entire guild (if required)

How to start as a single player
===============================
1) Make sure, you have Powershell 6.20 or higher installed (Windows, Mac, Linux) (https://aka.ms/PSWindows)
2) Download these 3 files to your Windows/Mac/Linux machine:
- Mod-HAMMR.ps1
- Config-Accounts.csv
- Config-Teams.csv
- Config-Need4Speed.csv
3) Replace the allycode in the Config-Accounts.csv file with your allycode and chose if you want the script to check your mods in "Strict" or "Relaxed" mode.
4) Customize the Config-Teams.csv file if needed so that if reflects that squads as you actually play them and set "Is3v3" to "true" for those line you added for 3v3 GA.
5) Unblock the PS1 file with "Unblock-File .\Mod-HAMMR.ps1" 
6) Start the script in Microsoft Powershell 6.2.0 or higher.
![image](https://github.com/BerndFranzen/Mod-HAMMR/assets/97521655/85dedaec-a6ea-490a-bba0-d48b3292a4d5)

How to start as a guild
=======================
Additionally, after following the steps above:
1) In the Config-Accounts.csv set the GuildMode value for your allycode to "true"
2) In th Config-Teams.csv file se the IsGuildTeam value to "true" for alle teams that you want to have analyzed for your entire guild
3) Start the script in Microsoft Powershell 6.2.0 or higher.
![image](https://github.com/BerndFranzen/Mod-HAMMR/assets/97521655/c4f8e438-4738-432d-9044-744742f6e815)

What information will you get as a player?
==========================================
Basically the tool will drop 3 HTML files with your player name:
- Chars     - listing all chars that you have and that have been leveled to Lvl 50 or higher
![image](https://github.com/user-attachments/assets/df0a12a9-b2ae-4ee7-be80-f00cf3061ce4)
- Teams     - showing the chars grouped in squads that can match the squads you defined within the game
![image](https://github.com/user-attachments/assets/de15e6e1-b12d-4a44-82d5-fb16fd6d8bbf)
- Teams-3v3 - showing you the teams you built for 3v3 GA (if any have been specified)
![image](https://github.com/user-attachments/assets/a9c1426f-a509-4a95-a199-0f54ac9451aa)
- GAC Oppenents : Once the script detects a new GAC bracket it will load the opponent's data automatically and created the 3 files mentioned above for each opponent in a separate subdirectory "GAC Opponents".

What does that data mean for me?
=================================
Let's take the first line from the sample below for a specific team:
![image](https://github.com/user-attachments/assets/31f2ebe4-aa9e-47e3-861b-65fc7a9fe5f7)
- Name          - The ingame name of the character, this may not reflect the name that you see in your localized version of the game but the API cannot return anythin else. In the teams list, if the name is followed by some information in brackets (GA, TB, TW, 3v3, 5v5, RD, CQ, CH) this means, that this char has an Omicron applied for this certain mode. If the Omicron is underlined it means that there are more than 1 Omicron required for that char but at least 1 but not all are applied.
- Role          - The role(s) that character has
- Power         - The total power of this char
- Gear          - The Gear-level either G01-G13 or R01-R09 for relic chars, prepending u(ltimate), z(eta), o(micron)
- Speed         - Speed of the character with the bonus given thorugh mods in brackets
- MMScore       - The Mod Meta Score indicating the level of modding (see below for further explanations)
- Mod-Sets      - applied (black) or recommended (red/italic) mod-sets for this char
- Mod-Slot 1-6  - if this field is black: Speed of this mod, number of rolls (improvements) on speed, mod-set of this mod, primary attribute of this mod, one or more "+" for any secondary attribute of this mod that matches the primary attribute and one or more "*" for any secondary attribute of this mod that matches on of the mod-sets.
- Mod-Slot 1-6  - if this field is read/italic: Recommended primary attribute for this mod

- Name written in bold      - Character is G12 or higher
- Name background coloured  - Character is G13 or Relic
- Mod slot written in bold  - Mod is 6*

And now let's take Rey (Jedi Training) as another example:

![image](https://github.com/BerndFranzen/Mod-HAMMR/assets/97521655/79690d78-16ba-48dd-ad1a-ceb4a3ff5d43)

The MMScore is below 100, and followed by "(A)" thus showing us that I missed something. First, the mod score was higher when comparing against the overall list but not the Top 100. On the Holo-Array the mod is written in red/italic, showing us that I do not have the suggestes primary applied or the mod doesn't have any speed secondary on it. So now I have to go into the game and see if I can find a suitable mod.
Additionally, several mods only show less than (5) rolls on speed, so I should also see if I can replace them by suitable mods with better speed or calibrate them to get additiona rolls.

What additional information will you get as a guild?
====================================================
For each guild, all data will be stored in a subdirectory with the guild's name:
- Guild-Members - Summary for the entire guild
  - Name and GM of each player
  - Number of Galactic Legends
  - Average MMScore (calculated over all characters having one or more mods assigned)
  - Average Speed-Bonus through mods (calculated over all characters having one or more mods assigned)
  - MMSpeed+ - Average of MMScore and Speed-Bonus
  - Grand Arena Position
![image](https://github.com/BerndFranzen/Mod-HAMMR/assets/97521655/b9547e97-0b48-40a0-a722-4aaeea984294)
- Member-(Name)-Chars - listing all chars of that meber that have been leveled to Lvl 50 or higher
- Member-(Name)-Teams - listing all guild-teams of that member 
- Team-(Name) - showing a summary for each team defined as well as detailed information about the team for each guild member. The summary contains the following information:
  - Overall gear level of the team indicated by the lowest-geared character
  - Average Speed and MMScore of the team
  - Gear level, Speed and MMScore of each character in the team
![image](https://github.com/BerndFranzen/Mod-HAMMR/assets/97521655/51beed50-153a-42ef-a8b7-45c857b88935)
![image](https://github.com/BerndFranzen/Mod-HAMMR/assets/97521655/ce1c549b-0da1-46bb-a74a-0661915184de)
- Galactic Legends - Summary of all Galactic Legends that exist within the guild
![image](https://github.com/BerndFranzen/Mod-HAMMR/assets/97521655/23cba134-cd3a-4c83-8220-3e0b9bbe9174)
- History - During the first run of the tool every month, guild summary and team analysis is stored in the History subdirectory prepended by the current year and month so you can track guild progress on a month-over month basis.

PREREQUISITES
=============
- Microsoft Powershell 6.2.0 or higher (Windows, Mac, Linux) (https://aka.ms/PSWindows)
- PSParseHTML Powershell Module (by EvotecIT), installed automatically if not present 
- Your allycode registered and synched on swgoh.gg
- Your allycode(s) updated in the CONFIG-Accounts.csv file

MMSCore and MMSpd+
==================
NOTE: There is no absolute truth in modding, this tool just compares the mods to the current meta. You my find it usefull to mod a character differently for another game mode (JKL for example) or as it takes a different role in the squad that you play it in. This is only a SUGGESTION! But what is NOT NEGOTIATBLE is speed, this why I added MMSpd+ which takes both, the MMScore and the Speed Bonus a character gets through mods and builds the average of it.

What is the MMScore? the MMScore is intended to help you to learn from the best. It pulls all data from swgoh.gg' Mod Meta Report and compares the character's mods against this meta list and calculates the score as follows:
- Matching mod set 20 points for 4-mod sets (e.g. Speed) and 10 points for 2-mod sets (e.g. Health) (max. 30)
- Matching primary attribute 5 points per mod (max. 30)
- Speed on primary or secondary attribute 5 points per mod (max. 30)
- All mod sets and primaries matching and speed on all mods 10 points

This results in a total possible MMScore of 100. If the score is not reached, the recommended mod sets and primaries are listed, otherwise the assigned mods are listed with their speed, mod set and primary attribute.

If a char has reached an MMScore of 100, the rarity of each mod will be evaluated as well as when sclicing a mod from 5A to 6E, both, primary and all secondary get a status boost which increases the mod's value.
- For each mod with a rarity of 6* extra 5 points are added (max. 30)
- If all mods have been sliced to 6A extra 20 points are added

This results in a total possible MMScore of 150. All 6* mods equipped are printed in BOLD to highlight them and show you were you still can improve.

So there are basically 3 levels to achieve:
- 100 - all mods follow the current meta for this char and every mod has Speed on either primary or secondary attribute
- 130 - all mods have additionally been sliced to 6*
- 150 - all mods have additionally been sliced to 6A

NOTE: Mods below 5* and Level 15 are filtered and regarded as not present.

What is the difference between Strict and Relaxed mode?
- swgoh.gg provides 2 different lists of their Mod Meta Report, one using the Top 100 Guilds' mods and one from all players registerd.
- In Strict mode, the tool only uses the Top 100's mods and gives you the corresponding score
- In Relaxed mode, the score is calculated for both lists and the higher score is displayed.
- If the score from All players is used, this is indicated by the MMScore beinfollowed by "(A)"
- Relaxed mode has been added to handle the fact that meta sometime "flickers" and shows you a good score one day and a bad store every other day


Contact
=======
Allycode  832-123-322

Mail      swgoh-guildstats@outlook.com

Q&A
===
Q: How can I create custom teams?

A: Just edit the CONIFG-Teams.csv file and add whatever you want to have an analysis for. You need to add the DefId as specified in 
   the game itself.



Q: How do I know what is the DefId for a certain char?

A: On each run, the script will create a file called GAME-NameMapping.htm that shows the display name and the corresponding
   DefId of each character and ship


Q: In the CONFIG-Accounts.csv there are 2 allycodes, do I have to provide 2 allycodes as well?

A: No, that's only required if you're also doing statistics for a partner or want to find out more about your current GA opponent.


Q: Why does an MMScore of a character drop although I modded according to the recommendations?

A: Because it's Meta and this is constantly changing so you may need to re-mod from time to time.


Q: Speed, speed, speed, but what about characters like Merrin that do not take speed from their mods?

A: That's what we implemented "Need4Speed" for, the corresponding config file contains those characters that don't need speed on their mods so having 0 speed on them will not turn down their MMSCore.


Q: When I try to run the script on Windows I get an error preventing the execution because it's not signed.

A: You can exempt the script with the command "Unblock-File <script-name>".


Q: I have upgrades my chars but why do the pages still show the old values?
  
A: swgoh.gg only updates the stats every 24 hours. You can force a manual update through your profile page on your profile page of swgoh.gg. You can also update the entire guild once every 12 hours or become a "Patron" at swgoh.gg 
   for a small fee, which reduces the automatic update intervall and grants more manual refreshes per day.
