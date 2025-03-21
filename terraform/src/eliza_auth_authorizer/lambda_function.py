import json
from source import utils, values
from source.utils import return_policy


def lambda_handler(event, context):
    """ how it works:
        client is expected to send the following header:
        Authorization: Bearer <jwt_token>

        this lambda will extract the jwt_token and validate it against our system signer (SSM: /launchpad/Auth/SecretKey)
    """
    print(">>>>>>> EVENT")
    print(json.dumps(event))
    print("<<<<<<<<")

    allow = "Allow"
    deny = "Deny"

    # Expected authorization token: "auth_token=<jwt_token>"
    auth_token_jwt = event['authorizationToken'].split("auth_token=")[1].strip()
    print("Got auth token: ", auth_token_jwt)

    try:
        secret_key = utils.ssm_get_auth_secret_key()
        jwt_data = utils.validate_jwt_token(auth_token_jwt, secret_key)
    except Exception as e:
        print(f"Error validating JWT token: {e}")
        msg = "Unauthorized - invalid auth token"
        if str(e) == "Token expired":
            msg = "Unauthorized - expired auth token"
        return return_policy(event, "unknown", deny, msg, None, auth_token_jwt)

    user = jwt_data["user"]
    return return_policy(event, auth_token_jwt, allow, "Authorized", user, auth_token_jwt)

