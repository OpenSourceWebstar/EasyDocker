#!/bin/bash

gitCleanInstallBackups()
{
    local result=$(sudo find "$backup_dir" -mindepth 1 -type f ! -name '*.zip' -o -type d ! -name '*.zip' -exec sudo rm -rf {} +)
    checkSuccess "Cleaning up install backup folders."
    local result=$(cd "$backup_dir" && sudo find . -maxdepth 1 -type f -name '*.zip' | sudo xargs ls -t | tail -n +6 | sudo xargs -r rm)
    checkSuccess "Deleting old install backup and keeping the latest 5."
}