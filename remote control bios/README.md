# Scripts for remotely controlling a device

This is an early version

Usage:

0) Put in two link cards into two computers
1) either call receiver-bios.lua or burn it using "flash remoteBIOS.lua remoteBIOS"
2) put the BIOS into the to-be-controlled device and turn it on
3) install https://github.com/7eggert/opencomputers-my-libs/blob/master/lib/tablex.lua
   into /home/lib (or /usr/lib)
4) run "rpc computer.beep" on the controlling computer
5) run "rpc component.list" on the controlling computer
5) run "rpc component.list eeprom" on the controlling computer
6) run "rpc 'function(a,b)return a+b;end' 1 2" on the controlling computer
7) improve and report here or on the forum thread yet to be created
