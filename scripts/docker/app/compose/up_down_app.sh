#!/bin/bash

dockerComposeRestart()
{
    local app_name="$1"

    dockerComposeDown $app_name;
    dockerComposeUp $app_name;
}
