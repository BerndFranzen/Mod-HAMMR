# Mod-HAMMR
Standard conversation that you will hear between SWGOH players each an every day:

A: I
  - cannot beat Tier 3.
  - always lose in GA.
  - struggle with the next fight.

B: Yeah, maybe your mods ain't good enough.

A: Really?

B: Sure, it's  often the mods, so as I sayd, they may not be good enough.

A: But then I need to know: How Are My Mods Really?


This is where Mod-HAMMR (How Are My Mods Really) my be helpflu to you. This tool crawls through your SWGOH roster and shows you:
- All your characters with their gear, power and how they are / should be modded
- Freely customizeable squads that reflect your squad selection within the game, helping you to keep focus und which chars to improve next.

How to start
============
Download these 3 files to your Windows/Mac/Linux machine:
- Mod-HAMMR.ps1
- Config-Accounts.csv
- Config-Teams.csv

Replace the allycode in the Config-Accounts.csv with your allycode.

Start the script.

What information will you get?
==============================

PREREQUISITES
=============
- Microsoft Powershell 6.0.0 or higher (Windows, Mac, Linux)
- PSParseHTML Powershell Module (by EvotecIT), installed automatically if not present 
- Your allycode registered and synched on swgoh.gg
- Your allycode(s) updated in the CONFIG-Accounts.csv file


MMSCore
-------
What is the MMScore? the MMScore is intended to help you to learn from the best. It pulls all data from https://swgoh.gg/stats/mod-meta-report/guilds_100_gp/ and compares the character's mods against this meta list and calculates the score as follows:
- Matching mod set 20 points for 4-mod sets (e.g. Speed) and 10 points for 2-mod sets (e.g. Health) (max. 30)
- Matching primary attribute 5 points per mod (max. 30)
- Speed on primary or secondary attribute 5 points per mod (max. 30)
- All mod sets and primaries matching and speed on all mods 10 points

This results in a total possible MMScore of 100. If the score is not reached, the recommended mod sets and primaries are listed, otherwise the assigned mods are listed with their speed, mod set and primary attribute.

If a char has reached an MMScore of 100, the rarity of each mod will be evaluated as well as when sclicing a mod from 5A to 6E, both, primary and all secondary get a status boost which increases the mod's value.
- For each mod with a rarity of 6* extra 5 points are added (max. 30)

This results in a total possible MMScore of 130. All 6* mods equipped are printed in BOLD to highlight them and show you were you still can improve.

NOTE: Mods below 5* and Level 15 are filtered and regarded as not present.
