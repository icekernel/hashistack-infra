import jwt
from pydantic import BaseModel
from typing import ClassVar
from source.types import PubkeyB58
from time import time

# Base class for JWT token generation and validation ----------------------------
class BaseJWT(BaseModel):
    """ base model for JWT token generation. Every JWT must have these fields. """
    user: PubkeyB58
    iat: int
    exp: int
    roles: list[str] = ["user"]  # may be useful for admins, etc.
    _alg: ClassVar[str] = "HS256"

    def generate_token(self, secret_key:str):
        """ this function must be defined in the subclass """
        raise NotImplementedError("This function must be defined in the subclass")

    @classmethod
    def _generate_token(cls, payload:dict, secret_key:str):
        # assert that all the keys present in BaseJWT are present in payload
        for key in BaseJWT.model_fields:
            assert key in payload, f"Key {key} is missing in payload"
        # sign the payload
        token = jwt.encode(payload, secret_key, algorithm=cls._alg)
        return token

    @classmethod
    def decode(cls, token:str, secret_key:str):
        """ raises jwt.exceptions.InvalidTokenError if the token is invalid """
        payload = jwt.decode(token, secret_key, algorithms=[cls._alg])
        return payload

    @classmethod
    def validate(cls, token, secret_key):
        """ returns True if the token is valid, False otherwise """
        try:
            cls.decode(token, secret_key)
            return True
        except jwt.exceptions.InvalidTokenError:
            return False

# Main class for JWT generation and validation --------------------------------
class JWT(BaseJWT):
    # ...
    # can add custom fields here

    def generate_token(self, secret_key:str):
        return self._generate_token(self.model_dump(), secret_key)

