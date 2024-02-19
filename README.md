## rpki-signed-tal-demo

A proof-of-concept for updating the TAL for a standalone RPKI
validator, based on the TAK issued by the TA operator.  See
[https://tools.ietf.org/html/draft-ietf-sidrops-signed-tal](https://datatracker.ietf.org/doc/html/draft-ietf-sidrops-signed-tal-14).

### Build

    $ docker build -t apnic/rpki-signed-tal-demo .

### Usage

    $ docker run -it apnic/rpki-signed-tal-demo /bin/bash
    # rpki-tal-updater --state-path {state-path} --tal {tal-path}

This takes the TAL at `{tal-path}`, finds the TAK issued under that
TA, and checks whether that TAK points to a valid successor key.  If
it does, then it records the beginning of an acceptance timer in the
state file at `{state-path}`, unless an acceptance timer already
exists, in which case it updates the TAL at `{tal-path}` with the
successor TAL if the acceptance timer period (30 days) has elapsed and
no other successor has been seen in that time.  If it doesn't point to
a valid successor, then it clears the acceptance timer for this TAL
(if one exists).

The container includes
[rpki-client](https://ftp.openbsd.org/pub/OpenBSD/rpki-client/), so
that it's possible to test validation alongside TAL updates.  For
example:

    # sudo -u rpki-client -H bash
    # mkdir /tmp/test
    # cd /tmp/test
    # echo "..." > tal
    # mkdir cache output
    # rpki-client -c -t tal -d cache output
    # cat output/csv
    ASN,IP Prefix,Max Length,Trust Anchor
    AS65001,10.0.0.0/24,24,tal
    # echo "{}" > state
    # rpki-tal-updater --tal tal --state-path state
    # rpki-client -c -t tal -d cache output
    ...

See [testbed TAs](./testbed-tas.md) for various TALs that can be used
to test different scenarios.  (The testbed RRDP service may not be
functional, in which case relying parties should fall back to using
rsync.)

### License

See [LICENSE](./LICENSE).
