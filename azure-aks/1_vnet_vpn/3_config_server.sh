#!/bin/bash
# Name: config_server.sh
# Owner: Saurav Mitra
# Description: Configure OpenVPN Access Server

# Install OpenVPN Access Server
apt-get update -y
apt-get upgrade -y
apt-get install -y wget curl net-tools gnupg

bash <(curl -fsS https://packages.openvpn.net/as/install.sh) --yes

while ! systemctl is-active --quiet openvpnas; do
    sleep 2
done

pushd /usr/local/openvpn_as/scripts
./sacli --user ${VPN_ADMIN_USER} --key "prop_superuser" --value "true" UserPropPut
./sacli --user ${VPN_ADMIN_USER} --key "user_auth_type" --value "local" UserPropPut
./sacli --user ${VPN_ADMIN_USER} --new_pass=${VPN_ADMIN_PASSWORD} SetLocalPassword
./sacli --key "vpn.server.daemon.enable" --value "false" ConfigPut
./sacli --key "cs.tls_version_min" --value "1.2" ConfigPut
./sacli --key "vpn.server.tls_version_min" --value "1.2" ConfigPut
./sacli --key "vpn.server.routing.gateway_access" --value "true" ConfigPut
./sacli --key "vpn.client.routing.inter_client" --value "false" ConfigPut
./sacli --key "vpn.client.routing.reroute_gw" --value "true" ConfigPut
./sacli --key "vpn.client.routing.reroute_dns" --value "true" ConfigPut
./sacli --key "vpn.server.routing.private_network.0" --value "${VNET_CIDR_BLOCK}" ConfigPut
./sacli --key "vpn.server.routing.private_access" --value "nat" ConfigPut
./sacli --key "vpn.server.dhcp_option.dns.0" --value "${VNET_NAME_SERVER}" ConfigPut
./sacli --key "vpn.server.dhcp_option.dns.1" --value "8.8.8.8" ConfigPut
./sacli start
popd

# ./sacli ConfigQuery