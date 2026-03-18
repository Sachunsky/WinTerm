# Personal PS Profile: UTF‑8 + Oh My Posh + Fastfetch with custom config

# Set UTF8 Encoding
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

# Variable declarations
$basePaths = @(
    "A:\github\ownRepos",
    "A:\github\clones"
)

$winTermPath = "A:\github\ownRepos\WinTerm"

# Function declarations for Aliases
function Set-Location-Repo {
    <#
    .SYNOPSIS
        Quickly navigate to a git repository folder.
    .DESCRIPTION
        Searches known repo base paths for a matching folder.
        - No argument: opens fzf picker with all repos
        - Single match: navigates directly
        - Multiple matches: picks via fzf
    .PARAMETER RepoName
        Full or partial name of the repo folder to navigate to.
    .EXAMPLE
        repo WinTerm
    .EXAMPLE
        repo
    #>
    param(
        [string]$RepoName
    )

    # No argument given -> list all repos and let the user pick with fzf
    if (-not $RepoName) {
        $allRepos = foreach ($base in $basePaths) {
            if (Test-Path $base) {
                Get-ChildItem -Path $base -Directory | ForEach-Object {
                    "$($_.Name) ($($_.FullName))"
                }
            }
        }

        $selection = $allRepos | fzf --prompt="Select repo: "

        # Extract the path from between the parentheses and navigate
        if ($selection) {
            $selectedPath = ($selection -replace '.*\((.+)\)$', '$1')
            Set-Location $selectedPath
        }
        return
    }

    # Argument given -> collect all matches (exact and partial) across all base paths
    $matches = @()

    foreach ($base in $basePaths) {
        if (-not (Test-Path $base)) { continue }

        Get-ChildItem -Path $base -Directory | ForEach-Object {
            if ($_.Name -like "*$RepoName*") {
                $matches += $_
            }
        }
    }

    if ($matches.Count -gt 1) {
        # Multiple matches -> let the user disambiguate with fzf
        $selection = $matches | ForEach-Object { "$($_.Name) ($($_.FullName))" } | fzf --prompt="Multiple matches: "
        if ($selection) {
            $selectedPath = ($selection -replace '.*\((.+)\)$', '$1')
            Set-Location $selectedPath
        }
    } elseif ($matches.Count -eq 1) {
        # Single match -> navigate directly
        Set-Location $matches[0].FullName
    } else {
        Write-Warning "Repo '$RepoName' not found in any known location."
    }
}

# Tab completion - suggests repo folder names from all base paths
Register-ArgumentCompleter -CommandName Set-Location-Repo -ParameterName RepoName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    # Collect all matching repos across all base paths
    $basePaths | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem -Path $_ -Directory |
                Where-Object { $_.Name -like "$wordToComplete*" }
        }
    } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.Name,
            $_.Name,
            'ParameterValue',
            $_.FullName
        )
    }
}

# Creates Directory and cd's into it.
function New-Item-And-Set-Location {
    param(
        [string]$dirPath
    )

    if (!(Test-Path $dirPath)) {
        New-Item -Path $dirPath -ItemType Directory
    }
    else {
        Write-Warning "Directory '$dirPath' already exists."
    }
    Set-Location $dirPath
}

# Edit PS Profile ( yes, this one :) )
function Edit-Profile {
    hx $PROFILE.CurrentUserAllHosts
}

# Reload PS Profile
function Reload-Profile {
    . $PROFILE.CurrentUserAllHosts
}

function Export-WinGet {
    winget export -o "$winTermPath\Configs\Winget_Packages\packages.json"
    echo "Exported WinGet Packages to '$winTermPath\Configs\Winget_Packages\packages.json'"
}

# Short aliases for quick access
Set-Alias -Name repo -Value Set-Location-Repo
Set-Alias -Name mkcd -Value New-Item-And-Set-Location
Set-Alias -Name wgexport -Value Export-WinGet

# Oh My Posh init
oh-my-posh init pwsh --config 'amro' | Invoke-Expression

# Init Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Clear Terminal
Clear-Host

# Fast fetch and Force it to use user config every time (bypass path confusion)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "$HOME/.config/fastfetch/config.jsonc"
}
