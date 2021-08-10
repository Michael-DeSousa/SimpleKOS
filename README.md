![SimpleKOS](https://user-images.githubusercontent.com/22509729/128433220-ec5e1cb8-ab0e-4eaa-bf87-feb4a009aa2c.png)

# Demo
[Video](https://www.youtube.com/watch?v=xL7zuwZx5dE)

You can also find this project on [Curseforge](https://www.curseforge.com/wow/addons/simple-kos) and [WoWInterface](https://www.wowinterface.com/downloads/info26125-SimpleKOS.html)
# Project Overview
**Simple KOS** is a World of Warcraft addon that scans and displays information about players who attack you during World PVP.  

**Usage:**

Simple KOS has two windows: the **"Kill On Sight" Window** and the **"Recent Attackers" Window**. 

* Each window can be moved by holding SHIFT and dragging the window with your left mouse button.
* Each window can be closed/hidden by clicking the close button in the top right or by using the slash command.
* Each window can be shown again by using the slash command.
* Moving your cursor over a player in either window will display additional information about them.
 
**"Recent Attackers" Window** - Displays basic information about all players who have attacked you during your current play session.

* Left click on a player to copy them to your "Kill On Sight" list.
* Right click on a player to remove them from this window.
 

**"Kill On Sight" Window** - Displays your PVP enemies! 

* You can add players to this window by left clicking on them in the "Recent Attackers" window.
* If AutoAdd is turned on (see the slash command), then players will be automatically added to this window when they kill you.
* Left click on a player to write a note about them. This note will be displayed whenever you move your cursor over the player in the "Kill On Sight" window.
* Simple KOS will track your win/loss record against players added to this list. You can see your win/loss record against a player by moving your cursor over them in the "Kill On Sight" window.
* Right click on a player to remove them from this window. 
 

**Slash Commands** - Type /kos in game to see a list of available slash commands. 

Note: This is my first addon and it is a WORK IN PROGRESS. Feel free to leave feedback or suggestions at kosaddon@gmail.com and I'll respond as quickly as I can. Thanks!

# Technologies Used
* Lua
* WoW API [Link](https://wowprogramming.com/docs/api.html)
* Ace3 Addon Framework [Link](https://www.wowace.com/projects/ace3/pages/getting-started)
