#!/bin/bash

checkConfigRequirement()
{  
	if [[ $CFG_REQUIREMENT_CONFIG == "true" ]]; then
		checkConfigFirstInstall;
		checkConfigFilesMissingVariables;
	fi
} 