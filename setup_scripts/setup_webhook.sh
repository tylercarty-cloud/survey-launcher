#!/bin/bash

# Setup On-Demand Webhook Trigger
# ===============================
# This script sets up the inbound webhook for on-demand survey link generation

set -e

CONFIG_FILE="./config.env"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: config.env file not found!"
    exit 1
fi

if [ -z "$ZIS_TOKEN" ]; then
    echo "Error: ZIS_TOKEN not set. Run setup.sh first and add the token to config.env"
    exit 1
fi

INTEGRATION_NAME="surveysparrow_integration"

echo "Creating ZIS Inbound Webhook for On-Demand Survey Links..."
echo "==========================================================="

WEBHOOK_RESPONSE=$(curl -s -X POST "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/services/zis/inbound_webhooks/generic/${INTEGRATION_NAME}" \
    -H "Authorization: Bearer ${ZIS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
        "source_system": "survey_trigger",
        "event_type": "generate_link"
    }')

echo "Webhook Response:"
echo "$WEBHOOK_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$WEBHOOK_RESPONSE"
echo ""

# Extract webhook details
WEBHOOK_PATH=$(echo "$WEBHOOK_RESPONSE" | grep -o '"path":"[^"]*"' | cut -d'"' -f4 || true)
WEBHOOK_USERNAME=$(echo "$WEBHOOK_RESPONSE" | grep -o '"username":"[^"]*"' | cut -d'"' -f4 || true)
WEBHOOK_PASSWORD=$(echo "$WEBHOOK_RESPONSE" | grep -o '"password":"[^"]*"' | cut -d'"' -f4 || true)

if [ -n "$WEBHOOK_PATH" ]; then
    echo ""
    echo "Webhook Setup Complete!"
    echo "======================="
    echo ""
    echo "Webhook URL: https://${ZENDESK_SUBDOMAIN}.zendesk.com${WEBHOOK_PATH}"
    echo "Username: $WEBHOOK_USERNAME"
    echo "Password: $WEBHOOK_PASSWORD"
    echo ""
    echo "To trigger a survey link generation for a ticket, send a POST request:"
    echo ""
    echo "curl -X POST 'https://${ZENDESK_SUBDOMAIN}.zendesk.com${WEBHOOK_PATH}' \\"
    echo "  -u '\$WEBHOOK_USERNAME:\$WEBHOOK_PASSWORD' \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -d '{\"ticket_id\": 12345}'"
    echo ""
    echo "Save these credentials securely!"
fi

# Install the on-demand job spec
echo ""
echo "Installing On-Demand Job Spec..."
echo "================================="

INSTALL_RESPONSE=$(curl -s -X POST "https://${ZENDESK_SUBDOMAIN}.zendesk.com/api/services/zis/registry/job_specs/install?job_spec_name=zis:${INTEGRATION_NAME}:job_spec:GenerateSurveyLinkOnDemand" \
    -H "Authorization: Bearer ${ZIS_TOKEN}")

echo "Job Spec Install Response: $INSTALL_RESPONSE"
echo ""
echo "On-demand webhook setup complete!"
