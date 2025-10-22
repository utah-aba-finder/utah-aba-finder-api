import React, { useState, useEffect } from 'react';

const MassEmailComponent = () => {
  const [statistics, setStatistics] = useState(null);
  const [providers, setProviders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [results, setResults] = useState(null);

  // Fetch statistics and provider list
  const fetchData = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/admin/mass_emails', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      const data = await response.json();
      setStatistics(data.statistics);
      setProviders(data.providers_needing_updates);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Send password reminder emails
  const sendPasswordReminders = async () => {
    if (!window.confirm(`Send password reminder emails to ${statistics?.providers_needing_updates || 0} providers?`)) {
      return;
    }

    setSending(true);
    try {
      const response = await fetch('/api/v1/admin/mass_emails/send_password_reminders', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      const data = await response.json();
      setResults(data);
      if (data.success) {
        // Refresh data after sending
        fetchData();
      }
    } catch (error) {
      console.error('Error sending emails:', error);
      setResults({ success: false, error: error.message });
    } finally {
      setSending(false);
    }
  };

  // Send system update emails
  const sendSystemUpdates = async () => {
    if (!window.confirm('Send system update emails to all providers?')) {
      return;
    }

    setSending(true);
    try {
      const response = await fetch('/api/v1/admin/mass_emails/send_system_updates', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      const data = await response.json();
      setResults(data);
    } catch (error) {
      console.error('Error sending emails:', error);
      setResults({ success: false, error: error.message });
    } finally {
      setSending(false);
    }
  };

  // Preview email for a specific provider
  const previewEmail = async (providerId) => {
    try {
      const response = await fetch(`/api/v1/admin/mass_emails/preview_email?provider_id=${providerId}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      const data = await response.json();
      if (data.success) {
        // Open email preview in new window
        const previewWindow = window.open('', '_blank');
        previewWindow.document.write(`
          <html>
            <head><title>Email Preview</title></head>
            <body>
              <h2>Subject: ${data.subject}</h2>
              <h3>To: ${data.to}</h3>
              <hr>
              ${data.html_content}
            </body>
          </html>
        `);
      }
    } catch (error) {
      console.error('Error previewing email:', error);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  if (loading) {
    return <div className="loading">Loading mass email data...</div>;
  }

  return (
    <div className="mass-email-component">
      <h2>Mass Email Management</h2>
      
      {/* Statistics */}
      {statistics && (
        <div className="statistics">
          <h3>Statistics</h3>
          <div className="stats-grid">
            <div className="stat-card">
              <h4>Total Users with Providers</h4>
              <p>{statistics.total_users_with_providers}</p>
            </div>
            <div className="stat-card">
              <h4>Need Password Updates</h4>
              <p>{statistics.users_needing_password_updates}</p>
            </div>
            <div className="stat-card">
              <h4>Recently Updated</h4>
              <p>{statistics.recently_updated_users}</p>
            </div>
            <div className="stat-card">
              <h4>Providers Needing Updates</h4>
              <p>{statistics.providers_needing_updates}</p>
            </div>
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="actions">
        <button 
          onClick={sendPasswordReminders}
          disabled={sending || !statistics?.providers_needing_updates}
          className="btn btn-primary"
        >
          {sending ? 'Sending...' : `Send Password Reminders (${statistics?.providers_needing_updates || 0})`}
        </button>
        
        <button 
          onClick={sendSystemUpdates}
          disabled={sending}
          className="btn btn-secondary"
        >
          {sending ? 'Sending...' : 'Send System Updates to All'}
        </button>
        
        <button 
          onClick={fetchData}
          disabled={loading}
          className="btn btn-outline"
        >
          Refresh Data
        </button>
      </div>

      {/* Results */}
      {results && (
        <div className={`results ${results.success ? 'success' : 'error'}`}>
          <h3>{results.success ? 'Success!' : 'Error'}</h3>
          <p>{results.message}</p>
          {results.statistics && (
            <div className="result-stats">
              <p>Emails sent: {results.statistics.emails_sent}</p>
              <p>Errors: {results.statistics.errors}</p>
            </div>
          )}
          {results.errors && results.errors.length > 0 && (
            <div className="error-list">
              <h4>Errors:</h4>
              <ul>
                {results.errors.map((error, index) => (
                  <li key={index}>{error}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}

      {/* Provider List */}
      <div className="provider-list">
        <h3>Providers Needing Password Updates</h3>
        <div className="table-container">
          <table>
            <thead>
              <tr>
                <th>Provider Name</th>
                <th>Provider Email</th>
                <th>User Email</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {providers.map((provider) => (
                <tr key={provider.id}>
                  <td>{provider.name}</td>
                  <td>{provider.email}</td>
                  <td>{provider.user_email}</td>
                  <td>{new Date(provider.created_at).toLocaleDateString()}</td>
                  <td>
                    <button 
                      onClick={() => previewEmail(provider.id)}
                      className="btn btn-sm btn-outline"
                    >
                      Preview Email
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <style jsx>{`
        .mass-email-component {
          padding: 20px;
          max-width: 1200px;
          margin: 0 auto;
        }
        
        .statistics {
          margin: 20px 0;
        }
        
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 15px;
          margin: 15px 0;
        }
        
        .stat-card {
          background: #f8f9fa;
          padding: 15px;
          border-radius: 8px;
          border-left: 4px solid #007bff;
        }
        
        .stat-card h4 {
          margin: 0 0 10px 0;
          color: #495057;
        }
        
        .stat-card p {
          margin: 0;
          font-size: 24px;
          font-weight: bold;
          color: #007bff;
        }
        
        .actions {
          margin: 20px 0;
          display: flex;
          gap: 10px;
          flex-wrap: wrap;
        }
        
        .btn {
          padding: 10px 20px;
          border: none;
          border-radius: 5px;
          cursor: pointer;
          font-size: 14px;
        }
        
        .btn:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
        
        .btn-primary {
          background: #007bff;
          color: white;
        }
        
        .btn-secondary {
          background: #6c757d;
          color: white;
        }
        
        .btn-outline {
          background: transparent;
          border: 1px solid #007bff;
          color: #007bff;
        }
        
        .btn-sm {
          padding: 5px 10px;
          font-size: 12px;
        }
        
        .results {
          margin: 20px 0;
          padding: 15px;
          border-radius: 5px;
        }
        
        .results.success {
          background: #d4edda;
          border: 1px solid #c3e6cb;
          color: #155724;
        }
        
        .results.error {
          background: #f8d7da;
          border: 1px solid #f5c6cb;
          color: #721c24;
        }
        
        .provider-list {
          margin: 20px 0;
        }
        
        .table-container {
          overflow-x: auto;
        }
        
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 15px 0;
        }
        
        th, td {
          padding: 12px;
          text-align: left;
          border-bottom: 1px solid #dee2e6;
        }
        
        th {
          background: #f8f9fa;
          font-weight: 600;
        }
        
        .loading {
          text-align: center;
          padding: 40px;
          font-size: 18px;
        }
      `}</style>
    </div>
  );
};

export default MassEmailComponent;
