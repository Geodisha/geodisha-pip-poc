FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir fastapi uvicorn pandas

# Copy seed data and server
COPY sql/seed/ sql/seed/
COPY mock_server.py .

EXPOSE 8080

CMD ["uvicorn", "mock_server:app", "--host", "0.0.0.0", "--port", "8080"]
