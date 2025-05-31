#!/bin/bash
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '// Create a new panel for the dock at the bottom
var dockPanel = new Panel
var dockPanelScreen = dockPanel.screen
dockPanel.location = "bottom";
dockPanel.height = gridUnit * 2.5 // Increased width to accommodate the Kickoff widget

// Add the Icon Tasks widget to the dock panel
// Add the Kickoff (Application Launcher) widget to the dock panel and center it
dockPanel.addWidget("org.kde.plasma.panelspacer")
var kickoff = dockPanel.addWidget("org.kde.plasma.kickoff")
kickoff.currentConfigGroup = ["Shortcuts"]
kickoff.writeConfig("global", "Alt+F1")
kickoff.currentConfigGroup = ["Look/Feel"]
kickoff.writeConfig("alignment", "center")
dockPanel.addWidget("org.kde.plasma.marginsseparator")
var tasks = dockPanel.addWidget("org.kde.plasma.icontasks")
tasks.currentConfigGroup = ["Configuration", "Launchers"];
 tasks.writeConfig("launchers", [
        "applications:k-settings.desktop",      // alternate desktop file
        "applications:thorium-browser.desktop",  // Thorium Browser
        "applications:org.kde.kate.desktop",
        "applications:org.kde.dolphin.desktop",
        "applications:org.kde.discover.desktop"
    ]);
dockPanel.addWidget("org.kde.plasma.panelspacer")


// Modify the top panel
var topPanel = new Panel
var topPanelScreen = topPanel.screen
topPanel.location = "top";

topPanel.addWidget("org.kde.plasma.appmenu")
// Add the Digital Clock widget to the top panel and center it
topPanel.addWidget("org.kde.plasma.panelspacer")
var digitalClock = topPanel.addWidget("org.kde.plasma.digitalclock")
digitalClock.currentConfigGroup = ["Look/Feel"]
digitalClock.writeConfig("alignment", "center")

// Add a spacer between the clock and system tray
var chatbot = topPanel.addWidget("org.kde.plasma.chatSotero")
topPanel.addWidget("org.kde.plasma.marginsseparator")
topPanel.addWidget("org.kde.plasma.panelspacer")

// Add the System Tray widget to the top panel and place it on the right side
var systemTray = topPanel.addWidget("org.kde.plasma.systemtray")
systemTray.currentConfigGroup = ["Look/Feel"]
systemTray.writeConfig("alignment", "right")
'
