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


origin=$(PWD)
cd $HOME
# The workstation-setup repo must be checked out under the users
# Windows home directory.
pdir=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | sed 's/.*\\//g')
WHOME=/mnt/c/Users/$pdir
setup_dir=${WHOME}/workstation-setup
msg="The setup directory, \"$setup_dir\" does not exist. Please make it so."
test -d $setup_dir || error_exit 1 "$msg"

rsync -av $setup_dir/dotfiles/ .

packages="
    ansible
    awscli
    build-essential
    docker-compose
    keychain
    mysql-client
    postgresql-client
    terminator
    terraform
    tree
"
echo "======================================="
echo "Installing linux packages"
echo "======================================="
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
for package in $packages; do
    sudo apt-get -y install $package
done

echo "======================================="
echo "Checking for miniconda installation"
echo "======================================="
downloads_dir=$HOME/Downloads
conda_dir=$HOME/miniconda3
if [[ ! -d $conda_dir ]]; then
    echo "======================================="
    echo "Installing miniconda."
    echo "======================================="
    conda_installer=Miniconda3-latest-Linux-x86_64.sh
    conda_url="https://repo.anaconda.com/miniconda/$conda_installer"
    if [[ ! -f $ddir/$conda_installer ]]; then
        curl --create-dirs --no-progress-meter --output $downloads_dir/$conda_installer $conda_url
    fi
fi
bash $downloads_dir/$conda_installer -b -p $conda_dir
source $conda_dir/etc/profile.d/conda.sh

echo "======================================="
echo "Checking conda environments"
echo "======================================="
for env_file in $setup_dir/conda-envs/*; do
    env=$(basename $env_file | sed 's/.yml$//')
    if [[ -n $(conda info --envs | cut -d' ' -f1,1 | grep '^'${env}'$') ]]; then
        echo "OK: $env"
    else
        echo "CREATING: $env"
        conda env create -f $env_file
    fi
done
