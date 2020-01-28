Param($SettingsPath, $SettingName, $PathToFile, [switch]$Help, [switch]$DoNothing, [switch]$Verbose)

Function Get-Format {
    Param($Format, $Regex, $Name, $FileName, [bool]$Verbose)
    #--- Capture ----

    $matchs = [regex]::Matches($FileName, $Regex)
    $Groups = $matchs[0].Groups
    if (!$matchs) {
        Write-Host "Regex doesnt match"
        Write-Help
        Exit 1
    }

    $Episode = [string]$Groups['episode']
    if (([string]::IsNullOrWhiteSpace($Episode))) {
        Write-Host "Episode number dont match !"
        Write-Help
        Exit 1
    }
    else {
        $EpisodeNumber = [int]($Episode.TrimStart('0'))
    }

    $EpisodeName = $Groups['episodeName']
    $Season = [string]$Groups['season']
    if (!([string]::IsNullOrWhiteSpace($Season))) {
        $SeasonNumber = [int]($Season.TrimStart('0'))
    }
    
    
    #--- Format ----
    $newName = $Format -f $Name, $SeasonNumber, $EpisodeNumber, $EpisodeName

    if ($Verbose) {
        Write-Host "Regex = $Regex"
        Write-Host "Format = $Format"
        Write-Host "Name = $Name"
        Write-Host "season = $Season"
        Write-Host " -> SeasonNumber = $SeasonNumber"
        Write-Host "episode = $episode"
        Write-Host " -> EpisodeNumber = $EpisodeNumber"
        Write-Host "episodeName = $EpisodeName"
        Write-Host "old name = $FileName"
        Write-Host "new name = $newName"
    }

    return $newName
}

#---- HELP ----
Function Write-Help {
    Write-Host "- Parameters are :"
    Write-Host "    SettingsPath    Path to settings folder (string)"
    Write-Host "    SettingName     Name of the json settings without extension (string)"
    Write-Host "    PathToFile      Path to file to rename (string)"
    Write-Host "    Help            Show this (switch)"
    Write-Host "    DoNothing       Doesn't modify files, write the output (switch)"
    Write-Host "    Verbose         More logs in console (switch)"
    Write-Host "- Regex groups are :"
    Write-Host "    season"
    Write-Host "    episode"
    Write-Host "    episodeName"
    Write-Host "- Format index are :"
    Write-Host "    0=Name"
    Write-Host "    1=Seaon number"
    Write-Host "    2=Episode number"
    Write-Host "    3=Episode name"
}
if ($Help) {
    Write-Help
    Exit 0
}

# ---- Test parameters ----
if (!(Test-Path -LiteralPath $PathToFile)) {
    Write-Host "File to rename ${PathToFile} doesn't exist."
    Write-Help
    Exit 1
}

if (!(Test-Path -Path $SettingsPath -PathType Container)) {
    Write-Host "Settings folder ${SettingsPath} doesn't exist."
    Write-Help
    Exit 1
}

$Setting = Join-Path -Path $SettingsPath -ChildPath "${SettingName}.json"

if (!(Test-Path -Path $Setting -PathType Leaf)) {
    Write-Host "Setting file ${SettingName}.json doesn't exist in ${SettingsPath}"
    Write-Help
    Exit 1
}

$SettingJson = Get-Content $Setting | ConvertFrom-Json

#---- TEST JSON ----
if (!($SettingJson.regex)) {
    Write-Host "Setting file ${SettingName}.json doesn't have property regex"
    Write-Help
    Exit 1
}
$Regex = $SettingJson.regex

if (!($SettingJson.format)) {
    Write-Host "Setting file ${SettingName}.json doesn't have property format"
    Write-Help
    Exit 1
}
$Format = $SettingJson.format

if (!($SettingJson.name)) {
    Write-Host "Setting file ${SettingName}.json doesn't have property name"
    Write-Help
    Exit 1
}
$Name = $SettingJson.name

#---- Format ----
$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($PathToFile)
$Extension = [System.IO.Path]::GetExtension($PathToFile)
$NewName = Get-Format -Format $Format -Regex $Regex -Name $Name -FileName $BaseName -Verbose $Verbose

if ($DoNothing) {
    Write-Host "${BaseName}${Extension} -> ${NewName}${Extension}"
}
else {
    #---- Rename ----
    Rename-Item -LiteralPath $PathToFile -NewName "${NewName}${Extension}"
}