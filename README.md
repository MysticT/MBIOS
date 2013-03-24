MBIOS
=====

The only function that the bios provides is the boot-loader. It lets you
have as many boot files as you want, and loads them from the rom, computer
root and floppy disks.

Installation
------------
1-	Download the bios.lua file
2-	Move the CC bios from /mods/ComputerCraft.zip/lua/bios.lua to
	/mods/ComputerCraft.zip/lua/rom/boot/CraftOS (this will allow
	you to boot CraftOS)
3-	Move the downloaded bios.lua to /mods/ComputerCraft/lua/bios.lua

Configuration
-------------
At the top of the bios file there's some configuration options.
Theses are:
*	BootPaths: defines the paths to look for boot files
*	BootFromDisk: whether to allow to boot from disks or not
*	DiskBootPaths: paths to search in disks for boot files (if enabled)