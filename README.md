<h1 align="center" style="border-bottom: none">
    <b>
        <a href="https://scottwebstar.co.uk/services/off-grid-it-systems/">EasyDocker</a><br>
    </b>
    ⭐️  Docker has never been so easy!  ⭐️ <br>
</h1>

<p align="center">
You can ditch the old popular data scraping platforms and replace them with your very own Open Source privacy based software giving you full control of your data.
</p>

<p align="center">
<a href="https://github.com/OpenSourceWebstar/EasyDocker"><img src="https://img.shields.io/github/stars/OpenSourceWebstar/EasyDocker?logo=github"></a>
<a href="https://github.com/OpenSourceWebstar/EasyDocker"><img src="https://img.shields.io/github/forks/OpenSourceWebstar/EasyDocker?label=forks"></a>
<a href="https://opensource.org/licenses/AGPL-3.0"><img src="https://img.shields.io/badge/license-AGPL-purple.svg" alt="License: AGPL"></a>
</p>

<p align="center"><img src="https://scottwebstar.co.uk/wp-content/uploads/2023/08/easydocker-intro.jpg" alt="EasyDocker Intro" width="1000px" /></p>
<p align="center"><img src="https://scottwebstar.co.uk/wp-content/uploads/2023/08/easydocker-menu.jpg" alt="EasyDocker Menu" width="1000px" /></p>
<p align="center"><img src="https://scottwebstar.co.uk/wp-content/uploads/2023/08/easydocker-system-apps.jpg" alt="EasyDocker System Apps" width="1000px" /></p>
<p align="center"><img src="https://scottwebstar.co.uk/wp-content/uploads/2023/08/easydocker-crontab.jpg" alt="EasyDocker Crontab" width="1000px" /></p>

# NOTICE
THIS HAS ONLY BEEN TESTED ON DEBIAN!<br/>
It should work with Ubuntu, but OS's with different commands will not work at the moment.

# Usage
The usage of an automated Docker script is highly beneficial for system administrators and developers alike. 

This type of script helps to simplify the deployment and management of Docker containers by automating tasks such as container creation, configuration, and deployment. 

Ultimately, an automated Docker script is a powerful solution that streamlines the process of containerization and significantly enhances the productivity of users, making it an essential tool for modern system admin and DevOps teams.

# Apps Available

| Type           | Name                                                                                                |  Status          | 
| -------------- | --------------------------------------------------------------------------------------------------- | ---------------- | 
| System         | <a href="https://github.com/fail2ban/fail2ban">Fail2Ban - Connection Security</a>                   | Tested & Working |
| System         | <a href="https://github.com/traefik/traefik">Traefik - Reverse Proxy</a>                            | Tested & Working |
| System         | <a href="https://github.com/wg-easy/wg-easy">Wireguard Easy - VPN Server</a>                        | Tested & Working |
| System         | <a href="https://github.com/AdguardTeam/AdGuardHome">Adguard & Unbound - DNS Server</a>             | Tested & Working |
| System         | <a href="https://github.com/pi-hole/pi-hole">Pi-Hole & Unbound - DNS Server</a>                     | Tested & Working |
| System         | <a href="https://github.com/portainer/portainer">Portainer - Docker Management</a>                  | Tested & Working |
| System         | <a href="https://github.com/containrrr/watchtower">Watchtower - Docker Updater</a>                  | Tested & Working |
| System         | <a href="https://github.com/Lissy93/dashy">Dashy - Docker Dashboard</a>                             | Tested & Working |
| Privacy        | <a href="https://github.com/searxng/searxng">Searxng - Search Engine</a>                            | Tested & Working |
| Privacy        | <a href="https://github.com/librespeed/speedtest">LibreSpeed - Internet Speed Test</a>              | Tested & Working |
| Privacy        | <a href="https://github.com/PeterDaveHello/ipinfo.tw">IPInfo - Show IP Address</a>                  | Tested & Working |
| Privacy        | <a href="https://github.com/zadam/trilium">Trilium - Note Manager</a>                               | Tested & Working |
| Privacy        | <a href="https://github.com/dani-garcia/vaultwarden">Vaultwarden - Password Manager</a>             | Tested & Working |
| Privacy        | <a href="https://github.com/firefly-iii/firefly-iii/">Firefly - Money Budgetting</a>                | Tested & Working |
| Privacy        | <a href="https://github.com/mailcow/mailcow-dockerized">Mailcow - Mail Server</a> *UNFINISHED*      | Needs Testing    |
| User           | <a href="https://github.com/jitsi/docker-jitsi-meet">Jitsi Meet - Video Conferencing</a>            | Tested & Working |
| User           | <a href="https://github.com/owncloud-docker/server">OwnCloud - File & Document Cloud</a>            | Tested & Working |
| User           | <a href="https://github.com/killbill/killbill">Killbill - Payment Processing</a>                    | Tested & Working |
| User           | <a href="https://github.com/mattermost/mattermost">Mattermost - Collaboration Platform</a>          | Tested & Working |
| User           | <a href="https://github.com/kimai/kimai">Kimai - Online-Timetracker</a>                             | Tested & Working |
| User           | <a href="https://github.com/Tiledesk/tiledesk">Tiledesk - Live Chat Platform</a> *UNFINISHED*       | Needs Finishing  |
| User           | <a href="https://github.com/rustdesk/rustdesk/">Rustdesk - Remote Desktop Server</a>                | Needs Testing    |
| User           | <a href="https://gitlab.com/gitlab-org/gitlab">GitLab - DevOps Platform</a> *UNFINISHED*            | Needs Testing    |
| Old            | <a href="https://github.com/duplicati/duplicati">Duplicati - Backups</a>                            | Tested & Working |


## Instructions
1. Run the following commands :  

```
cd ~ && rm -rf init.sh && apt-get install wget -y && wget -O init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 init.sh && ./init.sh run && su - easydocker -c 'source ~/.bashrc' && su easydocker
```
2. Let the install run and wait for the menu to show.
3. Once the menu is shown, choose the option you desire.

### NOTE
* All networking is currently routed through the VPN network

## Future Plans
- [ ] Finish setup of Mailcow software
- [ ] Finish setup of Akaunting software
- [ ] Jitisi Meet - Coturn Needed for improvement
- [ ] Migration Script
- [ ] Test on other Operating Systems other than Debian 11

## Improvements/Ideas
- [ ] Add postfix by default
- [ ] Add Duplicate Reports on Restart: https://www.abuseipdb.com/fail2ban.html
- [ ] Update networks with best security practices
- [ ] Password encryption

## Contributing
If you find issues, please let me know. I'm always open to new contributors helping progress this project.

## Licensing
My script is offered without warranty against defect, and is free for you to use any way / time you want.  You may modify it in any way you see fit.  Please see the individual project pages of the software packages for their licensing.

# Credit
* Inspired by https://opensourceisawesome.com <br/>
* Based on https://gitlab.com/bmcgonag/docker_installs.git <br/>
* Managed services available at https://scottwebstar.co.uk/it-services/   