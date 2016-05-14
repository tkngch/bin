#!/bin/bash

# The commands in this file follow archlinux wiki page
# (https://wiki.archlinux.org/index.php/Simple_stateful_firewall).
# Created on 28 Mar 2016.


# For this basic setup, we will create two user-defined chains that we will use
# to open up ports in the firewall.

iptables -N TCP
iptables -N UDP

# The chains can of course have arbitrary names. We pick these just to match
# the protocols we want handle with them in the later rules, which are
# specified with the protocol options, e.g. -p tcp, always.

# If you want to set up your machine as a NAT gateway, please look at #Setting
# up a NAT gateway. For a single machine, however, we simply set the policy of
# the FORWARD chain to DROP and move on:

iptables -P FORWARD DROP


# The OUTPUT chain

# We have no intention of filtering any outgoing traffic, as this would make
# the setup much more complicated and would require some extra thought. In this
# simple case, we set the OUTPUT policy to ACCEPT.

iptables -P OUTPUT ACCEPT


# The INPUT chain

# Similar to the previous chains, we set the default policy for the INPUT chain
# to DROP in case something somehow slips by our rules. Dropping all traffic
# and specifying what is allowed is the best way to make a secure firewall.

# Warning: If you are logged in via SSH, the following will immediately
# disconnect the SSH session. To avoid it: (1) add the first INPUT chain rule
# below (it will keep the session open), (2) add a regular rule to allow
# inbound SSH (to be able to reconnect in case of a connection drop) and (3)
# set the policy.

iptables -P INPUT DROP


# Every packet that is received by any network interface will pass the INPUT
# chain first, if it is destined for this machine. In this chain, we make sure
# that only the packets that we want are accepted.

# The first rule added to the INPUT chain will allow traffic that belongs to
# established connections, or new valid traffic that is related to these
# connections such as ICMP errors, or echo replies (the packets a host returns
# when pinged). ICMP stands for Internet Control Message Protocol. Some ICMP
# messages are very important and help to manage congestion and MTU, and are
# accepted by this rule.

# The connection state ESTABLISHED implies that either another rule previously
# allowed the initial (--ctstate NEW) connection attempt or the connection was
# already active (for example an active remote SSH connection) when setting the
# rule:

iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# The second rule will accept all traffic from the "loopback" (lo) interface,
# which is necessary for many applications and services.

# Note: You can add more trusted interfaces here such as "eth1" if you do not
# want/need the traffic filtered by the firewall, but be warned that if you
# have a NAT setup that redirects any kind of traffic to this interface from
# anywhere else in the network (let's say a router), it will get through,
# regardless of any other settings you may have.

iptables -A INPUT -i lo -j ACCEPT

# The third rule will drop all traffic with an "INVALID" state match. Traffic
# can fall into four "state" categories: NEW, ESTABLISHED, RELATED or INVALID
# and this is what makes this a "stateful" firewall rather than a less secure
# "stateless" one. States are tracked using the "nf_conntrack_*" kernel modules
# which are loaded automatically by the kernel as you add rules.

# Note:
    # This rule will drop all packets with invalid headers or checksums,
    # invalid TCP flags, invalid ICMP messages (such as a port unreachable when
    # we did not send anything to the host), and out of sequence packets which
    # can be caused by sequence prediction or other similar attacks. The "DROP"
    # target will drop a packet without any response, contrary to REJECT which
    # politely refuses the packet. We use DROP because there is no proper
    # "REJECT" response to packets that are INVALID, and we do not want to
    # acknowledge that we received these packets.

    # ICMPv6 Neighbor Discovery packets remain untracked, and will always be
    # classified "INVALID" though they are not corrupted or the like. Keep this
    # in mind, and accept them before this rule! iptables -A INPUT -p 41 -j
    # ACCEPT

iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# The next rule will accept all new incoming ICMP echo requests, also known as
# pings. Only the first packet will count as NEW, the rest will be handled by
# the RELATED,ESTABLISHED rule. Since the computer is not a router, no other
# ICMP traffic with state NEW needs to be allowed.

iptables -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT

# Now we attach the TCP and UDP chains to the INPUT chain to handle all new
# incoming connections. Once a connection is accepted by either TCP or UDP
# chain, it is handled by the RELATED/ESTABLISHED traffic rule. The TCP and UDP
# chains will either accept new incoming connections, or politely reject them.
# New TCP connections must be started with SYN packets.

# Note: NEW but not SYN is the only invalid TCP flag not covered by the INVALID
# state. The reason is because they are rarely malicious packets, and they
# should not just be dropped. Instead, we simply do not accept them, so they
# are rejected with a TCP RESET by the next rule.

iptables -A INPUT -p udp -m conntrack --ctstate NEW -j UDP
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP

# We reject TCP connections with TCP RESET packets and UDP streams with ICMP
# port unreachable messages if the ports are not opened. This imitates default
# Linux behavior (RFC compliant), and it allows the sender to quickly close the
# connection and clean up.

iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset

# For other protocols, we add a final rule to the INPUT chain to reject all
# remaining incoming traffic with icmp protocol unreachable messages. This
# imitates Linux's default behavior.

iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable


# If you are setting up the firewall remotely via SSH, append the following
# rule to allow new SSH connections before continuing (adjust port as
# required):
iptables -A TCP -p tcp --dport 22 -j ACCEPT


# Bruteforce attacks

# Unfortunately, bruteforce attacks on services accessible via an external IP
# address are common. One reason for this is that the attacks are easy to do
# with the many tools available. Fortunately, there are a number of ways to
# protect the services against them. One is the use of appropriate iptables
# rules which activate and blacklist an IP after a set number of packets
# attempt to initiate a connection. Another is the use of specialised daemons
# that monitor the logfiles for failed attempts and blacklist accordingly.

# Warning: Using an IP blacklist will stop trivial attacks but it relies on an
# additional daemon and successful logging (the partition containing /var can
# become full, especially if an attacker is pounding on the server).
# Additionally, if the attacker knows your IP address, they can send packets
# with a spoofed source header and get you locked out of the server. SSH keys
# provide an elegant solution to the problem of brute forcing without these
# problems.

# Two packages that ban IPs after too many password failures are Fail2ban or,
# for sshd in particular, Sshguard. These two applications update iptables
# rules to reject future connections from blacklisted IP addresses.

# The following rules give an example configuration to mitigate SSH bruteforce
# attacks using iptables.

iptables -N IN_SSH
iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -j IN_SSH
iptables -A IN_SSH -m recent --name sshbf --rttl --rcheck --hitcount 3 --seconds 10 -j DROP
iptables -A IN_SSH -m recent --name sshbf --rttl --rcheck --hitcount 4 --seconds 1800 -j DROP
iptables -A IN_SSH -m recent --name sshbf --set -j ACCEPT

# Most of the options should be self-explanatory, they allow for three
# connection packets in ten seconds. Further tries in that time will blacklist
# the IP. The next rule adds a quirk by allowing a total of four attempts in 30
# minutes. This is done because some bruteforce attacks are actually performed
# slow and not in a burst of attempts. The rules employ a number of additional
# options. To read more about them, check the original reference for this
# example: compilefailure.blogspot.com

# Using the above rules, now ensure that:
iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -j IN_SSH


iptables-save > /etc/iptables/iptables.rules
