## rpki-signed-tal-demo

A proof-of-concept for updating the TAL for a standalone RPKI
validator, based on the TAK issued by the TA operator.  See
[https://tools.ietf.org/html/draft-ietf-sidrops-signed-tal](https://tools.ietf.org/html/draft-ietf-sidrops-signed-tal)
(note that the current demo targets an unpublished draft version).

### Build

    $ docker build -t apnic/rpki-signed-tal-demo .

### Usage

    $ docker run -it apnic/rpki-signed-tal-demo /bin/bash
    # rpki-tal-updater --tal {tal-path}

This takes the TAL at `{tal-path}`, finds the TAK issued under that
TA, and then continues resolving TAs/TAKs until it reaches an
unrevoked key.  It then writes the earliest unrevoked current key in
TAL format to `{tal-path}`.

The container includes
[rpki-client](https://github.com/kristapsdz/rpki-client), so that it's
possible to test validation alongside TAL updates.  For example:

    # echo "..." > tal
    # mkdir cache output
    # rpki-client -c -t tal -d cache output
    # cat output/csv
    ASN,IP Prefix,Max Length,Trust Anchor
    AS65001,10.0.0.0/24,24,tal 
    # rpki-tal-updater --tal tal
    # rpki-client -c -t tal -d cache output
    ...

[https://rpki-testbed.apnic.net/signed-tal.html](https://rpki-testbed.apnic.net/signed-tal.html)
has a list of various testbed TAs that can be used to test different
signed TAL scenarios.

### License

See [LICENSE](./LICENSE).
