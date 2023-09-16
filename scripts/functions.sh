#!/bin/bash

gitFolderResetAndBackup()
{
    update_done=false
    # Folder setup
    # Check if the directory specified in $script_dir exists
    if [ ! -d "$backup_install_dir/$backupFolder" ]; then
        result=$(mkdirFolders "$backup_install_dir/$backupFolder")
        checkSuccess "Create the backup folder"
    fi
    result=$(cd $backup_install_dir)
    checkSuccess "Going into the backup install folder"
    
    # Copy folders
    result=$(copyFolder "$configs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the configs to the backup folder"
    result=$(copyFolder "$logs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the logs to the backup folder"
    
    # Reset git
    result=$(sudo -u $easydockeruser rm -rf $script_dir)
    checkSuccess "Deleting all Git files"
    result=$(mkdirFolders "$script_dir")
    checkSuccess "Create the directory if it doesn't exist"
    cd "$script_dir"
    checkSuccess "Going into the install folder"
    result=$(sudo -u $easydockeruser git clone "$repo_url" "$script_dir" > /dev/null 2>&1)
    checkSuccess "Clone the Git repository"
    
    # Copy files back into the install folder
    result=$(copyFolders "$backup_install_dir/$backupFolder/" "$script_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"
    
    # Zip up folder for safe keeping and remove folder
    result=$(sudo -u $easydockeruser zip -r "$backup_install_dir/$backupFolder.zip" "$backup_install_dir/$backupFolder")
    checkSuccess "Zipping up the the backup folder for safe keeping"
    result=$(sudo rm -rf "$backup_install_dir/$backupFolder")
    checkSuccess "Removing the backup folder"
    
    # Fixing the issue where the git does not use the .gitignore
    result=$(cd $script_dir)
    checkSuccess "Going into the install folder"
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_backup > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_general > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_requirements > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $configs_dir/$ip_file > /dev/null 2>&1
    sudo -u $easydockeruser find "$containers_dir" -type f -name '*.config' -exec git rm --cached {} \; > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $logs_dir/$docker_log_file > /dev/null 2>&1
    sudo -u $easydockeruser git rm --cached $logs_dir/$backup_log_file > /dev/null 2>&1
    isSuccessful "Removing configs and logs from git for git changes"
    result=$(sudo -u $easydockeruser git commit -m "Stop tracking ignored files")
    checkSuccess "Removing tracking ignored files"
    
    isSuccessful "Custom changes have been discarded successfully"
    update_done=true
}

function userExists() {
    if id "$1" &>/dev/null; then
        return 0 # User exists
    else
        return 1 # User does not exist
    fi
}

function checkSuccess()
{
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SUCCESS:${NC} $1"
        if [ -f "$logs_dir/$docker_log_file" ]; then
            echo "SUCCESS: $1" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" >/dev/null
        fi
    else
        echo -e "${RED}ERROR:${NC} $1"
        # Ask to continue
        while true; do
            isQuestion "An error has occurred. Do you want to continue, exit or go to back to the Menu? (c/x/m) "
            read -rp "" error_occurred
            if [[ -n "$error_occurred" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        
        if [[ "$error_occurred" == [cC] ]]; then
            isNotice "Continuing after error has occured."
        fi
        
        if [[ "$error_occurred" == [xX] ]]; then
            # Log the error output to the log file
            echo "ERROR: $1" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file"
            echo "===================================" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file"
            exit 1  # Exit the script with a non-zero status to stop the current action
        fi
        
        if [[ "$error_occurred" == [mM] ]]; then
            # Log the error output to the log file
            echo "ERROR: $1" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file"
            echo "===================================" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file"
            resetToMenu
        fi
    fi
}

function isSuccessful()
{
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

function isError()
{
    echo -e "${RED}ERROR:${NC} $1"
}

function isFatalError()
{
    echo -e "${RED}ERROR:${NC} $1"
}

function isFatalErrorExit()
{
    echo -e "${RED}ERROR:${NC} $1"
    echo ""
    exit 1
}

function isNotice()
{
    echo -e "${YELLOW}NOTICE:${NC} $1"
}

function isQuestion()
{
    echo -e -n "${BLUE}QUESTION:${NC} $1 "
}

function isOptionMenu()
{
    echo -e -n "${PINK}OPTION:${NC} $1"
}

function isOption()
{
    echo -e "${PINK}OPTION:${NC} $1"
}

detectOS()
{
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "$NAME" in
            "Debian GNU/Linux")
                detected_os="Debian 10 / 11 / 12"
            OS=1 ;;
            "Ubuntu")
                case "$VERSION_ID" in
                    "18.04")
                        detected_os="Ubuntu 18.04"
                    OS=2 ;;
                    "20.04" | "21.04" | "22.04")
                        detected_os="Ubuntu 20.04 / 21.04 / 22.04"
                    OS=3 ;;
                esac
            ;;
            "Arch Linux")
                detected_os="Arch Linux"
            OS=4 ;;
            *)  # Default selection (End this Installer)
                echo "Unable to detect OS."
            exit 1 ;;
        esac
        
        echo ""
        checkSuccess "Detected OS: $detected_os"
        
        if [ "$OS" -gt 1 ]; then
            isError "This OS ($detected_os) is untested and may not be fully supported."
            while true; do
                isQuestion "Do you wish to continue anyway? (y/n): "
                read -rp "" oswarningaccept
                if [[ -n "$oswarningaccept" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
        fi
        
        installDockerUser;
        scanConfigsForRandomPassword;
        checkRequirements;
    else
        checkSuccess "Unable to detect OS."
        exit 1
    fi
}

passwordValidation()
{
    # Password Setup for DB with complexity checking
    # Initialize valid password flag
    valid_password=false
    # Loop until a valid password is entered
    while [ $valid_password = false ]
    do
        # Prompt the user for a password
        echo -n "Enter your password: "
        # Disable echoing of the password input, so that it is not displayed on the screen
        stty -echo
        # Read in the password input
        read password
        # Re-enable echoing of the input
        stty echo
        echo
        # Check the length of the password
        if [ ${#password} -lt 8 ]; then
            isError "Password is too short. Please enter a password with at least 8 characters."
            continue
        fi
        # Check the complexity of the password
        if ! [[ "$password" =~ [[:lower:]] ]] || ! [[ "$password" =~ [[:upper:]] ]] || ! [[ "$password" =~ [[:digit:]] ]]; then
            isError "Password is not complex enough. Please include at least one uppercase letter, one lowercase letter, and one numeric digit."
            continue
        fi
        # If we make it here, the password is valid
        valid_password=true
    done
}

emailValidation()
{
    # Initialize email variable to empty string
    email=""
    
    # Loop until a valid email is entered
    while [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        
        # Prompt user to submit email
        isQuestion "Please enter your email address: "
        read -p "" email
        
        # Check email format using regex
        if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            isError "Invalid email format. Please try again."
        fi
        
    done
}

removeEmptyLineAtFileEnd()
{
    local file_path="$1"
    local last_line=$(tail -n 1 "$file_path")
    
    if [ -z "$last_line" ]; then
        result=$(sudo sed -i '$d' "$file_path")
        checkSuccess "Removed the empty line at the end of $file_path"
    fi
}

showInstallInstructions()
{
    echo ""
    echo "#####################################"
    echo "###       Usage Instructions      ###"
    echo "#####################################"
    echo ""
    isNotice "Please select 'c' for each item you would like to edit the config."
    isNotice "Please select 'i' for each item you would like to install."
    isNotice "Please select 'u' for each item you would like to uninstall."
    isNotice "Please select 's' for each item you would like to shutdown."
    isNotice "Please select 'r' for each item you would like to restart."
}

completeMessage()
{
    echo ""
    isSuccessful "You seem to have reached the end of the script! Restarting.... <3"
    echo ""
    sleep 1
}

resetToMenu()
{
    # Apps
    fail2ban=n
    traefik=n
    wireguard=n
    pihole=n
    portainer=n
    watchtower=n
    dashy=n
    searxng=n
    speedtest=n
    ipinfo=n
    trilium=n
    vaultwarden=n
    jitsimeet=n
    owncloud=n
    killbill=n
    mattermost=n
    kimai=n
    mailcow=n
    tiledesk=n
    gitlab=n
    actual=n
    akaunting=n
    cozy=n
    duplicati=n
    caddy=n
    
    # Backup
    backupsingle=n
    backupfull=n
    
    # Restore
    restoresingle=n
    restorefull=n
    
    # Mirate
    migratecheckforfiles=n
    migratemovefrommigrate=n
    migrategeneratetxt=n
    migratescanforupdates=n
    migratescanforconfigstomigrate=n
    migratescanformigratetoconfigs=n
    
    # Database
    toollistalltables=n
    toollistallapps=n
    toollistinstalledapps=n
    toolupdatedb=n
    toolemptytable=n
    tooldeletedb=n
    
    # Tools
    toolsresetgit=n
    toolstartpreinstallation=n
    toolsstartcrontabsetup=n
    toolrestartcontainers=n
    toolstopcontainers=n
    toolsremovedockermanageruser=n
    toolsinstalldockermanageruser=n
    toolinstallremotesshlist=n
    toolinstallcrontab=n
    toolinstallcrontabssh=n
    
    mainMenu
    return 1
}

