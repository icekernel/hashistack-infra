import json


def lambda_handler(event, context):

    message = "If you are here, it means that the auth is working."
    print(message)
    print("EVENT:")
    print(json.dumps(event))

    return {"statusCode": 200, "body": json.dumps({"message": message, "event": event})}
