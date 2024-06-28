<#

    SWGOH Mod-HAMMR Build 24-26 (c)2024 SuperSix/Schattenlegion

#>

<# 

Changes

- Improved accuracy of results by enforcing cache-bypass during all web requests
- Tested with Powershell 7.4.3
- Tested with PSParseHTML 1.0.2 

Planned upcoming features 

- Support Grandivory's Mod optimizer JSON templates to override swgoh.gg meta - mark MMScore with (C)ustom

Bugfixes

- None

Known Issues

- None


#>

# CSS for output table form

$header = @"
<style>

    h1 {
        font-family: Arial, Helvetica, sans-serif;
        color: #e68a00;
        font-size: 28px;
    }
    
    h2 {
        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;
    }
   
   table {
		font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
        width:100%
        
	} 
	
    td {
		padding: 4px;
		margin: 0px;
		border: 0;
	}
	
    th {
        background: #395870;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        padding: 10px 15px;
        vertical-align: middle;
       
	}

    tbody tr:nth-child(even) {
        background: #f0f0f2;
        vertical-align: middle;
    }

</style>

"@

function CheckPrerequisites() {
    
    Clear-Host
    Write-Host $VersionString  -ForegroundColor Green
    Write-Host

    # Check if all prerequisites are met

    if ($PSVersionTable.PSVersion.ToString() -lt "6.2.0") {Write-Host "ERROR - This script requires Powershell 6.2.0 or higher" -ForegroundColor Red; Break}
    if ((get-Item .\CONFIG-Accounts.csv -ErrorAction SilentlyContinue) -eq $null) {Write-Host "ERROR - Config file CONFIG-Accounts.csv missing"-ForegroundColor Red; Break}
    if ((get-Item .\CONFIG-Teams.csv -ErrorAction SilentlyContinue) -eq $null) {Write-Host "WARNING - Config file CONFIG-Teams.csv missing"-ForegroundColor Yellow}
    if ((get-Item .\CONFIG-Need4Speed.csv -ErrorAction SilentlyContinue) -eq $null) {Write-Host "WARNING - Config file CONFIG-Need4Speed.csv missing"-ForegroundColor Yellow}   
    if ((Invoke-WebRequest -uri http://swgoh.gg).StatusCode -ne 200) {Write-Host "ERROR - Cannot connect to swgoh.gg" -ForegroundColor Red; Break}
    $ParseModule = Get-Module PSParseHTML -ListAvailable -ErrorAction SilentlyContinue
    If ($ParseModule -eq $null) { Install-Module -Name PSParseHTML -AllowClobber -Force }

    $GacSubDir = (Get-ChildItem (".\GAC Opponents") -ErrorAction SilentlyContinue).name
    if ($GacSubDir -eq $null) { $Dummy = New-Item -Path (".\GAC Opponents") -ItemType Directory -Erroraction silentlycontinue }

}

# MAIN

# Define static data

$ModSetShort = ("","HE","OF","DE","SP","CC","CD","PO","TE")
$ModSetLong = ("","Health","Offense","Defense","Speed","Critical Chance","Critical Damage","Potency","Tenacity") 
$OmicronModeList = ("","","","","RD","","","TB","TW","GA","","CQ","CH","","3v3","5v5")
$SlotNameList = ("","","Transmitter","Receiver","Processor","Holo-Array","Data-Bus","Multiplexer")
$ModMetaUrlList = ("https://swgoh.gg/stats/mod-meta-report/all/","https://swgoh.gg/stats/mod-meta-report/guilds_100_gp/")
$VersionString = "SWGOH Mod-HAMMR Build 24-26 (c)2024 SuperSix/Schatten-Legion"

CheckPrerequisites

$AccountInfo = Import-Csv ".\CONFIG-Accounts.csv" -Delimiter ";"
$TeamList = Import-Csv ".\CONFIG-Teams.csv" -delimiter ";" 
$Need4SpeedList = Import-Csv ".\CONFIG-Need4Speed.csv" -delimiter ";"

$AccountInfo | Add-Member -Name "IsGACOpponent" -MemberType NoteProperty -Value $false

Write-Host "Loading support data" -ForegroundColor Green

$UnitsList = ((Invoke-WebRequest -Uri http://swgoh.gg/api/characters -ContentType "application/json" -Headers @{"Cache-Control"="no-cache"}).Content | ConvertFrom-Json)
$UnitsList | Select-Object Name,Base_id | Sort-Object Name | ConvertTo-Html -Head $header  | out-File ".\GAME-NameMapping.htm" -Encoding UTF8
$OmicronList = (Invoke-WebRequest -Uri http://swgoh.gg/api/abilities -Headers @{"Cache-Control"="no-cache"}).Content | ConvertFrom-Json | Where-Object {$_.is_omicron -eq $true} | Sort-Object character_base_id -Unique
$GalacticLegendsList = $UnitsList | Where-Object {$_.categories -contains "Galactic Legend"} |Sort-Object -Property Name

# Load and format mod meta data

$MetaListV2 = @{}


ForEach ($ModMetaUrl in $ModMetaUrlList)

{

    $RawMetaInfo = (Invoke-WebRequest $ModMetaUrl -Headers @{"Cache-Control"="no-cache"}).Content.Replace('&#34;','"').Replace("&#39;","'").Replace("&amp;","&")

    $RawMetaList = (($RawMetaInfo | ConvertFrom-HtmlTable))

    If ($ModMetaUrl -like "*guilds_100_gp*") { 
        
        $RawMetaList | Add-Member -Name "Mode" -MemberType NoteProperty -Value "Strict"
        $MetaCharList = $RawMetaList.Character
       
    } else {
        
        $RawMetaList | Add-Member -Name "Mode" -MemberType NoteProperty -Value "Relaxed"
    
    }

    ForEach ($RawMetaObject in $RawMetaList) {


        $SearchTarget = '"' + ($UnitsList | Where-Object {$_.name -like $RawMetaObject.Character}).base_id + '"'
        $SetMetaInfo = $RawMetaInfo.Substring($RawMetaInfo.IndexOf($SearchTarget))
        $SetMetaInfo = $SetMetaInfo.Substring(0,$SetMetaInfo.IndexOf("</div>`n</div></div>`n</div>"))

        $SetResults = @()
        
        $SetResults += ($SetMetaInfo | Select-String "Critical Damage").matches.Value
        $SetResults += ($SetMetaInfo | Select-String "Speed").matches.Value
        $SetResults += ($SetMetaInfo | Select-String "Offense").matches.Value

        $SetResults += ($SetMetaInfo | Select-String "Critical Chance" -AllMatches).matches.Value
        $SetResults += ($SetMetaInfo | Select-String "Defense" -AllMatches).matches.Value
        $SetResults += ($SetMetaInfo | Select-String "Health" -AllMatches).matches.Value
        $SetResults += ($SetMetaInfo | Select-String "Potency" -AllMatches).matches.Value
        $SetResults += ($SetMetaInfo | Select-String "Tenacity" -AllMatches).matches.Value
        
        $RawMetaObject.Sets = $SetResults

        $RawMetaObject.Receiver = $RawMetaObject.Receiver.Split(" / ") | Sort-Object
        $RawMetaObject.Multiplexer = $RawMetaObject.Multiplexer.Split(" / ") | Sort-Object
        $RawMetaObject."Holo-Array" = $RawMetaObject."Holo-Array".Split(" / ") | Sort-Object
        $RawMetaObject."Data-Bus" = $RawMetaObject."Data-Bus".Split(" / ") | Sort-Object
        $RawMetaObjectV2 = @{}
        $RawMetaObjectV2[$RawMetaObject.Mode] = $RawMetaObject | Select-Object -ExcludeProperty Character,Mode
        $MetaListV2[($RawMetaObject.Character)] += $RawMetaObjectV2 
        
    }

}

# Load custom mod configuration from JSON files

$CustomJSONFileList = (Get-Item ".\modsOptimizerTemplate-*.json").Name
$CustomMetaList = @()

if ($CustomJSONFileList -ne $null) {

    Write-Host "Loading Grandivory's Mods Optimizer Templates" -ForegroundColor Green

    ForEach ($CustomJSONFile in $CustomJSONFileList) {

        $CustomMetaList += (Get-Content (".\" + $CustomJSONFile) | ConvertFrom-Json).selectedCharacters

    }

    $CustomMetaList = $CustomMetaList # | Sort-Object -Property id -Unique

}

$ModTeamObj=[ordered]@{Name="";RawName="";"Power"=0;"Gear"="";"RawGear"="";"Speed"="";"RawSpeed"=0;"RawSpd+"=0;"RawEquippedModCount"=0;"MMScore"=0;"RawMMScore"="";"Mod-Sets"="";"Transmitter"="";"Receiver"="";"Processor"="";"Holo-Array"="";"Data-Bus"="";"Multiplexer"=""}
$GACOpponentObj=@{"AllyCode"="";"MetaMode"="";"IsGacOpponent"=$false;"GuildName"=""}
$GACOpponent = New-Object psobject -Property $GACOpponentObj

$MemberTeamList = @{}
$GuildTeamList = @{}
$MemberGalacticLegendList = @{}

$FullList = @()
$GuildStats = @()

ForEach ($Account in $AccountInfo) { 
    
    $GuildAllyCode = $Account.Allycode

    $GacBracketInfo = ((Invoke-WebRequest ("http://swgoh.gg/api/player/" + $GuildAllyCode + "/gac-bracket") -Headers @{"Cache-Control"="no-cache"} -SkipHttpErrorCheck -ErrorAction SilentlyContinue).Content | ConvertFrom-Json).data
    $PlayerInfo = ((Invoke-WebRequest ("http://swgoh.gg/api/player/" + $GuildAllyCode) -Headers @{"Cache-Control"="no-cache"} -SkipHttpErrorCheck -ErrorAction SilentlyContinue).Content | ConvertFrom-Json).data

    $Account |Add-Member -Name GuildID -Value $PlayerInfo.guild_id -MemberType NoteProperty
    $Account |Add-Member -Name PlayerName -Value $PlayerInfo.name -MemberType NoteProperty
    
    $FullList += $Account
    
    if ($GacBracketInfo -ne $null) {
    
        ForEach ($BracketPlayer in ($GACBracketInfo.bracket_players |Where-Object {$_.ally_code -notlike $GuildAllyCode -and $_.ally_code -ne $null})) {

            $IsPresent = (Get-ChildItem ".\GAC Opponents").name | Where-Object {$_ -like ($BracketPlayer.player_name + "*")} 

            if ($IsPresent -eq $null) { 

            $GACOpponent = New-Object psobject -Property $GACOpponentObj
            $GACOpponent.AllyCode = $BracketPlayer.ally_code
            $GACOpponent.MetaMode = $Account.MetaMode
            $GACOpponent.IsGacOpponent = $true
            $GACOpponent | Add-Member -Name PlayerName -Value $BracketPlayer.player_name -MemberType NoteProperty

            $FullList += $GACOpponent

            }

        }

    }

    If ($Account.GuildMode -like "true") {

        Write-Host "Loading guild data for",$PlayerInfo.guild_name -ForegroundColor Green

        $Dummy = New-Item -Path (".\" + $PlayerInfo.guild_name).Replace("?","_").Replace("<","_").Replace(">","_") -ItemType Directory -Erroraction silentlycontinue

        $GuildInfo = ((Invoke-WebRequest ("http://swgoh.gg/api/guild-profile/" + $Account.guildid) -Headers @{"Cache-Control"="no-cache"} -SkipHttpErrorCheck  -ErrorAction SilentlyContinue ).Content | ConvertFrom-Json).Data
        
        $GuildStats += $GuildInfo.members | Select-Object player_name,galactic_power | Sort-Object galactic_power -Descending

       ForEach ($GuildPlayer in ($GuildInfo.Members | Where-Object {$_.ally_code -ne $null} |  Sort-object player_name)) {

            $GACOpponent = New-Object psobject -Property $GACOpponentObj
            $GACOpponent.AllyCode = $GuildPlayer.ally_code
            $GACOpponent.MetaMode = $Account.MetaMode
            $GACOpponent.GuildName = $GuildInfo.name
            $GACOpponent |Add-Member -Name PlayerName -Value $GuildPlayer.player_name -MemberType NoteProperty

            $FullList += $GACOpponent

        }

    } 

}

$GuildStats | Add-Member -Name Member -MemberType NoteProperty -Value 0
$GuildStats | Add-Member -Name "Total GM" -MemberType NoteProperty -Value 0
$GuildStats | Add-Member -Name "Char GM" -MemberType NoteProperty -Value 0
$GuildStats | Add-Member -Name "Ship GM" -MemberType NoteProperty -Value 0
$GuildStats | Add-Member -Name "GLs" -MemberType NoteProperty -Value 0
$GuildStats | Add-Member -Name "MMScore" -MemberType NoteProperty -Value 0
$GuildStats | Add-Member -Name "Spd+" -MemberType NoteProperty -Value 0
$GuildStats | Add-Member -Name "MMSpd+" -MemberType NoteProperty -Value 0
$GuildStats | Add-Member -Name "GA Rank" -MemberType NoteProperty -Value 0

# Measure-Command {

# Start player analysis

ForEach ($Account in $FullList) {
    $GuildAllyCode = $Account.Allycode 
    if ($Account.Metamode -like "Strict") { 
        $ModMetaModeList = ("Strict") 
    } else {
        $ModMetaModeList = ("Strict","Relaxed")
    }

    # Load player data

    Write-Host "Loading player data for",$Account.PlayerName -foregroundcolor green -NoNewline

    If ($Account.IsGACOpponent) { Write-Host " GAC Opponent" -ForegroundColor Blue} else { Write-Host "",$Account.GuildName -ForegroundColor Blue}

    $RosterInfo = (Invoke-WebRequest ("http://swgoh.gg/api/player/" + $GuildAllyCode) -Headers @{"Cache-Control"="no-cache"} -ErrorAction SilentlyContinue).Content | ConvertFrom-Json

    $ModRoster=@()
    $MemberGalacticLegends=@()
    $ModList = $RosterInfo.mods | Where-Object {$_.level -eq 15 -and $_.Rarity -ge 5}
    $ModRosterInfo = $RosterInfo.Units.Data | Where-Object {($_.combat_type -eq 1) -and ($_.Level -ge 50) -and ($MetaCharList -contains $_.name)} 

    $ModTeam = New-Object PSObject -Property $ModTeamObj
    
    ForEach ($Char in $ModRosterInfo) {

        $ModTeam.Name = $Char.Name
        $ModTeam.RawSpeed = $Char.stats.5
        $ModTeam.Speed = "{0:0} ({1:0})" -f $Char.stats.5,$Char.stat_diffs.5 
        $ModTeam."RawSpd+" = $Char.stat_diffs.5
        $ModTeam.Power = $Char.power

        if ($Char.relic_tier -gt 2) {
            
            $ModTeam.Gear = "R{0:00}" -f ($Char.relic_tier -2)

        } else {

            $ModTeam.Gear = "G{0:00}" -f ($Char.gear_level)
            
            if (($Char.gear | Where-Object {$_.is_obtained -eq $true}).count -gt 0) {
                
                $ModTeam.Gear = $ModTeam.Gear + "+" + ($Char.gear | Where-Object {$_.is_obtained -eq $true}).count
            
            }

        }

        $ModTeam.RawGear = $ModTeam.Gear

        ForEach($ModMetaMode in $ModMetaModeList) {

            $MMScore = 0
            $EquippedModsets = $Char.mod_set_ids
            $EquippedMods = $ModList | Where-Object {$_.character -like $Char.base_id}
            $ModTeam.RawEquippedModCount = $EquippedMods.count
            $RequiredMods = $MetaListV2[$Char.Name][$ModMetaMode]

            if ($RequiredMods -ne $bull) {

                $RequiredModSets = $RequiredMods.Sets

                $ModTeam."Mod-Sets" = $RequiredModSets | Join-String -Separator " / "
                
                if (($RequiredModSets -contains "Offense" -and $EquippedModsets -contains 2) -or ($RequiredModSets -contains "Speed" -and $EquippedModsets -contains 4) -or ($RequiredModSets -contains "Critical Damage" -and $EquippedModsets -contains 6)) {$MMScore += 20}

                $MMScore += 10 * (($RequiredModSets | Where-Object {$_ -eq "Health"}).count,($EquippedModsets | Where-Object {$_ -eq 1}).Count | Measure-Object -Minimum).Minimum 
                $MMScore += 10 * (($RequiredModSets | Where-Object {$_ -eq "Defense"}).count,($EquippedModsets | Where-Object {$_ -eq 3}).Count | Measure-Object -Minimum).Minimum 
                $MMScore += 10 * (($RequiredModSets | Where-Object {$_ -eq "Critical Chance"}).count,($EquippedModsets | Where-Object {$_ -eq 5}).Count | Measure-Object -Minimum).Minimum 
                $MMScore += 10 * (($RequiredModSets | Where-Object {$_ -eq "Potency"}).count,($EquippedModsets | Where-Object {$_ -eq 7}).Count | Measure-Object -Minimum).Minimum 
                $MMScore += 10 * (($RequiredModSets | Where-Object {$_ -eq "Tenacity"}).count,($EquippedModsets | Where-Object {$_ -eq 8}).Count | Measure-Object -Minimum).Minimum 

                if ($MMScore -lt 30) {$ModTeam."Mod-Sets" = "RED" + $ModTeam."Mod-Sets"}
            
                ForEach ($Slot in (2..7)) {
                    
                    $SelectedMod = $EquippedMods | Where-Object {$_.Slot -eq $Slot}
                    $SlotName=$SlotNameList[$Slot]
        
                    switch ($Slot) {
                        
                        2 { $RequiredPrimaries = "Offense" }
                        3 { $RequiredPrimaries = $RequiredMods."Receiver" }
                        4 { $RequiredPrimaries = "Defense" }
                        5 { $RequiredPrimaries = $RequiredMods."Holo-Array" }
                        6 { $RequiredPrimaries = $RequiredMods."Data-Bus" }
                        7 { $RequiredPrimaries = $RequiredMods."Multiplexer" }
            
                    }

                    if (($RequiredPrimaries -contains $SelectedMod.primary_stat.name) -and ($RequiredModSets -contains $ModSetLong[$SelectedMod.set])) {

                        $MMScore += 5 # Mod primary matches meta

                        if (($SelectedMod.primary_stat.stat_id -eq 5) -or ($SelectedMod.secondary_stats.stat_id -contains 5) -or ($Need4SpeedList.MemberDefId -contains $Char.base_id )) { 
                            
                            $MMScore += 5 # Mod has speed on it or is excluded via Need4Speed list

                            if ($SelectedMod.primary_stat.stat_id -eq 5) {
                            
                                $ModSpeed = ("{0:00}" -f [int]$SelectedMod.primary_stat.display_value)
                            
                            } elseif ($SelectedMod.secondary_stats.stat_id -contains 5) {
                                
                                $ModSpeed = ("{0:00} " -f [int]($SelectedMod.secondary_stats | Where-Object {$_.Stat_id -eq 5}).display_value) + " (" + ($SelectedMod.secondary_stats | Where-Object {$_.Stat_id -eq 5}).roll + ")"
                                
                            } else {

                                $ModSpeed = "00"

                            }

                            $ModTeam.($Slotname) = [string]($ModSpeed + " - " + $ModSetShort[$SelectedMod.set] + " - " +  $SelectedMod.primary_stat.name.Replace("Critical","Crit."))

                            $ModTeam.($Slotname) += ("+" * ($SelectedMod.secondary_stats.name | Where-Object {$_ -like $SelectedMod.primary_stat.name}).count )
                            $ModTeam.($Slotname) += ("*" * ($SelectedMod.secondary_stats.name | Where-Object {$RequiredModSets -contains $_ -and $_ -notlike "Speed"}).count )


                            if ($SelectedMod.rarity -gt 5) {$ModTeam.($Slotname) = "BOLD" + $ModTeam.($Slotname)}
                                            
                        } else {$ModTeam.($Slotname) = "REDITALICON" + ($RequiredPrimaries | Join-String  -Separator (" / ")).Replace("Critical","Crit.")} 
                    } else {$ModTeam.($Slotname) = "REDITALICON" + ($RequiredPrimaries | Join-String  -Separator (" / ")).Replace("Critical","Crit.")}

                }
                
                $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Tenacity / Tenacity / Tenacity","Tenacity (x3)").Replace("Tenacity / Tenacity","Tenacity (x2)").Replace("Health / Health / Health","Health (x3)").Replace("Health / Health","Health (x2)").Replace("Defense / Defense / Defense","Defense (x3)")
                $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Defense / Defense","Defense (x2)").Replace("Potency / Potency / Potency","Potency (x3)").Replace("Potency / Potency","Potency (x2)")
                $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Critical Chance / Critical Chance / Critical Chance","Crit. Chance (x3)").Replace("Critical Chance / Critical Chance","Crit. Chance (x2)").Replace("Critical","Crit.")
                
                if ($MMScore -eq 90) {
                
                    $MMScore = 100 + ($EquippedMods | Where-Object {$_.rarity -gt 5}).count * 5

                        if ($MMScore -eq 130 -and ($EquippedMods | Where-Object {$_.rarity -gt 5 -and $_.tier -eq 5}).count -eq 6) {$MMScore = 150}

                } 

                $ModTeam.MMScore = $MMScore

                if ($ModMetaMode -like "Strict") { 
                    
                    $FinalModTeam = ($ModTeam).psobject.copy()
                    $FinalMMScore = $MMScore

                } elseif ($ModMetaMode -like "Relaxed" -and $ModTeam.MMScore -gt $FinalModTeam.MMScore) {

                    $ModTeam.MMScore = [string]$ModTeam.MMScore + " (A)"
                    $FinalModTeam = ($ModTeam).psobject.copy()
                    $FinalMMScore = $MMScore                    
                    
                } elseif ($ModMetaMode -like "Custom" -and $ModTeam.MMScore -gt $FinalModTeam.MMScore) {

                    $ModTeam.MMScore = [string]$ModTeam.MMScore + " (C)"
                    $FinalModTeam = ($ModTeam).psobject.copy()
                    $FinalMMScore = $MMScore

                }

            }

        }

        $FinalModTeam.RawMMScore = $FinalMMScore
        if ($FinalMMscore -ge 130) {$FinalModTeam.MMScore = "BOLD" + $FinalModTeam.MMScore}

        $ModRoster = $ModRoster + $FinalModTeam

        if ($GalacticLegendsList.name -contains $FinalModTeam.name -and $Account.GuildName -ne $null -and $Account.IsGacOpponent -ne $true) {

            $MemberGalacticLegends += $FinalModTeam

        }

    } # ForEach

    $ModRoster = $ModRoster | Sort-Object @{Expression="Power"; Descending=$true}

    $MemberGalacticLegendList.($Account.PlayerName)+= $MemberGalacticLegends

    If ($Account.IsGacOpponent -eq $true -and $AccountInfo.AllyCode -notcontains $Account.AllyCode) { $OutputSubdir = ".\GAC Opponents\" } else { 
        
        if ($Account.GuildName -ne $null) {$OutputSubdir = ".\" + $Account.GuildName.Replace("?","_").Replace("<","_").Replace(">","_") + "\Member-"} else {$OutputSubdir = ".\"}

    }    

    if ($Account.GuildName -ne $null -and $Account.IsGacOpponent -ne $true) {

        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)]."Member" = $RosterInfo.data.Name
        
        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)]."Total GM" = '{0:N0}' -f $RosterInfo.data.galactic_power
        
        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)]."Char GM" = '{0:N0}' -f $RosterInfo.data.character_galactic_power
        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)]."Ship GM" = '{0:N0}' -f $RosterInfo.data.ship_galactic_power
        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)].GLs = ($RosterInfo.units.data | Where-Object {$_.is_galactic_legend -eq $true}).Count
        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)].MMSCore = [int](($ModRoster |Where-Object {$_.RawEquippedModCount -gt 0}).RawMMScore |Measure-Object -Average).Average
        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)]."Spd+" = [int](($ModRoster |Where-Object {$_.RawEquippedModCount -gt 0})."RawSpd+" |Measure-Object -Average).Average

        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)]."MMSpd+" = [int](((($ModRoster |Where-Object {$_.RawEquippedModCount -gt 0})."RawSpd+" |Measure-Object -Average).Average + (($ModRoster |Where-Object {$_.RawEquippedModCount -gt 0}).RawMMScore |Measure-Object -Average).Average) / 2)
        $GuildStats[$GuildStats.player_name.indexof($Rosterinfo.data.name)]."GA Rank" = $RosterInfo.data.league_name + " " + $RosterInfo.data.division_number
    }

    ($ModRoster | Select-Object -ExcludeProperty Raw* | ConvertTo-Html -PreContent ("<H1> <Center>" + $Rosterinfo.data.name + "</H1>") -Head $header ).Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALICON","<i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)").Replace("BREAK","</br>") | Out-File ($OutputSubdir + $RosterInfo.data.Name + "-Chars.htm" ) -Encoding unicode -ErrorAction SilentlyContinue

    # Generating team statistics for all teams defined in CONFIG-Teams.csv

    $SquadOutput = $null
    $SquadOutput3v3 = $null

    If (($AccountInfo.allycode -contains $Account.AllyCode) -or ($Account.IsGACOpponent -eq $true)) {$IndividualTeamList = $TeamList} else { $IndividualTeamList = $TeamList | Where-Object {$_.IsGuildTeam -like "true"}}

    ForEach ($TeamData in $IndividualTeamList){

        $TeamName=$TeamData.TeamName
        $MemberDefId=$TeamData.MemberDefId.Split(",")

        $Squad = @()

        ForEach ($TeamMember in $MemberDefId) {

            $UnitInfo = $UnitsList | Where-Object {$_.base_id -eq $TeamMember}
            $MemberDisplayName = ($UnitsList | Where-Object {$_.base_id -eq $TeamMember}).Name

            $SquadMember = ($ModRoster | Where-Object {$_.name -like $MemberDisplayName}).PSObject.copy()

            if ($SquadMember.name -ne $null) {

                $SquadMember.RawName =$SquadMember.Name

                $SquadMemberInfo = $ModRosterInfo | Where-Object {$_.name -like $MemberDisplayName}

                if ($SquadMember.gear -ge "G12") { $SquadMember.Name = "BOLD" + $SquadMember.Name }
                
                if ($SquadMember.gear -ge "G13") {
                        
                        if ($UnitInfo.alignment -eq "Neutral") { $SquadMember.Name = "BGYELLOW" + $SquadMember.Name}
                        if ($UnitInfo.alignment -eq "Light Side") { $SquadMember.Name = "BGBLUE" + $SquadMember.Name}
                        if ($UnitInfo.alignment -eq "Dark Side") { $SquadMember.Name = "BGRED" + $SquadMember.Name}
                    
                } else {

                    if ($UnitInfo.alignment -eq "Neutral") { $SquadMember.Name = "YELLOW" + $SquadMember.Name}
                    if ($UnitInfo.alignment -eq "Light Side") { $SquadMember.Name = "BLUE" + $SquadMember.Name}
                    if ($UnitInfo.alignment -eq "Dark Side") { $SquadMember.Name = "RED" + $SquadMember.Name}
                }

                if ($SquadMemberInfo.ability_data -ne $null) {

                    if ($SquadMemberInfo.base_id -like $MemberDefId[0]) { 

                        $Zetas = $SquadMemberInfo.ability_data | Where-Object {$_.is_zeta -eq $true}
                        $Omicrons = $SquadMemberInfo.ability_data | Where-Object {$_.is_omicron -eq $true}

                    } else {

                        $Zetas = $SquadMemberInfo.ability_data | Where-Object {$_.is_zeta -eq $true -and $_.id -notlike "leaderskill*"}    
                        $Omicrons = $SquadMemberInfo.ability_data | Where-Object {$_.is_omicron -eq $true -and $_.id -notlike "leaderskill*"}    

                    }
                
                    $AppliedZetas = $Zetas | Where-Object {$_.has_zeta_learned -eq $true}
                    $AppliedOmicrons = $Omicrons | Where-Object {$_.has_omicron_learned -eq $true}

                    If (($Zetas.count -eq $AppliedZetas.count) -and ($Zetas -ne $null)) { $SquadMember.Gear = "z" + $SquadMember.Gear }

                    if ($AppliedOmicrons -ne $null) {

                        If ($Omicrons.count -eq $AppliedOmicrons.count) { 
                            
                            $SquadMember.Gear = "o" + $SquadMember.Gear
                            
                            $SquadMember.Name += (" (" + $OmicronModeList[($OmicronList | Where-Object {$_.character_base_id -like $TeamMember }).omicron_mode]  + ")")
                            $TeamName += (" (" + $OmicronModeList[($OmicronList | Where-Object {$_.character_base_id -like $TeamMember }).omicron_mode]  + ")")

                        } else {

                            $SquadMember.Name += (" (ITALICON" + $OmicronModeList[($OmicronList | Where-Object {$_.character_base_id -like $TeamMember }).omicron_mode]  + "ITALICOFF)")
                            $TeamName += (" (ITALICON" + $OmicronModeList[($OmicronList | Where-Object {$_.character_base_id -like $TeamMember }).omicron_mode]  + "ITALICOFF)")

                        }
                        
                    }
                    
                }

                If ($SquadMemberInfo.has_ultimate -eq $true) { $SquadMember.Gear = "u" + $SquadMember.Gear }

                $Squad += $SquadMember

            }
            
        }

        if ($TeamData.Is3v3 -like "true") {

            $SquadOutPut3v3 += ($Squad | Select-Object -ExcludeProperty Raw*) | ConvertTo-Html -Head $header  -PreContent ("<H1><Center>" + ($TeamName.Replace(") (",","))  + " ({0:0}k)" -f (($Squad.power | Measure-Object -Sum ).sum /1000)+ " (" + (($Squad.RawGear | Measure-Object -Minimum ).minimum) + ") </H1>")

        } else {

            if ($TeamData.IsGuildTeam -like "true") {$MemberTeamList[($TeamData.TeamName)] = ($Squad.psobject.Copy())}

            $SquadOutPut += ($Squad | Select-Object -ExcludeProperty Raw*) | ConvertTo-Html -Head $header  -PreContent ("<H1><Center>" + ($TeamName.Replace(") (",","))  + " ({0:0}k)" -f (($Squad.power | Measure-Object -Sum ).sum /1000) + " (" + (($Squad.RawGear | Measure-Object -Minimum ).minimum) + ") </H1>")
        
        }
    }

    $SquadOutput.Replace("<td>BGYELLOW","<td style='background-color:yellow'>").Replace("<td>BGRED","<td style='background-color:lightcoral'>").Replace("<td>BGBLUE","<td style='background-color:skyblue'>").Replace("<td>YELLOW","<td style='color:orange'>").Replace("<td>BLUE","<td style='color:blue'>").Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALICON","<i>").Replace("ITALICOFF","</i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)") | Out-File ($OutputSubdir + $RosterInfo.data.Name + "-Teams.htm" ) -Encoding unicode -ErrorAction SilentlyContinue

    If ($SquadOutput3v3 -ne $null) {

        $SquadOutput3v3.Replace("<td>BGYELLOW","<td style='background-color:yellow'>").Replace("<td>BGRED","<td style='background-color:lightcoral'>").Replace("<td>BGBLUE","<td style='background-color:skyblue'>").Replace("<td>YELLOW","<td style='color:orange'>").Replace("<td>BLUE","<td style='color:blue'>").Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALICON","<i>").Replace("ITALICOFF","</i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)") | Out-File ($OutputSubdir + $RosterInfo.data.Name + "-Teams-3v3.htm" ) -Encoding unicode -ErrorAction SilentlyContinue
  
    } 

    $GuildTeamList[($RosterInfo.data.name)] = $MemberTeamList.psobject.Copy() # only if not gac opponent
    
}   

# } # Measure-Command

# Output guild summary and guild teams

if ($GuildTeamList -ne $null) {

    $DatePrefix = Get-Date -Format "yy-MM-"

    $TeamStatList = $TeamList | Where-Object {$_.IsGuildTeam -like "true"}

    $GuildList = $FullList.GuildName | Where-Object {$_ -ne ""} | Sort-Object -Unique

    ForEach ($Guild in $GuildList) {

        $FileSystemGuild = $Guild.Replace("?","_").Replace("<","_").Replace(">","_")

        Write-Host "Building team statistics for",$Guild -ForegroundColor Green

        $GuildMemberList = ($FullList |Where-Object {$_.GuildName -eq $Guild}).PlayerName

        $GuildInfo = $GuildStats | Where-Object {$GuildMemberList -contains $_.player_name} 

        $GuildInfo | Select-Object -ExcludeProperty "*_*"  | ConvertTo-Html -Head $header  -PreContent ("<H1><Center>" + $Guild + "</H1>") | Out-File (".\" + $FileSystemGuild + "\Guild-Members.htm") -Encoding unicode 

        $Dummy = Get-Item (".\" + $FileSystemGuild + "\History\" + $DatePrefix + "Guild-Members.htm") -ErrorAction SilentlyContinue

        if ($Dummy -eq $null) {

            $Dummy = New-Item -Path (".\" + $FileSystemGuild + "\History") -ItemType Directory -Erroraction silentlycontinue

            $GuildInfo | Select-Object -ExcludeProperty "*_*"  | ConvertTo-Html -Head $header  -PreContent ("<H1><Center>" + $Guild + "</H1>") | Out-File (".\" + $FileSystemGuild + "\History\" + $DatePRefix + "Guild-Members.htm") -Encoding unicode 


        }


        $GLHTMLOutput = $null

        ForEach ($GalacticLegend in $GalacticLegendsList.name) {

            $GalacticLegendSummaryList = @()

            ForEach ($GuildMember in $GuildMemberList) {

                $GLEntry = ($MemberGalacticLegendList.$GuildMember | Where-Object {$_.Name -eq $GalacticLegend}).psobject.copy() | Select-Object -ExcludeProperty raw*

                if ($GLEntry.Name -eq $GalacticLegend) {
                    $GLEntry.Name = $GuildMember

                    $GalacticLegendSummaryList += $GLEntry
                }
                
                

            }

            $GLHTMLOutput += $GalacticLegendSummaryList | Sort-Object -Property Gear,Power -Descending| ConvertTo-Html -Head $header   -PreContent ("<H1><Center>" + $GalacticLegend + "</H1>")
          

        }

        $GLHTMLOutput.Replace("<td>BGYELLOW","<td style='background-color:yellow'>").Replace("<td>BGRED","<td style='background-color:lightcoral'>").Replace("<td>BGBLUE","<td style='background-color:skyblue'>").Replace("<td>YELLOW","<td style='color:orange'>").Replace("<td>BLUE","<td style='color:blue'>").Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALICON","<i>").Replace("ITALICOFF","</i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)")  | out-file (".\" + $FileSystemGuild + "\Guild-GalacticLegends.htm") -Encoding unicode

        $Dummy = Get-Item (".\" + $FileSystemGuild + "\History\" + $DatePrefix + "Guild-GalacticLegends.htm") -ErrorAction SilentlyContinue

        if ($Dummy -eq $null) {

            $Dummy = New-Item -Path (".\" + $FileSystemGuild + "\History") -ItemType Directory -Erroraction silentlycontinue

            $GLHTMLOutput.Replace("<td>BGYELLOW","<td style='background-color:yellow'>").Replace("<td>BGRED","<td style='background-color:lightcoral'>").Replace("<td>BGBLUE","<td style='background-color:skyblue'>").Replace("<td>YELLOW","<td style='color:orange'>").Replace("<td>BLUE","<td style='color:blue'>").Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALICON","<i>").Replace("ITALICOFF","</i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)")  | out-file (".\" + $FileSystemGuild +  "\History\" + $DatePRefix + "Guild-GalacticLegends.htm") -Encoding unicode

        }         



        ForEach ($Team in $TeamStatList) {

            $TeamSummaryObj=[ordered]@{Name="";"Gear"=0;"Power"=0;"Speed"=0;"MMScore"=0;"RawPower"=0}
            $TeamNameList = @()

            ForEach ($DefId in ($Team.MemberDefId.Split(","))) {

                $TeamSummaryObj.add(($UnitsList | Where-Object {$_.base_id -like $DefId}  ).name,0)
                $TeamNameList += ($UnitsList | Where-Object {$_.base_id -like $DefId}).name

            } 

            $TeamSummary = @()
            $TeamHtml = $null

            ForEach ($GuildMember in $GuildMemberList) {

                $TeamStatsUser = New-Object psobject -Property $TeamSummaryObj
                $TeamStatsUser.Name = $GuildMember

                ForEach ($TeamMember in $TeamNameList) {

                    if((($GuildTeamList[$GuildMember][$Team.TeamName]) |Where-Object {$_.RawName -eq $TeamMember}) -ne $null ) {

                        $TeamStatsUser.($TeamMember) = (($GuildTeamList[$GuildMember][$Team.TeamName]) |Where-Object {$_.RawName -eq $TeamMember}).Gear + " | " + (($GuildTeamList[$GuildMember][$Team.TeamName]) |Where-Object {$_.RawName -eq $TeamMember}).Speed  + " | " + (($GuildTeamList[$GuildMember][$Team.TeamName]) |Where-Object {$_.RawName -eq $TeamMember}).RawMMScore
                    
                    } else {

                        $TeamStatsUser.($TeamMember) = "---"

                    }

                }

                $TeamStatsUser."Power" =  '{0:N0}' -f (($GuildTeamList[$GuildMember][$Team.TeamName]).Power | Measure-Object -Sum).Sum
                $TeamStatsUser."RawPower" =  (($GuildTeamList[$GuildMember][$Team.TeamName]).Power | Measure-Object -Sum).Sum
                
                    if ((($GuildTeamList[$GuildMember][$Team.TeamName]).RawGear | Measure-Object -Minimum).count -eq $TeamNameList.count ) {

                        $TeamStatsUser."Gear" =  (($GuildTeamList[$GuildMember][$Team.TeamName]).RawGear | Measure-Object -Minimum).Minimum

                    } else {

                        $TeamStatsUser."Gear" =  "---"

                    }
                
                $TeamStatsUser."Speed" =  [int](($GuildTeamList[$GuildMember][$Team.TeamName]).RawSpeed | Measure-Object -Average).Average
                $TeamStatsUser."MMScore" =  [int](($GuildTeamList[$GuildMember][$Team.TeamName]).RawMMScore | Measure-Object -Average).Average

                if ($TeamStatsUser.Power -gt 0) { 
                    
                    $TeamSummary += $TeamStatsUser
                    $TeamHtml += $GuildTeamList[$GuildMember][$Team.TeamName] | Select-Object -ExcludeProperty raw* | ConvertTo-Html -PreContent ("<H1><Center>" + ($GuildMember) + "</H1>") -Title ($Team.TeamName)

                }

            }

            $TeamSummary = $TeamSummary |Sort-Object -Property Gear,RawPower -Descending

            $TeamHtml = ($TeamSummary | Select-Object -ExcludeProperty raw* | ConvertTo-Html -Title ($Team.TeamName) -Head $header  -PreContent ("<H1><Center>" + $Team.TeamName + "</H1>")) + $TeamHtml

            $TeamHtml.Replace("<td>BGYELLOW","<td style='background-color:yellow'>").Replace("<td>BGRED","<td style='background-color:lightcoral'>").Replace("<td>BGBLUE","<td style='background-color:skyblue'>").Replace("<td>YELLOW","<td style='color:orange'>").Replace("<td>BLUE","<td style='color:blue'>").Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALICON","<i>").Replace("ITALICOFF","</i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)") | Out-File (".\" + $FileSystemGuild + "\TEAM-" + $team.teamname + ".htm")  -Encoding unicode -ErrorAction SilentlyContinue

            $Dummy = Get-Item (".\" + $FileSystemGuild + "\History\" + $DatePrefix + "TEAM-" + $team.teamname + ".htm") -ErrorAction SilentlyContinue

            if ($Dummy -eq $null) {

                $Dummy = New-Item -Path (".\" + $FileSystemGuild + "\History") -ItemType Directory -Erroraction silentlycontinue

                $TeamHtml.Replace("<td>BGYELLOW","<td style='background-color:yellow'>").Replace("<td>BGRED","<td style='background-color:lightcoral'>").Replace("<td>BGBLUE","<td style='background-color:skyblue'>").Replace("<td>YELLOW","<td style='color:orange'>").Replace("<td>BLUE","<td style='color:blue'>").Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALICON","<i>").Replace("ITALICOFF","</i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)") | Out-File (".\" + $FileSystemGuild + "\History\" + $DatePrefix + "TEAM-" + $team.teamname + ".htm")  -Encoding unicode -ErrorAction SilentlyContinue


            }

        }

    }

}

