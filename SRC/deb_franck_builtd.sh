#!/bin/bash
# ==============================================================================
# Universal Debian Packager for EScribe Suite (Frankenstein Edition)
# Developed by Sergio Melas - 2026
#
# Copyright (C) 2026 Sergio Melas <sergiomelas@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
# ==============================================================================

set -e

# --- Configuration ---
PKG_NAME="escribe-suite"
ARCH="amd64"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BASE_DIR}/build_workspace"

echo " "
echo " ##################################################################"
echo " #                                                                #"
echo " #                System Configuration Debian                     #"
echo " #     EScribe Suite Master Builder - FRANKENSTEIN EDITION        #"
echo " #                                                                #"
echo " ##################################################################"
echo " "

# --- Automated System Dependencies Check & Installation ---
echo "⚙️  Verifying local build system tools..."
MISSING_DEPS=()

if ! command -v unzip &> /dev/null; then
    MISSING_DEPS+=("unzip")
fi

if ! command -v 7z &> /dev/null; then
    MISSING_DEPS+=("p7zip-full")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "⚠️  Missing essential compilation tools: ${MISSING_DEPS[*]}"
    echo "🔐 Elevating privileges to install prerequisites..."
    sudo apt-get update -qq
    sudo apt-get install -y "${MISSING_DEPS[@]}"
    echo "✅ Dependencies successfully synchronized."
else
    echo "✅ All required compilation utilities are already installed."
fi

# --- Dynamic Source Discovery ---
echo "🔍 Discovering installer payloads..."
LINUX_RUN=$(find "$BASE_DIR" -maxdepth 1 -name "*.run" | head -n 1)
WINDOWS_EXE=$(find "$BASE_DIR" -maxdepth 1 -name "*.exe" | head -n 1)

if [ -z "$LINUX_RUN" ] || [ ! -f "$LINUX_RUN" ]; then
    echo "❌ ERROR: Baseline Linux .run installer asset missing in: ${BASE_DIR}"
    exit 1
fi

echo "📦 Baseline Linux Installer: $(basename "$LINUX_RUN")"

if [ -n "$WINDOWS_EXE" ] && [ -f "$WINDOWS_EXE" ]; then
    echo "🪟 Upstream Windows Firmware Source Found: $(basename "$WINDOWS_EXE")"
else
    echo "⚠️  WARNING: No upstream Windows .exe detected. Building native Linux assets only."
fi

# --- Extract Version Dynamically from Linux Source ---
INSTALLER_FILENAME=$(basename "$LINUX_RUN")
SP_NUM=$(echo "$INSTALLER_FILENAME" | grep -oE 'SP[0-9]+' | sed 's/SP//' || echo "")
if [ -n "$SP_NUM" ]; then
    LINUX_VER="2.0.${SP_NUM}"
else
    LINUX_VER=$(echo "$INSTALLER_FILENAME" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "2.0.69")
fi
echo "🚀 Target Linux UI Software Version: V${LINUX_VER}"

# --- Extract Version Dynamically from Windows Source & Set PKG_VER ---
if [ -n "$WINDOWS_EXE" ] && [ -f "$WINDOWS_EXE" ]; then
    WIN_FILENAME=$(basename "$WINDOWS_EXE")
    WIN_SP_NUM=$(echo "$WIN_FILENAME" | grep -oE 'SP[0-9]+' | sed 's/SP//' || echo "")
    if [ -n "$WIN_SP_NUM" ]; then
        WIN_VER="2.0.${WIN_SP_NUM}"
    else
        WIN_VER=$(echo "$WIN_FILENAME" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "2.0.77")
    fi
    echo "🚀 Upstream Windows Firmware Version: V${WIN_VER}"

    # Custom combined tag: Explicitly tracks software (SW) and firmware (FW) variants
    PKG_VER="${LINUX_VER}SW+${WIN_VER}FW"
else
    PKG_VER="${LINUX_VER}SW"
fi
echo "📦 Final Deb Internal Package Control Version: ${PKG_VER}"

# --- 1. Workspace Isolation ---
echo "🧹 Initializing production build workspace layout..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/opt/Evolv/EScribe"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/pixmaps"
mkdir -p "$BUILD_DIR/lib/udev/rules.d"

TMP_LINUX="${BASE_DIR}/tmp_linux_extract"
TMP_WIN="${BASE_DIR}/tmp_windows_extract"
rm -rf "$TMP_LINUX" "$TMP_WIN"
mkdir -p "$TMP_LINUX" "$TMP_WIN"

# --- 2. Extraction Stage: Native Linux Baseline ---
echo "🏗️  Deconstructing native Linux MojoSetup framework..."
chmod +x "$LINUX_RUN"
"$LINUX_RUN" --target "$TMP_LINUX" --noexec

echo "📦 Unpacking core Linux baseline binary distribution..."
ZIP_PAYLOAD="${TMP_LINUX}/common/data/escribe-suite.zip"
if [ ! -f "$ZIP_PAYLOAD" ]; then
    echo "❌ ERROR: Core Linux zip payload missing from extraction tree!"
    rm -rf "$TMP_LINUX" "$TMP_WIN" "$BUILD_DIR"
    exit 1
fi
# Extract pure Linux framework base assets directly into target tree
unzip -q "$ZIP_PAYLOAD" -d "$BUILD_DIR/opt/Evolv/EScribe/"
rm -rf "$TMP_LINUX"

# --- 2.5 Frankenstein Upstream Windows Firmware Integration ---
if [ -n "$WINDOWS_EXE" ] && [ -f "$WINDOWS_EXE" ]; then
    echo "🪟 Dissecting Windows Installer for microcode extraction..."
    7z x "$WINDOWS_EXE" -o"$TMP_WIN" -y > /dev/null

    if [ -d "$TMP_WIN/Firmware" ]; then
        echo "🧹 Purging legacy native Linux firmware directory..."
        rm -rf "$BUILD_DIR/opt/Evolv/EScribe/Firmware"
        mkdir -p "$BUILD_DIR/opt/Evolv/EScribe/Firmware"

        echo "🔄 Injecting updated production Firmware layers into Linux target..."
        cp -rf "$TMP_WIN/Firmware"/* "$BUILD_DIR/opt/Evolv/EScribe/Firmware/"

        FW_COUNT=$(find "$BUILD_DIR/opt/Evolv/EScribe/Firmware" -type f \( -name "*.sw-service" -o -name "*.sw-update" \) | wc -l)
        echo "✅ Transferred ${FW_COUNT} updated device/firmware microcode definition maps."
    else
        echo "⚠️  WARNING: Could not locate 'Firmware' directory inside Windows installer tree. Skipping injection."
    fi
    rm -rf "$TMP_WIN"
else
    echo "⚠️  WARNING: No upstream Windows .exe detected. Keeping standard Linux firmware distribution profiles."
    rm -rf "$TMP_WIN"
fi

# --- 3. Custom Resource Integration ---
echo "🔄 Merging static assets..."
if [ -f "$BUILD_DIR/opt/Evolv/EScribe/Help/help.png" ]; then
    cp -f "$BUILD_DIR/opt/Evolv/EScribe/Help/help.png" "$BUILD_DIR/usr/share/pixmaps/escribe.png"
fi

# --- 4. Pure Mono Execution Wrapper Generation ---
echo "🚀 Forging production Bash execution wrapper pipeline..."
cat << 'EOF' > "$BUILD_DIR/opt/Evolv/EScribe/EScribe"
#!/bin/bash
exec mono /opt/Evolv/EScribe/EScribe.exe "$@"
EOF
chmod 755 "$BUILD_DIR/opt/Evolv/EScribe/EScribe"

# --- 5. Embedded Environment Configurations ---
echo "💾 Writing hardware connectivity rule maps and desktop integrations..."

# Hardware udev communication layers for raw USB tracking access mapping
cat << 'EOF' > "$BUILD_DIR/lib/udev/rules.d/99-evolv.rules"
# Evolv DNA USB Permissions
SUBSYSTEM=="usb", ATTR{idVendor}=="268b", MODE="0666", GROUP="plugdev"
EOF

# Standard environment application launcher schema configuration mapping
cat << 'EOF' > "$BUILD_DIR/usr/share/applications/escribe.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=EScribe Suite
Comment=Evolv DNA Configuration Tool
Exec=/opt/Evolv/EScribe/EScribe
Icon=escribe
Terminal=false
Categories=Utility;Development;
EOF

# --- 6. Package Control Manifest Architecture ---
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: $PKG_VER
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Sergio Melas <sergiomelas@gmail.com>
Depends: libc6, libglib2.0-0, libgtk-3-0 | libgtk-3-0t64, bash, coreutils, unzip, mono-runtime, mono-complete | mono-devel, ca-certificates-mono | mono-runtime, libmono-system-windows-forms4.0-cil
Description: Evolv EScribe Suite Stable Edition
 Professional DNA configuration toolkit running on native Linux UI stacks
 with targeted Mono graphical user interface support libraries.
EOF

# --- Post-Installation Management Hook ---
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/bash
update-desktop-database /usr/share/applications >/dev/null 2>&1
udevadm control --reload-rules || true
udevadm trigger --subsystem-match=usb || true

echo "#################################################"
echo "#  EScribe deployed successfully.               #"
#  Native Linux runtime environment ready!       #
echo "#################################################"
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# --- Post-Removal Management Hook ---
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postrm"
#!/bin/bash
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    rm -rf /opt/Evolv/EScribe
    rm -f /usr/share/pixmaps/escribe.png
    rm -f /lib/udev/rules.d/99-evolv.rules
    udevadm control --reload-rules || true
    update-desktop-database /usr/share/applications >/dev/null 2>&1
fi
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# --- 7. Final Compiling Target Production Build ---
DEB_FILENAME="${PKG_NAME}_${PKG_VER}_${ARCH}.deb"

echo "🔨 Compiling final production package layout: ${DEB_FILENAME}..."
dpkg-deb --build "$BUILD_DIR" "${BASE_DIR}/${DEB_FILENAME}"

# --- Post-Build Cleanup Isolation ---
rm -rf "$BUILD_DIR"
echo "✅ Compilation sequence complete! Find your custom build package target at:"
echo "👉 ${BASE_DIR}/${DEB_FILENAME}"
