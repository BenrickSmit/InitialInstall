##------------------------------------------------------------------------------------------
## SECTION: Base Variable Declarations
##------------------------------------------------------------------------------------------
GREEN=`tput setaf 10`
RED=`tput setaf 1`
BLUE=`tput setaf 33`
YELLOW=`tput setaf 11`
NC=`tput sgr0`

INPUT_ARGUMENTS=( $@ )
INSTALL_COMMAND="dnf"
DEFAULT_REP="rpm"
SOFTWARE=(  )
DEV_TOOLS="False"

#MegaSync
# cd /tmp/
# wget https://mega.nz/linux/MEGAsync/xUbuntu_14.04/i386/megasync_2.0.0_i386.deb
# cd /tmp/
# wget https://mega.nz/linux/MEGAsync/xUbuntu_14.04/i386/nautilus-megasync_2.0.0_i386.deb

##------------------------------------------------------------------------------------------
## SECTION: Function Declarations
##------------------------------------------------------------------------------------------
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
}
#print_color "Saluton!" "BLUE"

have_prog() {
    [ -x "$(which $1)" ]
}

print_help() {
	print_color "-------------------------------HELP-------------------------------" "YELLOW"
	print_color "-h Shows this Help menu" "YELLOW"
	print_color "-s Installs the flatpak version of Steam" "YELLOW"
	print_color "-y Installs recording software" "YELLOW"
        print_color "-b Installs the basic software" "YELLOW"
        print_color "-a Installs the more advanced software" "YELLOW"
        print_color "-d Installs the developer software" "YELLOW"
	print_color "------------------------------------------------------------------" "YELLOW"
}

install_flatpaks() {
	print_color "-------------------------------UPDATE-----------------------------" "BLUE"
	update_flatpaks
	SOFTWARE=( com.valvesoftware.Steam com.spotify.Client org.gimp.GIMP org.videolan.VLC )
	print_color "-------------------------------START-------------------------------" "BLUE"
	choose_flatpaks_command
	print_color "-------------------------------DONE--------------------------------" "BLUE"
}

install_recording_software() {
	print_color "-------------------------------UPDATE-----------------------------" "BLUE"
	update_packages
        SOFTWARE=( pulseeffects Kamoso cheese )
        print_color "-------------------------------START------------------------------" "BLUE"
        choose_install_commands
        SOFTWARE=( com.obsproject.Studio com.discordapp.Discord org.audacityteam.Audacity org.openshot.OpenShot org.olivevideoeditor.Olive )
        choose_flatpaks_commands
	print_color "-------------------------------DONE-------------------------------" "BLUE"
}

install_dev_software() {
	print_color "-------------------------------UPDATE-----------------------------" "BLUE"
	update_packages
        print_color "-------------------------------START------------------------------" "BLUE"
        SOFTWARE=( gedit cmake qt* IDLE )
        DEV_TOOLS="True"
        choose_install_commands
        DEV_TOOLS="False"
        SOFTWARE=( com.visualstudio.code io.atom.Atom org.gnome.Builder com.jetbrains.PyCharm-Community com.jetbrains.GoLand org.godotengine.Godot com.unity.UnityHub org.gnome.gitg )
        choose_flatpaks_commands
	print_color "-------------------------------DONE-------------------------------" "BLUE"
}


install_basic_software() {
	print_color "-------------------------------UPDATE-----------------------------" "BLUE"
	update_packages
        SOFTWARE=( dropbox nautilus-dropbox gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-ugly gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free gstreamer1-plugins-bad-freeworld gstreamer1-plugins-bad-free-extras libdvdread libdvdnav lsdvd ffmpeg tlp guvcview chromium gedit clamTk google-chrome-stable flatpak gnome-software-plugin-flatpak )
        print_color "-------------------------------START------------------------------" "BLUE"
        choose_install_commands
        SOFTWARE=( org.gnome.Boxes org.libreoffice.LibreOffice com.leinardi.gwe com.skype.Client org.kde.okular com.slack.Slack org.kde.ark us.zoom.Zoom com.skype.Client org.gnome.Photos org.onlyoffice.desktopeditors )
        choose_flatpaks_commands
	print_color "-------------------------------DONE-------------------------------" "BLUE"
}

install_advanced_software() {
	print_color "-------------------------------UPDATE-----------------------------" "BLUE"
	update_packages
	SOFTWARE=( gnome-tweak-tool wine icedtea-web java-openjdk p7zip p7zip-plugins unrar redshift GIMP VirtualBox ntfs-3g qbittorrent pdfmod )
        print_color "-------------------------------START------------------------------" "BLUE"
	choose_install_commands
	SOFTWARE=( org.inkscape.Inkscape org.kde.krita org.blender.Blender org.shadowsocks.qt5client com.github.junrrein.PDFSlicer org.inkscape.Inkscape )
	choose_flatpaks_commands
	print_color "-------------------------------DONE-------------------------------" "BLUE"

}

update_packages() {
	LINUX_DISTRIB=`hostnamectl | grep "Operating System: "`
	print_color "${LINUX_DISTRIB}" "BLUE"
	
	if have_prog dnf ; then 
		update_on_fedora
	elif have_prog apt-get ; then 
		update_on_ubuntu
	elif have_prog pacman ; then 
		update_on_manjaro
	else
		print_color "NO PACKAGE MANAGER FOUND!" "RED"
		exit 2
	fi
}

update_flatpaks() {
	flatpak update
}

choose_install_commands() {
	LINUX_DISTRIB=`hostnamectl | grep "Operating System: "`
	print_color "${LINUX_DISTRIB}" "BLUE"
	
	if have_prog dnf ; then 
		install_on_fedora
	elif have_prog apt-get ; then 
		install_on_ubuntu
	elif have_prog pacman ; then 
		install_on_manjaro
	else
		print_color "NO PACKAGE MANAGER FOUND!" "RED"
		exit 2
	fi
}

choose_flatpaks_commands() {
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	sudo flatpak install flathub ${SOFTWARE}
		
}

install_on_fedora() {
	# Add the repos
	sudo dnf install --nogpgcheck http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
	sudo dnf install --nogpgcheck http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
	sudo dnf install fedora-workstation-repositories
	sudo dnf config-manager --set-enabled google-chrome
	
	# Install the actual software
	if [${DEV_TOOLS}="True"] ; then 
		sudo dnf groupinstall "Development Tools"
	fi
	
	sudo dnf install ${SOFTWARE}
}
update_on_fedora() {
	sudo dnf update
	sudo dnf upgrade
}

install_on_ubuntu() {

	if [${DEV_TOOLS}="True"] ; then 
		sudo apt-get groupinstall "Development Tools"
	fi
	sudo apt-get install ${SOFTWARE}
}
update_on_ubuntu() {
	sudo apt-get update 
	sudo apt-get upgrade
}

install_on_manjaro() {
	if [${DEV_TOOLS}="True"] ; then 
		sudo pacman -S groupinstall "Development Tools"
	fi
	sudo pacman -S ${SOFTWARE}
}
update_on_majaro() {
	sudo pacman -Syu
}

##------------------------------------------------------------------------------------------
## SECTION: Program Logic
##------------------------------------------------------------------------------------------

while getopts "hfybad" arg; do
	case ${arg} in
	h )
	print_help
	;;
	f )
	install_flatpaks
	;;
	y )
	install_recording_software
	;;
	b )
	install_basic_software
	;;
	a )
	install_advanced_software
	;;
	d )
	install_dev_software
	;;
	esac
done
