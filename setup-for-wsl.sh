#!/bin/bash

origin=$(PWD)

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

cd $HOME

if [[ -d workstation-setup ]]; then
    cd workstation-setup
    git pull
else
    git clone git@github.com:j-lawrence-b1/workstation-setup
fi

cd $HOME
rsync -av workstation-setup/dotfiles/ .

packages="
    ansible
    awscli
    keychain
    mysqlclient
    postgresql-client
    terminator
"
sudo apt-get update
for package in $packages; do
    sudo apt-get -y install $package
done

ddir=$HOME/Downloads
conda_dir=$HOME/miniconda3
if [[ ! -d $conda_dir ]]; then
    conda_installer=Miniconda3-latest-Linux-x86_64.sh
    conda_url="https://repo.anaconda.com/miniconda/$conda_installer"
    if [[ ! -f $ddir/$conda_installer ]]; then
        curl --create-dirs --no-progress-meter --output $ddir/$conda_installer $conda_url
    fi
fi
bash $ddir/$conda_installer -b -p $conda_dir
source $conda_dir/etc/profile.d/conda.sh

for env_file in workstation_setup/conda-evns/*; do
    conda env create -f $env_file
done
