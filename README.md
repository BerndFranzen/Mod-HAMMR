# Mod-HAMMR
Standard conversation that you will hear between SWGOH players each an every day:

A: I
  - cannot beat Tier 3.
  - always lose in GA.
  - struggle with the next fight.

B: Yeah, maybe your mods ain't good enough.

A: Really?

B: Sure, it's  often the mods, so as I said, they may not be good enough.

A: But then I need to know: How Are My Mods Really?


This is where Mod-HAMMR (How Are My Mods Really) my be helpful to you. This tool crawls through your SWGOH roster and shows you:
- All your characters with their gear, power and how they are / should be modded
- Freely customizeable squads that reflect your squad selection within the game, helping you to keep focus und which chars to improve next.

How to start
============
Download these 3 files to your Windows/Mac/Linux machine:
- Mod-HAMMR.ps1
- Config-Accounts.csv
- Config-Teams.csv

Replace the allycode in the Config-Accounts.csv with your allycode.

Customize the Config-Teams.csv if needed so that if reflects that squads as you actually play them.

Start the script in Microsoft Powershell.

What information will you get?
==============================
Basically the tool will drop 2 HTML files with your player name:
- Chars - listing all chars that you have and that have been leveled to Lvl 50 or higher
- Teams - showing the chars grouped in squads that can math the squads you defined within the game.

What does that data mean?
=========================
Let's take the first line from the sample that I uploaded as well (Supersix-Chars.htm):

    Name                Power Gear  Speed MMScore Mod-Sets      Transmitter       Receiver    Processor         Holo-Array            Data-Bus        Multiplexer
    Jedi Master Kenobi  42292 uzR07 580   150     Health/Speed  27(5)-HE-Offense  32-SP-Speed 26(5)-SP-Defense  23(5)-HE-Crit. Damage 23(5)-SP-Health 26(5)-SP-Offense

- Name          - The ingame name of the character, this may not reflect the name that you see in your localized version of the game but the API cannot return anythin else.
- Power         - The total power of this char
- Gear          - The Gear-level either G01-G12 or R01-R09 for relic chars, prepending u(ltimate), z(eta), o(micron)
- Speed         - Speed of the character
- MMScore       - The Mod Meta Score indicating the level of modding (see below for forther explanations)
- Mod-Sets      - applied (black) or recommended (red/italic) mod-sets for this char
- Mod-Slot 1-6  - if this field is black: Speed of this mod, number of rolls (improvements) on speed, mod-set of this mod, primary attribute of this mod
- Mod-Slot 1-6  - if this field is read/italic: Recommended primary attribute for this mod

- Name written in bold      - Character is G12 or higher
- Name background coloured  - Character is relic
- Mod slot written in bold  - Mod is 6*


PREREQUISITES
=============
- Microsoft Powershell 6.0.0 or higher (Windows, Mac, Linux)
- PSParseHTML Powershell Module (by EvotecIT), installed automatically if not present 
- Your allycode registered and synched on swgoh.gg
- Your allycode(s) updated in the CONFIG-Accounts.csv file

MMSCore
=======
What is the MMScore? the MMScore is intended to help you to learn from the best. It pulls all data from https://swgoh.gg/stats/mod-meta-report/guilds_100_gp/ and compares the character's mods against this meta list and calculates the score as follows:
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

Q: When I try to run the script on Windows I get an error preventing the execution because it's not signed.

A: You can exempt the script with the command "Unblock-File <script-name>".

Q: I have upgrades my chars but why do the pages still show the old values?
  
A: swgoh.gg only updates the stats every 24 hours. You can force a manual update once every 24 hours or become a "Patron" at swgoh.gg 
   for a small fee (€3.50/month), which reduces the automatic update intervall to 1 hour and grants you 5 manual refreshes per day.


