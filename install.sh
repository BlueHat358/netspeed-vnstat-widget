#!/usr/bin/env bash

mkdir --parents --verbose ~/.local/share/plasma/plasmoids/org.kde.netspeedVnstatWidget
cp --recursive --update --verbose ./package/* $_
