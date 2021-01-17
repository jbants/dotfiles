
#!/bin/bash

DOTFILES="$(pwd)"
COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
    echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
    echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

error() {
    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
    exit 1
}

warning() {
    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

get_linkables() {
    find -H "$DOTFILES" -maxdepth 3 -name '*.symlink'
}

backup() {
    BACKUP_DIR=$HOME/dotfiles-backup

    echo "Creating backup directory at $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    for file in $(get_linkables); do
        filename=".$(basename "$file" '.symlink')"
        target="$HOME/$filename"
        if [ -f "$target" ]; then
            echo "backing up $filename"
            cp "$target" "$BACKUP_DIR"
        else
            warning "$filename does not exist at this location or is a symlink"
        fi
    done

    for filename in "$HOME/.config/nvim" "$HOME/.vim" "$HOME/.vimrc"; do
        if [ ! -L "$filename" ]; then
            echo "backing up $filename"
            cp -rf "$filename" "$BACKUP_DIR"
        else
            warning "$filename does not exist at this location or is a symlink"
        fi
    done
}

setup_symlinks() {
    title "Creating symlinks"

    if [ ! -e "$HOME/.dotfiles" ]; then
        info "Adding symlink to dotfiles at $HOME/.dotfiles"
        ln -s "$DOTFILES" ~/.dotfiles
    fi

    for file in $(get_linkables) ; do
        target="$HOME/.$(basename "$file" '.symlink')"
        if [ -e "$target" ]; then
            info "~${target#$HOME} already exists... Skipping."
        else
            info "Creating symlink for $file"
            ln -s "$file" "$target"
        fi
    done

    echo -e
    info "installing to ~/.config"
    if [ ! -d "$HOME/.config" ]; then
        info "Creating ~/.config"
        mkdir -p "$HOME/.config"
    fi

    config_files=$(find "$DOTFILES/config" -maxdepth 1 2>/dev/null)
    for config in $config_files; do
        target="$HOME/.config/$(basename "$config")"
        if [ -e "$target" ]; then
            info "~${target#$HOME} already exists... Skipping."
        else
            info "Creating symlink for $config"
            ln -s "$config" "$target"
        fi
    done
}

# # Add this back in  - JRB
# setup_git() {
#     title "Setting up Git"

#     defaultName=$(git config user.name)
#     defaultEmail=$(git config user.email)
#     defaultGithub=$(git config github.user)

#     read -rp "Name [$defaultName] " name
#     read -rp "Email [$defaultEmail] " email
#     read -rp "Github username [$defaultGithub] " github

#     git config -f ~/.gitconfig-local user.name "${name:-$defaultName}"
#     git config -f ~/.gitconfig-local user.email "${email:-$defaultEmail}"
#     git config -f ~/.gitconfig-local github.user "${github:-$defaultGithub}"

#     if [[ "$(uname)" == "Darwin" ]]; then
#         git config --global credential.helper "osxkeychain"
#     else
#         read -rn 1 -p "Save user and password to an unencrypted file to avoid writing? [y/N] " save
#         if [[ $save =~ ^([Yy])$ ]]; then
#             git config --global credential.helper "store"
#         else
#             git config --global credential.helper "cache --timeout 3600"
#         fi
#     fi
# }



 setup_shell() {
    title "Configuring shell"

    [[ -n "$(command -v brew)" ]] && zsh_path="$(brew --prefix)/bin/zsh" || zsh_path="$(which zsh)"
    if ! grep "$zsh_path" /etc/shells; then
        info "adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    if [[ "$SHELL" != "$zsh_path" ]]; then
        chsh -s "$zsh_path"
        echo "default shell changed to $zsh_path"
    fi
}

# if ! command_exists zsh; then
#     echo "zsh not found. Please install and then re-run installation scripts"
#     exit 1
# elif ! [[ $SHELL =~ .*zsh.* ]]; then
#     echo "Configuring zsh as default shell"
#     chsh -s "$( command -v zsh)"
# fi

# # Change the default shell to zsh
# zsh_path="$( command -v zsh )"
# if ! grep "$zsh_path" /etc/shells; then
#     echo "adding $zsh_path to /etc/shells"
#     echo "$zsh_path" | sudo tee -a /etc/shells
# fi

# if [[ "$SHELL" != "$zsh_path" ]]; then
#     chsh -s "$zsh_path"
#     echo "default shell changed to $zsh_path"
# fi

case "$1" in
    backup)
        backup
        ;;
    link)
        setup_symlinks
        ;;
    git)
        setup_git
        ;;
    homebrew)
        setup_homebrew
        ;;
    shell)
        setup_shell
        ;;
    terminfo)
        setup_terminfo
        ;;
    macos)
        setup_macos
        ;;
    all)
        setup_symlinks
        ;;
    *)
        echo -e $"\nUsage: $(basename "$0") {backup|link|git|homebrew|shell|terminfo|macos|all}\n"
        exit 1
        ;;
esac

echo -e
success "Done."