# NOTICE

THIS HAS ONLY BEEN TESTED ON DEBIAN!
It should work with Ubuntu, but OS's with different commands will not work at the moment.

# Usage
The usage of an automated Docker script is highly beneficial for system administrators and developers alike. 

This type of script helps to simplify the deployment and management of Docker containers by automating tasks such as container creation, configuration, and deployment. 

Ultimately, an automated Docker script is a powerful solution that streamlines the process of containerization and significantly enhances the productivity of users, making it an essential tool for modern system admin and DevOps teams.

## Reason for Making this Script. 
Deploying servers can be a tedious process, especially when it involves installing multiple dependencies and configuring various settings. 

This script aims to streamline the installation process by automating it, saving time and effort by eliminating the need for manual installation and setup. By using this script, users can easily and quickly deploy servers without the hassle of dealing with complex installation procedures. 

In addition, the use of Docker makes the deployment process even more efficient and lightweight, allowing applications to run smoothly and reliably. 

## Using this script
1. Upload init.sh to the root folder
2. Run - "cd ~ && chmod 0755 init.sh && ./init.sh run && source ~/.bashrc && easydocker"
3. Make that selection, and the install will continue.
4. Answering "n" or pressing enter to any option will cause them to be skipped.

### NOTE
* All networking is currently routed through the VPN network

## Future Work
- [ ] Add postfix by default
- [ ] Add Duplicate Reports on Restart: https://www.abuseipdb.com/fail2ban.html
- [ ] Add Rustdesk https://github.com/rustdesk/rustdesk-server
- [ ] Finish setup of Mailcow software
- [ ] Finish setup of Akaunting software
- [ ] Backup & Restore Scripts
- [ ] Update networks with best security practices
- [ ] Password encryption
- [ ] Test on other Operating Systems other than Debian 11

## Contributing
If you find issues, please let me know. I'm always open to new contributors helping progress this project.

## Licensing
My script is offered without warranty against defect, and is free for you to use any way / time you want.  You may modify it in any way you see fit.  Please see the individual project pages of the software packages for their licensing.

# Credit
Taken and modified from https://gitlab.com/bmcgonag/docker_installs.git