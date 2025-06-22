source ~/.antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions

# Load the theme.
antigen theme https://github.com/denysdovhan/spaceship-zsh-theme spaceship

# Tell Antigen that you're done.
antigen apply

eval "$(/usr/bin/mise activate zsh)"
export WORKON_HOME=$HOME/.virtualenvs
#source /usr/local/bin/virtualenvwrapper.sh
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"

. /etc/profile.d/fzf.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/ariel/google-cloud-sdk/path.zsh.inc' ]; then . '/home/ariel/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/ariel/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/ariel/google-cloud-sdk/completion.zsh.inc'; fi

# Enable Windows Vagrant access in WSL
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export PATH=$PATH:/mnt/c/Program\ Files/Oracle/VirtualBox

# Rust CLI alternatives
eval "$(zoxide init zsh)"
alias cat='bat'
alias ls='exa --icons'
alias cp='xcp'
alias cd='z'
alias du='dust'
alias find='fd'
alias ps='procs'
alias top='btn'
alias tree='broot'

export PATH="$HOME/.cargo/bin:$PATH"

# Mise activation
eval "$(/usr/bin/mise activate zsh)"

export SSH_AUTH_SOCK=/home/ariel/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock
