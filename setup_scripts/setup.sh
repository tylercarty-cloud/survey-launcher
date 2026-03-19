#!/bin/bash

# SurveySparrow-Zendesk ZIS Integration Setup Script
# ==================================================
# This script helps you set up the ZIS integration step by step.

set -e

echo "=================================================="
echo "  SurveySparrow-Zendesk ZIS Integration Setup"
echo "=================================================="
echo ""

# Configuration - Edit these values before running
CONFIG_FILE="./config.env"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: config.env file not found!"
    echo "Please copy config.env.example to config.env and fill in your values."
    exit 1
fi

# Validate required variables
required_vars=("ZENDESK_SUBDOMAIN" "ZENDESK_EMAIL" "ZENDESK_API_TOKEN" "SURVEYSPARROW_API_TOKEN" "SURVEY_BASE_URL" "SURVEY_ID")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in config.env"
        exit 1
    fi
done

INTEGRATION_NAME="surveysparrow_integration"

echo "Step 1: Registering ZIS Integration..."
echo "======================================="

REGISTER_RESPONSE=$(curl -s -X POST "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/services/zis/registry/${INTEGRATION_NAME}" \
    -H "Content-Type: application/json" \
    -u "${ZENDESK_EMAIL}/token:${ZENDESK_API_TOKEN}" \
    -d '{"description": "SurveySparrow Survey Link Integration"}')

echo "Response: $REGISTER_RESPONSE"
echo ""

# Extract JWT public key if present (for verification purposes)
JWT_KEY=$(echo "$REGISTER_RESPONSE" | grep -o '"jwt_public_key":"[^"]*"' | cut -d'"' -f4 || true)
if [ -n "$JWT_KEY" ]; then
    echo "JWT Public Key saved (for request verification)"
fi

echo "Step 2: Getting OAuth Client ID..."
echo "==================================="

CLIENTS_RESPONSE=$(curl -s "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/v2/oauth/clients.json" \
    -u "${ZENDESK_EMAIL}/token:${ZENDESK_API_TOKEN}")

# Use Python to reliably parse JSON and extract the client ID
OAUTH_CLIENT_ID=$(echo "$CLIENTS_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for client in data.get('clients', []):
    if client.get('identifier') == 'zis_surveysparrow_integration':
        print(client.get('id'))
        break
" 2>/dev/null || true)

if [ -z "$OAUTH_CLIENT_ID" ]; then
    echo "Error: Could not find OAuth client ID for the integration"
    echo "Response: $CLIENTS_RESPONSE"
    exit 1
fi

echo "OAuth Client ID: $OAUTH_CLIENT_ID"
echo ""

echo "Step 3: Creating ZIS OAuth Token..."
echo "===================================="

TOKEN_RESPONSE=$(curl -s -X POST "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/v2/oauth/tokens.json" \
    -H "Content-Type: application/json" \
    -u "${ZENDESK_EMAIL}/token:${ZENDESK_API_TOKEN}" \
    -d '{
        "token": {
            "client_id": "'"${OAUTH_CLIENT_ID}"'",
            "scopes": ["read", "write"]
        }
    }')

ZIS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"full_token":"[^"]*"' | cut -d'"' -f4 || true)

if [ -z "$ZIS_TOKEN" ]; then
    echo "Error: Could not create ZIS OAuth token"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
fi

echo "ZIS OAuth Token created successfully!"
echo ""

echo "Step 4a: Creating SurveySparrow Bearer Token Connection..."
echo "==========================================================="

SS_CONNECTION_RESPONSE=$(curl -s -X POST "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/services/zis/integrations/${INTEGRATION_NAME}/connections/bearer_token" \
    -H "Authorization: Bearer ${ZIS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "surveysparrow",
        "token": "'"${SURVEYSPARROW_API_TOKEN}"'",
        "allowed_domain": "api.surveysparrow.com"
    }')

echo "SurveySparrow Connection Response: $SS_CONNECTION_RESPONSE"
echo ""

echo "Step 4b: Creating Zendesk Basic Auth Connection..."
echo "==================================================="

ZD_CONNECTION_RESPONSE=$(curl -s -X POST "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/services/zis/integrations/${INTEGRATION_NAME}/connections/basic_auth" \
    -H "Authorization: Bearer ${ZIS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "zendesk",
        "username": "'"${ZENDESK_EMAIL}/token"'",
        "password": "'"${ZENDESK_API_TOKEN}"'",
        "allowed_domain": "'"${ZENDESK_SUBDOMAIN}.zendesk.com"'"
    }')

echo "Zendesk Connection Response: $ZD_CONNECTION_RESPONSE"
echo ""

echo "Step 5: Uploading ZIS Bundle..."
echo "================================"

# Determine which bundle to use
BUNDLE_FILE="${BUNDLE_FILE:-../zis_bundle.json}"

# Create a temporary bundle with the survey URL replaced
TEMP_BUNDLE="/tmp/zis_bundle_temp.json"
sed "s|SURVEY_BASE_URL_PLACEHOLDER|${SURVEY_BASE_URL}|g" "${BUNDLE_FILE}" > "${TEMP_BUNDLE}"

echo "Using survey URL: ${SURVEY_BASE_URL}"

UPLOAD_RESPONSE=$(curl -s -X POST "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/services/zis/registry/${INTEGRATION_NAME}/bundles" \
    -H "Content-Type: application/json" \
    -u "${ZENDESK_EMAIL}/token:${ZENDESK_API_TOKEN}" \
    -d @"${TEMP_BUNDLE}")

# Clean up temp file
rm -f "${TEMP_BUNDLE}"

echo "Bundle Upload Response: $UPLOAD_RESPONSE"
echo ""

echo "Step 6: Installing Job Spec..."
echo "=============================="

INSTALL_RESPONSE=$(curl -s -X POST "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/services/zis/registry/job_specs/install?job_spec_name=zis:${INTEGRATION_NAME}:job_spec:GenerateSurveyLinkOnSolved" \
    -H "Authorization: Bearer ${ZIS_TOKEN}")

echo "Job Spec Install Response: $INSTALL_RESPONSE"
echo ""

echo "=================================================="
echo "  Setup Complete!"
echo "=================================================="
echo ""
echo "Your ZIS integration is now active."
echo "Survey links will be automatically generated when tickets are marked as 'solved'."
echo ""
echo "Important: Save the following token for future API calls:"
echo "ZIS_TOKEN=${ZIS_TOKEN}"
echo ""
echo "To view integration logs:"
echo "1. Go to Zendesk Admin Center"
echo "2. Navigate to Apps and integrations > Integrations > Logs"
echo ""
