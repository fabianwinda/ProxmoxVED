#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: [YourGitHubUsername]
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/ShokoAnime/ShokoServer

APP="ShokoServer"
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  wget \
  unzip \
  apt-transport-https \
  software-properties-common \
  libmediainfo-dev \
  librhash-dev \
  libgdiplus \
  libc6-dev
msg_ok "Installed Dependencies"

msg_info "Installing .NET 8.0"
curl -fsSL https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
$STD dpkg -i packages-microsoft-prod.deb
rm -f packages-microsoft-prod.deb
$STD apt-get update
$STD apt-get install -y dotnet-sdk-8.0 aspnetcore-runtime-8.0
msg_ok "Installed .NET 8.0"

msg_info "Creating Directories"
mkdir -p /opt/shokoserver
mkdir -p /mnt/anime
msg_ok "Created Directories"

msg_info "Downloading Shoko Server"
RELEASE=$(curl -fsSL https://api.github.com/repos/ShokoAnime/ShokoServer/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL "https://github.com/ShokoAnime/ShokoServer/releases/download/${RELEASE}/Shoko.CLI_Framework_any-x64.zip" -o shoko-server.zip
$STD unzip -q shoko-server.zip -d /opt/shokoserver/
rm -f shoko-server.zip
echo "${RELEASE}" >/opt/${APP}_version.txt
msg_ok "Downloaded Shoko Server"

msg_info "Configuring Shoko Server"
chmod +x /opt/shokoserver/Shoko.CLI
cat <<EOF >/opt/shokoserver/.env
SHOKO_HOME=/root/.shoko
EOF
msg_ok "Configured Shoko Server"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/shoko-server.service
[Unit]
Description=Shoko Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/shokoserver
ExecStart=/opt/shokoserver/Shoko.CLI
Restart=always
RestartSec=10
Environment=HOME=/root
Environment=DOTNET_CLI_HOME=/root/.dotnet

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now shoko-server.service
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
