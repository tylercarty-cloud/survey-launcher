#!/usr/bin/env python3
"""
SurveySparrow API Test Script
=============================
This script tests the SurveySparrow API connection and survey retrieval.
"""

import requests
import json
import os
from urllib.parse import urlencode

# Configuration - update these values or use environment variables
SURVEYSPARROW_TOKEN = os.environ.get('SURVEYSPARROW_API_TOKEN', 'your_token_here')
SURVEY_ID = os.environ.get('SURVEY_ID', 'ntt-qgyGc')
SURVEY_BASE_URL = os.environ.get('SURVEY_BASE_URL', f'https://impiricusclientservices.surveysparrow.com/n/Concierge-Satifaction/{SURVEY_ID}')


def test_get_survey():
    """Test getting survey details from SurveySparrow API"""
    print("Testing SurveySparrow API - Get Survey")
    print("=" * 50)
    
    url = f"https://api.surveysparrow.com/v3/surveys/{SURVEY_ID}"
    
    headers = {
        'Accept': '*/*',
        'Authorization': f'Bearer {SURVEYSPARROW_TOKEN}'
    }
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        data = response.json()
        print(f"Survey Name: {data.get('data', {}).get('name', 'N/A')}")
        print(f"Survey Type: {data.get('data', {}).get('survey_type', 'N/A')}")
        print(f"Survey ID: {data.get('data', {}).get('id', 'N/A')}")
        print("\nFull Response:")
        print(json.dumps(data, indent=2))
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return False


def generate_survey_link(phone: str = None, external_id: str = None, ticket_id: str = None):
    """
    Generate a SurveySparrow survey link with custom parameters.
    
    This approach uses URL parameters (Global Variables) which is simpler
    than the create_unique_links API and doesn't require a channel setup.
    """
    print("\nGenerating Survey Link")
    print("=" * 50)
    
    params = {}
    
    if phone:
        params['phone'] = phone
    if external_id:
        params['external_id'] = external_id
    if ticket_id:
        params['ticket_id'] = ticket_id
    
    if params:
        survey_link = f"{SURVEY_BASE_URL}?{urlencode(params)}"
    else:
        survey_link = SURVEY_BASE_URL
    
    print(f"Generated Survey Link: {survey_link}")
    return survey_link


def test_create_unique_link(phone: str, email: str = None, full_name: str = None, 
                            external_id: str = None, channel_id: str = None):
    """
    Test creating a unique survey link using the SurveySparrow API.
    
    Note: This requires a channel to be set up first in SurveySparrow.
    The channel_id is required for this endpoint.
    """
    print("\nTesting SurveySparrow API - Create Unique Link")
    print("=" * 50)
    
    if not channel_id:
        print("Warning: channel_id is required for this endpoint")
        print("You need to create a LINK type channel in SurveySparrow first")
        return None
    
    url = "https://api.surveysparrow.com/v3/channels/create_unique_links"
    
    headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {SURVEYSPARROW_TOKEN}'
    }
    
    contact = {
        "phone": phone
    }
    
    if email:
        contact["email"] = email
    if full_name:
        contact["full_name"] = full_name
    
    variables = {}
    if external_id:
        variables["external_id"] = external_id
    
    if variables:
        contact["variables"] = variables
    
    payload = {
        "survey_id": int(SURVEY_ID),
        "channel_id": int(channel_id),
        "contacts": [contact],
        "short_url": True
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        
        data = response.json()
        print("\nResponse:")
        print(json.dumps(data, indent=2))
        
        # Extract the survey link
        if 'data' in data and len(data['data']) > 0:
            survey_link = data['data'][0].get('survey_link') or data['data'][0].get('short_url')
            print(f"\nSurvey Link: {survey_link}")
            return survey_link
        
        return None
        
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        return None


def list_channels():
    """List all channels for the survey to find the channel_id"""
    print("\nListing Survey Channels")
    print("=" * 50)
    
    url = f"https://api.surveysparrow.com/v3/channels?survey_id={SURVEY_ID}"
    
    headers = {
        'Accept': 'application/json',
        'Authorization': f'Bearer {SURVEYSPARROW_TOKEN}'
    }
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        data = response.json()
        print("\nAvailable Channels:")
        
        channels = data.get('data', [])
        for channel in channels:
            print(f"  - ID: {channel.get('id')}, Name: {channel.get('name')}, Type: {channel.get('type')}")
        
        print(f"\nFull Response:")
        print(json.dumps(data, indent=2))
        
        return channels
        
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return []


if __name__ == "__main__":
    print("SurveySparrow API Test")
    print("=" * 50)
    print(f"Survey ID: {SURVEY_ID}")
    print(f"Base URL: {SURVEY_BASE_URL}")
    print("")
    
    # Test 1: Get survey details
    test_get_survey()
    
    # Test 2: List channels
    channels = list_channels()
    
    # Test 3: Generate a simple survey link with parameters
    sample_link = generate_survey_link(
        phone="+15551234567",
        external_id="CUST-12345",
        ticket_id="98765"
    )
    
    print("\n" + "=" * 50)
    print("Tests Complete!")
    print("=" * 50)
    print(f"\nSample Survey Link for testing:")
    print(sample_link)
