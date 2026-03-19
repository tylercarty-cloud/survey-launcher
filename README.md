# Zendesk-SurveySparrow Integration (ZIS)

This integration automatically generates SurveySparrow survey links with Zendesk ticket data (phone number, external ID) and adds them to tickets for agents to send to customers.

## Overview

The integration uses Zendesk Integration Services (ZIS) to:
1. Listen for ticket events (solved tickets or manual trigger)
2. Extract customer phone number and external ID from the ticket
3. Generate a personalized SurveySparrow survey link
4. Add the link as an internal note on the ticket for the agent to copy/send

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────────┐
│   Zendesk       │────▶│   ZIS Flow      │────▶│   SurveySparrow     │
│   Ticket Event  │     │                 │     │   Survey Link       │
└─────────────────┘     └─────────────────┘     └─────────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │  Update Ticket  │
                        │  (Internal Note)│
                        └─────────────────┘
```

## Prerequisites

1. **Zendesk Account** - Suite Growth plan or above, or Support Professional plan or above
2. **SurveySparrow Account** with API access
3. **SurveySparrow API Token** - Generate from SurveySparrow Settings > Apps & Integrations > API
4. **Survey Setup** - Create your survey in SurveySparrow with custom variables for `phone` and `external_id`

## Setup Instructions

### Step 1: Configure SurveySparrow Survey

1. Create or edit your survey in SurveySparrow
2. Go to survey settings and add **Global Variables**:
   - Variable name: `phone`
   - Variable name: `external_id`
3. Note your **Survey ID** (visible in the survey URL or API)
4. Note your **Survey Share URL** (e.g., `https://yourcompany.surveysparrow.com/s/your-survey`)

### Step 2: Register ZIS Integration

```bash
# Replace {subdomain} with your Zendesk subdomain
# Replace {email} and {api_token} with your Zendesk credentials

curl -X POST "https://{subdomain}.zendesk.com/api/services/zis/registry/surveysparrow_integration" \
  -H "Content-Type: application/json" \
  -u {email}/token:{api_token} \
  -d '{"description": "SurveySparrow Survey Link Integration"}'
```

**Save the response** - it contains your OAuth client details and JWT public key.

### Step 3: Get ZIS OAuth Token

```bash
# First, get the OAuth client ID
curl "https://{subdomain}.zendesk.com/api/v2/oauth/clients.json" \
  -u {email}/token:{api_token}

# Find the client with identifier "zis_surveysparrow_integration" and note the ID

# Create OAuth token
curl -X POST "https://{subdomain}.zendesk.com/api/v2/oauth/tokens.json" \
  -H "Content-Type: application/json" \
  -u {email}/token:{api_token} \
  -d '{
    "token": {
      "client_id": "{oauth_client_id}",
      "scopes": ["read", "write"]
    }
  }'
```

**Save the `full_token` from the response.**

### Step 4: Create Zendesk OAuth Connection

```bash
# Create OAuth connection for Zendesk API calls
# Follow the OAuth flow at:
# https://developer.zendesk.com/documentation/integration-services/developer-guide/creating-managing-oauth-connections/#creating-an-oauth-connection-for-zendesk
```

### Step 5: Create SurveySparrow Bearer Token Connection

```bash
curl -X POST "https://{subdomain}.zendesk.com/api/services/zis/integrations/surveysparrow_integration/connections/bearer_token" \
  -H "Authorization: Bearer {zis_oauth_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "surveysparrow",
    "token": "{your_surveysparrow_api_token}",
    "allowed_domain": "api.surveysparrow.com"
  }'
```

### Step 6: Upload ZIS Bundle

```bash
curl -X POST "https://{subdomain}.zendesk.com/api/services/zis/registry/surveysparrow_integration/bundles" \
  -H "Content-Type: application/json" \
  -u {email}/token:{api_token} \
  -d @zis_bundle.json
```

### Step 7: Install Job Spec

```bash
# For automatic trigger on ticket solved:
curl -X POST "https://{subdomain}.zendesk.com/api/services/zis/registry/job_specs/install?job_spec_name=zis:surveysparrow_integration:job_spec:GenerateSurveyLinkOnSolved" \
  -H "Authorization: Bearer {zis_oauth_token}"
```

### Step 8: Create ZIS Config for Survey Settings

```bash
curl -X PUT "https://{subdomain}.zendesk.com/api/services/zis/registry/surveysparrow_integration/configs" \
  -H "Authorization: Bearer {zis_oauth_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "config": {
      "survey_base_url": "https://yourcompany.surveysparrow.com/s/your-survey",
      "survey_id": "1000461299"
    }
  }'
```

## Files

- `zis_bundle.json` - Main ZIS bundle with actions, flows, and job specs
- `setup_scripts/` - Helper scripts for setup
- `README.md` - This file

## Configuration

### Survey Link Format

The generated survey link follows this format:
```
{survey_base_url}?phone={ticket_phone}&external_id={ticket_external_id}&ticket_id={zendesk_ticket_id}
```

Example:
```
https://yourcompany.surveysparrow.com/s/customer-feedback?phone=+15551234567&external_id=CUST-12345&ticket_id=98765
```

### Ticket Fields Used

| Zendesk Field | SurveySparrow Variable | Description |
|---------------|------------------------|-------------|
| Requester Phone | `phone` | Customer's phone number |
| External ID | `external_id` | Your system's customer ID |
| Ticket ID | `ticket_id` | Zendesk ticket ID for reference |

## Trigger Options

### Option 1: Automatic on Ticket Solved (Default)

The integration automatically generates a survey link when a ticket status changes to "solved".

### Option 2: Manual Trigger via Inbound Webhook

For on-demand survey link generation, set up an inbound webhook and call it from a Zendesk app or macro.

See `zis_bundle_with_webhook.json` for this configuration.

## Troubleshooting

### View Integration Logs

1. Go to Zendesk Admin Center
2. Navigate to Apps and integrations > Integrations > Logs
3. Filter by "surveysparrow_integration"

### Common Issues

1. **Survey link not appearing**: Check that the ticket has a phone number or external ID
2. **Authentication errors**: Verify your SurveySparrow API token is valid
3. **Connection errors**: Ensure the bearer token connection is correctly configured

## Uninstalling

```bash
# Uninstall job spec
curl -X DELETE "https://{subdomain}.zendesk.com/api/services/zis/registry/job_specs/install?job_spec_name=zis:surveysparrow_integration:job_spec:GenerateSurveyLinkOnSolved" \
  -H "Authorization: Bearer {zis_oauth_token}"
```

## Support

For issues with:
- **ZIS Integration**: Refer to [Zendesk ZIS Documentation](https://developer.zendesk.com/documentation/integration-services/)
- **SurveySparrow API**: Refer to [SurveySparrow API Documentation](https://developers.surveysparrow.com/)
