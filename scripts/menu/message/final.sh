#!/bin/bash

menuShowFinalMessages()
{
	local app_name="$1"
	local username="$2"
	local password="$3"
	local port="$4"

	menuLoginRequired $app_name $username $password $port;
	menuPublic $port;
	menuContinue;
}
