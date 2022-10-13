## Testbed TAs

### Single TA with TAK object

```
rsync://rpki-testbed.apnic.net/repository/45EB16D44A9611ED8AB0D6149E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA44dly8aUKN+BB21h3vT4
YIB3tpjc4yRbshM42rZsBNe6Aq1nwmi2j6DEMNjIalOJhxGmYWtkXEFYuwbi/gma
PXOevq15i94YxV9BaNGqOHHVBFRJTvEphfEAdo+BJiUlf/6gYa5V/d8JWfcdN2Wq
n4uuCE9dWk2UVZQVeLPtnIS0QVqI5IHoDX3xUD2xeB/LC2l+5mr6DREfAGAR2cdm
exie7LPo6QZMN1q5i80n9cQlwwkqMAG6OGzN9iQiTNfV3J+JhYUG3iVhfweVmLxZ
0+jMFfhmlwUPLXsukjPO3hMTim9fuQg2cRU7GqaQ0FdWxuoavgqdiODTIZnoGxV8
AQIDAQAB
```

### Single TA with TAK object, unreachable successor URI

```
rsync://rpki-testbed.apnic.net/repository/5A55466C4A9611EDA7CB8C159E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvQzo3FDJvYwXkQ4KbCOG
S9rZytGOy1H9kxk+pXU6ved2rMQnjZ7hQOrk6vI//Tk59Q6xlqO/oPtgnh6dXVqC
PVV7161Sjj44xZFSkNzQEyR21pYaJ/U3sEno4RQfyRFf8mOnW3m1tcd9xudXrIOI
pxZ4EHlCCs4WYuf5UpYOH28cL/C2CnNzrUFTIjlJ8oABgtn+fU3SL3kJiT6NmqVt
WAnFKkjkJlcKWfATClBCdQnyk9QQk/4taqWbrTy8HHBX6jrC9/k1MrmHzWVUvEUR
fZ8H23rCocNtgw+qN5dWDIgkaSy8lvkxReumZwObqObKvo83Cf67Z+5lqt5fr53M
YQIDAQAB
```

### Two TAs with TAKs, first TA transitions to second TA

```
rsync://rpki-testbed.apnic.net/repository/70EAA8364A9611ED88383D169E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0iojr8dm3b8H8986P0+u
mc81nMeA6FVLE+Ub2hfeFaXoqp6oxllsTcSOolbMYkLiWRIagCjl2nsBqzWs1hkX
VQKDhF8nck4r0JRacTQIhiweCDgkjisXObYv2fQvaXNvjbttCgFwTKmROkrBxd6E
kaUfBrJp6lBo5fpTCZjOzUCoxa71WcP3N/VtC2fPHI3YGgec5kz9w4E9eUMb8ny0
QlCwVJCl/2RCqVz1xe/Sj+c871MpXPMBwrpWVoNB40D8X0fgnX5V1De6RuPyCuCs
4BTIbQ7jzmlCy6DbEWlot4X+H3oPQRAJcgga2du27VdlKuom7dXcnJW8A1PN2vdX
ZQIDAQAB
```

To test the transition, update the acceptance timer value
(`$state_file.$tal_key_sha256_hash_hex.timer.first_seen`) to zero, or some other
epoch value that is more than 30 days in the past.

### Two TAs with TAKs, predecessor/successor key mismatch

```
rsync://rpki-testbed.apnic.net/repository/A06DE6C24A9611EDB98DEB179E174E93/root.cer

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwRGuKXLD6HWEtdHKs8u/
ICtiWjS4YYzkEJz5EWlTpOwGfftuL4ED7/P4OAmoT9YT3tfZn1ebwPdxCov4iMLX
96163JYbx5GpzW6duC5NNbT8ObGHkF8Rh/N52nLjDckLLbgDRtNa8NIaqiW/6nJ1
PC8ionezmzQVnFbOA1LPqrTXYMHPzN7xrrUOIiWhgobX2uAA6Upc9bz0zSRlfZib
XjV+No7fN7UFne8CjUdNJRRMeHCmuuk3GVwyrgRazzf3ZjL98Qbct6gtlzgQLhPQ
5Iihb8tgVrNlCt6x8RIMPbtkrBuHDhHG7bKMuLauTTZHpZnP9RaAiCliDq42a3wR
zwIDAQAB
```

### TAK URLs

 - rsync://rpki-testbed.apnic.net/repository/45EB8F7E4A9611ED8AB0D6149E174E93/4DBFD0204A9611ED8AB0D6149E174E93.t
 - rsync://rpki-testbed.apnic.net/repository/5A554E784A9611EDA7CB8C159E174E93/62D5FA0C4A9611EDA7CB8C159E174E93.t
 - rsync://rpki-testbed.apnic.net/repository/70EAAF3E4A9611ED88383D169E174E93/86B7502E4A9611ED88383D169E174E93.ta
 - rsync://rpki-testbed.apnic.net/repository/A06DF0404A9611EDB98DEB179E174E93/B5D996D24A9611EDB98DEB179E174E93.t
 - rsync://rpki-testbed.apnic.net/repository/79BB6A9A4A9611ED88383D169E174E93/89269CC04A9611ED88383D169E174E93.t
 - rsync://rpki-testbed.apnic.net/repository/A8F0366A4A9611EDB98DEB179E174E93/B8227B524A9611EDB98DEB179E174E93.tak 
