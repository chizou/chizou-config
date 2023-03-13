#!/bin/bash
# Import root certificates into linux CA store

main() {
    # Location of bundle
    bundle="https://site.url/bundle.zip"

    # Set cert directory and update command based on OS
    source /etc/os-release
    if [[ $ID      =~ (fedora|rhel|centos) ||
          $ID_LIKE =~ (fedora|rhel|centos) ]]; then
        certdir=/etc/pki/ca-trust/source/anchors
        update=update-ca-trust
    elif [[ $ID      =~ (debian|ubuntu|mint) ||
            $ID_LIKE =~ (debian|ubuntu|mint) ]]; then
        certdir=/usr/local/share/ca-certificates
        update=update-ca-certificates
    else
        certdir=$1
        update=$2
    fi

    [[ -n $certdir && -n $update ]] || {
        echo 'Unable to autodetect OS using /etc/os-release.'
        echo 'Please provide CA certificate directory and update command.'
        echo 'Example: install_certs.sh /cert/store/location update-cmd'
        exit 1
    }

    # Extract the bundle
    cd $certdir
    wget -qP tmp $bundle
    unzip -qj tmp/${bundle##*/} -d tmp

    # Convert the PKCS#7 bundle into individual PEM files
    openssl pkcs7 -print_certs -in tmp/*.pem.p7b |
        awk 'BEGIN {c=0} /subject=/ {c++} {print > "cert." c ".pem"}'

    # Rename the files based on the CA name
    for i in *.pem; do
        name=$(openssl x509 -noout -subject -in $i |
               awk -F '(=|= )' '{gsub(/ /, "_", $NF); print $NF}'
        )
        mv $i ${name}.crt
    done

    # Remove temp files and update certificate stores
    rm -fr tmp
    $update
}

# Only execute if not being sourced
[[ ${BASH_SOURCE[0]} == "$0" ]] && main "$@"
