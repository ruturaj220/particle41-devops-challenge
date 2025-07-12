# app/app.py

from fastapi import FastAPI, Request
from datetime import datetime
import uvicorn

# Initialize the FastAPI application
app = FastAPI()

@app.get("/")
async def get_time(request: Request):
    """
    Handles GET requests to the root path ('/').
    Returns a JSON response containing the current timestamp (UTC) and the visitor's IP address.
    """
    
    # Get the current timestamp in UTC and format it as an ISO 8601 string.
    # Using UTC is a best practice for timestamps in APIs to avoid timezone issues.
    timestamp = datetime.utcnow().isoformat()

    # Get the client's IP address.
    # FastAPI's request.client.host typically handles X-Forwarded-For automatically
    # when behind a proxy like Uvicorn's proxy headers or a load balancer.
    ip_address = request.client.host
        
    # Construct the response dictionary
    response = {
        "timestamp": timestamp,
        "ip": ip_address
    }
    
    # Return the dictionary as a JSON response
    return response # FastAPI automatically converts dicts to JSON

# This block is for local development and direct execution.
# When running inside Docker, Uvicorn will typically be invoked directly via the CMD in the Dockerfile.
if __name__ == '__main__':
    # Run the FastAPI application using Uvicorn.
    # host='0.0.0.0': Makes the server accessible from outside the container.
    # port=5000: The port the application listens on.
    # reload=True: (Optional, for development) Automatically reloads the server on code changes.
    uvicorn.run(app, host="0.0.0.0", port=5000)
