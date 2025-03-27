#!/bin/bash

cliInitialize() 
{
    cliUpdateCommands;

    if [ "$initial_command1" = "help" ] || [ -z "$initial_command1" ]; then
        cliShowCommands;

    elif [ "$initial_command1" = "install" ]; then
        if [[ -z "$initial_command2" ]]; then
            install_via_cli="true"
            startLoad;
        elif [ "$initial_command2" = "unattended" ]; then
            install_via_cli="true"
            startLoad unattended;
        else
            isNotice "Invalid app command used : ${RED}$initial_command2${NC}"
            isNotice "Please use one of the following options below :"
            echo ""
            cliInstallCommands;
        fi

    elif [ "$initial_command1" = "restore" ]; then
        checkRemoteBackupEnabled;
        if [[ $remote_backups_disabled == "true" ]]; then
            local remote_backup_status="Enabled"
        elif [[ $remote_backups_disabled == "false" ]]; then
            local remote_backup_status="Disabled"
        fi
        checkRemoteBackupStatus()
        {
            echo ""
            isNotice "Remote restore is currently : ${RED}$remote_backup_status${NC}"
            if [[ $remote_backups_disabled == "false" ]]; then
                echo ""
                isNotice "Run the command 'easydocker config backup' to setup the config."
                echo ""
            fi
        }
        if [[ -z "$initial_command2" ]]; then
            cliRestoreCommands;


        elif [ "$initial_command2" = "app" ]; then
            if [[ -z "$initial_command3" ]]; then
                cliRestoreAppCommands;

            elif [ "$initial_command3" = "remote" ]; then
                if [[ -z "$initial_command4" ]]; then
                    cliRestoreAppCommands;
                elif [[ ! -z "$initial_command4" ]]; then
                    checkRemoteBackupStatus;
                    if [[ $remote_backups_disabled == "true" ]]; then
                        while true; do
                            read -rp "Remote backups are not configured. Do you want to edit the backup configuration now? (Y/N): " remotebackupsetup
                            case "$remotebackupsetup" in
                                [Yy]) 
                                    viewEasyDockerConfigs "backup"
                                    sourceScanFiles "easydocker_configs"
                                    break
                                    ;;
                                [Nn]) 
                                    isNotice "Skipping backup configuration."
                                    break
                                    ;;
                                *) 
                                    isNotice "Invalid input. Please enter 'Y' or 'N'."
                                    ;;
                            esac
                        done
                    elif [[ $remote_backups_disabled == "false" ]]; then
                        restoreStart app remote $initial_command4
                    fi
                fi

            elif [ "$initial_command3" = "local" ]; then
                if [[ -z "$initial_command4" ]]; then
                    cliRestoreAppCommands;
                elif [[ ! -z "$initial_command4" ]]; then
                    checkRemoteBackupStatus;
                    if [[ $remote_backups_disabled == "true" ]]; then
                        while true; do
                            read -rp "Remote backups are not configured. Do you want to edit the backup configuration now? (Y/N): " remotebackupsetup
                            case "$remotebackupsetup" in
                                [Yy]) 
                                    viewEasyDockerConfigs "backup"
                                    sourceScanFiles "easydocker_configs"
                                    break
                                    ;;
                                [Nn]) 
                                    isNotice "Skipping backup configuration."
                                    break
                                    ;;
                                *) 
                                    isNotice "Invalid input. Please enter 'Y' or 'N'."
                                    ;;
                            esac
                        done
                    elif [[ $remote_backups_disabled == "false" ]]; then
                        restoreStart app local $initial_command4
                    fi
                fi
            fi


        elif [ "$initial_command2" = "virtualmin" ]; then
            if [[ -z "$initial_command3" ]]; then
                cliRestoreVirtualminCommands;


            elif [ "$initial_command3" = "domain" ]; then
                if [[ -z "$initial_command4" ]]; then
                    cliRestoreVirtualminCommands;

                elif [ "$initial_command4" = "remote" ]; then
                    checkRemoteBackupStatus;
                    if [[ $remote_backups_disabled == "true" ]]; then
                        while true; do
                            read -rp "Remote backups are not configured. Do you want to edit the backup configuration now? (Y/N): " remotebackupsetup
                            case "$remotebackupsetup" in
                                [Yy]) 
                                    viewEasyDockerConfigs "backup"
                                    sourceScanFiles "easydocker_configs"
                                    break
                                    ;;
                                [Nn]) 
                                    isNotice "Skipping backup configuration."
                                    break
                                    ;;
                                *) 
                                    isNotice "Invalid input. Please enter 'Y' or 'N'."
                                    ;;
                            esac
                        done
                    elif [[ $remote_backups_disabled == "false" ]]; then

                        restoreStart virtualmin domain remote
                    fi

                elif [ "$initial_command4" = "local" ]; then
                    if [[ -z "$initial_command5" ]]; then
                        cliRestoreVirtualminCommands;
                    else
                        restoreStart virtualmin domain local
                    fi
                fi
            
            elif [ "$initial_command3" = "config" ]; then
                if [[ -z "$initial_command4" ]]; then
                    cliRestoreVirtualminCommands;

                elif [ "$initial_command4" = "remote" ]; then
                    checkRemoteBackupStatus;
                    if [[ $remote_backups_disabled == "true" ]]; then
                        while true; do
                            read -rp "Remote backups are not configured. Do you want to edit the backup configuration now? (Y/N): " remotebackupsetup
                            case "$remotebackupsetup" in
                                [Yy]) 
                                    viewEasyDockerConfigs "backup"
                                    sourceScanFiles "easydocker_configs"
                                    break
                                    ;;
                                [Nn]) 
                                    isNotice "Skipping backup configuration."
                                    break
                                    ;;
                                *) 
                                    isNotice "Invalid input. Please enter 'Y' or 'N'."
                                    ;;
                            esac
                        done
                    elif [[ $remote_backups_disabled == "false" ]]; then
                        restoreStart virtualmin config remote
                    fi

                elif [ "$initial_command4" = "local" ]; then
                    restoreStart virtualmin config local
                fi

            else
                isNotice "Invalid command used : ${RED}$initial_command3${NC}"
                isNotice "Please use one of the following options below :"
                echo ""
                cliRestoreVirtualminCommands;
            fi
        else
            isNotice "Invalid app command used : ${RED}$initial_command2${NC}"
            isNotice "Please use one of the following options below :"
            echo ""
            cliRestoreCommands;
        fi


    elif [ "$initial_command1" = "update" ]; then
        checkUpdates;

    elif [ "$initial_command1" = "reset" ]; then
        runReinstall;

    elif [ "$initial_command1" = "app" ]; then
        checkSuccessfulRun;
        checkInstallTypeRequirement;

        if [[ -z "$initial_command2" ]]; then
            cliAppCommands;

        elif [ "$initial_command2" = "list" ]; then
            if [[ -z "$initial_command3" ]]; then
                cliAppListCommands;
            elif [ "$initial_command3" = "available" ]; then
                appScanAvailable;
            elif [ "$initial_command3" = "installed" ]; then
                databaseListInstalledApps;
            else
                isNotice "Invalid app command used : ${RED}$initial_command3${NC}"
                isNotice "Please use one of the following options below :"
                echo ""
                cliAppListCommands;
            fi

        elif [ "$initial_command2" = "install" ]; then
            dockerInstallApp "$initial_command3";
        elif [ "$initial_command2" = "uninstall" ]; then
            dockerUninstallApp "$initial_command3";
        elif [ "$initial_command2" = "start" ]; then
            dockerStartApp "$initial_command3";
        elif [ "$initial_command2" = "stop" ]; then
            dockerStopApp "$initial_command3";
        elif [ "$initial_command2" = "restart" ]; then
            dockerRestartApp "$initial_command3";
        elif [ "$initial_command2" = "up" ]; then
            dockerComposeUp "$initial_command3";
        elif [ "$initial_command2" = "down" ]; then
            dockerComposeDown "$initial_command3";
        elif [ "$initial_command2" = "reload" ]; then
            dockerRestartAppViaInstall "$initial_command3";
        elif [ "$initial_command2" = "backup" ]; then
            if [[ -z "$initial_command3" ]]; then
                isNotice "No app provided."
                isNotice "Please provide an application name to backup."
                cliAppListCommands;
            else
                backupStart "$initial_command3";
            fi
        elif [ "$initial_command2" = "generate" ]; then
            if [[ -z "$initial_command3" ]]; then
                isNotice "No app provided."
                isNotice "Please provide an application name to backup."
                cliAppListCommands;
            else
                appGenerate "$initial_command3";
            fi
        else
            isNotice "Invalid app command used : ${RED}$initial_command2${NC}"
            isNotice "Please use one of the following options below :"
            echo ""
            cliAppCommands;
        fi

    elif [ "$initial_command1" = "dockertype" ]; then

        if [[ -z "$initial_command2" ]]; then
            cliDockertypeCommands;

        # First param given
        elif [ "$initial_command2" = "rooted" ]; then
            result=$(sudo sed -i "s|CFG_DOCKER_INSTALL_TYPE=rootless|CFG_DOCKER_INSTALL_TYPE=rooted|" "$configs_dir$config_file_general")
            checkSuccess "Updating CFG_DOCKER_INSTALL_TYPE to root in the $configs_dir$config_file_general config."
            source $configs_dir$config_file_general
            dockerSwitcherSwap cli;
        elif [ "$initial_command2" = "rootless" ]; then
            result=$(sudo sed -i "s|CFG_DOCKER_INSTALL_TYPE=rooted|CFG_DOCKER_INSTALL_TYPE=rootless|" "$configs_dir$config_file_general")
            checkSuccess "Updating CFG_DOCKER_INSTALL_TYPE to rootless in the $configs_dir$config_file_general config."
            source $configs_dir$config_file_general
            dockerSwitcherSwap cli;
        else
            isNotice "Invalid dockertype used : ${RED}$initial_command2${NC}"
            isNotice "Please use one of the following options below :"
            echo ""
            cliDockertypeCommands;
        fi

    elif [ -z "$initial_command1" ]; then
        echo ""
        echo "No option given, showing command menu..."
        cliShowCommands

    else
        echo "Unknown command: $initial_command1"
        cliShowCommands
    fi

    echo ""
}
