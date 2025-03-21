
import boto3
import jwt
from botocore.exceptions import ClientError
from time import time
from source import values
ssm = boto3.client("ssm")


def ssm_get_auth_secret_key():
    response = ssm.get_parameter(Name=values.SSM_AUTH_SECRET_KEY_PATH, WithDecryption=True)
    return response["Parameter"]["Value"]

def validate_jwt_token(jwt_token:str, secret_key:str):
    """ validate the jwt token against the secret key """
    try:
        return jwt.decode(jwt_token, secret_key, algorithms=["HS256"], options={"verify_exp": True})
    except jwt.ExpiredSignatureError:
        raise Exception("Token expired")
    except Exception as e:
        raise Exception(f"Invalid token: {e}")

def get_jwt_data(jwt_token:str):
    """ get the data from the jwt token without validating it """
    return jwt.decode(jwt_token, options={"verify_signature": False})

def return_policy(event, principalId, status, message, user, auth_token):
    """ `context` is passed down to the API Gateway """
    return {
        "principalId": principalId,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [{"Action": "execute-api:Invoke",
                           "Effect": status,
                           "Resource": event["methodArn"]}]
        },
        "context": {
            "message": message,
            "user": user,
            "auth_token": auth_token
        }
    }

