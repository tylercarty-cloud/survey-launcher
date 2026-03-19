(function() {
  var client = ZAFClient.init();
  
  client.invoke('resize', { width: '100%', height: '320px' });

  var surveyBaseUrl = '';
  var surveyLink = '';

  // Get app settings and ticket data
  Promise.all([
    client.metadata(),
    client.get(['ticket.id', 'ticket.requester'])
  ]).then(function(results) {
    var metadata = results[0];
    var data = results[1];
    
    surveyBaseUrl = metadata.settings.surveyBaseUrl || 'https://impiricusclientservices.surveysparrow.com/survey/1000461299';
    
    var ticketId = data['ticket.id'];
    var requester = data['ticket.requester'];
    
    // Now get the requester's full details
    return client.request({
      url: '/api/v2/users/' + requester.id + '.json',
      type: 'GET'
    }).then(function(response) {
      return {
        ticketId: ticketId,
        requester: requester,
        userDetails: response.user
      };
    });
  }).then(function(data) {
    var ticketId = data.ticketId;
    var user = data.userDetails;
    
    var phone = user.phone || '';
    var externalId = user.external_id || '';
    
    // Build survey link
    var params = [];
    if (phone) params.push('phone=' + encodeURIComponent(phone));
    if (externalId) params.push('external_id=' + encodeURIComponent(externalId));
    params.push('ticket_id=' + encodeURIComponent(ticketId));
    
    surveyLink = surveyBaseUrl + '?' + params.join('&');
    
    // Update UI
    document.getElementById('phone').textContent = phone || '(not set)';
    document.getElementById('externalId').textContent = externalId || '(not set)';
    document.getElementById('ticketId').textContent = ticketId;
    document.getElementById('surveyLink').textContent = surveyLink;
    
    // Show content, hide loading
    document.getElementById('loading').style.display = 'none';
    document.getElementById('content').style.display = 'block';
    
  }).catch(function(error) {
    console.error('Error loading data:', error);
    document.getElementById('loading').textContent = 'Error loading ticket data. Please refresh.';
  });

  // Insert into reply composer
  document.getElementById('insertBtn').addEventListener('click', function() {
    if (!surveyLink) return;
    
    var message = "Here is your survey link:\n\n" + surveyLink + "\n\nWe appreciate your feedback!";
    
    client.invoke('ticket.editor.insert', message).then(function() {
      showStatus('Survey link inserted into reply!', 'success');
    }).catch(function(error) {
      console.error('Error inserting:', error);
      showStatus('Error inserting link. Try copying instead.', 'error');
    });
  });

  // Copy to clipboard
  document.getElementById('copyBtn').addEventListener('click', function() {
    if (!surveyLink) return;
    
    navigator.clipboard.writeText(surveyLink).then(function() {
      showStatus('Link copied to clipboard!', 'success');
    }).catch(function() {
      // Fallback for older browsers
      var textarea = document.createElement('textarea');
      textarea.value = surveyLink;
      document.body.appendChild(textarea);
      textarea.select();
      try {
        document.execCommand('copy');
        showStatus('Link copied to clipboard!', 'success');
      } catch (err) {
        showStatus('Failed to copy. Please copy manually.', 'error');
      }
      document.body.removeChild(textarea);
    });
  });

  function showStatus(message, type) {
    var statusEl = document.getElementById('status');
    statusEl.textContent = message;
    statusEl.className = 'status status-' + type;
    statusEl.style.display = 'block';
    
    setTimeout(function() {
      statusEl.style.display = 'none';
    }, 3000);
  }
})();
