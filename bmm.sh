echo "Starting to bootstrap Mac OSX"


if test ! $(which brew); then
    echo "0. Installing homebrew..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update

# Install GNU core (those that come with OS X are outdated)
echo "Starting the core GNU experience"
brew install coreutils
brew install gnu-sed 
brew install gnu-tar
brew install gnu-indent
brew install gnu-which
brew install gnu-getopt

brew install wget #Support most downloads here onwards

## Commented below as I dont want another jdk mess right now
#brew install java11 #For Kafka - supported versions are 8,11,14
#brew install kafka --ignore-dependencies #To ensure not to bring own java with it 


echo "Setting up Findutils & Homebank Utils"
# Make life easy with `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

#whole unix experience
brew install homebank

echo "Getting Ready to Install important packages"

PACKAGES=( #Alphabetically Sorted
    awscli
    awscurl
    git
    go
    jq
    libserdes
    npm
    openvpn
    postgresql
    python
    python3
    rabbitmq
    rustup
    terraform@1.2
    tree
    vim
    wget
)


echo "Installing listed packages..."
brew install ${PACKAGES[@]}


echo "Cleaning up..."
brew cleanup

echo "Installing Go XML/Support"
#Install useful Go Packages
go install encoding/xml
go install github.com/tiaguinho/gosoap@latest

echo "Enabling Terraform Autocomplete Support"
terraform -install-autocomplete 

echo "Installing Brew Cask..."
brew install cask

CASKS=(
    #dashlane
    brackets #Open-source Code Editor
    dbeaver-community #DB Viewer
    drawio #Draw IO
    firefox #FireFox Browser
    flux
    google-chrome #Chrome Browser
    google-drive #Google Drive App Access
    intellij-idea-ce #Ensure IDE
    macvim
    microsoft-teams #MS-Teams
    microsoft-office #MS-Office Suite of Apps
    slack #Slack
    tresorit #Tresor
)

echo "Installing Cask Apps..."

brew install ${CASKS[@]} --cask

echo "Installing global npm packages..."
npm install marked -g


echo "Setting up Password prompt upon Screensaver"
#Setup security settings of password asking upon screensaver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 5


#Show filename options by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

#Install Docker Desktop as there is no cask
#mkdir tmp1
#cd tmp1
#wget https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64
#VOLUME=`hdiutil attach Docker.dmg | grep Volume | cut -f 3`
#cp -rf $VOLUME/*.app /Applications
#hdiutil detach $VOLUME
#cd ..
#rm -rf tmp1

#Install Monday.com coz there is no cask, maybe a DMG location?
#mkdir tmpXXX
#cd tmpXXX
#wget MONDAY.dmg
#VOLUME=`hdiutil attach MONDAY.dmg | grep Volume | cut -f 3`
#cp -rf $VOLUME/*.app /Applications
#hdiutil detach $VOLUME
#cd ..
#rm -rf tmpXXX

#Install Dashlane coz there is no cask, maybe a DMG location?
#mkdir tmpXXX
#cd tmpXXX
#wget Dashlane.dmg
#VOLUME=`hdiutil attach Dashlane.dmg | grep Volume | cut -f 3`
#cp -rf $VOLUME/*.app /Applications
#hdiutil detach $VOLUME
#cd ..
#rm -rf tmpXXX

#To ensure if any outdated formulas got installed, they get upgraded finally before exit
brew upgrade

#Keeping SUDO related commands in the end as otherwise dangeours for other flows above
#Ensure pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py
rm get-pip.py

echo "Installing Python packages..."
PYTHON_PACKAGES=(
    ipython
    virtualenv
    virtualenvwrapper
)
pip3 install ${PYTHON_PACKAGES[@]}



