#!/bin/bash

sourceScripts()
{
    source scripts/sources.sh
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

dashyUpdateConf() 
{
    # Hardcoded path to Dashy's conf.yml file
    conf_file="${install_dir}dashy/conf.yml"

    # Clean up for new generation
    sudo rm -rf ${install_dir}dashy/conf.yml

    # Check if Dashy app is installed
    if [ -d "${install_dir}dashy" ]; then
        echo ""
        echo "#####################################"
        echo "###    Dashy Config Generation    ###"
        echo "#####################################"
        echo ""

        # Copy the default dashy conf.yml configuration file
        result=$(copyResource "dashy" "conf.yml" "conf.yml")
        checkSuccess "Copy default dashy conf.yml configuration file"

        local original_md5
        original_md5=$(md5sum "$conf_file")

        # Initialize changes_made flag as false
        changes_made=false

        # Function to uncomment lines using sed based on line numbers under the pattern
        uncomment_lines() {
            local app_name="$1"
            local pattern="#### app $app_name"
            local start_line=$(grep -n "$pattern" "$conf_file" | cut -d: -f1)

            if [ -n "$start_line" ]; then
                # Uncomment lines under the app section based on line numbers
                sudo sed -i "$((start_line+1))s/#- title/- title/" "$conf_file"
                sudo sed -i "$((start_line+2))s/#  description/  description/" "$conf_file"
                sudo sed -i "$((start_line+3))s/#  icon/  icon/" "$conf_file"
                sudo sed -i "$((start_line+4))s/#  url/  url/" "$conf_file"
                sudo sed -i "$((start_line+5))s/#  statusCheck/  statusCheck/" "$conf_file"
                sudo sed -i "$((start_line+6))s/#  target/  target/" "$conf_file"
            #else
                #isNotice "App not found: $app_name"
            fi
        }

        # Function to uncomment category lines using sed based on line numbers under the pattern
        uncomment_category_lines() {
            local category_name="$1"
            local pattern="#### category $category_name"
            local start_line=$(grep -n "$pattern" "$conf_file" | cut -d: -f1)

            if [ -n "$start_line" ]; then
                # Uncomment lines under the category section based on line numbers
                sudo sed -i "$((start_line+1))s/^#- name/- name/" "$conf_file"
                sudo sed -i "$((start_line+2))s/^#  icon/  icon/" "$conf_file"
                sudo sed -i "$((start_line+3))s/^#  items/  items/" "$conf_file"
            #else
                #isNotice "Category not found: $category_name"
            fi
        }


            # Loop through immediate subdirectories of $install_dir
            for app_dir in "$install_dir"/*/; do
                # Get the app name from the folder name
                app_name=$(basename "$app_dir")

                # Call the uncomment_lines function for each app
                uncomment_lines "$app_name"
            done


        # Function to get the category name from the full path of an app
        get_category_name() {
            local app_path="$1"
            local category_name=$(basename "$(dirname "$app_path")")
            echo "$category_name"
        }

        # Collect all installed app paths
        installed_app_paths=()
        while IFS= read -r -d $'\0' app_name_dir; do
            app_name_path="$app_name_dir"
            installed_app_paths+=("$app_name_path")
        done < <(find "$containers_dir" -mindepth 2 -maxdepth 2 -type d -print0)

        # Get unique category names related to installed apps
        installed_categories=()
        for app_path in "${installed_app_paths[@]}"; do
            category_name=$(get_category_name "$app_path")
            # Add the category to the list if not already present
            if [[ ! " ${installed_categories[@]} " =~ " $category_name " ]]; then
                installed_categories+=("$category_name")
            fi
        done

        # Call the uncomment_category_lines function for each installed category
        for category_name in "${installed_categories[@]}"; do
            uncomment_category_lines "$category_name"
        done

        local updated_md5
        updated_md5=$(md5sum "$conf_file")

        # Check if changes were made to the file
        if [ "$original_md5" != "$updated_md5" ]; then
            isNotice "Changes made to dashy config file...restarting dashy..."
            result=$(runCommandForDockerInstallUser "docker restart dashy")
            checkSuccess "Restarting dashy docker container"
        else
            isSuccessful "No new changes made to the dashy config file."
        fi
    #else
        #isNotice "Dashy app not found...skipping application setup..."
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
    isNotice "TIP - You can use multiple options at once, but it will be in the order above"
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

