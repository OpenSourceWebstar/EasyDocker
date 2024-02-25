#!/bin/bash

function isSuccessful()
{
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

function isError()
{
    echo -e "${RED}ERROR:${NC} $1"
}

function isFatalError()
{
    echo -e "${RED}ERROR:${NC} $1"
}

function isFatalErrorExit()
{
    echo -e "${RED}ERROR:${NC} $1"
    echo ""
    exit 1
}

function isNotice()
{
    echo -e "${YELLOW}NOTICE:${NC} $1"
}

function isQuestion()
{
    echo -e -n "${BLUE}QUESTION:${NC} $1 "
}

function isOptionMenu()
{
    echo -e -n "${PINK}OPTION:${NC} $1"
}

function isOption()
{
    echo -e "${PINK}OPTION:${NC} $1"
}
