#!/bin/bash

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

packages="
    keychain
    ansible
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
