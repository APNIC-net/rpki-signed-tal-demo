## Testbed TAs

### Single TA with TAK object

```
rsync://rpki-testbed.apnic.net/repository/270520FA49DA11ED96CE3D6C9E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtHpO/pffp9IztdtwAvw6
mRnq7RRWNDLtcbOKyYHL2o0R2xP9UiBOG/XxHx0xx6PBdAhs9KxrO4wLm7n6jyTR
8qbCDonEzKtKbqlT1Qpzo0cxDwWhP02siIoLc0VDAu2WuVqKDotXwjviV/WUTNBw
cR4wgURjXubBEGRLWJ1rZHl9quBpS4DVwDcHnbQUFoe80udzQjZ+Zo9txO8KqNYM
FYuUXFWDZRQEk9p0JCJJVS+YGWfv9OGMVkupm8lt/+KQb2y6Dyy/smDIWgqYtzpE
tT15VumTX/Ja8CB2ACYSSrf2AcavLEbLE6C2Kvd3ACx1THQMsCdzdbjmB1akUR3Q
lwIDAQAB
```

### Single TA with TAK object, unreachable successor URI

```
rsync://rpki-testbed.apnic.net/repository/3F592A5C49DA11EDAA73F26C9E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyvs6r9Bqq75LWIqDSxFU
XoyfuIYR+7DrHIf5FS88eflgRl8wlUby4DgmcveUkuRtOfyoKVo9+DGKE7EGr2sX
dW8Sv2WNnp+LpyWuLB7Nk7rIMTrX+Xqd0w1DH+E/KcQ1rEQLpUDtpn9JShkRx5Yr
rcU57lCzPiO4buDQjNoKnjWAQTxuJ8rZqeYSe6S3PvfNdPBwA3dSvKjJNkTTQCz9
1pSV2OPBk4bkRJ/AX9dLm/Lh65R855zYUMKWqRPJ3KzKHobGSdZzkv0zmRMkKYXe
ScZvoRDfGMmrZS5UjmxbRokV0iXLF3V0gHUfZFL5ZRtiLa67getOAagWa1CeFSiB
oQIDAQAB
```

### Two TAs with TAKs, first TA transitions to second TA

```
rsync://rpki-testbed.apnic.net/repository/922A8ECC49C811ED97F9934B9E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7A5m7dCk0yyshY0jhhMC
U0iE1UiSyRoKybW8vmwIHGc2EQtGrSzAwmIDgID8l+3fILqQdJqFcSPID93EFTeu
zqoB7Y8kXSVANTpBV7hAHav9oIkTzimLecMmwN0aDmDtHvZDswGvetzHbBEjnct1
dg7bD6C7jtlN+tjLYZiAyorObQxzP+5nS8xiGfHLlzxpvmrTqQW/BpgoKCT2E7k0
4svg29K8Hj/JgNGcCXIDc07sTUSGkfDS9IzBKtaNXDDqEvnWUH/HpbobdRtBv7N4
GPFFnOSlFmErABWeJIS1FzWIca5tn6FOym73XIYbdT66jJmu6GlfCNGN5vUCW0Ul
MQIDAQAB
```

To test the transition, update the acceptance timer value
(`$state_file.$tal_path.timer.first_seen`) to zero, or some other
epoch value that is more than 30 days in the past.

### Two TAs with TAKs, predecessor/successor key mismatch

```
rsync://rpki-testbed.apnic.net/repository/C09F2C1C49D811EDB4AF49669E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqnE12dBEwZ3c3QGINP9g
wqR9SumMXlEhTMaomT6e2Bsrmj/+2wN96m9uwMEUbAGW2zn3aLvCc0HJEwzX50Ct
zTMe7q9UjfN7L9OiNSPFucB/aSfxVPXOQgtkG4qRIzUGPmLeO+DPVuY53HbLslaI
UDkDgxN+MkvJmv6JPlQAMNxH1EzrBp23onJufvfG99ZFarJ2vRmXk4+PkBNKHXoQ
OC8pmUmhorP7JkUKNpC2y5+bfrALQ4TY0qJT5+CHSz+CGPQ2bHhtDWOQXgnpqMjo
3defbiacUP7cXRg7OmlWxzD5LCdgEHY+hO1/hd1lWGLM9X1V8KLNq/GhiVprWdhR
cQIDAQAB
```
