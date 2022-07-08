#!/bin/bash

#Author: Maerifat Majeed

read -p "Enter the name of original profile (leave empty if default) : " original_profile
if [ "$original_profile" = "" ];then original_profile="default";fi

read -p "Enter the name of mfa profile (leave empty if mfa) : " mfa_profile
if [ "$mfa_profile" = "" ];then mfa_profile="mfa";fi

mfa_serial_number=$(aws iam list-mfa-devices --profile "$original_profile" --query 'MFADevices[*].SerialNumber' --output text)

if [ -z "$mfa_serial_number" ];then 
	echo "We could not find MFA Device for this profile";
	exit 0
else

	read -p "Enter your 6 digit token : " mfa_token

	authenticationOutput=$(aws sts get-session-token --profile "$original_profile" --serial-number "${mfa_serial_number}" \
	--token-code ${mfa_token} --duration-seconds 1600 --output text)

	if [ -z "$authenticationOutput" ];then

		echo "Something went wrong while fetching the session tokens..."
		exit 0
	else
	
		aws_access_key_id=$(echo "$authenticationOutput"|awk '{print $2}')
		aws_secret_access_key=$(echo "$authenticationOutput"|awk '{print $4}')
		aws_session_token=$(echo "$authenticationOutput"|awk '{print $5}')

		aws configure set aws_access_key_id "$aws_access_key_id" --profile "$mfa_profile" 
		aws configure set aws_secret_access_key "$aws_secret_access_key" --profile "$mfa_profile"
		aws configure set aws_session_token "$aws_session_token" --profile "$mfa_profile"
		aws configure set region ap-south-1 --profile "$mfa_profile" 
		
		echo "You can now use ${mfa_profile} profile."

	fi
fi
