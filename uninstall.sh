#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='U2FsdGVkX1+DoCUrBPq9h5KwSvMFrto5SOxCZfj7mx1xammcKOrXx/f94ZlAnUISOKrDdJ9aDoeOZbyrovVghtSqCZLubJp+R/ax8BdaW/cPOnJcWC83OqnRsIYA5+2BGiwAn6jsfsA32mzKjTCI6ye28edROCuvVjky29uOC8RvvjQ2HiE7+2GRY979u6X8X3NoxrKuhkpqDq8dfGiBuB2FgoYeqc1KBiW97uq0DcD755JHko7uMMZSmOuQtV8TuhCytl01uGiUBGCP/M5rFRKL9GrItbBSVOEW7CKvItAsMNGgC5fSu1DbsHmDqXa86yXX7gYggOnI3x7L39W5LaOkjeZXFlzO6abVea1GkQqAhJiPpJcp1b+Q2KB9jXDF+wS37+aNZ98I6cIQRMOReBLZD5ji5mxn4Bu7TP32s8V4nGgyyD29oC4DifnqMbU4F8an0m8g7Kge9U+8ZIMAJ6k0WW/4pU1NdhbNeWEF9v1Fi6ttKOc4o4LfqLJbIeyguIjcNthswAfuMDdkLBsYbaM4YTqEqFz+Xk8AspJVTJnCblC6e6G94qpykFjl3kZzq8oUun3uOHD/v7XGLgGUr/3JaC67E/4zpTrnnbKSU0u/4P8SMd1VwrfZ8l/RIiiZDcP8tG9Zds1mgXFXRg+EmNRbWFmUFV3Gd1fxg7VFVbxH5F7lkAx4h5C2Gtz0dIk/IYGOZqTcyMQjV/VOxqwvO+WPrXaYOFBYb9qjON+n50ym830xRzjZ0qrIAG1hUf/8dZ6Nak+jF7i43Hw6EMsxUM3TVxTk4R/90W/2MfCczfxBE24SDid3RWSmbiMHGzDf0ApHNZoEixX/YMrAHogUWgpfIHD/GiG+fpy9md8FnuWW7SNNK6fiD/0bQofAHlEg14FXX2pD/qu0uUVtH5NMHAODk+prozad39ym+mOlOczyMh5gfa0xBKOhKVSv2fD2GIsCRyVZA16xwrE43iUH3S8Q1hXX9ZRlc7ycG8aTlSl4hlI+AxMHe6+SftAr4rGVdv5DhKvX7+TAZfk3M67j+m/uqFM4MyIvaV9oK67YWiVILgU+H2BGAr6mr18V4pVwJlH+HTFFu1MP1Z36QTMIeGrAY+vpV50u5jI45xbGhBEhRbnfG2hVGXyr2Hs8ETfhhVWtHzfgVmvJeOPeFSitt/ovmOIUHNWUC2kxUQWpyzMIFW7Uc1cYBHnFh9ig6+o3xDF3zUc0hNXEujwn8XdayV+9tweVf/nF9I2/JdKwDHVg/2Q8It+UWl0alcTqmMHJBY9qbYIFVmi+y5L0L8gi6FdwMIwtfQ0gZ1d/2Y788rJXoWFMWumMe0AefpbW2JDRyWJ3NjssbiCdRFfN46qEDNF/jFmp2INKKkg4axg/yE1xKkRdbXNF9cklY/3L/XSMdgCVqbcEcUR73V3JTIdbMI9Ij4i4sgtfEV/Y74HFd1+rKSG8mWqquPY+RlPEfF/++dwuzEg06KbvxDFftq6gC20TrQvX66sA5G5Zvpg6XRmIlxsOEJQ0n+PyGBxWIwWfw3g7CXbEg7Yd+ZVRcFiBeWUZT72YHTd0QfxfF2kfD4nHyzC1IYHzc3VOlnraxignZjxujthdwEX4livMsgXauk3omb9eN8GWxQ1nzXl03kH1uuyrO0+ZoLJtCPYnS7zvHa1Tzas56Qd0Q0q8SF6qTNftwgKYmg1aM9kL5YdlBouyE/tv9BM8KlsTLM/IFOY//kjiVOUTFzr76KY5vWK/9hj9zOT67qwYCxCOLKaWAB5Q/x2QPVBzUsWmOjrtpS80ey3XjlS5qTt6Ti3UmBpwA6LFehU9xr4bC4/hSD9pEC+VgLIi7BKhOKQ38/2z32ntmnWXxFLIn4SnTPdlX87CkNrlEtljSFUuaowlI8EtolE4veD1YUV4YJTnuRJYVih0T1dzS/39sQYwoOa0QHlny0UsOMbxrZeEpLsC1FNfpvFXp7kFyRG8YEVtxNTTCxKGcPc6YBbGcA1mr+/ghTk8Pp8WpKLIyxHmWBhNr2V9WNuGxTx7+1GIYEZQatHc4k1C49NW8bZXX/lCjfregXOTgZSZKVmasUowACXiL8pnvnRBIVsYtI5MbiJ4NuocAWaxoTk0Psw4bkq6Kn9+nKUmFjxaUkEP5JeOvWu4oKqYsqwzIyNVxPZiUPovytUz3ZEGDODHacI52UMyv/j+/Qpq+Bm4WPAA4JMJQEkVMzCjMy7vZ+C5z3JACZJ74NW8QAYcuPS6Cc0EtZFuOUwNtz0jpV9RLdC8HnvyWu32rHc9eoeTS73rD1qctAJu2JqnqB+a0Z+ZuXfoZqDLkDrgN+HzAnAb2O34EOAN5CiYqgxncM2FPRxEcKMHAbXzmamR02Es82CWtyRElyQjFY4AU4OTMCkBeKM2pYJZMq5ThFtKVbq8sWV8f9aYULNjXATDK9lr5oot0vM24Is8tz86wfF/vI7z06GbFS4j79JevzAOKbDbPYq9HLU7oEzDPrbOg1YdSxx4IcAL9BNCr0LJV8xjo+U0LBb0k5s3OBkLupXlt54O3kcmS6whVh3Xrao+wLW+INvDBUEElKOaKwwSDn+Vnz0U+nXlt9W4H/87L2vUJSkZ/DG/2H39KpTjEyJosnIY156thaHBjb+wFricPEkKY+DVX0NPrGt1xzKbBruykDlXEFSlu7yMzX0JJABq1R6GkhnoO/ZjG6tHZbv2AbXoxkwzm/Zp6Sm0wHV3ooqLxX7mkiM1svi1ZmAG+EEvIUDBEPzOP+Mgc7YctxMJJtxrx2sJpgcqgHAKOu7yUwaysgqJwQ1q+ZQdusOU1WH6P/n5gK0UeTRUrq7LhAKS4hkcsAls1PF7ZN7pcM4AHn83UVeEOlEhFUnX215ojhkfGEsXxc/uX50eawLWMxDcq6+4kqZnsgt/QsmsaVveLRSKv8wJqOINF9uZbHGUncq3s32Om75I/1IKMhdUXyOhhRPBXWSE8tYs9PpbQz6Q2BvNTVnGQ6q8n+idHh+BLT3kNvaHpbIl2KguSf/NuvuN1ncBtju3Lbg1SoU5dV+IxQkm04tThmAABQVKgTNRfmCoUdxfKPwKn97jo7nHkQRvkvjdcH79cAZcS4JM9pCvmG/08xYStAvjY9dDZ5wHPuj1jC40ruXGdegUwNA1fHh3NisW67W8NoVu1Ks8QGwLorHT6HGXpbaCTTtSeI1CI0xJF1S0zFvfiYrlwZXfmrtP99TQu8s3ky5mHcMrl8OStNBD4xLTskpgJ/W1uU9L05dNl8L6I7DEUpZalmbycQLJEChDj70ojH8tZkvEQqg66Uzm8clNEYqo2/QhD414mMcdrXtWQc4Ju3efshK2b/yUpXS2WLt/TRiF0wsylsfP0eSoxibGiQCQxhguZwIxoEawnCzvZaKE5UPGKWCr1W8TFFK9Ruh5W3JnfvGM00tSdNkBAtucDA2vVk3y2CuS1isbk51enOWT4RCrC0kxWNvlN8u+RQ=='
    local obfuscated_key='NDEzM2VkMjExZWZkNDY1ZWJmZWJlYzE5NDEyZTU1ZjNkNjVmYTg0YThlMTM0MzUyNTAzNDU3MjVjNzQ5MThiYg=='

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
