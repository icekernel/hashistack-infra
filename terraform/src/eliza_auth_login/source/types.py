import base58
from typing import Annotated
from pydantic import AfterValidator


def raise_(exc):
    """ raises exception """
    raise exc

def is_pubkey_b58(pubkey: str) -> bool:
    """Checks if a string looks like a valid base58 encoded public key"""
    try:
        pubkey = base58.b58decode(pubkey)
        return len(pubkey) == 32
    except Exception:
        return False

def is_signature_b58(sig: str) -> bool:
    """Checks if a string looks like a valid base58 encoded signature"""
    try:
        sig = base58.b58decode(sig)
        return len(sig) == 64
    except Exception:
        return False

# PubkeyB58 is a string that must be a valid base58 encoded pubkey
PubkeyB58 = Annotated[str, AfterValidator(lambda v: raise_(ValueError('Invalid b58 pubkey'))
                                          if not is_pubkey_b58(v) else v)]

SignatureB58 = Annotated[str, AfterValidator(lambda v: raise_(ValueError('Invalid b58 signature'))
                                             if not is_signature_b58(v) else v)]

