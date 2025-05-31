#!/bin/bash
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '// Create a new panel for the dock at the bottom
var Panel = new Panel
var PanelScreen = Panel.screen
Panel.location = "bottom";
Panel.height = gridUnit * 2.5 // Increased width to accommodate the Kickoff widget

// Add the Icon Tasks widget to the dock panel
// Add the Kickoff (Application Launcher) widget to the dock panel and center it

var kickoff = Panel.addWidget("org.kde.plasma.kickoff")
kickoff.currentConfigGroup = ["Shortcuts"]
kickoff.writeConfig("global", "Alt+F1")
kickoff.currentConfigGroup = ["Look/Feel"]
kickoff.writeConfig("alignment", "center")
Panel.addWidget("org.kde.plasma.marginsseparator")
var tasks = Panel.addWidget("org.kde.plasma.icontasks")
tasks.currentConfigGroup = ["Configuration", "Launchers"];
 tasks.writeConfig("launchers", [
        "applications:k-settings.desktop",      // alternate desktop file
        "applications:thorium-browser.desktop",  // Thorium Browser
        "applications:org.kde.kate.desktop",
        "applications:org.kde.dolphin.desktop",
        "applications:org.kde.discover.desktop"
    ]);
Panel.addWidget("org.kde.plasma.panelspacer")

Panel.addWidget("org.kde.plasma.marginsseparator")
// Add the System Tray widget to the top panel and place it on the right side
var chatbot = Panel.addWidget("org.kde.plasma.chatSotero")
Panel.addWidget("org.kde.plasma.marginsseparator")
var systemTray = Panel.addWidget("org.kde.plasma.systemtray")
systemTray.currentConfigGroup = ["Look/Feel"]
systemTray.writeConfig("alignment", "right")



// Add the Digital Clock widget to the top panel and center it
Panel.addWidget("org.kde.plasma.marginsseparator")
var digitalClock = Panel.addWidget("org.kde.plasma.digitalclock")
digitalClock.currentConfigGroup = ["Look/Feel"]
digitalClock.writeConfig("alignment", "right")
'
