#!/bin/bash

usage="
Usage: bash $0 <.pem-path> [<rsa-key-name>]
where:
  <.pem-path> = Path to an AWS .pem file (No Default)
  [<rsa key>] = [Base] filename of the output rsa private key
                (default: Same as .pem file). The output keypair
                will be generated in the same directory as the
                input .pem file.
"
if [[ $# == 0 ]]; then
    echo "Insufficient arguments on commandline"
    echo "$usage"
    exit 1
fi
pem_path=$1
if [[ ! -f $pem_path ]]; then
    echo "The .pem file does not exist."
    exit 1
fi
pem_dir=$(dirname $pem_path)
pem_file=$(basename $pem_path)
pem_base=${pem_file%%.*}
rsa_base=${2:-$pem_base}
pri_key="${pem_dir}/${rsa_base}"
pub_key="${pem_dir}${rsa_base}.pub"
if [[ -f $pri_key || -f $pub_key ]]; then
    echo -n "The $rsa_base keypair already exists. Overwrite? [y/n]: "
    read ans
    if [[ -z $(echo "$ans" | grep -i '^y') ]]; then
        echo "Exiting at operator request"
        exit 1
    fi
fi
openssl rsa -in $pem_path -out $pri_key
ssh-keygen -y -f $pem_path > $pub_key
