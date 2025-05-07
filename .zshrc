#=========================================================
# OH MY ZSH CONFIGURATION
#=========================================================
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme configuration
ZSH_THEME="robbyrussell"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  history-substring-search
  docker
  pyenv
  sudo                  # Press ESC twice to add sudo to current command
  web-search            # Enables: google, bing, ddg, etc. directly from terminal
  copypath              # Command to copy current directory path to clipboard
  copybuffer            # Ctrl+O to copy current command
  dirhistory            # Alt+Left/Right to navigate directory history
)

# Oh My Zsh update behavior
zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 30   # check for updates every 30 days

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

#=========================================================
# PATH CONFIGURATION
#=========================================================
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# User binaries
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Solana
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Python-related paths
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Pipx binaries
export PATH="$PATH:$HOME/.local/bin"

#=========================================================
# ENVIRONMENT VARIABLES
#=========================================================
# Uncomment to set language environment
export LANG=en_US.UTF-8

# Terminal colors
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Preferred editor configuration
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'  # Uncomment if you use Neovim
fi

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS  # Don't record duplicate commands
setopt HIST_FIND_NO_DUPS     # Don't display duplicates when searching
setopt EXTENDED_HISTORY      # Record timestamp of command
setopt SHARE_HISTORY         # Share history between all sessions
setopt HIST_VERIFY           # Don't execute immediately upon history expansion

#=========================================================
# CUSTOM FUNCTIONS
#=========================================================
# Download videos from a list of m3u8 URLs.
# Usage:
#   download_videos [input_file] [cookie_file] [output_dir]
download_videos() {
  local input_file="${1:-section_one.txt}"
  local cookie_file="${2:-~/downloads/www.nma.art_cookies.txt}"
  local output_dir="${3:-downloads}"
  local counter=1

  # Create the output directory if it doesn't exist.
  mkdir -p "$output_dir"

  while IFS= read -r url; do
    # Skip blank lines.
    if [ -z "$url" ]; then
      continue
    fi

    echo "Downloading video #$counter from URL: $url"
    yt-dlp --force-overwrites \
           --cookies "$cookie_file" \
           -o "${output_dir}/video_${counter}.%(ext)s" \
           --no-playlist-reverse \
           "$url"

    if [ $? -eq 0 ]; then
      echo "Video #$counter downloaded successfully."
    else
      echo "Error downloading video #$counter."
    fi

    counter=$((counter + 1))
  done < "$input_file"
}

# Create a new directory and enter it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract almost any archive
extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Search process by name and highlight the search term
psg() {
  ps aux | grep -v grep | grep -i -e "^USER" -e "$1" | grep -i "$1" --color="auto"
}

# Create a Python virtual environment
mkvenv() {
  python -m venv ${1:-.venv} && source ${1:-.venv}/bin/activate
}

# Weather function
weather() {
  curl -s "wttr.in/${1:-}?m&format=3"
}

# Cheatsheet for common commands
cheat() {
  curl -s "cheat.sh/$1"
}

# Create a backup of a file
bak() {
  cp "$1" "$1.bak-$(date +%Y%m%d-%H%M%S)"
}

# Convert and resize images easily with ImageMagick
# Usage: imgconvert input.png output.jpg 90%
imgconvert() {
  if [ $# -lt 2 ]; then
    echo "Usage: imgconvert input output [resize%]"
    return 1
  fi
  
  local resize=""
  if [ $# -eq 3 ]; then
    resize="-resize $3"
  fi
  
  convert $1 $resize $2
}

# Git terminal display - adds git status to your prompt
# You'll need to modify your ZSH_THEME or add this to a custom theme
git_prompt() {
  local git_status="$(git status 2> /dev/null)"
  local branch_pattern="On branch ([^${IFS}]*)"
  local detached_pattern="HEAD detached at ([^${IFS}]*)"
  local pattern="$branch_pattern|$detached_pattern"
  
  if [[ $git_status =~ $pattern ]]; then
    local branch=${match[1]:-${match[2]}}
    
    if [[ $git_status =~ "Your branch is ahead" ]]; then
      branch+="↑"
    elif [[ $git_status =~ "Your branch is behind" ]]; then
      branch+="↓"
    elif [[ $git_status =~ "Your branch and (.*) have diverged" ]]; then
      branch+="↕"
    fi
    
    if [[ $git_status =~ "Changes not staged for commit" ]]; then
      branch+="!"
    fi
    
    if [[ $git_status =~ "Changes to be committed" ]]; then
      branch+="+"
    fi
    
    if [[ $git_status =~ "Untracked files" ]]; then
      branch+="?"
    fi
    
    echo " ($branch)"
  fi
}

# Terminal welcome message with system info
welcome() {
  echo ""
  echo "Welcome, $(whoami)! Today is $(date '+%A, %B %d %Y')"
  echo "$(uptime)"
  echo ""
  echo "CPU: $(sysctl -n machdep.cpu.brand_string)"
  echo "Memory: $(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages free: (\d+)/ and printf("%.2f GB Free / ", $1 * $size / 1024 / 1024 / 1024); /Pages active: (\d+)/ and printf("%.2f GB Total\n", ($1 * $size / 1024 / 1024 / 1024) * 4)')"
  echo "Disk: $(df -h | grep disk1s1 | awk '{print $4 " Free / " $2 " Total"}')"
  echo ""
  echo "Quote of the day:"
  echo "$(curl -s https://api.quotable.io/random | python3 -c 'import json,sys; obj=json.load(sys.stdin); print(f""{obj["content"]}"" + "\n  — " + obj["author"])')"
  echo ""
  weather
  echo ""
}

# Colorful help function to show all available features
zhelp() {
  # Define colors
  local BLUE='\033[0;34m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[0;33m'
  local RED='\033[0;31m'
  local PURPLE='\033[0;35m'
  local CYAN='\033[0;36m'
  local GRAY='\033[0;90m'
  local BOLD='\033[1m'
  local UNDERLINE='\033[4m'
  local NC='\033[0m' # No Color
  
  # Define categories
  local categories=(
    "File Management"
    "Directory Navigation"
    "Git Shortcuts"
    "Python Tools"
    "System Tools"
    "Network Tools"
    "Docker Tools"
    "Fun Commands"
    "Utility Functions"
    "Keyboard Shortcuts"
  )
  
  # Print header
  echo -e "\n${BOLD}${UNDERLINE}Your ZSH Configuration Cheatsheet${NC}\n"
  
  # File Management
  echo -e "${BOLD}${BLUE}╔══ File Management ═══════════════════════════╗${NC}"
  echo -e "${GREEN}ls${NC}            - List files with colors"
  echo -e "${GREEN}ll${NC}            - List files in long format"
  echo -e "${GREEN}la${NC}            - List all files (including hidden)"
  if command -v exa >/dev/null 2>&1; then
    echo -e "${GREEN}lt${NC}            - List files in tree format"
    echo -e "${GREEN}ltl${NC}           - List files in tree format with details"
  fi
  echo -e "${GREEN}extract${NC} file   - Extract any compressed archive"
  echo -e "${GREEN}bak${NC} file       - Create a timestamped backup of a file"
  echo -e "${GREEN}mkcd${NC} dir       - Create a directory and enter it"
  echo -e "${GREEN}imgconvert${NC} in out [size%] - Convert and resize images"
  echo -e "${GRAY}# Example: extract archive.zip${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Directory Navigation
  echo -e "${BOLD}${BLUE}╔══ Directory Navigation ═══════════════════════╗${NC}"
  echo -e "${GREEN}..${NC}            - Go up one directory"
  echo -e "${GREEN}...${NC}           - Go up two directories"
  echo -e "${GREEN}....${NC}          - Go up three directories"
  echo -e "${GREEN}.....${NC}         - Go up four directories"
  echo -e "${GREEN}-${NC}             - Go to previous directory"
  echo -e "${GREEN}cd.${NC}           - Re-enter current directory to refresh"
  echo -e "${GRAY}# Use Alt+Left/Right for directory history navigation${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Git Shortcuts
  echo -e "${BOLD}${BLUE}╔══ Git Shortcuts ═══════════════════════════════╗${NC}"
  echo -e "${GREEN}gs${NC}            - git status"
  echo -e "${GREEN}gd${NC}            - git diff"
  echo -e "${GREEN}gc${NC}            - git commit"
  echo -e "${GREEN}gp${NC}            - git push"
  echo -e "${GREEN}gl${NC}            - git pull"
  echo -e "${GREEN}gb${NC}            - git branch"
  echo -e "${GREEN}gco${NC}           - git checkout"
  echo -e "${GREEN}gcl${NC}           - git clone"
  echo -e "${GREEN}glog${NC}          - git log with graph visualization"
  echo -e "${GREEN}grst${NC}          - git reset --hard HEAD"
  echo -e "${GRAY}# Example: gc -m \"Fixed bug in login form\"${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Python Tools
  echo -e "${BOLD}${BLUE}╔══ Python Tools ════════════════════════════════╗${NC}"
  echo -e "${GREEN}py${NC}            - python shortcut"
  echo -e "${GREEN}py3${NC}           - python3 shortcut"
  echo -e "${GREEN}pipup${NC}         - Update all pip packages"
  echo -e "${GREEN}mkvenv${NC} [name] - Create and activate Python virtual env"
  echo -e "${GREEN}jl${NC}            - Start Jupyter Lab"
  echo -e "${GREEN}jn${NC}            - Start Jupyter Notebook"
  echo -e "${GRAY}# Example: mkvenv my_project${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # System Tools
  echo -e "${BOLD}${BLUE}╔══ System Tools ════════════════════════════════╗${NC}"
  echo -e "${GREEN}cpu${NC}           - Show processes sorted by CPU usage"
  echo -e "${GREEN}mem${NC}           - Show processes sorted by memory usage"
  echo -e "${GREEN}df${NC}            - Show disk usage in human-readable format"
  echo -e "${GREEN}du${NC}            - Show directory sizes in current location"
  echo -e "${GREEN}psg${NC} process   - Search for a process with highlighting"
  echo -e "${GREEN}path${NC}          - Show PATH variable entries (one per line)"
  echo -e "${GREEN}zshconfig${NC}     - Edit your .zshrc file"
  echo -e "${GREEN}zshreload${NC}     - Reload your .zshrc file"
  echo -e "${GRAY}# Example: psg chrome${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Network Tools
  echo -e "${BOLD}${BLUE}╔══ Network Tools ═══════════════════════════════╗${NC}"
  echo -e "${GREEN}myip${NC}          - Show your public IP address"
  echo -e "${GREEN}localip${NC}       - Show your local IP address"
  echo -e "${GREEN}netlist${NC}       - Show all listening ports"
  echo -e "${GREEN}ports${NC}         - Show all open ports"
  echo -e "${GREEN}speedtest${NC}     - Test your internet connection speed"
  echo -e "${GRAY}# These tools require internet connection${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Docker Tools
  echo -e "${BOLD}${BLUE}╔══ Docker Tools ════════════════════════════════╗${NC}"
  echo -e "${GREEN}dps${NC}           - docker ps"
  echo -e "${GREEN}dpsa${NC}          - docker ps -a"
  echo -e "${GREEN}di${NC}            - docker images"
  echo -e "${GREEN}dex${NC} container - docker exec -it container bash"
  echo -e "${GREEN}dcu${NC}           - docker-compose up -d"
  echo -e "${GREEN}dcd${NC}           - docker-compose down"
  echo -e "${GREEN}dcl${NC}           - docker-compose logs -f"
  echo -e "${GRAY}# Example: dex my_container${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Fun Commands
  echo -e "${BOLD}${BLUE}╔══ Fun Commands ════════════════════════════════╗${NC}"
  echo -e "${GREEN}weather${NC} [location] - Show weather forecast"
  echo -e "${GREEN}moon${NC}          - Show current moon phase"
  echo -e "${GREEN}joke${NC}          - Get a random dad joke"
  echo -e "${GREEN}welcome${NC}       - Show welcome message with system info"
  echo -e "${GREEN}cheat${NC} topic   - Get a cheatsheet for a command/language"
  echo -e "${GREEN}qr${NC} text       - Generate a QR code in terminal"
  echo -e "${GRAY}# Example: weather london${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Utility Functions
  echo -e "${BOLD}${BLUE}╔══ Custom Functions ══════════════════════════════╗${NC}"
  echo -e "${GREEN}download_videos${NC} [file] [cookies] [outdir] - Download videos from m3u8 links"
  echo -e "${GRAY}# Example: download_videos my_list.txt${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Keyboard Shortcuts
  echo -e "${BOLD}${BLUE}╔══ Keyboard Shortcuts ════════════════════════════╗${NC}"
  echo -e "${YELLOW}ESC ESC${NC}       - Add sudo to current command"
  echo -e "${YELLOW}Ctrl+O${NC}        - Copy current command line"
  echo -e "${YELLOW}Ctrl+R${NC}        - Fuzzy search command history"
  echo -e "${YELLOW}Alt+Left/Right${NC} - Navigate directory history"
  echo -e "${YELLOW}Up/Down${NC}       - Search history with current prefix"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  # Tips and Dependencies
  echo -e "${BOLD}${BLUE}╔══ Tips and Dependencies ══════════════════════════╗${NC}"
  echo -e "For the best experience, install these packages:"
  echo -e "${CYAN}brew install exa fzf bat jq qrencode ncdu${NC}"
  echo -e ""
  echo -e "For Oh My Zsh plugins, install:"
  echo -e "${CYAN}git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions${NC}"
  echo -e "${CYAN}git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting${NC}"
  echo -e "${BLUE}╚═════════════════════════════════════════════╝${NC}\n"
  
  echo -e "${BOLD}Type ${GREEN}zhelp${NC} ${BOLD}anytime to see this list again.${NC}\n"
}

# Add automatic welcome message at shell start
welcome

#=========================================================
# ALIASES
#=========================================================
# General aliases
alias zshconfig="$EDITOR ~/.zshrc"
alias zshreload="source ~/.zshrc"
alias ohmyzsh="cd ~/.oh-my-zsh"
alias c="clear"
alias h="history"
alias path='echo -e ${PATH//:/\\n}'

# Enhanced ls with exa (if installed)
if command -v exa >/dev/null 2>&1; then
  alias ls="exa --icons"
  alias ll="exa -l --icons --git"
  alias la="exa -la --icons --git"
  alias lt="exa -T --icons --git -L 2"
  alias ltl="exa -T --icons --git -L 3 --long"
else
  # Fallback to standard ls with colors
  alias ls="ls -G"
  alias ll="ls -lh"
  alias la="ls -lah"
fi

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"                  # Go to previous directory with -
alias cd.="cd $(pwd)"              # Re-enter current directory to refresh

# Git shortcuts
alias gs="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gb="git branch"
alias gco="git checkout"
alias gcl="git clone"
alias glog="git log --oneline --decorate --graph"
alias grst="git reset --hard HEAD"

# Docker aliases
alias dps="docker ps"
alias dpsa="docker ps -a"
alias di="docker images"
alias dex="docker exec -it"
alias dcu="docker-compose up -d"
alias dcd="docker-compose down"
alias dcl="docker-compose logs -f"

# Python shortcuts
alias py="python"
alias py3="python3"
alias pyenv-update="pyenv update"
alias pip-upgrade="pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U"
alias pipup="pip-upgrade"
alias jl="jupyter lab"
alias jn="jupyter notebook"

# Networking aliases
alias myip="curl -s http://ipinfo.io/ip"
alias localip="ipconfig getifaddr en0"
alias netlist="lsof -i -P | grep -i 'listen'"
alias ports="netstat -tulanp"

# System monitoring and management
alias cpu="top -o cpu"
alias mem="top -o rsize"
alias df="df -h"
alias du="du -h -d 1"

# Clipboard aliases
alias pbp="pbpaste"
alias pbc="pbcopy"

# Fun and practical aliases
alias weather="curl wttr.in"
alias moon="curl wttr.in/Moon"
alias joke="curl -s https://icanhazdadjoke.com"
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -"
alias qr="qrencode -t ANSI -o -"  # Requires qrencode to be installed

#=========================================================
# ZSH KEY BINDINGS
#=========================================================
# Use emacs key bindings
bindkey -e

# History search with Up/Down arrows
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Alt+left/right for directory navigation
bindkey '^[^[[D' backward-word
bindkey '^[^[[C' forward-word

# Ctrl+R for fuzzy history search (needs fzf)
if command -v fzf >/dev/null 2>&1; then
  source $(brew --prefix)/opt/fzf/shell/key-bindings.zsh
  source $(brew --prefix)/opt/fzf/shell/completion.zsh
fi

#=========================================================
# LOCAL CONFIGURATION (Create this file for machine-specific settings)
#=========================================================
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Display help hint when shell starts
echo -e "\033[0;32mType \033[1mzhelp\033[0;32m to see available shortcuts and functions\033[0m"

# Added by Windsurf
export PATH="/Users/andrewbenavides/.codeium/windsurf/bin:$PATH"
