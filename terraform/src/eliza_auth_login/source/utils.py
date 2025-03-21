import json
import base58
import boto3
from time import time
from datetime import datetime, timezone
from pydantic import BaseModel, ConfigDict
from solders.signature import Signature
from solders.pubkey import Pubkey
from source.types import PubkeyB58, SignatureB58
from source import values

from urllib.parse import urlparse

ssm = boto3.client("ssm")

def ssm_get_auth_secret_key():
    response = ssm.get_parameter(Name=values.SSM_AUTH_SECRET_KEY_PATH, WithDecryption=True)
    return response["Parameter"]["Value"]

def get_signed_message(timestamp:int):
    """ The signed message must be: `"Sign in: id=<timestamp>"` """
    return values.SIGNED_MESSAGE_PATTERN.format(timestamp)

class LoginBody(BaseModel):
    model_config = ConfigDict(strict=True)

    user: PubkeyB58
    signature: SignatureB58
    timestamp: int

    def validate_timestamp(self):
        """ Validates that timestamp is not too old or in the future.
            Raises ValueError otherwise.
        """
        print("Validating timestamp ...")
        cur_time = int(time())
        if cur_time - self.timestamp > values.LOGIN_MESSAGE_MAX_AGE:
            raise ValueError("Request too old")
        if self.timestamp - cur_time > values.LOGIN_MESSAGE_MAX_FUTURE_SECONDS:
            raise ValueError("Request in the future")

    def validate_signature(self):
        """ Validates that the signature is valid.
            Raises ValueError otherwise.
        """
        print("Validating signature ...")
        try:
            usr = Pubkey.from_string(self.user)
            sig = Signature.from_string(self.signature)
            msg = get_signed_message(self.timestamp).encode()
            is_valid = sig.verify(usr, msg)
            if not is_valid:
                raise ValueError("Signature verification failed")
        except Exception as e:
            print(f"Signature verification failed: {e}")
            raise ValueError("Signature verification failed")

def generate_set_cookie_header_for_auth_token(
    auth_token:str,
    domain:str,  # if None, will default to host domain (=> be set for subdomains like app.cook.meme)
    max_age:int=values.AUTH_COOKIE_MAX_AGE,
    path:str=values.AUTH_COOKIE_PATH,
    http_only:bool=values.AUTH_COOKIE_HTTP_ONLY,
    secure:bool=values.AUTH_COOKIE_SECURE,
    priority:str=values.AUTH_COOKIE_PRIORITY,
    same_site:str=values.AUTH_COOKIE_SAME_SITE
):
    """ returns a header for the Set-Cookie field """
    cur_time = int(time())
    expires_gmt = datetime.utcfromtimestamp(cur_time + max_age).strftime("%a, %d %b %Y %H:%M:%S GMT")
    parts = [f"auth_token={auth_token}",
             f"Max-Age={max_age}",
             f"Path={path}",
             f"Expires={expires_gmt}",
    ]
    if domain: parts.append(f"Domain={domain}")
    if http_only: parts.append("HttpOnly")
    if secure: parts.append("Secure")
    if priority: parts.append(f"Priority={priority}")
    if same_site: parts.append(f"SameSite={same_site}")
    return "; ".join(parts)

def get_headers(origin:str, auth_token:str=None):
    """ if you pass auth token, it will also create and include it in the Set-Cookie header. """
    result = {"Content-Type": "application/json",
              "Access-Control-Allow-Credentials": "true",  # use this to allow cookies to be sent with the request
              "Access-Control-Allow-Headers": "Content-Type, Set-Cookie, Date",
              }
    # only add Access-Control-Allow-Origin if the origin is in the allowed list
    result["Access-Control-Allow-Origin"] = origin

    if auth_token:
        host = urlparse(origin).hostname
        domain = None
        if host and host.endswith(values.MAIN_DOMAIN_NAME):
            domain = f".{values.MAIN_DOMAIN_NAME}"  # set the cookie for subdomains too if host is cook.meme
        result["Set-Cookie"] = generate_set_cookie_header_for_auth_token(auth_token, domain=domain)
    print(f"Returning headers: {result}")
    return result

def return_response(status_code, message, headers:dict, response:dict=None):
    """ returns a response object for the lambda function """
    response = {
        "statusCode": status_code,
        "body": json.dumps({"message": message, "response": response}),
        "headers": headers
    }
    return response

