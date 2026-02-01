from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Optional
import uuid
import random

from agora_manager import generate_agora_token
from fcm_manager import init_fcm, send_call_notification

app = FastAPI()

# In-memory storage for demo purposes
# users_fcm[user_id] = fcm_token
users_fcm: Dict[str, str] = {}

# Phonebook: phone_number -> user_id
phonebook: Dict[str, str] = {}
# Reverse Phonebook: user_id -> phone_number
reverse_phonebook: Dict[str, str] = {}

# Initialize Firebase
init_fcm()

class LoginRequest(BaseModel):
    username: str

class FCMRegisterRequest(BaseModel):
    user_id: str
    fcm_token: str

class CallRequest(BaseModel):
    caller_id: str
    target_number: str  # Changed from target_user_id

@app.post("/login")
def login(request: LoginRequest):
    user_id = f"user_{request.username}"
    
    # Assign Phone Number if not exists
    if user_id not in reverse_phonebook:
        while True:
            # Generate random 4-digit number (1001 - 9999)
            # 100 is reserved for Voice Agent
            new_number = str(random.randint(1001, 9999))
            if new_number not in phonebook:
                phonebook[new_number] = user_id
                reverse_phonebook[user_id] = new_number
                print(f"Assigned {new_number} to {user_id}")
                break
    
    phone_number = reverse_phonebook[user_id]
    
    return {
        "user_id": user_id, 
        "token": "mock_session_token",
        "phone_number": phone_number
    }

@app.post("/register_fcm")
def register_fcm(request: FCMRegisterRequest):
    users_fcm[request.user_id] = request.fcm_token
    print(f"Registered FCM for {request.user_id}: {request.fcm_token}")
    return {"message": "FCM registered successfully"}

@app.post("/trigger_call")
def trigger_call(request: CallRequest):
    # Special Number: 100 -> Voice Agent
    if request.target_number == "100":
        # Create a channel for the Voice Agent interaction
        channel_name = f"agent_{uuid.uuid4().hex[:8]}"
        # Generate token for the caller (uid 0)
        agora_token = generate_agora_token(channel_name, 0)
        
        # In a real system, you would also trigger the Voice Agent service here 
        # to join the channel.
        print(f"User {request.caller_id} called Voice Agent (100)")

        return {
            "channel_name": channel_name,
            "token": agora_token,
            "uid": 0,
            "target_type": "agent"
        }

    # P2P Call
    target_user_id = phonebook.get(request.target_number)
    if not target_user_id:
        raise HTTPException(status_code=404, detail="Number not found")

    target_fcm = users_fcm.get(target_user_id)
    if not target_fcm:
         raise HTTPException(status_code=404, detail="Target user is offline (No FCM)")

    channel_name = f"call_{uuid.uuid4().hex[:8]}"
    
    # Generate Token for the Caller
    agora_token = generate_agora_token(channel_name, 0)

    # Send Notification to Target
    # Note: We send the channel info to the target so they can join
    # We might want to send a separate token for them if we used specific UIDs
    send_call_notification(target_fcm, channel_name, agora_token, request.caller_id)

    return {
        "channel_name": channel_name,
        "token": agora_token,
        "uid": 0,
        "target_type": "user"
    }

@app.get("/get_agora_token")
def get_token(channel_name: str, uid: int):
    return {"token": generate_agora_token(channel_name, uid)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
    # python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload