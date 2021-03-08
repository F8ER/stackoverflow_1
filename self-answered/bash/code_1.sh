#!/bin/bash

# -------------------------- #
# User variables             #
# -------------------------- #

certificateAuthorityName="certificate_authority";
certificateAuthorityPrivateKeyPassword="";

certificateName="certificate";
certificateTestPostfix="_test";

# -------------------------- #
# Variables                  #
# -------------------------- #

stdout='/dev/null';
stderr='/dev/null';
certificateAuthorityFilepath="$( pwd )/${certificateAuthorityName}";
certificateFilepath="$( pwd )/${certificateName}";

# -------------------------- #
# Functions                  #
# -------------------------- #

function OR
{
	declare i;

	for (( i=0; i < "$1"; i++ ));
	do
		printf '%s' "$2";
	done;
}

function SignedCertificateCreate
{
	declare createSerial_l="-CAserial ${certificateAuthorityFilepath}.srl";

	if [ "$1" = "1" ];
	then
		rm "${certificateAuthorityFilepath}.srl" > "/dev/null" 2>&1;
		createSerial_l='-CAcreateserial';
	fi

	if ! openssl x509 \
		-req -sha256 \
		-days "365" \
		$createSerial_l \
		-CA "${certificateAuthorityFilepath}.crt" -CAkey "${certificateAuthorityFilepath}.key" -passin "pass:${certificateAuthorityPrivateKeyPassword}" \
		-in "${certificateFilepath}.csr" -extfile "${certificateFilepath}.ext" \
		-out "${certificateFilepath}${certificateTestPostfix}.crt" \
		> "$stdout" 2> "$stderr";
	then
		printf $'Couldn\'t create a certificate\n';

		return 1;
	fi
}

function SignedCertificatesCreate
{
	declare loops_l="1";

	if [ "$1" != "" ];
	then
		loops_l="$1";
	fi

	declare i;

	for (( i=0; i < "$loops_l"; i++ ));
	do
		if ! SignedCertificateCreate "$2";
		then
			return 1;
		fi
	done
}

function ReadCertificateSerialFromFile
{
	cat "${certificateAuthorityFilepath}.srl" 2> "$stderr";
}

# -------------------------- #
# Methods                    #
# -------------------------- #

function Help
{
	echo
	printf ' Description: OpenSSL serial generation test\n\n';
	printf ' Additional arguments:\n\n';
	printf '   -d - Enable certain output for debugging\n';
	printf '   -h - Help message\n\n';
}

function Main
{
	if [[ "$1" == *"h"* ]];
	then
		Help;
		exit 0;
	fi

	if [[ "$1" == *"d"* ]];
	then
		stdout='/dev/stdout';
		stderr='/dev/stderr';
	fi

	if [ ! -f "${certificateAuthorityFilepath}.key" ];
	then
		printf $'There\'s no Certificate Authority private key: %s\n' "${certificateAuthorityFilepath}.key";
		exit 1;
	fi

	if [ "$certificateAuthorityPrivateKeyPassword" = "" ];
	then
		echo
		read -s -p " [ ? ] Certificate Authority Private Key Password: " certificateAuthorityPrivateKeyPassword;
		echo
	fi

	printf '\n  %s \n' "$( OR 80 "-" )";
	printf ' | %35s | ' 'A new {serial #1} generated';
	SignedCertificateCreate 1 || exit 2;
	printf '%40s |\n' "$( ReadCertificateSerialFromFile )"
	printf ' | %35s | ' 'A new {serial #2} generated';
	SignedCertificateCreate 1 || exit 3;
	printf '%40s |\n' "$( ReadCertificateSerialFromFile )"
	printf ' | %35s | ' 'Used the same {serial #2} 5 times';
	SignedCertificatesCreate 5 || exit 4;
	printf '%40s |\n' "$( ReadCertificateSerialFromFile )"
	printf ' | %35s | ' 'Used the same {serial #2} 256 times';
	SignedCertificatesCreate 256 || exit 5;
	printf '%40s |\n' "$( ReadCertificateSerialFromFile )"
	printf '  %s \n\n' "$( OR 80 "-" )";
}

# -------------------------- #
# Main                       #
# -------------------------- #

Main "$@";
