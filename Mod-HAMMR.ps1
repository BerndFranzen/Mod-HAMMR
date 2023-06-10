<#

    SWGOH Mod-HAMMR Build 23-23a (c)2023 SuperSix/Schattenlegion

#>

$ModSetShort = ("","HE","OF","DE","SP","CC","CD","PO","TE")
$ModSetLong = ("","Health","Offense","Defense","Speed","Critical Chance","Critical Damage","Potency","Tenacity") 

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
    Write-Host "SWGOH Mod-HAMMR Build 23-23a (c)2023 SuperSix/Schatten-Legion" -ForegroundColor Green
    Write-Host

    # Check if all prerequisites are met

    if ($PSVersionTable.PSVersion.ToString() -lt "6.2.0") {Write-Host "ERROR - This script requires Powershell 6.0.0 or higher" -ForegroundColor Red; Break}
    if ((get-Item .\CONFIG-Accounts.csv -ErrorAction SilentlyContinue) -eq $null) {Write-Host "ERROR - Config file CONFIG-Accounts.csv missing"-ForegroundColor Red; Break}
    if ((get-Item .\CONFIG-Teams.csv -ErrorAction SilentlyContinue) -eq $null) {Write-Host "WARNING - Config file CONFIG-Teams.csv missing"-ForegroundColor Yellow; Break}
    # if ((get-Item .\CONFIG-Fleets.csv -ErrorAction SilentlyContinue) -eq $null) {Write-Host "WARNING - Config file CONFIG-Fleets.csv missing"-ForegroundColor Yellow; Break}
    if ((Invoke-WebRequest -uri http://api.swgoh.gg).StatusCode -ne 200) {Write-Host "ERROR - Cannot connect to api.swgoh.gg" -ForegroundColor Red; Break}
    $ParseModule = Get-Module PSParseHTML -ListAvailable -ErrorAction SilentlyContinue
    If ($ParseModule -eq $null) { Install-Module -Name PSParseHTML -AllowClobber -Force }

}

# MAIN

CheckPrerequisites

$AccountInfo = Import-Csv ".\CONFIG-Accounts.csv" -Delimiter ";"
$TeamList = Import-Csv ".\CONFIG-Teams.csv" -delimiter ";" 
# $FleetList = Import-Csv ".\CONFIG-Fleets.csv" -delimiter ";" | Sort-Object FleetName

Write-Host "Loading support data" -ForegroundColor Green

$UnitsList = ((Invoke-WebRequest -Uri http://api.swgoh.gg/units -ContentType "application/json" ).Content | ConvertFrom-Json).data
$UnitsList | Select-Object Name,Base_id | Sort-Object Name | ConvertTo-Html -Head $header | out-File ".\GAME-NameMapping.htm" -Encoding UTF8

# Load and format mod meta data

$RawMetaInfo = (Invoke-WebRequest https://swgoh.gg/stats/mod-meta-report/guilds_100_gp/).Content 

$RawMetaInfo = $RawMetaInfo.Replace('<div class="collection-char-set collection-char-set1 collection-char-set-max" data-toggle="tooltip" data-title="','')
$RawMetaInfo = $RawMetaInfo.Replace('<div class="collection-char-set collection-char-set2 collection-char-set-max" data-toggle="tooltip" data-title="','')
$RawMetaInfo = $RawMetaInfo.Replace('<div class="collection-char-set collection-char-set3 collection-char-set-max" data-toggle="tooltip" data-title="','')
$RawMetaInfo = $RawMetaInfo.Replace('<div class="collection-char-set collection-char-set4 collection-char-set-max" data-toggle="tooltip" data-title="','')
$RawMetaInfo = $RawMetaInfo.Replace('<div class="collection-char-set collection-char-set5 collection-char-set-max" data-toggle="tooltip" data-title="','')
$RawMetaInfo = $RawMetaInfo.Replace('<div class="collection-char-set collection-char-set6 collection-char-set-max" data-toggle="tooltip" data-title="','')
$RawMetaInfo = $RawMetaInfo.Replace('<div class="collection-char-set collection-char-set7 collection-char-set-max" data-toggle="tooltip" data-title="','')
$RawMetaInfo = $RawMetaInfo.Replace('<div class="collection-char-set collection-char-set8 collection-char-set-max" data-toggle="tooltip" data-title="','')
$RawMetaInfo = $RawMetaInfo.Replace("Crit Chance","Critical-Chance")
$RawMetaInfo = $RawMetaInfo.Replace("Critical Chance","Critical-Chance")
$RawMetaInfo = $RawMetaInfo.Replace("Crit Damage","Critical-Damage")
$RawMetaInfo = $RawMetaInfo.Replace("Critical Damage","Critical-Damage")
$RawMetaInfo = $RawMetaInfo.Replace("&#x27;","'")
$RawMetaInfo = $RawMetaInfo.Replace("&quot;",'"')
$RawMetaInfo = $RawMetaInfo.Replace('" data-container="body"></div>','')

$RawMetaList = $RawMetaInfo | ConvertFrom-HtmlTable 

$ModTeamObj=[ordered]@{Name="";"Power"=0;"Gear"="";"Speed"="";"MMScore"=0;"Mod-Sets"="";"Transmitter"="";"Receiver"="";"Processor"="";"Holo-Array"="";"Data-Bus"="";"Multiplexer"=""}

# Start guild analysis

ForEach ($Account in $AccountInfo) {

    $GuildAllyCode = $Account.Allycode 

    # Load guild data, including list of all guild member's allycodes

    Write-Host "Loading player data for allycode",$GuildAllyCode -foregroundcolor green

    $RosterInfo = (Invoke-WebRequest ("http://api.swgoh.gg/player/" + $GuildAllyCode) -ErrorAction SilentlyContinue).Content | ConvertFrom-Json
    
    $ModRoster=@()
    $ModList = $RosterInfo.mods | Where-Object {$_.level -eq 15 -and $_.Rarity -ge 5}
    $ModRosterInfo = $RosterInfo.Units.Data | Where-Object {$_.combat_type -eq 1 -and $_.Level -ge 50}

    ForEach ($Char in $ModRosterInfo) {

        $ModTeam = New-Object PSObject -Property $ModTeamObj
        $ModTeam.Name = $Char.Name
        $ModTeam.Speed = "{0:0}" -f $Char.stats.5
        $ModTeam.Power = $Char.power

        if ($Char.relic_tier -gt 2) {
            
            $ModTeam.Gear = "R{0:00}" -f ($Char.relic_tier -2)

        } else {

            $ModTeam.Gear = "G{0:00}" -f ($Char.gear_level)
            
            if (($Char.gear | Where-Object {$_.is_obtained -eq $true}).count -gt 0) {
                
                $ModTeam.Gear = $ModTeam.Gear + "+" + ($Char.gear | Where-Object {$_.is_obtained -eq $true}).count
            
            }

        }
        
        $MMScore = 0
        $EquippedModsets = $Char.mod_set_ids
        $EquippedMods = $ModList | Where-Object {$_.character -like $Char.base_id}
        $RequiredMods = ($RawMetaList | Where-Object {$_.Character -eq ($Char.name)})
        $RequiredModSets = $RequiredMods.Sets.Split().Replace("-"," ").trim() | Sort-Object

        if ($RequiredModSets -contains "Offense" -and $EquippedModsets -contains 2) {$MMScore += 20}
        if ($RequiredModSets -contains "Speed" -and $EquippedModsets -contains 4) {$MMScore += 20}
        if ($RequiredModSets -contains "Critical Damage" -and $EquippedModsets -contains 6) {$MMScore += 20}
        if ($RequiredModSets -contains "Health" -and $EquippedModsets -contains 1) { $MMScore += 10 * (($RequiredModSets | Where-Object {$_ -like "Health"}).count,($EquippedModsets | Where-Object {$_ -eq 1}).Count | Measure-Object -Minimum).Minimum }
        if ($RequiredModSets -contains "Defense" -and $EquippedModsets -contains 3) { $MMScore += 10 * (($RequiredModSets | Where-Object {$_ -like "Defense"}).count,($EquippedModsets | Where-Object {$_ -eq 3}).Count | Measure-Object -Minimum).Minimum }
        if ($RequiredModSets -contains "Critical Chance" -and $EquippedModsets -contains 5) {$MMScore += 10 * (($RequiredModSets | Where-Object {$_ -like "Critical Chance"}).count,($EquippedModsets | Where-Object {$_ -eq 5}).Count | Measure-Object -Minimum).Minimum }
        if ($RequiredModSets -contains "Potency" -and $EquippedModsets -contains 7) {$MMScore += 10 * (($RequiredModSets | Where-Object {$_ -like "Potency"}).count,($EquippedModsets | Where-Object {$_ -eq 7}).Count | Measure-Object -Minimum).Minimum }
        if ($RequiredModSets -contains "Tenacity" -and $EquippedModsets -contains 8) { $MMScore += 10 * (($RequiredModSets | Where-Object {$_ -like "Tenacity"}).count,($EquippedModsets | Where-Object {$_ -eq 8}).Count | Measure-Object -Minimum).Minimum }
        
        if ($MMScore -lt 30) {$ModTeam."Mod-Sets" = "REDITALIC" + $ModTeam."Mod-Sets"}

        ForEach ($Slot in (1,2,3,4,5,6)) {

            $SelectedMod = $EquippedMods | Where-Object {$_.slot -eq $Slot}

            switch ($Slot) {
                
                1 { $RequiredPrimaries = "Offense"; $SlotName = "Transmitter" }
                2 { $RequiredPrimaries = ($RequiredMods."Receiver").Split(" / "); $SlotName = "Receiver"  }
                3 { $RequiredPrimaries = "Defense"; $SlotName = "Processor" }
                4 { $RequiredPrimaries = ($RequiredMods."Holo-Array").Split(" / "); $SlotName = "Holo-Array" }
                5 { $RequiredPrimaries = ($RequiredMods."Data-Bus").Split(" / "); $SlotName = "Data-Bus"  }
                6 { $RequiredPrimaries = ($RequiredMods."Multiplexer").Split(" / "); $SlotName = "Multiplexer" }

                Default {}
            }

            $RequiredPrimaries = $RequiredPrimaries.Replace("-"," ")

            if (($RequiredPrimaries -contains $SelectedMod.primary_stat.name) -and ($RequiredModSets -contains $ModSetLong[$SelectedMod.set])) {

                $MMScore += 5

                if ($SelectedMod.primary_stat.stat_id -eq 5 -or $SelectedMod.secondary_stats.stat_id -contains 5) { 
                    
                    $MMScore += 5

                    if ($SelectedMod.primary_stat.stat_id -eq 5) {
                    
                        $ModSpeed = ("{0:00}" -f [int]$SelectedMod.primary_stat.display_value)
                        $ModRoll = ""

                    } else {
                        
                        $ModSpeed = ("{0:00}" -f [int]($SelectedMod.secondary_stats | Where-Object {$_.Stat_id -eq 5}).display_value) 
                        $ModRoll = " (" + ($SelectedMod.secondary_stats | Where-Object {$_.Stat_id -eq 5}).roll + ") "
                        
                    }

                    $ModTeam.($SlotName) = $ModSpeed + $ModRoll + " - " + $ModSetShort[$SelectedMod.set] + " - " +  $SelectedMod.primary_stat.name.Replace("Critical","Crit.")
                                                        
                    if ($SelectedMod.rarity -gt 5) {$ModTeam.($SlotName) = "BOLD" + $ModTeam.($SlotName)}
                                    
                } else {$ModTeam.($SlotName) = "REDITALIC" + ($RequiredPrimaries | Join-String  -Separator (" / ")).Replace("Critical","Crit.").trim(" / ")} 
            } else {$ModTeam.($SlotName) = "REDITALIC" + ($RequiredPrimaries | Join-String  -Separator (" / ")).Replace("Critical","Crit.").trim(" / ")}
    

        }
        
        ForEach ($ModSet in $RequiredModSets) {

            $ModTeam."Mod-Sets" += $ModSet  + " / "

        }

        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".trim(" / ").Replace("/ /","/").trim(" / ").trim("/").trim(" /")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Tenacity / Tenacity / Tenacity","Tenacity (x3)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Tenacity / Tenacity","Tenacity (x2)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Health / Health / Health","Health (x3)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Health / Health","Health (x2)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Defense / Defense / Defense","Defense (x3)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Defense / Defense","Defense (x2)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Potency / Potency / Potency","Potency (x3)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Potency / Potency","Potency (x2)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Critical Chance / Critical Chance / Critical Chance","Critical Chance (x3)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Critical Chance / Critical Chance","Critical Chance (x2)")
        $ModTeam."Mod-Sets" = $ModTeam."Mod-Sets".Replace("Critical","Crit.")
        
        if ($MMScore -eq 90) {
        
            $MMScore = 100 + ($EquippedMods | Where-Object {$_.rarity -gt 5}).count * 5

                if ($MMScore -eq 130 -and ($EquippedMods | Where-Object {$_.rarity -gt 5 -and $_.tier -eq 5}).count -eq 6) {$MMScore = 150}
                if ($MMscore -ge 130) {$MMScore = "BOLD" + $MMScore}
        
        } else {
         
        }

        $ModTeam.MMScore = $MMScore
        $ModRoster = $ModRoster + $ModTeam

    }

    $ModRoster = $ModRoster | Sort-Object @{Expression="Power"; Descending=$true}

    ($ModRoster | ConvertTo-Html -PreContent ("<H1> <Center>" + $Rosterinfo.data.name + "</H1>") -Head $header).Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALIC","<i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)") | Out-File ($RosterInfo.data.Name + "-Chars.htm" ) -Encoding unicode -ErrorAction SilentlyContinue

    # Generating team statistics for all teams defined in CONFIG-Teams.csv

    Write-Host "Calculating team statistics" -foregroundcolor green

    $SquadOutput = $null

    ForEach ($TeamData in $TeamList){

        $TeamName=$TeamData.TeamName
        $MemberDefId=$TeamData.MemberDefId.Split(",")

        $Squad = @()

        ForEach ($TeamMember in $MemberDefId) {

            $UnitInfo = $UnitsList | Where-Object {$_.base_id -eq $TeamMember}
            $MemberDisplayName = ($UnitsList | Where-Object {$_.base_id -eq $TeamMember}).Name

            $SquadMember = ($ModRoster | Where-Object {$_.name -like $MemberDisplayName}).PSObject.copy()

            if ($SquadMember.name -ne $null) {

                $SquadMemberInfo = $ModRosterInfo | Where-Object {$_.name -like $MemberDisplayName}

                if ($SquadMember.gear -ge "G12") { $SquadMember.Name = "BOLD" + $SquadMember.Name }
                
                if ($SquadMember.gear -ge "G13") {
                        
                        if ($UnitInfo.alignment -eq 1) { $SquadMember.Name = "BGYELLOW" + $SquadMember.Name}
                        if ($UnitInfo.alignment -eq 2) { $SquadMember.Name = "BGBLUE" + $SquadMember.Name}
                        if ($UnitInfo.alignment -eq 3) { $SquadMember.Name = "BGRED" + $SquadMember.Name}
                    
                } else {

                    if ($UnitInfo.alignment -eq 1) { $SquadMember.Name = "YELLOW" + $SquadMember.Name}
                    if ($UnitInfo.alignment -eq 2) { $SquadMember.Name = "BLUE" + $SquadMember.Name}
                    if ($UnitInfo.alignment -eq 3) { $SquadMember.Name = "RED" + $SquadMember.Name}
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
                    If ($Omicrons.count -eq $AppliedOmicrons.count -and ($Omicrons -ne $null)) { $SquadMember.Gear = "o" + $SquadMember.Gear }
                    
                }

                If ($SquadMemberInfo.has_ultimate -eq $true) { $SquadMember.Gear = "u" + $SquadMember.Gear }

                $Squad += $SquadMember
                
                
            }
        }

        $SquadOutPut += $Squad | ConvertTo-Html -Head $header -PreContent ("<H1><Center>" + $TeamName + "</H1>")

    }

    $SquadOutput.Replace("<td>BGRED","<td style='background-color:lightcoral'>").Replace("<td>BGBLUE","<td style='background-color:skyblue'>").Replace("<td>BLUE","<td style='color:blue'>").Replace("<td>RED","<td style='color:red'>").Replace("BOLD","<b>").Replace("ITALIC","<i>").Replace("STRIKE","<s>").Replace("Transmitter","Transmitter</br>(Square)").Replace("Receiver","Receiver</br>(Arrow)").Replace("Processor","Processor</br>(Diamond)").Replace("Holo-Array","Holo-Array</br>(Triangle)").Replace("Data-Bus","Data-Bus</br>(Circle)").Replace("Multiplexer","Multiplexer</br>(Cross)") | Out-File ($RosterInfo.data.Name + "-Teams.htm" ) -Encoding unicode -ErrorAction SilentlyContinue
    

}   