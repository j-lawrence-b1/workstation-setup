# Goals
* Bootstrap linux software and infrastructure development on a Windows 10 machine.
* Minimize manual setup tasks.
* Minimize time-to-live.

# System Requirements.
* Intel/AMD processor
* Up to date Windows 10
* 16GB RAM. You could get by with less if you omit the db docker containers.
* Enough disk to install Ubuntu (8GB + home, apps, and data).

# Installation Artifacts
On the windows side, this setup installs:
* Git
* Windows Subsystem for Linux (WSL) running Ubuntu-20.04
* Docker for Desktops
* An X-server (VcXsrv)

And sets up:
* X-server autostart
* A shortcut for running the Terminator for wsl access

On the Linux (WSL) side, this setup installs:
* keychain and ssh-agent
* Ansible
* The AWS CLI
* My current bash environment. NOTE: My ssh keys will be useless to you w/o the passphrase. Substitute your own.
* The Terminator X-client app.
* Miniconda
* mysqldb and postgresql client apps.

And configures:
* A conda environment (db-env) suitable for Python data engineering and data analysis.
* 2 docker containers, one running mariadb and one running postgresql

# References
* [Windows Subsystem for Linux Installation Instructions](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
* [WSL Memory hog workaround](https://github.com/microsoft/WSL/issues/4166)
* [Windows Xserv Installation Instructions](https://sourceforge.net/projects/vcxsrv/)
* [How to run WSL X Clients from windows](https://medium.com/javarevisited/using-wsl-2-with-x-server-linux-on-windows-a372263533c3)
* [Miniconda for Linux List of Installers](https://docs.conda.io/en/latest/miniconda.html#linux-installers)
* [Docker for Desktop Windows Installer](https://docs.docker.com/docker-for-windows/install/)

# Windows side tasks 1

## Install git for Windows
[Get it here](https://git-scm.com/download/win)

## Checkout the workstation_setup repo
Open a git bash window and run:
```
# Use HTTP authentication (since .ssh keys aren't installed on the Windows side).
$ git clone  https://<your-git-username>@github.com/j-lawrence-b1/workstation-setup.git
```

## Install Windows Subsystem for Linux (WSL):
Follow the step-by-step procedure in the [Windows Subsystem for Linux Installation for Windows 10](https://docs.microsoft.com/en-us/windows/wsl/install-win10).

### Splunk puppet workaround (only needed if you work there)
Splunk runs a Puppet agent that manages login permissions on their Windows laptops. This infrastruction won't allow WSL logins ("Not approved for this type of logon") unless  Virtualization is detected. Unfortunately, the way it does this is a little crude and requires the Hyper-V Windows feature to be explicitly enabled. The WSL2 installation, on the other hand, only enables the "Windows Virtualization Platform" feature, a Hyper-V subset. But fear not! Hyper-V and Windows Virtualization Platform are compatible, so the workaround is to just enable Hyper-V also. To do so:
1. Open a Powershell window as Administrator.
2. Run:
```
PS > dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-Management-Clients /all /norestart
```
# Linux side tasks 1

## Allow sudo to run without entering a password.
1. Safety First! Leave yourselve a way back if you screw up the sudoers file edit!
```
<Windows>-R wsl -d Ubuntu-20.04
# Switch to the root user so you can restore the sudoers file from the backup if things go wrong.
# ****LEAVE THIS WINDOW OPEN WHILE PERFORMINAG THE NEXT STEP****
$ sudo su
<root>$
```
2. Open a second wsl terminal to do the sudoers file edit.
```
<Windows>-R wsl -d Ubuntu-20.04
$ sudo sed -i.bak 's/%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL
# Test that sudo now works without a passwd.
$ sudo echo hello
hello
```
3. IF step 2 fails, go back to the first window and restore the original sudoers file from the .bak file.
```
<root>$ cd /etc
<root>$ mv sudoers.bak sudoers
```

## Install Linux packages, apps, and conda environments.
1. Open a wsl bash window. Edit /etc/sudoer "in place" with sed
```
<Windows>-R wsl -d Ubuntu-20.04
$ bash /mnt/c/Users/<WINDOWS_USER>/workstation-setup/setup-for-wsl.sh 
```

# Windows side tasks 2

## Install vcxsrv (Windows X-server):
1. [Download and run the vcxserv installer](https://sourceforge.net/projects/vcxsrv/)
2. Ensure both vcxsrv entries in the Windows firewall are enabled.
   Control Panel-->Windows Defender Firewall-->Allow and App or Feature through Windows Defender Firewall
   Scroll down the list to VcXsrv. Ensure both entries are enabled.
3.  Create a Desktop shortcut to start vcxserv
   Set the Target as:
   ```
   "C:\Program Files\VcXsrv\vcxsrv.exe" :0 -ac -terminate -lesspointer -multiwindow -clipboard -wgl -dpi auto
   ```
   Set Start in as:
   ```
   "C:\Program Files\VxXsrv"
   ```
   Rename the shortcut to VcXsrv.
3. Set VcXsrv to start at login:
   ```
   <Windows Key>-R shell:startup
   [Copy and past the VxXsrv shortcut from the desktop into the startup list.]
   ```
See [this article](https://medium.com/javarevisited/using-wsl-2-with-x-server-linux-on-windows-a372263533c3) for more details and installation debugging tips.

## Configure the Terminator to run from a Windows shortcut. (Better WSL terminal):
1. Open a git bash window and run:
   ```
   # Populate %USERPROFILE%\local\bin\startXClient.vbs.
   $ mkdir -p local/bin
   $ cp workstation_setup/local/bin/startXClient.vbs local/bin
   ```
2. Create a new desktop shortcut
   Set the Target as:
   ```
   "C:\Windows\System32\wscript.exe %USERPROFILE%\local\bin\startXClient.vbs terminator
   ```
   Set the Start in location to the WSL home:
   ```
   \\wsl$\Ubuntu-20.04\home\larry
   ```
   Rename the shortcut to Terminator.
4. In Windows Exporer, copy the Terminator shortcut to %USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu. 
   
NB: This technique can be used to start any X client; However, the startXClient.vbs script doesnt currently support passing parameters to the X client app)

## Setup local db access.

### Install Docker for Desktop
[Download and install Docker](https://docs.docker.com/docker-for-windows/install/)

In Settings-->General
1. Expose daemon on tcp://localhost:2375 without TLS
2. Use the WSL 2 based engine

In Settings-->Resources
1. Enable integration with the Ubuntu-20.04 distro.

### Setup db server docker containers.
1. Create db server containers.
   From a git bash (Windows) window, run:
   ```
   # Dockerhub repository access.
   $ docker login
   
   # mariadb
   $ docker pull mariadb
   $ docker run -d -p 3306:3306 --name maria_db -e MYSQL_ROOT_PASSWORD=root mariadb
   
   # Postgres
   $ docker pull postgres
   $ docker run -d -p 5432:5432 --name pg_db -e POSTGRES_PASSWORD=postgres postgres
   ```
2. Test db access.
   From a Terminator (linux) window, try to access the databases.
   ```
   # mysql
   $ mysql -h 127.0.0.1 -u root -proot mysql
   # postgresql
   $ PGPASSWORD=postgres psql -h localhost -U postgres postgres
   ```
NB: To stop/start the docker containers:
From a git bash window, run:
```
# stop
$ docker stop maria_db|pg_db
# start
$ docker stop maria_db|pg_db
```

```
