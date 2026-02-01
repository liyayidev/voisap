import time
from agora_token_builder import RtcTokenBuilder

# Replace these with your actual App ID and App Certificate from Agora Console
# In a real app, load these from environment variables
APP_ID = "596d9b79002a434a990e1825754088e4" 
APP_CERTIFICATE = "YOUR_AGORA_APP_CERTIFICATE"

def generate_agora_token(channel_name: str, uid: int, role: int = 1, expiration_time_in_seconds: int = 3600) -> str:
    """
    Generates an Agora RTC Token.
    
    :param channel_name: Name of the channel.
    :param uid: User ID (int).
    :param role: 1 for Broadcaster, 2 for Subscriber. Default is 1.
    :param expiration_time_in_seconds: Token validity. Default 1 hour.
    :return: The generated token string.
    """
    current_timestamp = int(time.time())
    privilege_expired_ts = current_timestamp + expiration_time_in_seconds
    
    token = RtcTokenBuilder.buildTokenWithUid(
        APP_ID, APP_CERTIFICATE, channel_name, uid, role, privilege_expired_ts
    )
    return token
