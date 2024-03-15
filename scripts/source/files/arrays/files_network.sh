#!/bin/bash

network_scripts=(
    "network/dns/setup_dns_ip.sh"
    "network/dns/setup_dns.sh"

    "network/ports/open/port_close.sh"
    "network/ports/open/port_open_add_conflict.sh"
    "network/ports/open/port_open_add_ufwd.sh"
    "network/ports/open/port_open_all_ufwd.sh"
    "network/ports/open/port_open_conflict_found.sh"
    "network/ports/open/port_open.sh"

    "network/ports/used/port_unuse.sh"
    "network/ports/used/port_use.sh"
    "network/ports/used/port_used_add_conflict.sh"
    "network/ports/used/port_used_conflict_found.sh"

    "network/ports/port_clear_all_data.sh"
    "network/ports/port_handle_all_conflicts.sh"
    "network/ports/ports_check_app.sh"
    "network/ports/ports_remove_app.sh"
    "network/ports/ports_remove_from_db.sh"
    "network/ports/ports_remove_stale.sh"

    "network/variables/basic_app.sh"
    "network/variables/basic_scan.sh"
    "network/variables/headscale_variables.sh"
    "network/variables/install_variables.sh"
    "network/variables/ips_hostnames.sh"

    "network/firewall_commands.sh"
    "network/ssh.sh"
)
