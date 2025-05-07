#!/bin/bash
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '// Get an array of all Panel containments
var allPanels = panels();
// Loop through and delete each one
for (var i = 0; i < allPanels.length; i++) {
    allPanels[i].remove();
}
'
