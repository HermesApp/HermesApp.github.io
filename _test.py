#!/usr/bin/env python
import os
import sys
import requests
from bs4 import BeautifulSoup
import subprocess


VERSIONS_XML = 'versions.xml'
DSA_PUBKEY = '_dsa_pub.pem'


def find_last_release(appcast):
    with open(appcast, 'rb') as f:
        soup = BeautifulSoup(f.read(), 'xml')
    first = soup.find('item').enclosure
    return {
        'url': first['url'],
        'signature': first['sparkle:dsaSignature'],
    }


def verify(dsa_pubkey, signature, zipfile):
    return_status = subprocess.call(['sh',
                                     '_validate_sparkle_signature.sh',
                                     dsa_pubkey,
                                     signature,
                                     zipfile])
    if return_status == 0:
        return True
    else:
        return False


def fetch_url(url):
    r = requests.get(url)
    if r.status_code != 200:
        r.raise_for_status()
    local_file = os.path.basename(url)
    with open(local_file, 'wb') as f:
        f.write(r.content)
    return local_file


def main():
    release = find_last_release(VERSIONS_XML)
    print('Latest release is {} in {}. Downloading.'.format(os.path.basename(release['url']), VERSIONS_XML))
    release_file = fetch_url(release['url'])
    print('Verifying DSA signature...')
    if not verify(DSA_PUBKEY, release['signature'], release_file):
        sys.exit(1)
    os.remove(release_file)
    print('Success!')


if __name__ == '__main__':
    main()