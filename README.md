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

## Reason for Making this Script. 
Deploying servers can be a tedious process, especially when it involves installing multiple dependencies and configuring various settings. 

This script aims to streamline the installation process by automating it, saving time and effort by eliminating the need for manual installation and setup. By using this script, users can easily and quickly deploy servers without the hassle of dealing with complex installation procedures. 

In addition, the use of Docker makes the deployment process even more efficient and lightweight, allowing applications to run smoothly and reliably. 

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