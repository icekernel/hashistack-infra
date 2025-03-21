import os
MINUTE = 60; HOUR = 60*MINUTE; DAY = 24*HOUR

SSM_AUTH_SECRET_KEY_PATH = "/launchpad/Auth/SecretKey"

# signing message for proving that the user is the owner of the pubkey
LOGIN_MESSAGE_MAX_AGE = 300  # if the signed message is too old
LOGIN_MESSAGE_MAX_FUTURE_SECONDS = 5  # if the signed message time is in the future
SIGNED_MESSAGE_PATTERN = os.getenv("SIGNED_MESSAGE_PATTERN", "Sign in: id={}")  # {timestamp}

# token that gives user access to the API
AUTH_TOKEN_EXPIRATION_DELTA = int(os.getenv("AUTH_TOKEN_EXPIRATION_DELTA", 1*DAY))  # exp field in JWT
AUTH_COOKIE_MAX_AGE = int(os.getenv("AUTH_COOKIE_MAX_AGE", 1*DAY))
MAIN_DOMAIN_NAME = os.getenv("MAIN_DOMAIN_NAME", "example.com")  # used to set the cookie for subdomains too
AUTH_COOKIE_PATH = "/"
AUTH_COOKIE_HTTP_ONLY = True
AUTH_COOKIE_SECURE = True  # Make sure it is set to True !!! (to Only send cookie over HTTPS to prevent interception )
AUTH_COOKIE_PRIORITY = "High"
AUTH_COOKIE_SAME_SITE = "Lax"  # won't send cookie with cross-site requests

