#!/bin/bash

setupHeadscaleCheckRemote()
{
    if [[ "$CFG_HEADSCALE_HOST" == "" ]]; then
        isError "Please setup a Headscale host in the EasyDocker General config for CFG_HEADSCALE_HOST"
        return
    fi
    if [[ "$CFG_HEADSCALE_KEY" == "" ]]; then
        isError "Please setup a Headscale Key in the EasyDocker General config for CFG_HEADSCALE_KEY"
        return
    fi
    isSuccessful "Remote Headscale config data has been provided...continuing..."
}   
