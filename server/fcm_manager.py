import firebase_admin
from firebase_admin import credentials, messaging
import os

# Path to your serviceAccountKey.json
# You must download this from the Firebase Console > Project Settings > Service Accounts
CRED_PATH = "serviceAccountKey.json"

def init_fcm():
    """Initializes the Firebase Admin SDK."""
    if not os.path.exists(CRED_PATH):
        print(f"WARNING: {CRED_PATH} not found. FCM will not work.")
        return

    try:
        cred = credentials.Certificate(CRED_PATH)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin Initialized")
    except ValueError:
        # App already initialized
        pass

def send_call_notification(token: str, channel_name: str, agora_token: str, caller_id: str):
    """
    Sends a data message to the specified FCM token to trigger a call.
    
    :param token: The FCM registration token of the target device.
    :param channel_name: The Agora channel to join.
    :param agora_token: The Agora token for authentication.
    :param caller_id: The ID of the caller.
    """
    if not firebase_admin._apps:
        print("Error: Firebase not initialized.")
        return

    # specific android config for high priority
    android_config = messaging.AndroidConfig(
        priority='high',
        ttl=0, # Delivery immediately
    )

    message = messaging.Message(
        token=token,
        data={
            "type": "call_initiation",
            "channel_name": channel_name,
            "agora_token": agora_token,
            "caller_id": caller_id,
        },
        android=android_config,
    )

    try:
        response = messaging.send(message)
        print('Successfully sent message:', response)
        return response
    except Exception as e:
        print('Error sending message:', e)
        return None
