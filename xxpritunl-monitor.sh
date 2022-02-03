#!/usr/bin/env bash
#########################################################
# Config
#########################################################
SCRIPT_VERSION="1.4"
SCRIPT_NAME="xxpritunl-monitor"
FIX_SCRIPT_SERVICE="/etc/systemd/system/xxpritunl-monitor.service"
FIX_SCRIPT_LOCATION="/usr/bin/xxpritunl-fix"
RESTART_TIME="300"

#########################################################
# Helpers
#########################################################
function check_root () {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root!"
        exit 1
    fi
}

function setup_prerequisites () {
    local _packages=""
    if [ ! -f /bin/systemctl ]; then
        echo "This script requires systemd. Installing..."
        _packages+="systemctl "
    fi
    if [ ! -f /usr/bin/curl ]; then
        echo "This script requires curl. Installing..."
        _packages+="curl "
    fi
    # check if string is empty
    if [ -n "$_packages" ]; then
        apt-get update && apt-get install -y "$_packages"
    fi
}

function add_systemd () {
    cat <<EOF > "$FIX_SCRIPT_SERVICE"
[Unit]
Description=Dirty fix for pritunl interpersonal problems.

[Service]
User=root
ExecStart=/bin/bash ${FIX_SCRIPT_LOCATION}
RestartSec=${RESTART_TIME}

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable xxpritunl-monitor.service
systemctl start xxpritunl-monitor.service
systemctl status xxpritunl-monitor.service
}

function write_script () {
    cat <<EOF > "$FIX_SCRIPT_LOCATION"
#!/usr/bin/env bash
SCRIPT_VERSION="${SCRIPT_VERSION}"
function verify_curl() {
    if [[ "\$2" == *"\$1"* ]]; then 
        echo "Site is up"
        return 0
    else
        echo "Site is down. Reissuing SSL and restarting service..."
        pritunl reset-ssl-cert
        systemctl restart pritunl
        return 1
    fi
}

function verify_service() {
    local _service="\$1"
    echo "Checking if service \$_service is running..."
    if [ "\$(systemctl is-active "\$_service")" == "active" ]; then
        echo "Service \$_service is running"
        return 0
    else
        echo "Service \$_service is not running. Restarting service..."
        systemctl restart "\$_service"
        return 1
    fi 
}

verify_service "pritunl"
verify_service "mongod"
verify_curl "login-backdrop" "\$(curl -s -k -L https://localhost)"
echo "All done."
exit 0
EOF
chmod +x "$FIX_SCRIPT_LOCATION"
}

#########################################################
# Main
#########################################################
setup_prerequisites
check_root
write_script
add_systemd
echo "[$SCRIPT_NAME v$SCRIPT_VERSION]: Done!"
exit 0
