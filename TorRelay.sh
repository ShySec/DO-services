#!/bin/usr/env bash

if [ ${#@} -lt 2 ]; then
  echo "usage: $0 <NICKNAME> <CONTACT_INFO>"
  exit
fi

# ./setup <NICKNAME> <CONTACT_INFO>
NICKNAME=$1 #"somerandomnickname"
CONTACT_INFO=$2 #"Random Person <nobody AT example dot com>"

# prevent apt-get trying to snag copy & pasted data
export DEBIAN_FRONTEND=noninteractive

# install packages
apt-get -y install tor tor-arm

cp /etc/tor/torrc /etc/tor/torrc.orig
cat << EOF > /etc/tor/torrc
## See https://www.torproject.org/docs/tor-doc-relay for details.
## See https://www.torproject.org/docs/tor-manual.html for more details

## Tor opens a socks proxy on port 9050 by default -- even if you don't
## configure one below. Set "SocksPort 0" if you plan to run Tor only
## as a relay, and not make any local application connections yourself.
SocksPort 0

## Required: what port to advertise for incoming Tor connections.
ORPort 443

## Define these to limit how much relayed traffic you will allow. Note that
## RelayBandwidthRate must be at least 20 KB.
## Note that units for these config options are bytes per second, not bits
## per second, and that prefixes are binary prefixes, i.e. 2^10, 2^20, etc.
BandwidthRate 1 MB # Throttle average bandwidth to 1 MB/s (8 Mbps)
BandwidthBurst 1 MB # Throttle maximum bandwidth to 1 MB/s (8 Mbps)
RelayBandwidthRate 1 MB  # Throttle average relay bandwidth to 1 MB/s (8 Mbps)
RelayBandwidthBurst 1 MB # Throttle maximum relay bandwidth to 1 MB/s (8 Mbps)
MaxAdvertisedBandwidth 1 MB  # Tell everyone we're capped at 1 MB/s

## Use these to restrict the maximum traffic per day, week, or month.
AccountingMax 25 GB # 25 GB/day * 31 days/month = 775 GB/month < 1 TB/month
AccountingStart day 00:00 # Limit bandwidth to AccountingMax each day

## https://www.torproject.org/documentation.html
ExitPolicy reject *:*  # no exits allowed

## This is where the logs are stored
Log notice file /var/log/tor/notices.log
EOF

if [[ -n "$NICKNAME" ]]; then
cat << EOF >> /etc/tor/torrc

## A handle for your relay, so people don't have to refer to it by key.
Nickname $NICKNAME
EOF
fi

if [[ -n "$CONTACT_INFO" ]]; then
cat << EOF >> /etc/tor/torrc

## Contact info to be published in the directory, so we can contact you
## if your relay is misconfigured or something else goes wrong. Google
## indexes this, so spammers might also collect it.
#ContactInfo Random Person <nobody AT example dot com>
## You might also include your PGP or GPG fingerprint if you have one:
#ContactInfo 0xFFFFFFFF Random Person <nobody AT example dot com>
ContactInfo $CONTACT_INFO
EOF
fi

service tor restart
TARGET='Self-testing indicates your ORPort is reachable from the outside. Excellent.'
_=$(grep "$TARGET" /var/log/tor/notices.log)
if $?; then
	echo "Tor Relay appears to be working; Thank You and Congratulations!"
	echo 'type `arm` to see additional details'
else
	echo "Something went wrong; the TorRelay does not appear reachable!"
fi

