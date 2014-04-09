#!/bin/sh
# Install into $PATH as verify_sparkle_signature

set -e

: ${VERIFY_WITH_OPENSSL:='/usr/bin/openssl'}
DSAPUBKEY="$1"
SIGNATURE="$2"
ZIPFILE="$3"
MKTEMP_TEMPLATE="validate_sparkle_signature.$$.XXXXXXXXX."

my_mktemp(){
    mktemp -t "${MKTEMP_TEMPLATE}${1}"
}

usage() {
    printf '%s DSAPUBKEY SIGNATURE ZIPFILE\n' "$0"
    echo 'Override environment variable VERIFY_WITH_OPENSSL to use different OpenSSL.'
    echo
    printf 'Example: %s public_dsa.pem "MCwCFGRnB0iQO97Nzf2Jaq1WIWh1Jym0AhRhfxNTjunEtMxar8naY5wEBvvEow==" my-app.zip\n' "$0"
    exit
}

if [ $# -ne 3 ]; then
    usage
fi

DECODED_SIGNATURE_FILE="$(my_mktemp sigfile)"
ZIPFILE_SHA1_FILE="$(my_mktemp zipfile_sha1)"

echo "$SIGNATURE" | "$VERIFY_WITH_OPENSSL" enc -base64 -d > "$DECODED_SIGNATURE_FILE"
"$VERIFY_WITH_OPENSSL" dgst -sha1 -binary < "$ZIPFILE" > "$ZIPFILE_SHA1_FILE"
"$VERIFY_WITH_OPENSSL" dgst -dss1 -verify "$DSAPUBKEY" -signature "$DECODED_SIGNATURE_FILE" "$ZIPFILE_SHA1_FILE"

rm -f "$DECODED_SIGNATURE_FILE" "$ZIPFILE_SHA1_FILE"
