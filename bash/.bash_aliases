# --- Bitwarden SSH Agent ---
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

# --- Backup ---
alias backup-now='sudo btrbk -c /etc/btrbk/btrbk.conf run && $HOME/backup-data-ext4.sh'

# --- Modern Unix Tools ---

# Zoxide (cd replacement)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
    alias cd='z'
fi

# Eza (ls replacement)
if command -v eza &> /dev/null; then
    alias ls='eza --icons --git --group-directories-first'
    alias ll='eza --icons --git --header --long --group-directories-first'
fi

# Bat (cat replacement)
if command -v bat &> /dev/null; then
    alias cat='bat'
fi

# Ripgrep (grep replacement)
if command -v rg &> /dev/null; then
    alias grep='rg'
fi
