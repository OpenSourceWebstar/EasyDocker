#!/bin/bash

function userExists() 
{
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
            echo "SUCCESS: $1" | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" >/dev/null
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
            echo "ERROR: $1" | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file"
            echo "===================================" | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file"
            exit 1  # Exit the script with a non-zero status to stop the current action
        fi
        
        if [[ "$error_occurred" == [mM] ]]; then
            # Log the error output to the log file
            echo "ERROR: $1" | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file"
            echo "===================================" | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file"
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
                case "$VERSION_ID" in
                    "10")
                        detected_os="Debian 10"
                        OS=1
                        ;;
                    "11")
                        detected_os="Debian 11"
                        OS=2
                        ;;
                    "12")
                        detected_os="Debian 12"
                        OS=3
                        ;;
                    *)
                        detected_os="Debian (Unknown Version)"
                        OS=4
                        ;;
                esac
                ;;
            "Ubuntu")
                case "$VERSION_ID" in
                    "18.04")
                        detected_os="Ubuntu 18.04"
                        OS=5
                        ;;
                    "20.04" | "21.04" | "22.04")
                        detected_os="Ubuntu 20.04 / 21.04 / 22.04"
                        OS=6
                        ;;
                    *)
                        detected_os="Ubuntu (Unknown Version)"
                        OS=7
                        ;;
                esac
                ;;
            "Arch Linux")
                detected_os="Arch Linux"
                OS=8
                ;;
            *)  # Default selection (End this Installer)
                echo "Unable to detect OS."
                exit 1
                ;;
        esac
        
        echo ""
        checkSuccess "Detected OS: $detected_os"
        
        if [ "$OS" -gt 3 ]; then
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
        
        startUp;
    else
        checkSuccess "Unable to detect OS."
        exit 1
    fi
}

fileHasEmptyLine() 
{
    tail -n 1 "$1" | [[ "$(cat -)" == "" ]]
}

containsElement() 
{
    local element="$1"
    shift
    local arr=("$@")

    for item in "${arr[@]}"; do
        if [[ "$item" == *"$element"* ]]; then
            return 0  # Substring found
        fi
    done
    return 1  # Substring not found
}

passwordValidation()
{
    # Password Setup for DB with complexity checking
    # Initialize valid password flag
    local valid_password=false
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
        local valid_password=true
    done
}

emailValidation()
{
    local input_email=$1

    # Check email format using regex
    if [[ ! $input_email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        isError "Invalid email format. Please try again."
        return 1  # Return 1 to indicate validation failure
    fi

    return 0  # Return 0 to indicate validation success
}

removeEmptyLineAtFileEnd()
{
    local file_path="$1"
    local last_line=$(tail -n 1 "$file_path")
    
    if [ -z "$last_line" ]; then
        local result=$(sudo sed -i '$d' "$file_path")
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
    isNotice "TIP - You can use multiple options at once, but it will be in the order below"
    echo ""
    isNotice "Please select 'c' to edit the config."
    isNotice "Please select 't' to use the tools."
    isNotice "Please select 'i' to install."
    isNotice "Please select 'u' to uninstall."
    isNotice "Please select 's' to shutdown."
    isNotice "Please select 'r' to restart."
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
    firefly=n
    cozy=n
    duplicati=n
    caddy=n
    authelia=n
    
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

