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

| Type           | Name                                             |  Status          | 
| -------------- | ------------------------------------------------ | ---------------- | 
| System         | Fail2Ban - Connection Security                   | Tested & Working |
| System         | Traefik - Reverse Proxy *RECOMMENDED*            | Tested & Working |
| System         | Caddy - Reverse Proxy *NOT RECOMMENDED*          | Tested & Working |
| System         | Wireguard Easy - VPN Server                      | Tested & Working |
| System         | Adguard & Unbound - DNS Server *RECOMMENDED*     | Tested & Working |
| System         | Pi-Hole & Unbound - DNS Server *NOT RECOMMENDED* | Tested & Working |
| System         | Portainer - Docker Management                    | Tested & Working |
| System         | Watchtower - Docker Updater                      | Tested & Working |
| System         | Dashy - Docker Dashboard                         | Tested & Working |
| Privacy        | Searxng - Search Engine                          | Tested & Working |
| Privacy        | Speedtest - Internet Testing                     | Tested & Working |
| Privacy        | IPInfo - Show IP Address                         | Tested & Working |
| Privacy        | Trilium - Note Manager                           | Tested & Working |
| Privacy        | Vaultwarden - Password Manager                   | Tested & Working |
| Privacy        | Actual - Money Budgetting                        | Tested & Working |
| Privacy        | Mailcow - Mail Server *UNFINISHED*               | Needs Testing    |
| User           | Jitsi Meet - Video Conferencing                  | Tested & Working |
| User           | OwnCloud - File & Document Cloud                 | Tested & Working |
| User           | Killbill - Payment Processing                    | Tested & Working |
| User           | Mattermost - Collaboration Platform              | Tested & Working |
| User           | Kimai - Online-Timetracker                       | Tested & Working |
| User           | Tiledesk - Live Chat Platform *UNFINISHED*       | Needs Finishing  |
| User           | GitLab - DevOps Platform *UNFINISHED*            | Needs Testing    |
| User           | Akaunting - Invoicing Solution *UNFINISHED*      | Needs Testing    |
| Old            | System - Duplicati - Backups                     | Tested & Working |
| Old            | User - Cozy - Cloud Platfrom *BROKEN             | Needs Fixing     |


## Instructions
1. Upload init.sh to your root (~) folder
2. Run - "cd ~ && chmod 0755 init.sh && ./init.sh run && source ~/.bashrc && easydocker"
3. Make that selection, and the install will continue.
4. Answering "n" or pressing enter to any option will cause them to be skipped.

### NOTE
* All networking is currently routed through the VPN network

## Future Plans
- [ ] Finish setup of Mailcow software
- [ ] Finish setup of Akaunting software
- [ ] Finish setup of Ruskdesk software
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