## Testbed TAs

### Single TA with TAK object

```
rsync://rpki-testbed.apnic.net/repository/38ABA74A4DA711EDB37796549E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuwgv1ZKuqbCEER+LQCvN
o3H+pwS3Sve0k1kXnnPh0RaxgFcCRcNjFP5Xj2wVkZfWmKottdW2wA2VuK+wlrxJ
NnvSRd7r1RLOAVsnNtdB2JXwjFalbGnz2IQglwW+q8LiofdLVGT8AoU3R72h2b6i
hohyu+BISp+QauwYhr+gOYPyR3EeNTqM5x+hdsK/kPy3xUwh/8JMHKbOzJehymDD
6zKbX0tdxDVg22Cy0Ooz84BRFFMNZWtFJQBrL4UkLZo0m9gljV5dEr+P//0pYELY
VLkr8fmzRAXoeOG7tmsyCrNZB5ZeCcDUsyKx5uvu4+/zC4a/Q8mJME6on9DZkg5c
+wIDAQAB
```

### Single TA with TAK object, unreachable successor URI

```
rsync://rpki-testbed.apnic.net/repository/AD9FA45A4DA911EDAF862D5A9E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsmzbunOJHibDmZpHz8bM
LukudGsEw/FkV6QNEykmQ08mWU5Mn9vxJyczgA/3NEKr+zS96F/fw2DkhVXMfPhi
BjpctTpk7ksqDOy5xBBbEr+eYX4MvIK46p267td2dh679yg5sC1y2gN6FBgBwh64
qR9N24Dage7tYD2pXMYZPYnGTqFfNfFzOBjnUq9LGUtgZkzUo1Ysss06HQeLOA8U
H7TqhhLvfP71eIlBp4vkgsW6r/Q3/+8hj4Sm0gyRTBHETbzE27xVrg9NmiMTjlBR
5j9Bs9AeRYpZB7S4Rfmmh++6q/Raqm0gsxQxxZwx3BbSstbFf4AnbGRW766n+NEB
xwIDAQAB
```

### Two TAs with TAKs, first TA transitions to second TA

```
rsync://rpki-testbed.apnic.net/repository/ED9D5F8E4DA911EDB9AC0C5B9E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyYT3tLDtrBW4xeBnhNWM
jgRkJJKlUyh3TodVDLxF+7r2CZOpTqSjkNO68G7HEmlRJnIxT6OyY+E4vg9kHmIU
cYyy9Cf3AP1GN9PbgR2TD6BCZzinxhQZSvm8tN0D16jjWBLh23FXbNr0a0lhnbPa
MGuLVIN2mHQ1eLyUSqhx6G40f+yVfOvmjW2vgkfiYkOSjbDPIGSVSn8jHzwDAVMY
QZdqPgHniw3RHlCmJRJWFVGxgG4qBdjeZfnlCRZamv3/MA8HJMMu6knLc4xj7uFC
kd/+I40pmZHrubsyWgLN4RBfx62hAOF/TTKzCqoncc45PYe8KOFHeEIR5fna0RjW
sQIDAQAB
```

To test the transition, update the acceptance timer value
(`$state_file.$tal_key_sha256_hash_hex.timer.first_seen`) to zero, or some other
epoch value that is more than 30 days in the past.

### Two TAs with TAKs, predecessor/successor key mismatch

```
rsync://rpki-testbed.apnic.net/repository/306D3F184DB011EDAEF022669E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqu44imm5RCONwt9gH35B
Tg/1M1KJXFn6qD9DLatyiV4bklLGgH9PcywhOWvamhmKOgfFHciPZksxEnJCawVc
Ef+HGT7odPEokAS4BqBIbW2zjXKCxEpu0VT7/FDqAgHHxKv5x8oyar5InFHuvJ+Z
e4OmTCYkiT6wDXKvOGbx3WFkhnVpdwn8Hkj454JjQj+LUnuiqIdFtndmVnRWVr6t
8BPKZvE1lHlWW1scbShpKuErDoCwpwO2weZfXDWKUn5Rb+SzVlOmOjkky7vru9Le
xH3QAEuy1avQLCehXsgPNqWxfV4z2EtsXSXYkomlo09uiH8s9TZGFLIe9IT3/whW
MwIDAQAB
```

### TAK URLs

 - rsync://rpki-testbed.apnic.net/repository/38AC22A64DA711EDB37796549E174E93/42AE70A64DA711EDB37796549E174E93.tak
 - rsync://rpki-testbed.apnic.net/repository/AD9FACFC4DA911EDAF862D5A9E174E93/B7C2334E4DA911EDAF862D5A9E174E93.tak
 - rsync://rpki-testbed.apnic.net/repository/F785B1B84DA911EDB9AC0C5B9E174E93/08FD617A4DAA11EDB9AC0C5B9E174E93.tak
 - rsync://rpki-testbed.apnic.net/repository/ED9D6A424DA911EDB9AC0C5B9E174E93/05F53BCE4DAA11EDB9AC0C5B9E174E93.tak
 - rsync://rpki-testbed.apnic.net/repository/306D47EC4DB011EDAEF022669E174E93/48662B524DB011EDAEF022669E174E93.tak
 - rsync://rpki-testbed.apnic.net/repository/398563D24DB011EDAEF022669E174E93/4B331D9A4DB011EDAEF022669E174E93.tak
