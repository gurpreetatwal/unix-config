
# default XDG_DATA_HOME to ~/.local/share and XDG_CONFIG_HOME to ~/.config if not set
# @see https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#basics
XDG_DATA_HOME ?= $(HOME)/.local/share
XDG_CONFIG_HOME ?= $(HOME)/.config

tmux: version ?= 2.6
maven: version ?= 3.5.2
gradle: version ?= 4.8.1
stterm: version ?= 0.8.1
flags/docker-compose: compose-version ?= 1.23.1
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
gpg: flags/gpg
polybar: flags/polybar
gestures: flags/gestures
hall-monitor: flags/hall-monitor
libinput: flags/libinput
redshift: flags/redshift
intel-backlight: flags/intel-backlight
fonts-hack: flags/fonts-hack

# Fixes for firefox when using dark themes and for scrolling using a touchscreen
# Theme fix from https://wiki.archlinux.org/index.php/Firefox#Unreadable_input_fields_with_dark_GTK.2B_themes
# Scrolling fix from https://wiki.gentoo.org/wiki/Firefox#Xinput2_scrolling
firefox-fix:
	sudo sed -i 's/Exec=.*firefox/Exec=env MOZ_USE_XINPUT2=1 GTK_THEME=Adwaita:light firefox/' /usr/share/applications/firefox.desktop

pgcli: pip3 apt.python3-dev apt.libpq-dev apt.libevent-dev
	pip3 install --user --upgrade pgcli
	mkdir --parents "$(XDG_CONFIG_HOME)/pgcli"
	@bash ./install/run-helper link pgcli $(XDG_CONFIG_HOME)/pgcli/config
	-ln -sf "$$(which pgcli)" "flags"

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

flags/pip2:
	curl --location --silent --show-error https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
	python2 /tmp/get-pip.py --user
	ln -sf "$(XDG_DATA_HOME)/bin/pip2" "flags"

flags/pip3:
	curl --location --silent --show-error https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
	python3 /tmp/get-pip.py --user
	ln -sf "$(XDG_DATA_HOME)/bin/pip3" "flags"

flags/i3: apt.i3 apt.i3lock apt.xautolock apt.rofi fonts-hack
	mkdir --parents "$(XDG_CONFIG_HOME)/i3"
	mkdir --parents "$(XDG_CONFIG_HOME)/i3status"
	mkdir --parents "$(XDG_CONFIG_HOME)/rofi"
	@bash ./install/run-helper link "i3.conf" "$(XDG_CONFIG_HOME)/i3/config"
	@bash ./install/run-helper link "i3status.conf" "$(XDG_CONFIG_HOME)/i3status/config"
	@bash ./install/run-helper link "rofi.rasi" "$(XDG_CONFIG_HOME)/rofi/config.rasi"
	ln -sf "$(XDG_CONFIG_HOME)/i3/config" "flags/i3"

flags/polybar: repository = https://github.com/jaagr/polybar
flags/polybar:
	sudo apt install --no-install-recommends \
	  libcairo2-dev \
	  libxcb1-dev \
	  libxcb-util0-dev \
	  libxcb-randr0-dev \
	  libxcb-composite0-dev \
	  python-xcbgen \
	  xcb-proto \
	  libxcb-image0-dev \
	  libxcb-ewmh-dev \
	  libxcb-icccm4-dev \
	  libxcb-cursor-dev \
	  libjsoncpp-dev \
	  libpulse-dev \
	  libnl-genl-3-dev
	@# get latest tagged version
	$(eval version = $(shell git ls-remote --tags --refs $(repository) | awk -F"[\t/]" 'END{print $$NF}'))
	$(eval file = polybar-$(version).tar)
	wget --directory-prefix="/tmp" --timestamping "$(repository)/releases/download/$(version)/$(file)"
	tar --directory "/tmp" --extract --file  "/tmp/$(file)"
	mkdir --parents "/tmp/polybar/build"
	cd "/tmp/polybar/build" && cmake ..
	make -C "/tmp/polybar/build" -j$$(nproc)
	sudo make -C "/tmp/polybar/build" install
	mkdir --parents "$(XDG_CONFIG_HOME)/polybar"
	@bash ./install/run-helper link "polybar.ini" "$(XDG_CONFIG_HOME)/polybar/config"
	@bash ./install/run-helper link "install/launch-polybar.sh" "$(XDG_CONFIG_HOME)/polybar/launch.sh"
	-ln -sf "$$(which polybar)" "flags"

flags/node:
	curl --location https://git.io/n-install | N_PREFIX=$(XDG_DATA_HOME)/nodejs bash -s -- -n
	@bash ./install/run-helper link "tern-project" "$(HOME)/.tern-project"
	ln -sf $(XDG_DATA_HOME)/nodejs/bin/node flags/node

flags/rust:
	$(eval tmp = $(shell mktemp --dry-run --tmpdir="/tmp" rustup-init-XXX))
	wget -O $(tmp) https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
	chmod a+x $(tmp)
	exec $(tmp) --verbose --no-modify-path -y
	-rm $(tmp)
	ln -sf $(HOME)/.cargo/bin/rustc flags/rust

flags/java:
	@bash ./install/run-helper installif default-jdk
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
flags/alacritty: fonts-hack
	@# get latest tagged version
	$(eval version = $(shell git ls-remote --tags --refs $(repository) | grep -P -o '(v\d+\.\d+\.\d+)$$' | sort | tail -1))
	$(eval file = Alacritty-$(version)-ubuntu_18_04_amd64.deb)
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

flags/docker: flags/docker-credential-ecr-login
	sudo apt-key add install/docker.gpg
	sudo add-apt-repository --update "deb [arch=amd64] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable"
	@bash ./install/run-helper installif docker-ce
	@# force returns success if group exists already
	sudo groupadd --force docker
	sudo usermod --append --groups docker $(USER)
	ln -sf "$$(which docker)" flags/docker

flags/docker-credential-ecr-login:
	@bash ./install/run-helper git-clone "https://github.com/awslabs/amazon-ecr-credential-helper" "/tmp/amazon-ecr-credential-helper"
	make -C "/tmp/amazon-ecr-credential-helper" docker
	cp "/tmp/amazon-ecr-credential-helper/bin/local/docker-credential-ecr-login" "$(HOME)/bin"
	mkdir -p "$(HOME)/.docker"
	@bash ./install/run-helper link "install/docker-config.json" "$(HOME)/.docker/config.json"
	ln -sf "$(HOME)/bin/docker-credential-ecr-login" "flags"

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

flags/gpg: apt.scdaemon
	@sudo bash ./install/run-helper link "install/70-yubikey.rules" "/etc/udev/rules.d/70-yubikey.rules"
	mkdir "$(HOME)/.gnupg"
	chmod 700 "$(HOME)/.gnupg"
	@sudo bash ./install/run-helper link "gpg.conf" "$(HOME)/.gnupg/gpg.conf"
	@sudo bash ./install/run-helper link "gpg-agent.conf" "$(HOME)/.gnupg/gpg-agent.conf"

flags/gestures: apt.libinput-tools
	@# Only known to work with libinput on Ubuntu 18.04
	@bash ./install/run-helper git-clone \
	  "https://github.com/bulletmark/libinput-gestures.git" \
	  "/tmp/libinput-gestures"
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
	ln -sf "/etc/X11/xorg.conf.d/40-libinput.conf" "flags/libinput"

flags/redshift:
	sudo apt-get install --no-install-recommends redshift-gtk
	command -v debfoster && sudo debfoster redshift-gtk
	@sudo bash ./install/run-helper link "redshift.conf" "$(XDG_CONFIG_HOME)/redshift.conf"
	-ln -sf "$$(which redshift)" "flags"

flags/intel-backlight: apt.xserver-xorg-video-intel apt.xbacklight
	@sudo bash ./install/run-helper link "install/20-intel-backlight.conf" "/etc/X11/xorg.conf.d/20-intel-backlight.conf"
	-ln -sf "/etc/X11/xorg.conf.d/20-intel-backlight.conf" "flags/intel-backlight"

flags/fonts-hack: repository = https://github.com/source-foundry/Hack
flags/fonts-hack:
	@# get latest tagged version
	$(eval version = $(shell git ls-remote --tags --refs $(repository) | awk -F"[\t/]" 'END{print $$NF}'))
	$(eval file = Hack-$(version)-ttf.zip)
	wget --directory-prefix="/tmp" --timestamping "$(repository)/releases/download/$(version)/$(file)"
	wget --directory-prefix="/tmp" --timestamping "https://raw.githubusercontent.com/source-foundry/Hack/$(version)/config/fontconfig/45-Hack.conf"
	unzip "/tmp/$(file)" -d "/tmp/hack"
	sudo mv /tmp/hack/ttf/* "/usr/local/share/fonts"
	sudo mv "/tmp/45-Hack.conf" "/etc/fonts/conf.d"
	fc-cache -f -v
	-ln -sf "$$(fc-list | grep Hack-Regular | awk -F : '{print $$1}')" "flags/fonts-hack"

opt-dir: flags/opt-dir
flags/opt-dir:
	sudo groupadd optgroup
	sudo usermod -aG optgroup gurpreet
	sudo usermod -aG optgroup root
	sudo chown -R root:optgroup /opt
	sudo chmod -R g+rw /opt
	ln -sf /opt flags/opt-dir
