# SurveySparrow Survey Link - Zendesk App

This Zendesk sidebar app allows agents to generate personalized SurveySparrow survey links on demand.

## Features

- Displays customer phone number and external ID from the ticket
- Generates a personalized survey link with these parameters
- **Insert into Reply**: Adds the link directly to the agent's reply composer
- **Copy to Clipboard**: Copies the link for use elsewhere

## Installation

### Option 1: Upload via Zendesk Admin Center (Recommended)

1. **Package the app**:
   ```bash
   cd /Users/tylercarty/Survey_sparrow_automation/zendesk_app
   zip -r surveysparrow_app.zip manifest.json assets translations
   ```

2. **Upload to Zendesk**:
   - Go to Zendesk Admin Center
   - Navigate to **Apps and integrations** > **Apps** > **Zendesk Support apps**
   - Click **Upload private app**
   - Select the `surveysparrow_app.zip` file
   - Fill in the **Survey Base URL** setting with your survey URL
   - Click **Install**

### Option 2: Using ZCLI (Zendesk CLI)

1. Install ZCLI:
   ```bash
   npm install -g @zendesk/zcli
   ```

2. Login to Zendesk:
   ```bash
   zcli login -i
   ```

3. Validate the app:
   ```bash
   cd /Users/tylercarty/Survey_sparrow_automation/zendesk_app
   zcli apps:validate
   ```

4. Create and upload:
   ```bash
   zcli apps:create
   ```

## Configuration

After installation, configure the app:

1. Go to **Apps and integrations** > **Apps** > **Zendesk Support apps**
2. Find "SurveySparrow Survey Link" and click the gear icon
3. Set the **Survey Base URL** to your SurveySparrow survey share link
   - Example: `https://impiricusclientservices.surveysparrow.com/survey/1000461299`

## Usage

1. Open any ticket in Zendesk Support
2. Look for the "SurveySparrow Survey Link" app in the right sidebar
3. The app will display:
   - Customer's phone number
   - Customer's external ID
   - Ticket ID
   - Generated survey link
4. Click **Insert into Reply** to add the link to your message
5. Or click **Copy to Clipboard** to copy the link

## Survey Link Format

The generated link includes these parameters:
```
{survey_base_url}?phone={customer_phone}&external_id={customer_external_id}&ticket_id={zendesk_ticket_id}
```

## Disable the ZIS Auto-Post Integration

If you previously set up the ZIS integration that auto-posts survey links, you should disable it:

```bash
curl -X DELETE "https://impiricussupport.zendesk.com/api/services/zis/registry/job_specs/install?job_spec_name=zis:surveysparrow_integration:job_spec:GenerateSurveyLinkOnSolved" \
  -H "Authorization: Bearer {your_zis_token}"
```

## Troubleshooting

**App not showing in sidebar:**
- Make sure the app is installed and enabled
- Refresh the ticket page

**Phone/External ID showing "(not set)":**
- The customer's profile doesn't have these fields populated
- The link will still work, just without those parameters

**Insert into Reply not working:**
- Make sure you have the reply composer open
- Try using Copy to Clipboard instead
