#!/usr/bin/env nu

# arch linux setup script for surface laptop 4

def ensure_yay [] {
    if (which yay | is-empty) {
        print "yay not found, installing..."
        
        sudo pacman -S --needed git base-devel --noconfirm
        
        cd /tmp
        
        if ("/tmp/yay" | path exists) {
            sudo rm -rf yay
        }
        
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        
        print "yay installed successfully"
    } else {
        print "yay is already installed"
    }
}

def install_packages [] {
    let args = [
        "-S"
        "gnome" "firefox" "ani-cli" "flatpak" "openvpn-update-systemd-resolved"
        "arch-update" "bottles" "cpupower-gui" "surface-control"
        "extension-manager" "google-chrome" "auto-cpufreq"
        "heroic-games-launcher-bin" "jetbrains-toolbox"
        "minecraft-launcher" "python-pipx" "lunar-client" "openvpn-update-systemd-resolved"
        "pipes.sh" "spotify" "floorp-bin" "helium-browser-bin" "vesktop-bin" "thermald"
        "visual-studio-code-bin" "webapp-manager" "yt-dlp" "zen-browser-bin" "systemd-resolvconf"
        "ghostty" "rclone" "meson" "minecraft-launcher" "ghostty-shell-integration"
        "ghostty-terminfo" "proton-ge-custom-bin" "unzip" "tar" "zip" "thefuck" "extension-manager"
        "arch-update" "github-cli" "libreoffice-fresh" "gimp" "brave-bin" "wireguard-tools" "steam" "mold"
        "proton-pass-bin" "proton-authenticator-bin" "proton-mail-bin"
        "--sudoloop"
        "--answerdiff=None"
        "--answeredit=None"
        "--answerclean=None"
        "--answerupgrade=None"
        "--needed"
        "--noconfirm"
    ]
    
    print ...$args

    ^yay ...$args
}

def setup_linux_surface [] {
    print "Setting up linux-surface..."
    
    curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | sudo pacman-key --add -
    
    sudo pacman-key --finger 56C464BAAC421453
    sudo pacman-key --lsign-key 56C464BAAC421453
    
    let pacman_conf = open /etc/pacman.conf
    if not ($pacman_conf | str contains "linux-surface") {
        print "Adding linux-surface repository to /etc/pacman.conf"
        "
[linux-surface]
Server = https://pkg.surfacelinux.com/arch/
" | sudo tee -a /etc/pacman.conf | ignore
    }
    
    sudo pacman -Sy --noconfirm
    sudo pacman -S --noconfirm linux-surface linux-surface-headers iptsd
    sudo pacman -S --noconfirm linux-firmware-intel
    sudo pacman -S --noconfirm linux-surface-secureboot-mok
    
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    print "linux-surface setup complete"
}

def setup_jvm [] {
    print "Setting up JVM with SDKMAN..."
    
    bash -c 'curl -s "https://get.sdkman.io" | bash'
    
    let bashrc_path = $"($nu.home-path)/.bashrc"
    if ($bashrc_path | path exists) {
        let bashrc_content = open $bashrc_path
        if not ($bashrc_content | str contains "SDKMAN_DIR") {
            print "Adding SDKMAN to .bashrc"
            $'export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
' | save -a $bashrc_path
        }
    }
    
    bash -c $'
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        sdk version
        sdk install java 21.0.9-tem
        sdk install kotlin
        sdk install gradle
        sdk install maven
    '
    
    let config_path = $"($nu.config-path)"
    let config_content = open $config_path
    let java_home_line = $'$env.JAVA_HOME = $"($nu.home-path)/.sdkman/candidates/java/21.0.9-tem"'
    
    if not ($config_content | str contains "JAVA_HOME") {
        print "Adding JAVA_HOME to config.nu"
        $"\n($java_home_line)\n" | save -a $config_path
    }
    
    print "JVM setup complete"
}

def setup_rust [] {
    print "Setting up Rust..."
    
    # Install rustup
    bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
    
    let config_path = $"($nu.config-path)"
    let config_content = open $config_path
    let cargo_env_line = $'source $"($nu.home-path)/.cargo/env.nu"'
    
    if not ($config_content | str contains ".cargo/env.nu") {
        print "Adding Cargo environment to config.nu"
        $"\n($cargo_env_line)\n" | save -a $config_path
    }
    
    print "Rust setup complete"
}

def setup_homebrew [] {
    print "Setting up Homebrew..."
    
    bash -c '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    
    let config_path = $"($nu.config-path)"
    let config_content = open $config_path
    let brew_path_line = '$env.PATH = ($env.PATH | split row (char esep) | prepend "/home/linuxbrew/.linuxbrew/bin")'
    
    if not ($config_content | str contains "linuxbrew") {
        print "Adding Homebrew to PATH in config.nu"
        $"\n($brew_path_line)\n" | save -a $config_path
    }
    
    /home/linuxbrew/.linuxbrew/bin/brew install gcc
    
    print "Homebrew setup complete"
}

def install_wine_sober [] {
    print "Installing Wine and Sober..."
    
    sudo pacman -S --noconfirm wine
    flatpak install -y https://sober.vinegarhq.org/sober.flatpakref
    
    print "Wine and Sober installed"
}

def remove_terminals [] {
    print "Removing unnecessary terminals..."
    
    sudo pacman -R --noconfirm gnome-terminal gnome-console alacritty
    
    print "Terminal cleanup complete"
}

def install_gnome_extensions [] {
    print "Installing GNOME extensions..."
    
    pipx install gnome-extensions-cli --system-site-packages
    
    gext install appindicatorsupport@rgcjonas.gmail.com
    gext install blur-my-shell@aunext
    gext install dash-to-dock@micxgx.gmail.com
    gext install fullscreen-to-empty-workspace2@corgijan.dev
    gext install lockscreen-extension@pratap.fastmail.fm
    gext install open-desktop-location@laura.media
    
    print "GNOME extensions installed"
}

def run_step [name: string, step: closure] {
    try {
        do $step
        null
    } catch { |err|
        {function: $name, error: ($err.msg? | default ($err | to text))}
    }
}

def main [] {
    if (is-admin) {
        error make {
            msg: 'the script is not to be ran as admin'
        }
    }
    
    print "Starting system setup..."
    
    mut errors = []
    
    # ensure_yay
    let step_error = (run_step "ensure_yay" { ensure_yay })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    # install_packages
    let step_error = (run_step "install_packages" { install_packages })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    # setup_linux_surface
    let step_error = (run_step "setup_linux_surface" { setup_linux_surface })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    # setup_jvm
    let step_error = (run_step "setup_jvm" { setup_jvm })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    # setup_rust
    let step_error = (run_step "setup_rust" { setup_rust })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    # setup_homebrew
    let step_error = (run_step "setup_homebrew" { setup_homebrew })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    # install_wine_sober
    let step_error = (run_step "install_wine_sober" { install_wine_sober })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    # remove_terminals
    let step_error = (run_step "remove_terminals" { remove_terminals })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    # install_gnome_extensions
    let step_error = (run_step "install_gnome_extensions" { install_gnome_extensions })
    if $step_error != null {
        $errors = ($errors | append $step_error)
    }
    
    print "\n========================================="
    print "Setup complete!"
    print "=========================================\n"
    
    if ($errors | length) > 0 {
        print "The following errors occurred during setup:\n"
        for error in $errors {
            print $"Function: ($error.function)"
            print $"Error: ($error.error)\n"
        }
    } else {
        print "All functions completed successfully!"
    }
    
    print "\nPlease reboot your system to complete the setup."
}