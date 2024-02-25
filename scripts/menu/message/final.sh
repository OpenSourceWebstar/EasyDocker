#!/bin/bash

menuShowFinalMessages()
{
	local app_name="$1"
	local username="$2"
	local password="$3"
	menuLoginRequired;
	menuPublic;
	menuContinue;
}
