#!/system/bin/sh

IPTABLES=/system/bin/iptables
DEBUG_RULES_HOOK=/system/bin/debug_firewall.sh
GREENGRASS_RULES_HOOK=/system/bin/greengrass_firewall.sh
GETPROP=/system/bin/getprop
LOG=/system/bin/log
TAG=Firewall
OOBEIP=$($GETPROP p2p.server.addr)
GET_DYN_CONF=/system/bin/get-dynconf-value
COMPANION_APP_TCPTUNNEL_PORT_CONF_NAME=url.companionapp.tcptunnel.port
COMPANION_APP_TCPTUNNEL_PORT=$($GETPROP persist.oobe.compapp.port)
WPA_CLI=/system/bin/wpa_cli
DNS1IP=$($GETPROP net.dns1)
DNS2IP=$($GETPROP net.dns2)
DNS4IP=$($GETPROP net.dns4)
DNS5IP=$($GETPROP net.dns5)
TCPTUNNEL_LOCAL_LISTENING_PORT=$($GETPROP lab126.oobe.local.listening.prt)

# Read the P2P interface name
target=$($GETPROP ro.fireos.target.product)
if [ "${target}" == "full_sonar" ] || [ "${target}" == "rook" ] || [ "${target}" == "csm_sonar" ]; then
    IF_NAME='p2p-wlan0-'
    P2PIF=$($WPA_CLI interface | grep $IF_NAME)
else
    P2PIF=p2p0
fi

print() {
    $LOG -t $TAG $1
}

# If '.' in the address, then it's IPv4.
# The iput comes from properties, should be valid V4 or V6 address
function valid_ipv4() {
    local  ip=$1
    local  stat=1

    OIFS=$IFS
    IFS='.'
    tokens=($ip)
    IFS=$OIFS

    [[ ${#tokens[@]} -gt 1 ]]
    stat=$?
    return $stat
}

get_companion_app_tcptunnel_port() {

    # set the local variable port to ""
    local port=""
    if [ -e ${GET_DYN_CONF} ]; then
        port=$(${GET_DYN_CONF} ${COMPANION_APP_TCPTUNNEL_PORT_CONF_NAME})
    fi

    if [ "${port}" == "" ]; then
        port=${COMPANION_APP_TCPTUNNEL_PORT}
    fi

    print "Companion App TCPTunnel Port:${port}"
    echo -n "${port}"
}

if [ ! -x $IPTABLES ]; then
    print "$IPTABLES... not found"
    exit 1
fi

# Add default firewall settings here
default_firewall_setup () {
    print "Setting up default firewall settings"
    $IPTABLES --flush INPUT
    $IPTABLES --flush OUTPUT
    $IPTABLES --flush FORWARD

    # Default policy for all chains: DROP
    $IPTABLES -P INPUT DROP
    $IPTABLES -P OUTPUT DROP
    $IPTABLES -P FORWARD DROP

    # Accept RELATED,ESTABLISHED connections on wlan0 (device initiated)
    $IPTABLES -A INPUT -i wlan0 -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp -m state --state ESTABLISHED -j ACCEPT

    # Spotify Connect login server.
    $IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 4070 -j ACCEPT

    # Whatify Spotify Connect login server.
    $IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 4071 -j ACCEPT

    # SIP Calling support
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 16384:32767 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p tcp --dport 16384:32767 -j ACCEPT

    # TPH traffic on wlan0. TPH/phd listens on port 40317
    $IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 40317 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 40317 --sport 40317 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 40317 --sport 49317 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 40317 --sport 33434 -j ACCEPT

    # Whole Home Audio traffic on wlan0.  The whad listens on:
    # udp port 55442 for audio distribution
    # tcp port 55442 for audio distribution
    # tcp port 55443 for control plane behavior,
    # udp port 55444 for timestamp exchange
    # udp port 55445 for Quantum UDP WHASP
    # tcp port 55445 for TCP WHASP
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 55442 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 55442:55445 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 55444:55445 -j ACCEPT

    # UPnP:
    # allow traffic on Dst Port 1900 which are UPnP advertisements and Bye Bye
    # Allow traffic on Dst Port 50000; these pkts are SSDP search results
    # SSDP search queries are sent with Src Port 50000
    $IPTABLES -A INPUT -i wlan0  -p udp --dport 1900 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0  -p udp --dport 50000 -j ACCEPT

    # mDNS: Avahi Publish of Spotify Connect service.
    $IPTABLES -A INPUT -i wlan0  -p udp --dport 5353 -j ACCEPT

    # ICMP. Allow only responses to local connections
    $IPTABLES -A INPUT -p icmp -m state --state RELATED,ESTABLISHED -j ACCEPT

    # CMB. Allow packets on port 5000
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 5000 -j ACCEPT

    # Add rules for internal debugging use
    if [ -f $DEBUG_RULES_HOOK ]; then
        /system/bin/sh $DEBUG_RULES_HOOK
    else
        print "$DEBUG_RULES_HOOK does not exist"
    fi

    if [ -f $GREENGRASS_RULES_HOOK ]; then
        /system/bin/sh $GREENGRASS_RULES_HOOK
    fi

    # Filter everything to OUTPUT through oem_out
    $IPTABLES -A OUTPUT -j oem_out

    # Allow all outgoing traffic on wlan0
    $IPTABLES -A OUTPUT -o wlan0 -j ACCEPT

    # Accept all on the loopback interface
    $IPTABLES -A INPUT -i lo -j ACCEPT
    $IPTABLES -A OUTPUT -o lo -j ACCEPT
}

# Alexa hybrid firewall setup routine
alexa_hybrid_firewall_setup() {
    print "alexa_hybrid_firewall_setup"
    AHE_CLIENT_UID=$($GETPROP alexa.hybrid.client.uid)
    AHE_SERVICE_UID=$($GETPROP alexa.hybrid.service.uid)
    AHE_PORT=$($GETPROP alexa.hybrid.service.port)

    if [ -z $AHE_CLIENT_UID ] || [ -z $AHE_SERVICE_UID ] || [ -z $AHE_PORT ]; then
        print "Invalid parameters. client=$AHE_CLIENT_UID, service=$AHE_SERVICE_UID, port=$AHE_PORT"
        exit 1
    fi

    # Allow extensions device connecting to AHE on wlan0
    $IPTABLES -A INPUT -i wlan0 -p tcp --dport $AHE_PORT -j ACCEPT

    # Remove any existing rules
    $IPTABLES --flush oem_out
    # Drop traffic from a non alexa hybrid client user to AHE port/prevent impersonating SIM process.
    # Accept packets for an ESTABLISHED connection. This is required to allow FIN packets.
    $IPTABLES -A oem_out -o lo -p tcp --dport $AHE_PORT -d 127.0.0.1 -m state --state ESTABLISHED -j ACCEPT
    $IPTABLES -A oem_out -o lo -p tcp --dport $AHE_PORT -d 127.0.0.1 -m owner ! --uid-owner $AHE_CLIENT_UID -j DROP
    # Drop traffic from a non alexa hybrid service user from AHE port/prevent impersonating AHE process.
    # Don't accept for ESTABLISHED connection. When client initiates connection the SYN_ACK packet is
    # considered as part of ESTABLISHED connection. We don't want that.
    # We want to include SYC_ACK packets in owner uid filter.
    $IPTABLES -A oem_out -o lo -p tcp --sport $AHE_PORT -s 127.0.0.1 -m owner ! --uid-owner $AHE_SERVICE_UID -j DROP
}

# Firewall settings for P2P interface
p2p_firewall_start () {
    print "Setting up P2P firewall settings on $P2PIF"

    COMPANION_APP_TCPTUNNEL_PORT=$(get_companion_app_tcptunnel_port)

    # Setup ip tables to reject all non-essential traffic
    # Redirect all DNS traffic to ourselves. This is necessary when the client device
    # has a static DNS address configured
    $IPTABLES -t nat -A PREROUTING -i "$P2PIF" -p udp --dport 53 -j DNAT --to ${OOBEIP}
    # ACCEPT all DNS traffic
    $IPTABLES -A INPUT -i "$P2PIF" -p udp --dport 53 -j ACCEPT
    # ACCEPT all DHCP traffic
    $IPTABLES -A INPUT -i "$P2PIF" -p udp --dport 67:68 --sport 67:68 -j ACCEPT
    # ACCEPT all incoming OOBE webserver traffic
    $IPTABLES -A INPUT -i "$P2PIF" -p tcp --dport 8080 -j ACCEPT
    $IPTABLES -A INPUT -i "$P2PIF" -p tcp --dport ${COMPANION_APP_TCPTUNNEL_PORT} -j ACCEPT

    # Allow all outgoing traffic
    $IPTABLES -A OUTPUT -o "$P2PIF" -j ACCEPT
}

# Firewall settings for P2P interface
p2p_firewall_stop () {
    print "Disabling P2P firewall settings on $P2PIF"

    COMPANION_APP_TCPTUNNEL_PORT=$(get_companion_app_tcptunnel_port)

    # Delete all rules setup by p2p_firewall_start
    # Delete DNS redirection
    $IPTABLES -t nat -D PREROUTING -i "$P2PIF" -p udp --dport 53 -j DNAT --to ${OOBEIP}
    # Delete ACCEPT all DNS traffic
    $IPTABLES -D INPUT -i "$P2PIF" -p udp --dport 53 -j ACCEPT
    # Delete ACCEPT all DHCP traffic
    $IPTABLES -D INPUT -i "$P2PIF" -p udp --dport 67:68 --sport 67:68 -j ACCEPT
    # Delete ACCEPT all incoming OOBE webserver traffic
    $IPTABLES -D INPUT -i "$P2PIF" -p tcp --dport 8080 -j ACCEPT
    $IPTABLES -D INPUT -i "$P2PIF" -p tcp --dport ${COMPANION_APP_TCPTUNNEL_PORT} -j ACCEPT

    # Delete Allow all outgoing traffic
    $IPTABLES -D OUTPUT -o "$P2PIF" -j ACCEPT

    # below is a temporary change.
    print "killing dnsmasq.."
    kill -9 `cat /data/local/dnsmasq.pid`
}

nat_firewall_start () {
    PROP_COMPANION_IP="lab126.p2p.companion.app.ip"
    IP=`getprop $PROP_COMPANION_IP`
    if [ "x$IP" == "x" ]; then
        print "$PROP_COMPANION_IP is empty, failed to enable NAT"
        return
    fi
    print "enabling ip_forward"
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Add rules for forwarding and NAT-ing traffic for the companion
    # app IP if necessary.
    $IPTABLES -C FORWARD -p tcp -s ${IP} -i ${P2PIF} -o wlan0 -j ACCEPT

    if [ $? -ne 0 ]; then
        # Accept tcp forwarding traffic
        print "enabling NAT for $IP only"
        iptables -A FORWARD -p tcp -s $IP -i ${P2PIF} -o wlan0 -j ACCEPT
        iptables -A FORWARD -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT
        # Masquerade all NAT traffic
        iptables -t nat -I natctrl_nat_POSTROUTING -o wlan0 -j MASQUERADE
    fi

    print "detecting nameserver"
    # Save nameserver to a file
    if valid_ipv4 ${DNS1IP}; then echo "nameserver ${DNS1IP}" > /data/local/resolv.dnsmasq;
    elif valid_ipv4 ${DNS2IP}; then echo "nameserver ${DNS2IP}" > /data/local/resolv.dnsmasq;
    elif valid_ipv4 ${DNS4IP}; then echo "nameserver ${DNS4IP}" > /data/local/resolv.dnsmasq;
    elif valid_ipv4 ${DNS5IP}; then echo "nameserver ${DNS5IP}" > /data/local/resolv.dnsmasq;
    fi
    echo "nameserver 8.8.8.8" >> /data/local/resolv.dnsmasq;
    chmod 644 /data/local/resolv.dnsmasq

    print "applying nameserver"
    # Reload dnsmasq to use upstream nameserver from the file
    kill -s HUP `cat /data/local/dnsmasq.pid`
}

nat_firewall_stop () {
    # cleanup
    print "disabling ip_forward"
    echo 0 > /proc/sys/net/ipv4/ip_forward

    # Stop accepting forward traffic
    iptables -F FORWARD
    # Delete NAT masquerade rule.
    iptables -t nat -D POSTROUTING -o wlan0 -j MASQUERADE

    print "clearing nameserver"
    echo "" > /data/local/resolv.dnsmasq
    chmod 644 /data/local/resolv.dnsmasq

    print "applying nameserver"
    kill -s HUP `cat /data/local/dnsmasq.pid`
}

tcp_tunnel_start () {
    COMPANION_APP_TCPTUNNEL_PORT=$(get_companion_app_tcptunnel_port)

    # The companion app make authorize link code call on port number 443. OOBE apk is a prebuilt. So it cannot bind to port numbers less than 1024.
    # So, any traffic that is sent over the p2p interface to the server ip, should be redirected to a port that the OOBE apk can bind to. This port
    # on which the OOBE apk is listening is written in the system property lab126.oobe.local.listening.prt, by the OOBE apk.
    print "Enabling TCPTunnel port forwarding from ${TCPTUNNEL_LOCAL_LISTENING_PORT} to ${COMPANION_APP_TCPTUNNEL_PORT} on $P2PIF"

    iptables -A INPUT -i "$P2PIF" -p tcp --dport ${TCPTUNNEL_LOCAL_LISTENING_PORT} -j ACCEPT
    iptables -t nat -A PREROUTING -i "$P2PIF" -p tcp --dport ${COMPANION_APP_TCPTUNNEL_PORT} -d ${OOBEIP} -j DNAT --to-destination ${OOBEIP}:${TCPTUNNEL_LOCAL_LISTENING_PORT}
}

tcp_tunnel_stop () {
    # cleanup
    print "Disabling TCPTunnel port forwarding"

    COMPANION_APP_TCPTUNNEL_PORT=$(get_companion_app_tcptunnel_port)

    iptables -D INPUT -i "$P2PIF" -p tcp --dport ${TCPTUNNEL_LOCAL_LISTENING_PORT} -j ACCEPT
    iptables -t nat -D PREROUTING -i "$P2PIF" -p tcp --dport ${COMPANION_APP_TCPTUNNEL_PORT} -d ${OOBEIP} -j DNAT --to-destination ${OOBEIP}:${TCPTUNNEL_LOCAL_LISTENING_PORT}
}

start_setup_firewall () {

    case "$1" in
        default)
            default_firewall_setup
            ;;
        p2p)
            shift
            p2p_firewall_start
            ;;
        nat)
            shift
            nat_firewall_start
            ;;
        port_forwarding)
            shift
            tcp_tunnel_start
            ;;
        alexa_hybrid_firewall)
            alexa_hybrid_firewall_setup
            ;;
        *)
            exit 1
            ;;
    esac
}

stop_setup_firewall () {

    case "$1" in
        p2p)
            shift
            p2p_firewall_stop
            nat_firewall_stop
            ;;
        nat)
            shift
            nat_firewall_stop
            ;;
        port_forwarding)
            shift
            tcp_tunnel_stop
            ;;
        *)
            exit 1
            ;;
    esac
}

case "$1" in
    start)
        if [ "$2" ]
        then
            shift
            # Setup any specific settings
            start_setup_firewall "$@"
            exit 0
        fi
        ;;
    stop)
        if [ "$2" ]
        then
            shift
            # Stop any specific settings
            stop_setup_firewall "$@"
            exit 0
        fi
        ;;
    *)
        exit 1
        ;;
esac

exit 1
