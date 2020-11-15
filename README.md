## rpki-signed-tal-demo

A proof-of-concept for updating the TAL for a standalone RPKI
validator, based on the TAK issued by the TA operator.  See
[https://tools.ietf.org/html/draft-ietf-sidrops-signed-tal-06](https://tools.ietf.org/html/draft-ietf-sidrops-signed-tal-06).

### Build

    $ docker build -t apnic/rpki-signed-tal-demo .

### Usage

    $ docker run -it apnic/rpki-signed-tal-demo /bin/bash
    # rpki-tal-updater --tal {tal-path} --state {state-path}

On the first run, `{state-path}` should point to a non-existent file:
in that case, this takes the TAL at `{tal-path}`, finds the TAK issued
under that TA, and then continues resolving TAs/TAKs until it has the
complete set of current/revoked keys.  It then writes one of the
current keys in TAL format to `{tal-path}`, and writes the full set of
keys (plus other state) to `{state-path}`.  On subsequent runs,
`{tal-path}` is not used as input, but the process is otherwise the
same.

[https://rpki-testbed.apnic.net/signed-tal.html](https://rpki-testbed.apnic.net/signed-tal.html)
has a list of various testbed TAs that can be used to test different
signed TAL scenarios.

### License

See [LICENSE](./LICENSE).
