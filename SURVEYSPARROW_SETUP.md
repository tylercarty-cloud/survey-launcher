# SurveySparrow Survey Configuration Guide

This guide explains how to configure your SurveySparrow survey to work with the Zendesk integration and track responses by customer phone number and external ID.

## Overview

When a survey link is generated from Zendesk, it will include URL parameters like:
```
https://yourcompany.surveysparrow.com/s/customer-feedback?phone=+15551234567&external_id=CUST-12345&ticket_id=98765
```

These parameters are captured by SurveySparrow and stored with the response, allowing you to match survey responses back to specific customers and tickets.

## Step 1: Create Global Variables

Global Variables in SurveySparrow allow you to pass custom data via URL parameters and track them with responses.

1. **Open your survey** in the SurveySparrow editor
2. Click on the **Variables** icon ($ symbol) in the right sidebar
3. Select the **Variables** tab
4. Click **"Add a Custom Variable"**
5. Add the following variables:

| Variable Name | Description |
|---------------|-------------|
| `phone` | Customer's phone number from Zendesk |
| `external_id` | Customer's external ID from Zendesk |
| `ticket_id` | Zendesk ticket ID for reference |

6. **Save** each variable

## Step 2: Configure Variable Tracking

To ensure variables are captured with responses:

1. Go to **Survey Settings** > **Variables**
2. Ensure "Track variables in responses" is enabled
3. Variables will now appear as columns in your Responses report

## Step 3: Using Variables in Survey Questions (Optional)

You can personalize your survey using the captured variables:

1. In any question text, click the **$** icon
2. Select your custom variable (e.g., `$phone`)
3. The variable will be replaced with the actual value when the survey is viewed

Example:
```
"Thank you for contacting us regarding ticket #{{ticket_id}}. How was your experience?"
```

## Step 4: Get Your Survey Details

### Find Survey ID

1. Go to your **Survey Dashboard**
2. Open the survey
3. The Survey ID is visible in the URL: `https://app.surveysparrow.com/surveys/{SURVEY_ID}/build`
4. Or use the API:
   ```bash
   curl "https://api.surveysparrow.com/v3/surveys" \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

### Get Survey Share URL

1. Click **Share** on your survey
2. Select **Share Link**
3. Copy the base URL (without any parameters)
4. Example: `https://yourcompany.surveysparrow.com/s/customer-feedback`

## Step 5: API Token Setup

1. Log in to SurveySparrow
2. Go to **Settings** > **Apps & Integrations** > **API**
3. Click **"Create Token"**
4. Give it a descriptive name (e.g., "Zendesk Integration")
5. Set appropriate permissions:
   - Surveys: Read
   - Channels: Read, Write (if using create_unique_links)
   - Contacts: Read, Write (if using create_unique_links)
6. **Copy and save** the token securely

## Response Tracking

### Viewing Responses with Variables

1. Go to **Survey** > **Responses**
2. Click on the columns selector
3. Add columns for `phone`, `external_id`, and `ticket_id`
4. You'll now see these values alongside each response

### Exporting Data

When exporting responses:
1. Click **Export** on the Responses page
2. Select your format (CSV, Excel, etc.)
3. The custom variables will be included as columns

### Filtering Responses

You can filter responses by variable values:
1. Click the filter icon on the Responses page
2. Add a filter for your variable (e.g., `ticket_id equals 98765`)
3. This shows all responses for a specific ticket

## Alternative: Using the Unique Links API

For more advanced tracking, you can use the SurveySparrow Channels API to create unique links that automatically associate contacts with responses.

### Step 1: Create a Web Link Channel

First, create a channel for the survey:

```bash
curl -X POST "https://api.surveysparrow.com/v3/channels" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "survey_id": YOUR_SURVEY_ID,
    "name": "Zendesk Integration Channel",
    "type": "LINK",
    "link": {
      "title": "Customer Feedback Survey",
      "description": "Post-support survey for Zendesk tickets"
    }
  }'
```

Save the `channel_id` from the response.

### Step 2: Create Unique Links

```bash
curl -X POST "https://api.surveysparrow.com/v3/channels/create_unique_links" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "survey_id": YOUR_SURVEY_ID,
    "channel_id": YOUR_CHANNEL_ID,
    "contacts": [
      {
        "phone": "+15551234567",
        "email": "customer@example.com",
        "full_name": "John Doe",
        "variables": {
          "external_id": "CUST-12345",
          "ticket_id": "98765"
        }
      }
    ],
    "short_url": true
  }'
```

This returns a unique URL for the specific contact.

## Best Practices

1. **Always URL-encode phone numbers**: Special characters in phone numbers should be encoded (+ becomes %2B)

2. **Handle missing data gracefully**: Not all Zendesk tickets will have phone numbers or external IDs

3. **Use external_id for matching**: The external_id is the most reliable way to match responses to your customer records

4. **Test thoroughly**: Before deploying, test the full flow:
   - Create a test ticket in Zendesk
   - Trigger the survey link generation
   - Click the link and complete the survey
   - Verify the variables are captured in SurveySparrow

## Troubleshooting

### Variables Not Captured

- Ensure the variable names in the URL exactly match the variable names in SurveySparrow (case-sensitive)
- Check that "Track variables" is enabled in survey settings
- Verify the URL parameters are properly formatted

### Survey Link Errors

- Verify the survey is published and active
- Check that the survey base URL is correct
- Ensure the API token has proper permissions

### API Errors

- Check the API token is valid and not expired
- Verify you're using the correct Survey ID
- Review the error message in the API response
