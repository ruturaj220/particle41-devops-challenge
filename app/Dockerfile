# app/Dockerfile

# --- STAGE 1: Builder Stage ---
# This stage is used to install Python dependencies.
# We use a 'slim' base image to keep the overall image size down.
FROM python:3.11-slim AS builder

# Set the working directory inside the container for this stage.
WORKDIR /app

# Copy only the requirements file first to leverage Docker's build cache.
# If requirements.txt doesn't change, this layer won't be rebuilt.
COPY requirements.txt .

# Install Python dependencies.
# --no-cache-dir: Prevents pip from storing downloaded packages in a cache, reducing image size.
# --upgrade pip: Ensures pip itself is up-to-date.
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# --- STAGE 2: Final Production Image ---
# This stage creates the final, minimal image for running the application.
# It also uses a 'slim' base image.
FROM python:3.11-slim

# Create a dedicated non-root user and group for security best practices.
# --system: Creates a system user/group, typically for services.
# --gid appuser: Assigns the user to the 'appuser' group.
# appuser: The name of the new user and group.
RUN groupadd --system appuser && useradd --system --gid appuser appuser

# Set the working directory for the final image.
WORKDIR /app

# Copy the installed Python packages from the 'builder' stage.
# This ensures only the necessary runtime dependencies are included, not build tools.
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy the application source code into the final image.
COPY app.py .

# Expose the port on which the FastAPI application listens.
# This informs Docker that the container listens on this port at runtime.
EXPOSE 5000

# Set the non-root user that the application will run as.
# This is a critical security measure to prevent the application from running with root privileges.
USER appuser

# Define the command to run the application when the container starts.
# --host 0.0.0.0: Listens on all network interfaces.
# --port 5000: Listens on port 5000.
# app:app: Refers to the 'app' FastAPI instance inside the 'app.py' module.
CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
