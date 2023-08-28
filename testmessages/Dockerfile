FROM python:3.9

# Set the working directory in the container
WORKDIR /app

# Copy the local requirements file to the container
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the local script to the container
COPY test.py .

# Command to run your script
CMD ["python", "test_messages.py"]
