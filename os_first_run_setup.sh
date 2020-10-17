##------------------------------------------------------------------------------------------
## SECTION: Base Variable Declarations
##------------------------------------------------------------------------------------------
GREEN=`tput setaf 10`
RED=`tput setaf 1`
BLUE=`tput setaf 33`
YELLOW=`tput setaf 11`
NC=`tput sgr0`

INPUT_ARGUMENTS=( $@ )
SOFTWARE=(  )
DEV_TOOLS="False"
SETUP="False"
CURRENT_DIRECTORY=""

##------------------------------------------------------------------------------------------
## SECTION: Function Declarations
##------------------------------------------------------------------------------------------

## Changes the colour of the passed text
print_color(){
	if [ "$2" == "RED" ]; then
		printf "${RED}${1}${NC}\n"
	elif [ "$2" == "YELLOW" ]; then
		printf "${YELLOW}${1}${NC}\n"
	elif [ "$2" == "BLUE" ]; then
		printf "${BLUE}${1}${NC}\n"
	elif [ "$2" == "GREEN" ]; then
		printf "${GREEN}${1}${NC}\n"
	else
		printf "$1\n"
	fi
	#print_color "Saluton!" "BLUE"
}

# Determines whether the system has a particular command as a Bash script
have_prog() {
    [ -x "$(which $1)" ]
}

# Install the software based on the os
install_on_os() {
	# Find the linux distribution name
	LINUX_DISTRIB=`hostnamectl | grep "Operating System: "`
	print_color "${LINUX_DISTRIB}" "BLUE"
	
	# Determine which distribution's installer to use
	if have_prog dnf ; then 
		fedora_install
	elif have_prog apt-get ; then 
		ubuntu_install
	elif have_prog pacman ; then 
		manjaro_install
	else
		print_color "NO PACKAGE MANAGER FOUND!" "RED"
		exit 2
	fi
}

# Install the software with Flatpak
install_with_flatpak() {
	# Ensure the required repo is added for use
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	sudo flatpak install flathub ${SOFTWARE}
}

# Provides a brief introduction on the script and what it will do
script_prompt() {
	print_color "##----------------------------------------------------------------------------------------" "BLUE" 
	print_color "NOTE: The following sections will require you to provide prompts at regular intervals." "BLUE"
	print_color "      Please be sure to input your password and the relevant (Y/N) inputs should you " "BLUE" 
	print_color "      encounter them. " "BLUE"
	print_color "      " "BLUE"
	print_color "      The time this script will take to complete is entirely dependent on your " "BLUE"
	print_color "      system and its internet connection." "BLUE"
	print_color "##----------------------------------------------------------------------------------------" "BLUE"
}
# Provides a starting line
script_start() {
	print_color "##-----------------------------------------START------------------------------------------" "BLUE"
}
# Provides an ending line
script_ending() {
	print_color "##------------------------------------------END-------------------------------------------" "BLUE"
}



# Nvidia Drivers Installation
download_nvidia_drivers() {
	if has_prog dnf ; then
		# Follow the instructions on: 
		# https://rpmfusion.org/Howto/NVIDIA#Current_GeForce.2FQuadro.2FTesla
		# for Fedora Installation
		
		# The plain Nvidia Drivers
		sudo dnf update -y # and reboot if you are not on the latest kernel
		sudo dnf install akmod-nvidia # rhel/centos users can use kmod-nvidia instead
		sudo dnf install xorg-x11-drv-nvidia-cuda #optional for cuda/nvdec/nvenc support

		# The CUDA Nvidia Drivers
		sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora32/x86_64/cuda-fedora32.repo
		sudo dnf install xorg-x11-drv-nvidia-cuda
		sudo dnf clean all
		sudo dnf module disable nvidia-driver
		sudo dnf -y install cuda

		# Install Vulkan
		sudo dnf install vulkan

		# For CUDA accellerated ffmpeg
		sudo dnf install xorg-x11-drv-nvidia-cuda-libs

		# Install the latest/Beta driver
		sudo dnf install "kernel-devel-uname-r == $(uname -r)"
		sudo dnf update -y
		sudo dnf --releasever=$(rpm -R %fedora) install akmod-nvidia xorg-x11-drv-nvidia --nogpgcheck

		# In order to enable video acceleration support for your player and if your NVIDIA card 
		# is recent enough (Geforce 8 and later is needed). You can install theses packages 
		sudo dnf install vdpauinfo libva-vdpau-driver libva-utils nvidia-smi

	elif has_prog apt-get ; then
		# To install the required nvidia drivers first display a list of the available drivers
		sudo ubuntu-drivers devices

		# Autoinstall the drivers
		sudo ubuntu-drivers autoinstall

		# Set to use the GPU (should actually occur after a restart, but let's try)
		print_color "(Should actually be done after reboot, but let's try)" "YELLOW"
		print_color "sudo prime-select Nvidia" "YELLOW"
		sudo prime-select Nvidia
		#sudo prime-select intel

		# Restart the computer for changes to take effect
		sudo shutdown -r now

	elif has_prog pacman ; then
		# Install the latest driver on Manjaro
		LATEST_DRIVER=video-nvidia-44xx

		# Find the latest driver and install it
		LATEST_DRIVER=$( mhwd -l | grep -o "video-nvidia-[+a-zA-Z0-9\-]" )
		LATEST_DRIVER=${LATEST_DRIVER[@]}
		LATEST_DRIVER=$[LATEST_DRIVER[0]]

		sudo mhwd -i pci ${LATEST_DRIVER}
	else
		print_color "Can't find Package Manager; Can't install Nvidia Drivers!" "RED"
	fi
}
install_nvidia_drivers() {
	script_start
	print_color "INSTALLING NVIDIA PROPRIETARY DRIVER:" "BLUE"
	print_color "" "BLUE"
	download_nvidia_drivers
	script_ending
}


# Help Menu
print_help() {
	script_start
	print_color "./os_first_run_setup.sh [arg]" "YELLOW"
	print_color ""
	print_color "ARGUMENT:\t\tDESCRIPTION:" "YELLOW"
	print_color "\t--help             \tShows this Help menu" "YELLOW"
	print_color "\t--recording        \tInstalls basic recording software" "YELLOW"
    print_color "\t--basic            \tInstalls the some basic rpm repository software" "YELLOW"
    print_color "\t--advanced         \tInstalls the more advanced rpm repository software" "YELLOW"
    print_color "\t--dev              \tInstalls software useful for developers (Flatpaks)" "YELLOW"
    print_color "\t--mega             \tInstalls the MegaSync Linux client" "YELLOW"
	print_color "\t--nvidia           \tInstalls the MegaSync Linux client" "YELLOW"
    print_color "\t--all              \tInstalls all above options" "YELLOW"
	script_ending
}



# Basic Software
install_basic_software() {
	script_start
    # Install the normal software not yet on Flatpak
	SOFTWARE=( dropbox nautilus-dropbox gstreamer1-plugins-base \
	gstreamer1-plugins-good gstreamer1-plugins-ugly gstreamer1-plugins-bad-free \
	gstreamer1-plugins-bad-free gstreamer1-plugins-bad-freeworld \
	gstreamer1-plugins-bad-free-extras libdvdread libdvdnav lsdvd ffmpeg tlp \
	guvcview chromium gedit clamTk google-chrome-stable flatpak \
	gnome-software-plugin-flatpak clamtk clamav)
    install_on_os

	# Install the flatpaks
    SOFTWARE=( org.gnome.Boxes org.libreoffice.LibreOffice com.leinardi.gwe \
	com.skype.Client org.kde.okular com.slack.Slack org.kde.ark us.zoom.Zoom \
	com.skype.Client org.gnome.Photos org.onlyoffice.desktopeditors \
	org.onlyoffice)
    install_with_flatpak
	script_ending
}



# Advanced Software
install_advanced_software() {
	script_start
	# Install the normal software not yet on Flatpak
	SOFTWARE=( gnome-tweak-tool wine icedtea-web java-openjdk p7zip \
	p7zip-plugins unrar redshift GIMP VirtualBox ntfs-3g qbittorrent pdfmod )
    install_on_os

	# Install the flatpaks
	SOFTWARE=( org.inkscape.Inkscape org.kde.krita org.blender.Blender \
	org.shadowsocks.qt5client com.github.junrrein.PDFSlicer \
	org.inkscape.Inkscape )
	install_with_flatpak
	script_ending

}



# Recording Tools
install_recording_software() {
	script_start
    # Add the selection of normal software to install and intall them based on
	# the distribution
	SOFTWARE=( pulseeffects Kamoso cheese )
	install_on_os
    
	# Add the selection of flatpak software to install and install them with
	# flatpak
	update_flatpaks
	SOFTWARE=( com.obsproject.Studio com.discordapp.Discord \
	org.audacityteam.Audacity org.openshot.OpenShot org.olivevideoeditor.Olive )
    install_with_flatpak
	script_ending
}


# Dev Tools
install_dev_software() {
	## This will provide a prompt and the installation of the required software
	script_start
	print_color "INSTALLING DEVELOPER TOOLS:" "BLUE"
	print_color " " "BLUE"
	# Takes care of downloading and installing the developer tools based on the
	# unix distro
	DEV_TOOLS="True"
	download_dev_tools
	DEV_TOOLS="False"
	script_ending
}
download_dev_tools() {
	# Should it be necessary, install Dev tools based on the OS
	if [ ${DEV_TOOLS} == "True" ] ; then 
		if have_prog dnf ; then 
			sudo dnf groupinstall "Development Tools"
		elif have_prog apt-get ; then 
			sudo apt-get install build-essential 
		elif have_prog pacman ; then 
			sudo pacman -S base-devel
		else
			print_color "Can't Identify Distribution. Can't install Developer Packages!" "RED"
		fi
	fi
}



# Mega Cloud Client
download_mega() {

	# Install Mega based on the OS
	if have_prog dnf ; then
		#MegaSync
		# Save the current directory
		CURRENT_DIRECTORY=$( pwd )
		# Download Mega and the Nautilus extension (and everything else)
		cd /tmp/
		wget --no-verbose --no-parent --no-clobber --recursive --level=1 --no-directories -erobots=off https://mega.nz/linux/MEGAsync/Fedora_$(rpm -E %fedora)/x86_64
		
		# Install Mega
		MEGASYNC_NAME=$( ls -S | grep -o "megasync-[0-9\.]\+-[0-9\.]\+[a-zA-Z0-9_]\+.rpm" )
		NAUTILUS_NAME=$( ls -S | grep -o "nautilus-megasync-[0-9\.]\+-[0-9\.]\+[a-zA-Z0-9_]\+.rpm" )
		#sudo rpm -i ${MEGASYNC_NAME} ${NAUTILUS_NAME}

		# Install the MEGA GUI client
		MEGASYNC_NAME=${MEGASYNC_NAME[@]}
		for arg in ${MEGASYNC_NAME} ; do
			if [ -f ${arg} ] ; then
				sudo rpm -i ${arg}
			fi		
		done

		# Install the MEGA GUI client
		NAUTILUS_NAME=${NAUTILUS_NAME[@]}
		for arg in ${NAUTILUS_NAME} ; do
			if [ -f ${arg} ] ; then
				sudo rpm -i ${arg}
			fi		
		done

		# Return to the saved directory
		cd ${CURRENT_DIRECTORY}

	elif have_prog apt-get ; then
		#MegaSync
		# Save the current directory
		CURRENT_DIRECTORY=$( pwd )
		# Download Mega and the Nautilus extension
		cd /tmp/
		wget --no-clobber https://mega.nz/linux/MEGAsync/xUbuntu_{18..99}.{00..99}/amd64/megasync-xUbuntu_{18..99}.{00..99}_amd64.deb
		wget --no-clobber https://mega.nz/linux/MEGAsync/xUbuntu_{18..99}.{00..99}/x86_64/nautilus-megasync-xUbuntu_{18..99}.{00..99}_amd64.deb

		# Install Mega
		MEGASYNC_NAME=$( ls -S | grep -w "megasync-[0-9\.]\+-[0-9\.]\+[a-zA-Z0-9_]\+.rpm" )
		NAUTILUS_NAME=$( ls -S | grep -w "nautilus-megasync-[0-9\.]\+-[0-9\.]\+[a-zA-Z0-9_]\+.rpm" )

		# Install the MEGA GUI client
		MEGASYNC_NAME=${MEGASYNC_NAME[@]}
		for arg in ${MEGASYNC_NAME} ; do
			if [ -f ${arg} ] ; then
				sudo dpkg -i ${arg}
			fi		
		done

		# Install the MEGA GUI client
		NAUTILUS_NAME=${NAUTILUS_NAME[@]}
		for arg in ${NAUTILUS_NAME} ; do
			if [ -f ${arg} ] ; then
				sudo dpkg -i ${arg}
			fi		
		done

		sudo apt-get -f install

		# Return to the saved directory
		cd ${CURRENT_DIRECTORY}
	elif have_prog pacman ; then
		#MegaSync
		#Download and Install Mega
		sudo yaourt -S megasync
		sudo yaourt -S nautilus-megasync
	fi
}
install_mega() {
	script_start
	print_color "INSTALLING MEGA CLOUD CLIENT:" "BLUE"
	print_color "" "BLUE"
	download_mega
	script_ending
}



## OS Specific Functions
# Setup Fedora with the basics required to install the software
fedora_setup() {
	# Ensure that flatpak is installed as well as other
	# required software/repos for Fedora usage

	# Exit the function if already setup
	if [ ${SETUP} == "True" ] ; then
		return
	fi

	# Add the necessary repos	
	sudo dnf install --nogpgcheck http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
	sudo dnf install --nogpgcheck http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
	sudo dnf install fedora-workstation-repositories
	sudo dnf config-manager --set-enabled google-chrome
	
	# Enable different themes to be used
	sudo dnf install gnome-tweak-tool
	sudo dnf install chrome-gnome-shell
	
	# Find the list of installable gtk themes
	GTK_THEMES=$( dnf search gtk | grep -o "[+0-9.a-zA-Z\-]\+.noarch" )
	sudo dnf install ${GTK_THEMES}

	# Find the list of installable cursor themes
	CURSOR_THEMES=$( dnf search cursor-theme | grep -o "[+0-9.a-zA-Z\-]\+.noarch" )
	sudo dnf install ${CURSOR_THEMES}

	# Find the list of installable icon themes
	ICON_THEMES=$( dnf search icon-theme | grep -o "[+0-9.a-zA-Z\-]\+.noarch" )
	sudo dnf install ${ICON_THEMES}

	# Find the list of installable shell themes
	SHELL_THEMES=$( dnf search shell-theme | grep -o "[+0-9.a-zA-Z\-]\+.noarch" )
	sudo dnf install ${SHELL_THEMES}

	# Remove any software that wasn't supposed to be installed here as they will
	# be installed with flatpak
	sudo dnf remove gimp -y

	SETUP="True"
}

# Installs software on Fedora and Debian-based Systems
fedora_install() {	
	# Install the actual software
	fedora_setup	
	fedora_update
	sudo dnf install ${SOFTWARE}
	sudo dnf clean all
}

# Update all installed packages
fedora_update() {
	# Update the software as necessary
	sudo dnf update
	sudo dnf upgrade
}

# Install software on Ubuntu and Ubuntu-based Systems
ubuntu_setup() {
	# Ensure that flatpak is installed as well as other
	# required software/repos for Ubuntu usage
	
	# Exit the function if already setup
	if [ ${SETUP} == "True" ] ; then
		return
	fi
	
	# Install the necessities
	ubuntu_update

	# Enable different themes to be used
	sudo apt install flatpak
	sudo apt-get install gnome-tweak-tool
	sudo apt-get install chrome-gnome-shell
	
	# Find the list of installable gtk themes
	GTK_THEMES=$( apt-get search gtk | grep -o "[+0-9.a-zA-Z\-]\+.noarch" )
	sudo apt-get install ${GTK_THEMES}

	# Find the list of installable cursor themes
	CURSOR_THEMES=$( apt-get search cursor-theme | grep -o "[+0-9.a-zA-Z\-]\+.noarch" )
	sudo apt-get install ${CURSOR_THEMES}

	# Find the list of installable icon themes
	ICON_THEMES=$( apt-get search icon-theme | grep -o "[+0-9.a-zA-Z\-]\+.noarch" )
	sudo apt-get install ${ICON_THEMES}

	# Find the list of installable shell themes
	SHELL_THEMES=$( apt-get search shell-theme | grep -o "[+0-9.a-zA-Z\-]\+.noarch" )
	sudo apt-get install ${SHELL_THEMES}
	
	# Install Chrome on Ubuntu
	CURRENT_DIRECTORY=$( pwd )
	cd /tmp/
	wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	#sudo apt-get install ./google-chrome-stable_current_amd64.deb
	cd ${CURRENT_DIRECTORY}

	SETUP="True"
}

# Installs software on Ubuntu and Ubuntu-based Systems
ubuntu_install() {
	ubuntu_setup
	ubuntu_update
	sudo apt-get install ${SOFTWARE}
}

# update all installed packages
ubuntu_update() {
	sudo apt-get update 
	sudo apt-get upgrade
}

# Install software on Majaro and other arch-based systems
majaro_setup() {
	# Ensure that Flatpak is installed as well as other
	# required software/repos for Manjaro usage
	
	# Exit the function if already setup
	if [ ${SETUP} == "True" ] ; then
		return
	fi
	
	# Install the necessities
	sudo pacman-mirrors --fasttrack
	sudo pacman install flatpak
	sudo pacman -S aspell-en libmythes mythes-en languagetool
	if [${DEV_TOOLS}="True"] ; then 
		sudo pacman -S groupinstall "Development Tools"
	fi
	manjaro_update
	sudo systemctl --failed
	
	# Install Chrome
	sudo pacman -S git
	git https://aur.archlinux.org/google-chrome.git
	cd Downloads
	cd google-chrome
	makepkg -s
	sudo pacman -U google-chrome*.tar.xz
	cd ..
	rm -rf google-chrome

	SETUP="True"
}

# installs software on Manjaro and Arch-based Systems
manjaro_install() {
	# Install the required software on Manjaro
	setup_majaro
	manjaro_update
	sudo pacman -S ${SOFTWARE}
}

# Update all installed packages
majaro_update() {
	# Update the Manjaro installation
	sudo pacman -Syu
}

##------------------------------------------------------------------------------------------
## SECTION: Program Logic
##------------------------------------------------------------------------------------------ 
for arg in ${INPUT_ARGUMENTS}
do
	case $arg in 
	"--recording" )
		script_prompt
		install_recording_software		# WORKS
		exit
	;;
	"--basic" )
		script_prompt
		install_basic_software			# WORKS
		exit
	;;
	"--advanced" )
		script_prompt
		install_advanced_software		# WORKS
		exit
	;;
	"--dev" )
		script_prompt	
		install_dev_software			# WORKS
		exit		 
	;;
	"--mega" )
		script_prompt
		install_mega					# WORKS
		exit
	;;
	"--nvidia" )
		script_prompt
		install_nvidia_drivers			# SHOULD WORK
		exit
	;;
	"--all" )
		script_prompt					# SHOULD WORK
		install_basic_software
		install_advanced_software
		install_recording_software
		install_dev_software
		install_mega
		exit
	;;
	* )
		print_help 						# WORKS
		exit		
	;;
	esac
done