##################################################################
#                                                                #
#                SML Escribe - Debian Integration                #
#                       Sergio Melas 2026                        #
#                                                                #
##################################################################

Hello everyone,

I created a bit of a "Frankenstein" automated packaging engine for Debian/Ubuntu systems.

This script lets you take any native Linux .run installer and combine it with ANY newer upstream Windows .exe installer to build a single, fully functional .deb package. It uses the stable Linux C# UI libraries for smooth graphical rendering under Mono/GTK, but automatically dissects the Windows installer using 7z to extract and inject the latest production Firmware maps directly into the Linux package path.

The script automatically labels both versions inside the final file name and package control configurations using an explicit tagging schema:
escribe-suite_[LinuxVersion]SW+[WindowsVersion]FW_amd64.deb
(Example: escribe-suite_2.0.69SW+2.0.77FW_amd64.deb)

It is a great way to keep your Linux installation updated with the latest device profiles and microcode updates without waiting for a new native Linux release.

How to use it:
1. Download and drop both the official Evolv Linux .run file and the latest Windows .exe installer into the SRC directory from:
    https://downloads.evolvapor.com/SetupEScribe2_SP77_INT.exe
    https://forum.evolvapor.com/topic/69197-linux-escribe-suite-beta-thread/
2. Run the deb_franck_build.sh to create the deb package.

It will automatically check your system dependencies, extract both targets, merge the assets, swap the firmwares, generate your hardware udev rules, and output a clean .deb package ready for apt-get install.

Let me know if this works smoothly for you or if you run into any quirks with different desktop environments! Enjoy!


*** REMOVAL & MAINTENANCE ***
To remove or completely purge the application along with all custom hardware communication profiles from your system, use standard apt commands:

  sudo apt-get remove escribe-suite
  or
  sudo apt-get purge escribe-suite


*** DISCLAIMER ***
This is an unofficial packaging helper script. Use it at your own risk. This script does NOT alter or patch any executable binaries, nor does it modify Evolv's firmware files. It simply automates the extraction of official, untouched firmware packs from the Windows .exe and places them into the standard Linux directory path. The flash process is handled entirely by the native, secure Evolv bootloader via USB.


*** Source package's ***
Linux:    https://forum.evolvapor.com/topic/69197-linux-escribe-suite-beta-thread
Windows:  https://www.evolvapor.com/escribe then chose your windows version

---

### Change Log:
- V0.0 (2026-05-20):
    * Initial Prototype.

- V0.1 (2026-05-24):
    * Initial Public Release.
    * Added automated 7z Windows firmware parsing layer.
    * Integrated explicit SW/FW dual-version naming matrix.
