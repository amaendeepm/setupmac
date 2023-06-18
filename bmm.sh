
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
brew install gh


## Commented below as I dont want another jdk mess right now
#brew install java11 #For Kafka - supported versions are 8,11,14
#brew install kafka --ignore-dependencies #To ensure not to bring own java with it 


echo "Setting up Findutils & Homebank Utils"
# Make life easy with `find`, `grep`, `ninja`, `gettext`, `locate`, `updatedb`, and `xargs`, g-prefixed, and many more
brew install ccache cmake ninja libtool gettext llvm gcc binutils grep findutils

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
    cmake
    wget #Support most downloads here onwards
    MaterializeInc/materialize/materialized
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

echo "Installing Cask Apps..."
brew install --cask brackets
brew install --cask canva
brew install --cask dbeaver-community #DB Viewer
brew install --cask drawio #Draw IO
brew install --cask firefox #FireFox Browser
brew install --cask google-chrome #Chrome Browser
brew install --cask pycharm-ce #PyCharm community edition
brew install --cask intellij-idea-ce #Ensure IDE
brew install --cask microsoft-teams #MS-Teams
brew install --cask microsoft-office #MS-Office Suite of Apps
brew install --cask slack #Slack
brew install --cask tresorit #Tresor
brew install --cask visual-studio-code #VSCode
brew install --cask openvpn-connect
brew install --cask postman #Postman

brew install rust-analyzer #After VSCode installed


#Add shortcuts also for installed apps in dock
defaults delete com.apple.dock persistent-apps
defaults delete com.apple.dock recent-apps
defaults delete com.apple.dock persistent-others

dock_item() {
    printf '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%s</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>', "$1"
}

defaults write com.apple.dock persistent-apps -array \
    "$(dock_item /Applications/Canva.app)" \
    "$(dock_item /Applications/Visual\ Studio\ Code.app)" \
    "$(dock_item /Applications/Slack.app)" \
    "$(dock_item /Applications/Google\ Chrome.app)" \
    "$(dock_item /Applications/Microsoft\ Outlook.app)" \
    "$(dock_item /Applications/Microsoft\ Teams.app)" \
    "$(dock_item /Applications/draw.io.app)" \
    "$(dock_item /Applications/Tresorit.app)" \
    "$(dock_item /Applications/DBeaver.app)" \

killall Dock




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

#Install Azure specific packages
pip3 install azure-mgmt-compute
pip3 install azure-mgmt-storage
pip3 install azure-mgmt-resource
pip3 install azure-keyvault-secrets
pip3 install azure-storage-blob
pip3 install azure-eventhub
pip3 install azure-eventhub-checkpointstoreblob-aio
pip3 install azure-identity
pip3 install ulid-py

echo "Installing global npm packages..."
sudo npm install marked -g

#Tooling for generating software bom in json or cycloneDX formats
gh ext install advanced-security/gh-sbom

echo "Your Mac OSX is now ready as Developer Machine"
