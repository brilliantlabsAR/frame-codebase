# Setting up Radiant

Radiant is Lattice's proprietary FPGA toolchain available on x86 Linux and Windows.

Download it [here](https://www.latticesemi.com/en/Products/DesignSoftwareAndIP/FPGAandLDS/Radiant), and be sure to obtain a free node locked [license](https://www.latticesemi.com/Support/Licensing/DiamondAndiCEcube2SoftwareLicensing/Radiant) in order to use the software.

## Set up Radiant on a Linode Arch VM

For users without an x86 compatible machine, follow these steps to set Radiant up on a remote VM. These instructions are tested to work on a 4GB shared CPU [Linode](https://www.linode.com) instance running Arch.

```sh
# SSH into the remote VM as root
ssh root@ip

# Update and install some packages
pacman -Syu base-devel git github-cli gnome gnome-extra gdm tigervnc libxss qt5 libxcrypt-compat

# Add yourself as a user
nano /etc/sudoers # Uncomment the line: %wheel ALL=(ALL:ALL) ALL
useradd -m -G wheel user_name
passwd user_name

# Exit root user
exit

# Optional: Copy your public SSH key from local machine to the remote
ssh-copy-id user_name@ip

# Login as your user and enable VNC passthrough
ssh -L 5901:127.0.0.1:5901 user_name@ip

# Set some environment variables to allow Radiant to run without a graphics card
nano ~/.bashrc # Add the lines:
             #   export DISPLAY=:1
             #   export LIBGL_ALWAYS_SOFTWARE=1
             #   export QTWEBENGINE_DISABLE_SANDBOX=1

# Log into github
gh auth login

# Clone this project
gh repo clone brilliantlabsAR/frame-codebase ~/projects/frame-codebase -- --recursive

# Configure vnc settings
vncpasswd
sudo nano /etc/tigervnc/vncserver.users # Add the line: :1=user_name
nano ~/.vnc/config # Add the lines:
                   #   session=gnome
                   #   geometry=1920x1080
                   #   localhost
                   #   alwaysshared

# Start the vnc server
vncserver :1 &

# Start your VNC client and login to the desktop environment

# Download and install Radiant, and install the licence file

# Before launching Radiant, remove the included libstdc++
rm $(PATH_TO_RADIANT)/2023.2/bin/lin64/libstdc++.so.6
```