#!/bin/bash

mkdir -p $HOME/.config/kortex/coverart
mkdir -p $HOME/.config/kortex/banners/

if [ -d "$HOME/.cache/lutris/banners/" ]; then
    cp -r $HOME/.cache/lutris/banners/* $HOME/.config/kortex/banners/
fi


if [ -d "$HOME/.cache/lutris/coverart/" ]; then
    cp -r $HOME/.cache/lutris/coverart/* $HOME/.config/kortex/coverart
fi


#for steam
if [ -d "$HOME/.cache/lutris/steam/coverart/" ]; then
    cp -r $HOME/.cache/lutris/steam/coverart/* $HOME/.config/kortex/coverart
fi

if [ -d "$HOME/.cache/lutris/steam/banners/" ]; then
    cp -r $HOME/.cache/lutris/steam/banners/* $HOME/.config/kortex/banners/
fi
