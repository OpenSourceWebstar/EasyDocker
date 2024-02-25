#!/bin/bash

showInstructions()
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
