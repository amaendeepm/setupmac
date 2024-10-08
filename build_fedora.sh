#!/bin/bash
# NOT TESTED YET!!
echo "Starting to Setup Development Fedora"

# Step 1: Update the system
echo "0. Updating Fedora system..."
sudo dnf update -y

# Step 2: Install core GNU utilities
echo "Starting the core GNU experience"
sudo dnf install -y coreutils sed tar indent which getopt git gh wireshark openssl tresorit apache-activemq

# Install Redpanda (Kafka alternative)
echo "Installing Redpanda"
curl -1sLf \
    'https://packages.vectorized.io/rpm/setup.rpm.sh' \
    | sudo -E bash
sudo dnf install redpanda -y

# Step 3: Install build and developer tools
echo "Setting up Findutils & Homebank Utils"
sudo dnf install -y ccache cmake ninja-build libtool gettext llvm gcc binutils grep findutils

# Install Homebank (financial management tool)
sudo dnf install -y homebank

echo "Getting Ready to Install important packages"

# Step 4: List of additional packages to install
PACKAGES=(
    awscli
    git
    go
    jq
    libserdes
    npm
    openvpn
    postgresql
    python3
    rabbitmq-server
    rustup
    terraform
    tree
    vim
    cmake
    wget
    libxml2
)

echo "Installing listed packages..."
sudo dnf install -y ${PACKAGES[@]}

echo "Cleaning up..."
sudo dnf autoremove -y

# Step 5: Install useful Go packages
echo "Installing Go XML/Support"
go install encoding/xml
go install github.com/tiaguinho/gosoap@latest

# Step 6: Enable Terraform autocomplete support
terraform -install-autocomplete

# Step 7: Install additional apps using Flatpak or native methods (for apps like VSCode, Postman, etc.)
echo "Installing additional apps via Flatpak"

# Enable Flatpak support
sudo dnf install -y flatpak

# Adding Flathub repository (if not already added)
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install apps via Flatpak
flatpak install flathub com.microsoft.Teams com.google.Chrome org.mozilla.firefox com.microsoft.VisualStudioCode com.jetbrains.PyCharm-Community com.slack.Slack com.getpostman.Postman org.sqlitebrowser.sqlitebrowser

# Install Docker
echo "Installing Docker..."
sudo dnf install -y docker
sudo systemctl enable docker --now

# Install Rust tools
echo "Installing Rust tools..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
sudo dnf install -y rust-analyzer

# Step 8: Install and configure Oh My Zsh (if preferred)
echo "Installing Oh My Zsh"
sudo dnf install -y zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Step 9: Install pip and Azure-related packages
echo "Installing pip and Azure SDKs"
sudo dnf install -y python3-pip
pip3 install azure-mgmt-compute azure-mgmt-storage azure-mgmt-resource azure-keyvault-secrets azure-storage-blob azure-eventhub azure-eventhub-checkpointstoreblob-aio azure-identity ulid-py

echo "Installing global npm packages..."
sudo npm install -g marked

# Step 10: Final cleanup and reboot prompt
echo "Your Fedora is now ready as a Developer Machine"
