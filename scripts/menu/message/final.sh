#!/bin/bash

menuShowFinalMessages()
{
	local app_name="$1"
	local username="$2"
	local password="$3"

	menuLoginRequired $app_name $username $password;
	menuPublic;
	menuContinue;
}
