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

eval "$(~/.local/bin/mise activate zsh)"

. /etc/profile.d/fzf.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/ariel/google-cloud-sdk/path.zsh.inc' ]; then . '/home/ariel/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/ariel/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/ariel/google-cloud-sdk/completion.zsh.inc'; fi

export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
