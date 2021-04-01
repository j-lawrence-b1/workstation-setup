# Setup on Windows

## Install Windows Subsystem for Linux (WSL):
[https://docs.microsoft.com/en-us/windows/wsl/install-win10](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

Apply wsl memory hog workaround:
[https://github.com/microsoft/WSL/issues/4166](https://github.com/microsoft/WSL/issues/4166)

## Install vcxsrv (Windows X-server):
[https://sourceforge.net/projects/vcxsrv/](https://sourceforge.net/projects/vcxsrv/)

## Install and configure the Terminator (Better WSL terminal):
[https://medium.com/javarevisited/using-wsl-2-with-x-server-linux-on-windows-a372263533c3](https://medium.com/javarevisited/using-wsl-2-with-x-server-linux-on-windows-a372263533c3)

Gotchas:
* Windows Firewall tweak: Be sure both vcsrv entries are enabled

* The vbs script to start Terminator from the article above didn’t work for me. I started with this one: https://gist.github.com/Raneomik/202f5adb964723b16d14c3799d28e1e2#file-wsl-terminator-vbs, tweaked it into something more generic. It's in the repo at local/bin/startXClient.vbs.

* To start up any wsl X client program (not just terminator):
1. Install the X client app.
2. Create a shortcut on the Windows desktop. Name it for the X client.
3. Add this as the target:
```
C:\Windows\System32\wscript.exe C:\Users\lb999\local\bin\startXClient.vbs <x-client>
```
4. Set the Start in location to the WSL home:
```
\\wsl$\Ubuntu-20.04\home\larry
```
5. Copy/Move the shortcut to %USERPROFILE%\AppData\Roaming\Microsoft\Windows\"Start Menu"

## Install dotfiles from Dropbox (or this repo)

NB The .vimrc was adapted from here: https://github.com/mlavin/dotfiles/blob/master/vimrc

## Setup Git:
git configure user.name j-lawrence-b1
git configure user.password <look-in-keepass>

## Install conda:
https://docs.conda.io/en/latest/miniconda.html#linux-installers

## Install Docker for Desktop
https://docs.docker.com/docker-for-windows/install/

In Settings-->General
1. Expose daemon on tcp://localhost:2375 without TLS
2. Use the WSL 2 based engine

In Settings-->Resources
1. Enable integration with the Ubuntu-20.04 distro.

## Setup a postgres db docker container.
1. Install psql client.
   ```
   $ sudo apt-get install postgresql-client
   ```
2. Create and run the postgres docker container.
   ```
   $ docker login  # Dockerhub repository access.
   $ docker pull postgres
   $ docker run -d -p 5432:5432 --name pg_db -e POSTGRES_PASSWORD=postgres postgres
   ```
3. Test db access.
   ```
   $ psql -h localhost -U postgres
   ```
