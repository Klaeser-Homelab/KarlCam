.PHONY: help start-api start-frontend start-admin-backend start-admin-frontend start-collect start-sql clean

# Default target
help:
	@echo "Available targets:"
	@echo "  start-api            - Setup and start the API server (http://localhost:8002)"
	@echo "  start-frontend       - Setup and start the main frontend development server (http://localhost:3000)"
	@echo "  start-admin-backend  - Setup and start the admin backend server (http://localhost:8001)"
	@echo "  start-admin-frontend - Setup and start the admin frontend development server (http://localhost:3001)"
	@echo "  start-collect        - Setup and run the dual scoring collector locally"
	@echo "  start-sql           - Start Cloud SQL Proxy for local development"
	@echo "  clean               - Remove virtual environments and node_modules"

# API: setup venv + install deps + start
start-api:
	@echo "Setting up and starting API server..."
	@if [ ! -f web/api/.env ]; then \
		echo "⚠️  No .env file found in web/api/"; \
		echo "📝 Copy web/api/.env.example to web/api/.env and configure:"; \
		echo "   cp web/api/.env.example web/api/.env"; \
		echo ""; \
		echo "Then:"; \
		echo "1. Start Cloud SQL proxy: make start-sql"; \
		echo "2. Get DB password: gcloud secrets versions access latest --secret=\"karlcam-db-password\" --project=karlcam"; \
		echo "3. Update DATABASE_URL in .env with the password"; \
		exit 1; \
	fi
	cd web/api && python3 -m venv venv || true
	cd web/api && source venv/bin/activate && pip install -r requirements.txt
	@echo "Starting API server on http://localhost:8002"
	cd web/api && source venv/bin/activate && python main.py

# Frontend: npm install + start
start-frontend:
	@echo "Setting up and starting frontend development server..."
	cd web/frontend && npm install
	@echo "Starting frontend development server on http://localhost:3000"
	cd web/frontend && npm start

# Admin backend: setup venv + install deps + start
start-admin-backend:
	@echo "Setting up and starting admin backend server..."
	cd admin/backend && python3 -m venv venv || true
	cd admin/backend && source venv/bin/activate && pip install -r requirements.txt
	@echo "Starting admin backend server on http://localhost:8001"
	cd admin/backend && source venv/bin/activate && python main.py

# Admin frontend: npm install + start
start-admin-frontend:
	@echo "Setting up and starting admin frontend development server..."
	cd admin/frontend && npm install
	@echo "Starting admin frontend development server on http://localhost:3001"
	cd admin/frontend && npm start

# Collector: setup venv + install deps + run
start-collect:
	@echo "Setting up and running dual scoring collector..."
	rm -rf collect/venv
	cd collect && python3.12 -m venv venv
	cd collect && source venv/bin/activate && pip install -r requirements.txt
	@echo "📁 Creating test directories..."
	@mkdir -p test_data/{raw/{images,labels},review/{pending,metadata}}
	@echo "🚀 Running collector..."
	@echo "📊 Data will be saved to ./test_data/"
	PYTHONPATH=/Users/reed/Code/Homelab/KarlCam collect/venv/bin/python -m collect.collect_and_label

# Cloud SQL Proxy: start proxy for local development
start-sql:
	@echo "🔌 Starting Cloud SQL Proxy for local development..."
	@echo "📍 Connecting to: karlcam:us-central1:karlcam-db"
	@echo "🔗 Local port: 5432"
	@echo ""
	@echo "To use in another terminal, set these environment variables:"
	@echo "  export DATABASE_URL=\"postgresql://karlcam:<password>@localhost:5432/karlcam_v2\""
	@echo "  export BUCKET_NAME=\"karlcam-fog-data\""
	@echo ""
	@echo "Get the password with:"
	@echo "  gcloud secrets versions access latest --secret=\"karlcam-db-password\" --project=karlcam"
	@echo ""
	@echo "Press Ctrl+C to stop the proxy"
	@echo "----------------------------------------"
	cloud-sql-proxy karlcam:us-central1:karlcam-db --port 5432 --gcloud-auth

# Clean up
clean:
	@echo "Cleaning up virtual environments and node_modules..."
	rm -rf web/api/venv
	rm -rf admin/backend/venv
	rm -rf collect/venv
	rm -rf web/frontend/node_modules
	rm -rf admin/frontend/node_modules
	@echo "Cleanup complete!"