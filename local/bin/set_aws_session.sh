#!/bin/bash

set -uo pipefail

usage () {
  echo "Usage: $0 [OPTIONS]"
  echo "where [OPTIONS] in:"
  echo "  -c, --code    = The code currently displayed on your configured MFA"
  echo "                  device (Default: Do not use MFA)."
  echo "  -h, --help    = Print usage information and exit."
  echo "  -p, --profile = AWS profile to use as the basis for configuration"
  echo "                  (No default)."
  echo ""
  echo "This script will create a new profile called <profile_name>_<suffix>"
  echo "with temporary credentials good for 2 hours. If an mfa_code is"
  echo "provided, <suffix> is \"mfa\"; otherwise, \"session\". As a"
  echo "convenience, the script creates the .aws/set_aws_env.sh bash script"
  echo "which may be sourced to install the credentials and session token"
  echo "into the shell environment."
  echo ""
  echo "Example:"
  echo "  You have a profile named 'prod' that assumes a role and requires mfa."
  echo "  Running $0 -p prod -c 123456 will create a new profile 'prod_mfa'"
  echo "  that has the session credentials for a temporary session"
  echo ""
  echo "Note: Your aws profile doesn't need to assume a role for this script"
  echo "to work. Normal IAM permissions are sufficient."
}

exitError () {
  echo "Error: $1"
  echo ""
  usage
  echo ""
  exit 1
}


code=""
mfa_arn=""
mfa_args=""
role_arn=""

while [ $# -gt 0 ]; do
    case "$1" in
        --profile)
            ;&
        -p)
            shift
            profile="$1"
            shift
            ;;
        --code)
            ;&
        -c)
            shift
            code="$1"
            shift
            ;;
        -h)
            usage
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

if [[ $code = "" ]]; then
    echo "Setting up without MFA"
    profile_suffix="_session"
else
    echo "Setting up with MFA"
    profile_suffix="_mfa"
fi

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

if [[ $profile = "" ]]; then
    exitError "--profile or -p is required"
fi
echo "getting profile details"
if [[ $code != "" ]]; then
    mfa_arn=$(aws configure get mfa_serial --profile $profile)
    echo "using mfa_arn $mfa_arn"
    if [[ $mfa_arn = "" ]]; then
        exitError "mfa_serial is required to be set in your .aws/credentials profile"
    fi
fi

role_arn="$(aws configure get role_arn --profile $profile)"
if [[ $role_arn != "" ]]; then
    echo "using role_arn $role_arn"
    if [[ "$mfa_arn" != "" ]]; then
        mfa_args='--serial-number "$mfa_arn" --token-code "$code"'
    fi
    return_body=$(aws sts assume-role --role-arn "$role_arn" --role-session-name "${profile}_mfa" --serial-number "$mfa_arn" --token-code "$code" --duration-seconds 7200 --output text | tail -n1)
    if [[ $? != 0 ]]; then
        exitError "unable to get credentials for role"
    fi
    aws configure set profile.${profile}${profile_suffix}.source_profile $profile
else
    echo "No role! Seting up access directly from the profile"
    if [[ -n "$mfa_arn" ]]; then
        mfa_args='--serial-number "$mfa_arn" --token-code "$code"'
    fi
    return_body="$(aws sts get-session-token --profile "${profile}" $mfa_args --duration-seconds 7200 --output text | tail -n1)"
    if [[ $? != 0 ]]; then
        exitError "unable to get credentials for profile"
    fi
fi
access_key_id=$(echo "$return_body" | awk '{ print $2 }' )
secret_access_key=$(echo "$return_body" | awk '{ print $4 }' )
aws_session_token=$(echo "$return_body" | awk '{ print $5 }' )

aws configure set profile.${profile}${profile_suffix}.aws_access_key_id "$access_key_id"
aws configure set profile.${profile}${profile_suffix}.aws_secret_access_key "$secret_access_key"
aws configure set profile.${profile}${profile_suffix}.aws_session_token "$aws_session_token"

cat <<EOF > ~/.aws/set_aws_env.sh
export AWS_ACCESS_KEY_ID=$access_key_id
export AWS_SECRET_ACCESS_KEY=$secret_access_key
export AWS_SESSION_TOKEN=$aws_session_token
EOF

echo "To read the aws credentials into the shell environment, type:"
echo "source ~/.aws/set_aws_env.sh"
