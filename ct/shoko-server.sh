#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/fabianwinda/ProxmoxVED/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: FabianWinda
# License: MIT | https://github.com/fabianwinda/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/ShokoAnime/ShokoServer

APP="Shoko Server"
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

  if check_for_gh_release "shokoserver" "ShokoAnime/ShokoServer"; then
    msg_info "Stopping Shoko Server"
    systemctl stop shoko-server
    msg_ok "Stopped Shoko Server"

    msg_info "Creating Backup"
    cp /opt/shokoserver/appsettings.json /opt/shokoserver_appsettings.bak 2>/dev/null || true
    msg_ok "Backup Created"

    msg_info "Updating Shoko Server to v${RELEASE}"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "shokoserver" "ShokoAnime/ShokoServer" "tarball" "latest" "/opt/shokoserver"
    msg_ok "Updated Shoko Server"

    msg_info "Restoring Configuration"
    cp /opt/shokoserver_appsettings.bak /opt/shokoserver/appsettings.json 2>/dev/null || true
    msg_ok "Restored Configuration"

    msg_info "Starting Shoko Server"
    systemctl start shoko-server
    msg_ok "Started Shoko Server"

    msg_info "Cleaning Up"
    rm -f /opt/shokoserver_appsettings.bak
    msg_ok "Cleanup Completed"

    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at the latest version"
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
