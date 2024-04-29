#!/bin/bash

# This script should be used to install Neovim with all pre-requisites
# needed to run my kickstart. https://github.com/kyallanum/kickstart.nvim
#
# This script only supports Ubuntu WSL

is_package_present() {
	if ! [[ $1 =~ ^[0-9]+$ ]]; then
		echo "is_package_present must be called with an exit code" >&2; exit 1
	else
		EXIT_CODE=$1
	fi

	if [[ $EXIT_CODE -eq 127 ]]; then
		echo false
	else 
		echo true
	fi
}

function get_packages {
	NVM_PRESENT=$(nvm >/dev/null 2>&1; is_package_present $?)
	PYENV_PRESENT=$(pyenv which python3 >/dev/null 2>&1; is_package_present $?)
	GIT_PRESENT=$(git version >/dev/null 2>&1; is_package_present $?)
	MAKE_PRESENT=$(make -v >/dev/null 2>&1; is_package_present $?)
	UNZIP_PRESENT=$(unzip >/dev/null 2>&1; is_package_present $?)
	RIPGREP_PRESENT=$(rg -V >/dev/null 2>&1; is_package_present $?)
	FD_PRESENT=$(fdfind -V >/dev/null 2>&1; is_package_present $?)
	CURL_PRESENT=$(curl -V >/dev/null 2>&1; is_package_present $?)
	GZIP_PRESENT=$(gzip -V >/dev/null 2>&1; is_package_present $?)
	TAR_PRESENT=$(tar --version >/dev/null 2>&1; is_package_present $?)
	JQ_PRESENT=$(jq -V >/dev/null 2>&1; is_package_present $?)
	TMUX_PRESENT=$(tmux -V >/dev/null 2>&1; is_package_present $?)

	UTILITIES_TO_ADD=()
	if ! $GIT_PRESENT; then
		UTILITIES_TO_ADD+=( "git" )
	fi

	if ! $MAKE_PRESENT; then
		UTILITIES_TO_ADD+=( "build-essential" )
	fi

	if ! $UNZIP_PRESENT; then
		UTILITIES_TO_ADD+=( "zip" "unzip" )
	fi

	if ! $RIPGREP_PRESENT; then
		UTILITIES_TO_ADD+=( "ripgrep" )
	fi

	if ! $FD_PRESENT; then
		UTILITIES_TO_ADD+=( "fd-find" )
	fi

	if ! $CURL_PRESENT; then
		UTILITIES_TO_ADD+=( "curl" )
	fi

	if ! $GZIP_PRESENT; then
		UTILITIES_TO_ADD+=( "gzip" )
	fi

	if ! $TAR_PRESENT; then
		UTILITIES_TO_ADD+=( "tar" )
	fi

	if ! $JQ_PRESENT; then
		UTILITIES_TO_ADD+=( "jq" )
	fi

	if ! $TMUX_PRESENT; then
		UTILITIES_TO_ADD+=( "tmux" )
	fi
}

function install_utilities {
	UTILITIES_STRING=""
	for utility in ${UTILITIES_TO_ADD[@]}; do
		UTILITIES_STRING+="$utility "
	done
	sudo apt install $UTILITIES_STRING
}

function install_packages {
	echo Installing required utilities
	echo =============================
	install_utilities
	echo -e "\n"

	if ! $NVM_PRESENT; then
		NVM_LATEST_RELEASE=$(curl "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | jq -r '.tag_name')
		echo Installing NVM $NVM_LATEST_RELEASE
		echo ======================
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_LATEST_RELEASE/install.sh | bash
		export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf $s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
		[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # Load NVM
		nvm install --lts
		nvm use node
		npm i -g tree-sitter-cli neovim
	else
		echo NVM already installed
		echo -e "=====================\n"
	fi

	if ! $PYENV_PRESENT; then
		echo Installing prerequisites for pyenv
		echo -e "=================================="
		sudo apt install libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev

		echo -e "\nInstalling pyenv"
		echo ================
		curl https://pyenv.run | bash

		echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
		echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
		echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/.bashrc
		export PYENV_ROOT="$HOME/.pyenv"
		export PATH="$PYENV_ROOT/bin:$PATH"
		eval "$(pyenv init -)"
		pyenv install 3.10.14
		pyenv global 3.10.14
		pip install neovim
	else
		echo Pyenv already installed
		echo -e "=======================\n"
	fi
}

function install_neovim {
	echo -e "\nInstalling NeoVim"
	echo =================

	curl -LJO https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz
	sudo tar -C /opt -xzf nvim-linux64.tar.gz
	sudo ln -s /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
	rm -r nvim-linux64.tar.gz

	git clone https://github.com/kyallanum/kickstart.nvim.git ~/.config/nvim

	echo "set-option -sg escape-time 10" >> ~/.tmux.conf
	echo "set-option -g focus-events on" >> ~/.tmux.conf
	echo "set-option -g default-terminal screen-256color" >> ~/.tmux.conf
	echo "set-option -sa terminal-features ',xterm-256color:RGB'" >> ~/.tmux.conf
}

get_packages
install_packages

install_neovim
