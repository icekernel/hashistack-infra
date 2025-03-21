import json
from time import time
from source import utils, values
from source.utils import LoginBody
from source.auth import JWT


def lambda_handler(event, context):
    """ input json body format:
        ```python
        { "user": <pubkey>,  "signature": <signature>, "timestamp": <unix seconds> }
        ```
        The signed message must be: `"Sign in: id=<timestamp unix>"`

        Headers need to include Origin and it needs to be one of allowed origins.
        Otherwise, the browser will reject the response.

        Returns Set-Cookie header that contains `auth_token=<jwt_token>`.
        The browser will automatically set the cookie and will automatically include
        it in subsequent requests to the given domain.
    """
    print(f"Received new request {event}")
    headers = event.get("headers", {})

    event_origin = headers.get("origin") or headers.get("Origin")  # need to consider both cases.
    default_headers = utils.get_headers(event_origin)

    # DEMO REMOVE THIS ---------------------------------------------------------
    skip_validation_for_demo = json.loads(event['body']).get("skip_validation_for_demo", False)
    # -----------------------------------------------------------------------------

    # Parse request body
    try:
        print(f"Parsing request body {event['body']}")
        login_body = LoginBody(**json.loads(event['body']))
    except Exception as e:
        print(f"Invalid request body: {e}")
        return utils.return_response(400, str(e), headers=default_headers)

    print(f"Request details: Origin = {event_origin}", {"request": login_body.model_dump()})

    # --------------------------------------------------------------------------
    # DEMO REMOVE THIS ---------------------------------------------------------
    if skip_validation_for_demo:
        print("Skipping validation for demo")
    else:
        try:
            print("Validating timestamp ...")
            login_body.validate_timestamp()
            print("Validating signature ...")
            login_body.validate_signature()
        except Exception as e:
            print(f"Invalid request: {e}")
            return utils.return_response(400, str(e), headers=default_headers)
    # --------------------------------------------------------------------------
    # --------------------------------------------------------------------------

    # UNCOMMENT THIS FOR PROD --------------------------------------------------
    # Validate that it's a valid request
    # try:
    #     print("Validating timestamp ...")
    #     login_body.validate_timestamp()
    #     print("Validating signature ...")
    #     login_body.validate_signature()
    # except Exception as e:
    #     print(f"Invalid request: {e}")
    #     return utils.return_response(400, str(e), headers=default_headers)

    # Generate a cookie that's a JWT token.
    cur_time = int(time())
    jwt = JWT(
        user=login_body.user,
        iat=cur_time,
        exp=cur_time + values.AUTH_TOKEN_EXPIRATION_DELTA,
        roles=["user"]  # in the future, you may query this from DDB
    )
    jwt_secret_key = utils.ssm_get_auth_secret_key()
    auth_token = jwt.generate_token(jwt_secret_key)
    headers = utils.get_headers(event_origin, auth_token=auth_token)
    response = jwt.model_dump()
    print(f"Response {response}")
    print(f"Headers {headers}")
    return utils.return_response(200, "Login successful", headers=headers, response=response)

