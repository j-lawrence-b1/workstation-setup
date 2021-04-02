#!/bin/bash

set -uo pipefail

usage () {
  echo "Usage:"
  echo "$0 --profile profile_name -c mfa_code"
  echo ""
  echo "This will create a new profile called profile_name_mfa with temporary credentials good for 2 hours"
  echo "Example:"
  echo "  You have a profile named 'prod' that assumes a role and requires mfa."
  echo "  Running $0 -p prod -c 123456 will create a new profile 'prod_mfa' that has the session credentials for a temporary session"
  echo ""
  echo "Note: Your aws profile doesn't need to assume a role for this script to work."
  echo "Normal IAM permissions are sufficient."
}

exitError () {
  echo "Error: $1"
  echo ""
  usage
  echo ""
  exit 1
}


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
    exitError "--code or -c is required"
fi

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

if [[ $profile = "" ]]; then
    exitError "--profile or -p is required"
fi
echo "getting profile details"
mfa_arn=$(aws configure get mfa_serial --profile $profile)
echo "using mfa_arn $mfa_arn"

if [[ $mfa_arn = "" ]]; then
    exitError "mfa_serial is required to be set in your .aws/credentials profile"
fi

role_arn="$(aws configure get role_arn --profile $profile)"
if [[ -n $role_arn ]]; then
    echo "using role_arn $role_arn"
    return_body=$(aws sts assume-role --role-arn "$role_arn" --role-session-name "${profile}_mfa" --serial-number "$mfa_arn" --token-code "$code" --duration-seconds 7200 --output text | tail -n1)
    if [[ $? != 0 ]]; then
        exitError "unable to get credentials for role"
    fi
    echo "$return_body"
else
    echo "No role! Seting up access directly from the profile"
    return_body="$(aws sts get-session-token --profile "${profile}" --serial-number "$mfa_arn" --token-code "$code" --duration-seconds 7200 --output text | tail -n1)"
    if [[ $? != 0 ]]; then
        exitError "unable to get credentials for profile"
    fi
fi
access_key_id=$(echo "$return_body" | awk '{ print $2 }' )
secret_access_key=$(echo "$return_body" | awk '{ print $4 }' )
aws_session_token=$(echo "$return_body" | awk '{ print $5 }' )

echo ""
echo "session = $aws_session_token"
echo "access key = $secret_access_key"
echo "key id = $access_key_id"

aws configure set profile.${profile}_mfa.source_profile $profile
aws configure set profile.${profile}_mfa.aws_access_key_id "$access_key_id"
aws configure set profile.${profile}_mfa.aws_secret_access_key "$secret_access_key"
aws configure set profile.${profile}_mfa.aws_session_token "$aws_session_token"

cat <<EOF > ~/.aws/set_mfa_env.sh
export AWS_ACCESS_KEY_ID=$access_key_id
export AWS_SECRET_ACCESS_KEY=$secret_access_key
export AWS_SESSION_TOKEN=$aws_session_token
EOF
