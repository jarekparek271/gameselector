import httpx
import asyncio
import json

async def test():
    url = "https://kurim.ithope.eu/v1/chat/completions"
    headers = {
        "Authorization": "Bearer sk-PxXPuVcDHUKcfq0ZyzHGgg",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "gemma2:27b",
        "messages": [
            {"role": "user", "content": "Hello"}
        ]
    }
    async with httpx.AsyncClient() as client:
        try:
            r = await client.post(url, headers=headers, json=payload, timeout=10)
            print("Status:", r.status_code)
            print("Response:", r.text)
        except Exception as e:
            print("Error:", e)

asyncio.run(test())
