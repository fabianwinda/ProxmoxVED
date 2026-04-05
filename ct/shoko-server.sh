#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/fabianwinda/ProxmoxVED/main/misc/build.func)

# Copyright (c) 2021-2026 fabianwinda ORG
# Author: fabianwinda
# License: MIT | https://github.com/fabianwinda/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/ShokoAnime/ShokoServer

APP="ShokoServer"
var_tags="${var_tags:-media;anime}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/shokoserver ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/ShokoAnime/ShokoServer/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Shoko Server"
    systemctl stop shoko-server
    msg_ok "Stopped Shoko Server"

    msg_info "Creating Backup"
    cp /opt/shokoserver/appsettings.json /opt/shokoserver_appsettings.bak 2>/dev/null || true
    msg_ok "Backup Created"

    msg_info "Updating Shoko Server to v${RELEASE}"
    curl -fsSL --retry 3 --retry-delay 2 "https://github.com/ShokoAnime/ShokoServer/releases/download/${RELEASE}/Shoko.CLI_Framework_any-x64.zip" -o /opt/shoko-server.zip
    if ! unzip -t /opt/shoko-server.zip >/dev/null 2>&1; then
      msg_error "Downloaded file is not a valid zip archive"
      exit 1
    fi
    $STD unzip -q /opt/shoko-server.zip -d /opt/shokoserver/
    # Move files from publish subdirectory if they exist
    if [[ -d /opt/shokoserver/publish ]]; then
      mv /opt/shokoserver/publish/* /opt/shokoserver/
      rmdir /opt/shokoserver/publish 2>/dev/null || true
    fi
    rm -f /opt/shoko-server.zip
    chmod +x /opt/shokoserver/Shoko.CLI
    msg_ok "Updated Shoko Server"

    msg_info "Restoring Configuration"
    cp /opt/shokoserver_appsettings.bak /opt/shokoserver/appsettings.json 2>/dev/null || true
    rm -f /opt/shokoserver_appsettings.bak
    msg_ok "Restored Configuration"

    msg_info "Starting Shoko Server"
    systemctl start shoko-server
    msg_ok "Started Shoko Server"

    msg_info "Cleaning Up"
    rm -f /opt/shokoserver_appsettings.bak
    msg_ok "Cleanup Completed"

    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8111${CL}"
echo -e "${INFO}${YW} Important:${CL}"
echo -e "${TAB}1. Create an admin account on first start via the Web UI"
echo -e "${TAB}2. Configure your AniDB account in the settings"
echo -e "${TAB}3. Set up import folders for your anime collection"
