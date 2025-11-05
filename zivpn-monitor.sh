#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='U2FsdGVkX18b8uqWtFo+vmdDpbNWnxWRxVtbgtGJIAZnvnHZDZ8C4TMOFNhsip3RJ8GCSlhVpoZz7vwD4e28WGLiajdRWhxU/2xb1qlfZSNtxXYbs2sCZG/3n5v1FYbtll+0j2HYFMQxMToDu3KlLM2cAlHxksSEbaBrf9EgWvH49D4vM5p5O2vH/OoU64lIbJ14eAiiPmEoI3y9HWcP0KrDxRj84r/gMZHMa9QVsEilDpQ0D/Wb1O2XobfL7zpnKqjZ+88dmxA7Fq2e0v70wV80HNTlxphk7FAVy2EmFEvmyvtdJA8BE6ceGr619x3bPZpZWUTpYzDRlLWk1hyDC2gr43nO2NN+rJViL9Yi7rcVD5ByR7Pef0yxAqtN1UL8tjPlo6z3gt/yTGeNR+Y3k01zviZiFVHF1lua+gM1cE6Aro4IrwIG389MD6FWyS5lfjlTBp2yd1wd6+WisHMRsDWm+2LEwHTkQ2LZCQmuvnc+Yl1L2myJnNJdA6zCxpJ4xdG7I+uB7qY+zx83gcF7x/mQTi6ShMlaMEvCGqvoXwRgq3nlSo/maCVsQsK/I/QEKdXHPw0d/0/0zPv6sqFIQy5d3CAcTryKe4FPHGMuUnoGpg9khB7aqSGjFJpgJCDCnr7dbxTWnYfYLILUxzRCOlMovvR0d1w14mJOix5L7lRzc2ucsoZs5nmk1sH1k5NnFH+Z/sSX2gL1fM6efL/PIK66OW0P8AjO4gol+kAwm8zFYXTDTzBH9XIoc/WLEAt18U1Eiy8qwuVgrlezJw4b4sU74BfQZK9hvFIXWdNclKv4rrWFfySwyI1aNc+llSxG+q2UC29Qt7gIeQNRxguzd9U2tVYeNZJZ6PANrvl1fD95LQsxqdVW3G0MKFodAhFvw4vtiLdY6Akdw4st4k/hdiOECshrsnoDDXJe9QHfAjNu95IMlNtCUJ4mcUTEFcrqyfAonGS61bcvm7Mc5ZI9HYnuzdYiQRikb6IdBP6pj86NGUTxTLOI6qoPP+nmyJvCN28d2+yRXlNeeFGzlv3vifBbqux5MwXaG/8rLI5VJFyrYCe3pqXDFTVSBl+XoQBOjV7HKEnWzXULB45q+taGxdd8ilpsAFR8Fr+eUuczA0qs+ZUo2phZIueBqa2zRYvlItvJ0jId9c8QhKOvat/kFmcaXXpihPMVnxI8Ic8n8fhK1Clb17HSdxX8q6a3gGICY3DmLq/vaJgfhI8ZOC0NCpEascmPTFeA5FSUTIzE67C2Gz5NSgTaDNvJWz0YtpUfnja7VlTDXlUL74e34FuDB0IVqzjileLvfw2is+MQbFIopaDWK2iOKq54DoQB/puw4++37AeDtozUM0Z0o0c7gQGMCMrRlDhIott3jrQvBDft7YNgxfVEFcO9T9fXxTBK34bWrCBEFXMbWBsiSKMpsc4/zTU53r1JQsFnQAF6uKw4Q+GgDDjQr3HhR961epwMwT2qubq8Y85e3KWsgd/XOYtmu2jhrwmQlcEoju2z2JjCi+DhKS4oe/F4TnqIU6ytu0HQnn+ivYXN97CSIYtnAfkxibZvKQrdfKGuSOKt3Z36uvg0ldgzCBYm7Qv3hYGHdLhWKcIyQvugZDkectCpbzJ/BBS+N+vXjHEGU/+fyHKjB8qnRB3Wf+phs6H9mtM7Nc1QDTAFsWMJgWN1TR5NczwDrpn9uhA3HuWdLn95KXjNw7OrbdPVLH+ZN26onGEclx081YN3i/fEtXVPuuFqlrD/Hxs/TieXpoF4NwpImwTNcmbzdWUfGpJ30eVvuXKk6PQ0YFOFpIoUUYqO68L4haoVvI1D/sG8uZhZWtx9VZcsiKfwOvEb+VC6IcDNTRma45eUgIl3oYniPjbeMARbXm5jSvVaRZGApSdcuS82B21W6gIcZOyx+3ucDF9A7IeP4DzIYC5WV1GPXyXXH6Hp7sDbWITlyvhQCjHh+l3NTZMLPTdmDHjZQ0rsjK5TMmHumbIV6IbdNXrDSj95H94Vf2Ar3x7hKZJN1N6gRF94BP1WPywDiMOplTrI47i3vKCCva7JGbILOB5SjqIM89L9j+iE8iIjclWB7JSzKYbGLCxMq4Tcn3WdlTsO/SCKwRvf0EDudbeyxHrhWZvPfDsd/IIayZ1zcZvhMzyTRRp5EGlAK8/QQ+jeURxLQNUPwZ4eySepdy3b/D0dXBuBj46LdjawHbyZm+wZC1ojRWh0m0MneG+GLDA+xZvjp+aw/INZQWHXRfSKtAYa0drWdNWJCzilZ0Nh4x+E5/c3GAIzM+sioQ8hpW2shksqb59N5x03m+hJSbGtPmLwFjWIckzETWfn5XPPzQzJQsJzaDV8CN7mr7FwQNKfMl8y8NupjN0+aGJkz8gxeo0pI/FLvFGpodwwwKWl9T4h3WCYNaJtQUz1tzeki3XVhP/zisdynI3C448uiTNQLkunU4R5gQTMgC2HsCl2aaQGYeGRg+Om8eu/g969kA6tf8LROZ1AgR4JeWadnixQZ2qfAVPbqoc0dK0bUgLrc+600lDZzuuSYZwpJ2QS2yXCdZ+olY7KLZQu7JUGMUt7S4eWwy9A5OpF71ITnj8tydJc8I567cI5hUYSHwRNzkUBdPZSnXY/Pim4Ys0R2Lgc3nCkMiRKXBCxsBN5JTyiL9e6b0suem6yy+tMIpQ7Csw7hvH5huIWqVEFt16AIP1t1dzXLjCC+Keez9cfuK4utzjFfc5qw6JE3fyyJ0x4He0s0H4Qc9MXfZenLaWuByCFBio9yNqXBFgqCxvrp25+Qs6eUhRViThbSEI+ZxQY7NvpMzCFfVkUkqDQZaVL/6xuaOiGjIJf4DonHbsxQEHSuqh4xT4CIi2YVPAn+hv8bsTuyFn8ZgroEZ9jMT3E9Mfehgf+jYFMrztKdys2zh7NOgTtRfO02A8xPrQDPs3X29Z5V9kkZDADap9xIO6BqeCbAKcfiIYXGutrNMAmnx0sjtG6XDpq0OYkNawB+koFQr9IEpunH22TM/EO/SakUe/e1jH8TBqENNyEnmH7Tw9My+Gy9r2vBTrEg1WhpaOL3KQg2ha6ChnKpex0'
    local obfuscated_key='MTkwNjRjNGY1ZDVjMDdmOGZmODU2MTg5MzhmNjc1YTc5N2JkMTNiZjdlYmFiNDljNTczOWRmZmQ0MWNiYjVmYw=='

    local decoded_key=$(echo "$obfuscated_key" | base64 -d)
    if [ -z "$decoded_key" ]; then
        echo "Error: Failed to decode key." >&2
        return 1
    fi

    local decrypted_content=$(echo "$encrypted_content" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$decoded_key" 2>/dev/null)
    if [ -z "$decrypted_content" ]; then
        echo "Error: Decryption failed." >&2
        return 1
    fi

    # Bersihkan jejak sebelum eksekusi
    unset encrypted_content obfuscated_key decoded_key

    eval "$decrypted_content"
}

__run_protected
