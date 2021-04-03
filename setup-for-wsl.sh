#!/bin/bash

origin=$(PWD)
windows_user=lb999


function error_exit () {
    local e_code=$1
    shift
    local msg="$*"

    local label="ERROR"
    if [[ $e_code == 0 ]]; then
        local label="INFO"
    fi
    echo "$label : $msg"
    exit $e_code
}

if [[ -n $1 ]]; then
    windows_user=$1
fi
windows_home=/mnt/c/Users/$windows_user

cd $HOME

setup_dir=${windows_home}/workstation-setup
msg="The setup directory, \"$setup_dir\" does not exist. Please check it out from github."
test -d $setup_dir || error_exit 1 "$msg"

rsync -av $setup_dir/dotfiles/ .

packages="
    ansible
    awscli
    keychain
    mysql-client
    postgresql-client
    terminator
"
sudo apt-get update
for package in $packages; do
    sudo apt-get -y install $package
done

downloads_dir=$HOME/Downloads
conda_dir=$HOME/miniconda3
if [[ ! -d $conda_dir ]]; then
    conda_installer=Miniconda3-latest-Linux-x86_64.sh
    conda_url="https://repo.anaconda.com/miniconda/$conda_installer"
    if [[ ! -f $ddir/$conda_installer ]]; then
        curl --create-dirs --no-progress-meter --output $downloads_dir/$conda_installer $conda_url
    fi
fi
bash $downloads_dir/$conda_installer -b -p $conda_dir
source $conda_dir/etc/profile.d/conda.sh

for env_file in $setup_dir/conda-envs/*; do
    conda env create -f $env_file
done
