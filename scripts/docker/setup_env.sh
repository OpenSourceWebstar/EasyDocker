#!/bin/bash

dockerSetupEnvFile()
{
    local result=$(copyFile "loud" $containers_dir$app_name/env.example $containers_dir$app_name/.env $docker_install_user)
    checkSuccess "Setting up .env file to path"
}
