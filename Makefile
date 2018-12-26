
# default XDG_DATA_HOME to ~/.local/share and XDG_CONFIG_HOME to ~/.config if not set
# @see https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#basics
XDG_DATA_HOME ?= $(HOME)/.local/share
XDG_CONFIG_HOME ?= $(HOME)/.config

tmux: version ?= 2.6
maven: version ?= 3.5.2
gradle: version ?= 4.8.1
stterm: version ?= 0.8.1
flags/docker-compose: compose-version ?= 1.21.2
zsh: prompt-location ?= $(XDG_DATA_HOME)/spaceship-prompt
zsh: completions-location ?= $(XDG_DATA_HOME)/zsh-completions
npm-%: packages = bower browser-sync bunyan gulp-cli eslint_d nodemon prettier

.PHONY:
	install
	pgcli
	npm
	npm-install
	npm-update

install:
	./install.sh

basic: apt.tree apt.silversearcher-ag apt.xclip apt.jq
	mkdir -p $(HOME)/bin
	mkdir -p $(HOME)/temp
	test -d $(HOME)/scripts/.git || git clone https://github.com/gurpreetatwal/scripts.git  $(HOME)/scripts
	@bash ./install/run-helper link "agignore" "$(HOME)/.agignore"
	@bash ./install/run-helper link "gitconfig" "$(HOME)/.gitconfig"
	@bash ./install/run-helper link "gitignore.global" "$(HOME)/.gitignore.global"
	@bash ./install/run-helper link "shell/profile" "$(HOME)/.profile"

zsh: apt.zsh
	grep "$$(whoami):$$(which zsh)$$" /etc/passwd || sudo usermod --shell "$$(which zsh)" "$$(whoami)"
	mkdir --parents "$(HOME)/.zfunctions"
	@bash ./install/run-helper link "shell/zshrc" "$(HOME)/.zshrc"
	@bash ./install/run-helper link "shell/profile" "$(HOME)/.zprofile"
	test -d "$(prompt-location)" || git clone https://github.com/denysdovhan/spaceship-prompt.git "$(prompt-location)"
	test -d "$(completions-location)" || git clone git://github.com/zsh-users/zsh-completions.git "$(completions-location)"
	git -C "$(prompt-location)" pull
	git -C "$(completions-location)" pull
	ln -sf "$(prompt-location)/spaceship.zsh" "$(HOME)/.zfunctions/prompt_spaceship_setup"
	rm "$(HOME)/.zcompdump"
	zsh -c "source $(HOME)/.zshrc && compinit"

fasd: flags/fasd

pip2: flags/pip2
pip3: flags/pip3

i3: flags/i3
nvim: flags/neovim
neovim: flags/neovim

# Programming Languages
node: flags/node
rust: flags/rust
java: flags/java
maven: flags/maven
gradle: flags/gradle

docker: flags/docker docker-compose
docker-compose: flags/docker-compose
docker-compose-update: update.flags/docker-compose flags/docker-compose

# Tools
postman: flags/postman

# System Configuration
gestures: flags/gestures
hall-monitor: flags/hall-monitor
libinput: flags/libinput

# Fixes for firefox when using dark themes and for scrolling using a touchscreen
# Theme fix from https://wiki.archlinux.org/index.php/Firefox#Unreadable_input_fields_with_dark_GTK.2B_themes
# Scrolling fix from https://wiki.gentoo.org/wiki/Firefox#Xinput2_scrolling
firefox-fix:
	sudo sed -i 's/Exec=.*firefox/Exec=env MOZ_USE_XINPUT2=1 GTK_THEME=Adwaita:light firefox/' /usr/share/applications/firefox.desktop

pgcli: pip2 apt.libpq-dev apt.libevent-dev
	pip install --user --upgrade pgcli
	@bash ./install/run-helper link pgcli $(XDG_CONFIG_HOME)/pgcli/config

bindkeys: apt.xbindkeys apt.xdotool
	@bash ./install/run-helper link xbindkeysrc $(HOME)/.xbindkeysrc
	xbindkeys

tmux: apt.libevent-dev apt.libncurses-dev apt.xclip
	curl --location --silent --show-error https://github.com/tmux/tmux/releases/download/$(version)/tmux-$(version).tar.gz | tar -xz -C /tmp
	cd /tmp/tmux-$(version) && ./configure && make
	cd /tmp/tmux-$(version) && sudo make install
	tic -o ~/.terminfo install/tmux-256color.terminfo
	@bash ./install/run-helper link tmux.conf $(HOME)/.tmux.conf

alacritty: flags/alacritty
stterm: flags/stterm

flags/neovim: pip2 pip3
	sudo add-apt-repository --update --yes ppa:neovim-ppa/stable
	@bash ./install/run-helper installif neovim
	python2 -m pip install --user --upgrade pynvim
	python3 -m pip install --user --upgrade pynvim
	mkdir -p ~/.config/nvim
	@bash ./install/run-helper link vimrc $(HOME)/.config/nvim/init.vim
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	nvim +PlugUpdate +qa
	touch flags/neovim

npm: npm-install npm-update

npm-install: node
	npm install --global $(packages)

npm-update: node
	npm install --global npm
	npm update --global $(packages)

jetbrains:
	./jetbrains.sh

apt.%:
	@bash ./install/run-helper installif $*

update.flags/%:
	@rm flags/$* || true

flags/fasd:
	$(eval tmp = $(shell mktemp --dry-run))
	git clone https://github.com/clvv/fasd $(tmp)
	cd $(tmp) && sudo make install
	ln -sf /usr/local/bin/fasd flags

flags/pip2: apt.python-dev apt.python-pip
	python2 -m pip install --user --upgrade pip
	python2 -m pip install --user --upgrade wheel
	python2 -m pip install --user --upgrade setuptools
	touch flags/pip2

flags/pip3: apt.python3-dev apt.python3-pip
	python3 -m pip install --user --upgrade pip
	python3 -m pip install --user --upgrade wheel
	python3 -m pip install --user --upgrade setuptools
	touch flags/pip3

flags/i3: apt.i3 apt.i3lock apt.xautolock
	mkdir --parents "$(XDG_CONFIG_HOME)/i3"
	mkdir --parents "$(XDG_CONFIG_HOME)/i3status"
	@bash ./install/run-helper link "i3.conf" "$(XDG_CONFIG_HOME)/i3/config"
	@bash ./install/run-helper link "i3status.conf" "$(XDG_CONFIG_HOME)/i3status/config"
	ln -sf "$(XDG_CONFIG_HOME)/i3/config" "flags/i3"

flags/node:
	curl --location https://git.io/n-install | N_PREFIX=$(XDG_DATA_HOME)/nodejs bash -s -- -n
	ln -sf $(XDG_DATA_HOME)/nodejs/bin/node flags/node

flags/rust:
	$(eval tmp = $(shell mktemp --dry-run --tmpdir="/tmp" rustup-init-XXX))
	wget -O $(tmp) https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
	chmod a+x $(tmp)
	exec $(tmp) --verbose --no-modify-path -y
	-rm $(tmp)
	ln -sf $(HOME)/.cargo/bin/rustc flags/rust

flags/java:
	sudo apt-get remove --purge 'openjdk8*'
	sudo add-apt-repository --yes --update ppa:webupd8team/java
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
	@bash ./install/run-helper installif oracle-java8-installer oracle-java8-set-default
	ln -sf "$$(update-alternatives --list java)" flags/java

flags/maven: flags/java flags/opt-dir
	# TODO verify signature of download
	wget -O /tmp/maven.tar.gz http://www-us.apache.org/dist/maven/maven-3/$(version)/binaries/apache-maven-$(version)-bin.tar.gz
	tar -xzf /tmp/maven.tar.gz --directory /opt
	mv /opt/apache-maven-$(version) /opt/maven
	ln -sf /opt/maven flags

flags/gradle: flags/java flags/opt-dir
	$(eval tmp = $(shell mktemp --dry-run --tmpdir="/tmp" gradle-XXX.zip))
	wget -O "$(tmp)" "https://services.gradle.org/distributions/gradle-$(version)-bin.zip"
	unzip -d "/opt" "$(tmp)"
	mv "/opt/gradle-$(version)" "/opt/gradle"
	-rm "$(tmp)"
	ln -sf /opt/gradle flags

flags/alacritty: repository = https://github.com/jwilm/alacritty
flags/alacritty:
	@# get latest tagged version
	$(eval version = $(shell git ls-remote --tags --refs $(repository) | awk -F"[\t/]" 'END{print $$NF}'))
	$(eval file = Alacritty-$(version)_amd64.deb)
	wget --directory-prefix="/tmp" --timestamping "$(repository)/releases/download/$(version)/$(file)"
	sudo apt install "/tmp/$(file)"
	mkdir -p "$(XDG_CONFIG_HOME)/alacritty"
	@bash ./install/run-helper link "alacritty.yml" "$(XDG_CONFIG_HOME)/alacritty/alacritty.yml"
	ln -sf "/usr/bin/alacritty" "flags"

flags/alacritty-src: rust apt.cmake apt.libfreetype6-dev apt.libfontconfig1-dev apt.xclip
	@bash ./install/run-helper git-clone "https://github.com/jwilm/alacritty" "/tmp/alacritty"
	rustup override set stable
	rustup update stable
	cd "/tmp/alacritty" && cargo build --release
	sudo mv "/tmp/alacritty/target/release/alacritty" "/usr/local/bin"
	sudo mv "/tmp/alacritty/alacritty.desktop" "/usr/share/applications"
	-rm -rf "/tmp/alacritty"
	mkdir -p "$(XDG_CONFIG_HOME)/alacritty"
	@bash ./install/run-helper link "alacritty.yml" "$(XDG_CONFIG_HOME)/alacritty/alacritty.yml"
	ln -sf "/usr/local/bin/alacritty" "flags/alacritty-src"

flags/stterm: apt.libx11-dev apt.libxft-dev
	wget --directory-prefix="/tmp" --timestamping https://dl.suckless.org/st/st-$(version).tar.gz
	wget --directory-prefix="/tmp" --timestamping https://dl.suckless.org/st/sha256sums.txt
	cd /tmp && sha256sum --ignore-missing --check sha256sums.txt
	tar -xzf /tmp/st-$(version).tar.gz -C /tmp
	-rm /tmp/st-$(version).tar.gz
	-rm /tmp/sha256sums.txt
	sudo make -C /tmp/st-$(version) clean install
	-rm -rf /tmp/st-$(version)
	ln -sf /usr/local/bin/st flags/stterm

flags/docker:
	sudo apt-key add install/docker.gpg
	sudo add-apt-repository --update "deb [arch=amd64] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable"
	@bash ./install/run-helper installif docker-ce
	@# force returns success if group exists already
	sudo groupadd --force docker
	sudo usermod --append --groups docker $(USER)
	ln -sf "$$(which docker)" flags/docker

flags/docker-compose:
	curl --location --silent --show-error https://github.com/docker/compose/releases/download/$(compose-version)/docker-compose-Linux-x86_64 -o $(HOME)/bin/docker-compose
	chmod +x $(HOME)/bin/docker-compose
	ln -sf $(HOME)/bin/docker-compose flags

flags/postman: opt-dir
	wget --output-document "/tmp/postman.tar.gz" https://dl.pstmn.io/download/latest/linux64
	tar --directory "/opt" --extract --gzip --file  "/tmp/postman.tar.gz"
	sudo ln -sf "/opt/Postman/app/Postman" "/usr/local/bin/postman"
	rm -f "/tmp/postman.tar.gz"
	ln -sf "/usr/local/bin/postman" "flags"

flags/gestures:
	@# Only known to work with libinput on Ubuntu 18.04
	git clone https://github.com/bulletmark/libinput-gestures.git "/tmp/libinput-gestures"
	sudo usermod --append --groups input "$(USER)"
	sudo make -C "/tmp/libinput-gestures" install
	@bash ./install/run-helper link "libinput-gestures.conf" "$(XDG_CONFIG_HOME)/libinput-gestures.conf"
	ln -sf "/usr/bin/libinput-gestures-setup" "flags/gestures"

flags/hall-monitor: apt.jq apt.lxrandr apt.x11-xserver-utils
	mkdir --parents "$(XDG_CONFIG_HOME)/hall-monitor"
	@sudo bash ./install/run-helper link "hall-monitor/hall-monitor" "/usr/local/bin/hall-monitor"
	@sudo bash ./install/run-helper link "hall-monitor/95-hall-monitor.rules" "/etc/udev/rules.d/95-hall-monitor.rules"
	@sudo bash ./install/run-helper link "hall-monitor/hall-monitor.service" "/etc/systemd/user/hall-monitor.service"
	systemctl --user enable hall-monitor.service
	systemctl --user start hall-monitor.service
	ln -sf "/usr/local/bin/hall-monitor" "flags"

flags/libinput:
	sudo mkdir --parents "/etc/X11/xorg.conf.d"
	@sudo bash ./install/run-helper link "40-libinput.conf" "/etc/X11/xorg.conf.d/40-libinput.conf"
	ln -sf "/etc/X11/xorg.conf.d/40-libinput.conf" "flags"

opt-dir: flags/opt-dir
flags/opt-dir:
	sudo groupadd optgroup
	sudo usermod -aG optgroup gurpreet
	sudo usermod -aG optgroup root
	sudo chown -R root:optgroup /opt
	sudo chmod -R g+rw /opt
	ln -sf /opt flags/opt-dir
