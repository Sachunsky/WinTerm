# Minimal profile: UTF‑8 + Oh My Posh (if installed) + Fastfetch with explicit config path
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

# Function declarations for Aliases

function Set-Location-Repo {
    <#
    .SYNOPSIS
        Quickly navigate to a git repository folder.
    .DESCRIPTION
        Searches known repo base paths for a matching folder.
        - No argument: opens fzf picker with all repos
        - Exact match: navigates directly (or picks via fzf if duplicates exist)
        - Partial match: navigates directly or picks via fzf if ambiguous
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
    
    # Base paths where repos live
    $basePaths = @(
        "A:\github\ownRepos",
        "A:\github\clones"
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
    
    # Argument given -> collect exact and partial matches across all base paths
    $exactMatches = @()
    $partialMatches = @()
    
    foreach ($base in $basePaths) {
        if (-not (Test-Path $base)) { continue }
        
        Get-ChildItem -Path $base -Directory | ForEach-Object {
            if ($_.Name -eq $RepoName) {
                $exactMatches += $_
            } elseif ($_.Name -like "*$RepoName*") {
                $partialMatches += $_
            }
        }
    }
    
    # Prefer exact matches over partial ones
    $results = if ($exactMatches.Count -gt 0) { $exactMatches } else { $partialMatches }
    
    if ($results.Count -gt 1) {
        # Multiple matches -> let the user disambiguate with fzf
        $selection = $results | ForEach-Object { "$($_.Name) ($($_.FullName))" } | fzf --prompt="Multiple matches: "
        if ($selection) {
            $selectedPath = ($selection -replace '.*\((.+)\)$', '$1')
            Set-Location $selectedPath
        }
    } elseif ($results.Count -eq 1) {
        # Single match -> navigate directly
        Set-Location $results[0].FullName
    } else {
        Write-Warning "Repo '$RepoName' not found in any known location."
    }
}

# Tab completion - suggests repo folder names from all base paths
Register-ArgumentCompleter -CommandName Set-Location-Repo -ParameterName RepoName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)
    
    $basePaths = @(
        "A:\github\ownRepos",
        "A:\github\clones"
    )
    
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

# Short alias for quick access
Set-Alias -Name repo -Value Set-Location-Repo

# Oh My Posh init
# oh-my-posh init pwsh --config 'jblab_2021' | Invoke-Expression
oh-my-posh init pwsh --config 'amro' | Invoke-Expression

# Init Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Clear Terminal
Clear-Host

# Fast fetch and Force it to use user config every time (bypass path confusion)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "$HOME/.config/fastfetch/config.jsonc"
}
