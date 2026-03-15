# Minimal profile: UTF‑8 + Oh My Posh (if installed) + Fastfetch with explicit config path
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

# Function declarations for Aliases
function CD-WinTerm-Repo {
    cd A:\github\ownRepos\WinTerm\
}

# Setting Aliases
Set-Alias -Name WinTerm -Value CD-WinTerm-Repo

# Oh My Posh init
# oh-my-posh init pwsh --config 'jblab_2021' | Invoke-Expression
oh-my-posh init pwsh --config 'amro' | Invoke-Expression

# Init Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Clear Terminal
Clear-Host

# Fast fetch and Force it to use user config every time (bypass path confusion)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "C:/Users/tom/.config/fastfetch/config.jsonc"
}
