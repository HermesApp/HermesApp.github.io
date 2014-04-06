#!/usr/bin/env python
import os
import sys
import xml.etree.ElementTree as ET
import subprocess
# Python 2 vs 3
try:
    import urllib2
except ImportError:
    import urllib.request as urllib2


VERSIONS_XML = 'versions.xml'
DSA_PUBKEY = '_dsa_pub.pem'
# Crutch for ElementTree's shortcomings.
SPARKLE_NS = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'


def find_last_release(appcast):
    tree = ET.parse(appcast)
    first = tree.find('./channel/item/enclosure')
    return {
        'url': first.attrib['url'],
        'signature': first.attrib[SPARKLE_NS+'dsaSignature'],
    }


def verify(dsa_pubkey, signature, zipfile):
    return_status = subprocess.call(['sh',
                                     '_verify_sparkle_signature.sh',
                                     dsa_pubkey,
                                     signature,
                                     zipfile])
    return not bool(return_status)


def fetch_url(url):
    local_file = os.path.basename(url)
    response = urllib2.urlopen(url)
    with open(local_file, 'wb') as f:
        f.write(response.read())
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
