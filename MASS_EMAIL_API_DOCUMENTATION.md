# Mass Email API Documentation

## Overview
The Mass Email API allows you to manage bulk email campaigns for providers through a web UI. This system is designed to send password update reminders and system notifications to providers.

## API Endpoints

### 1. Get Statistics and Provider List
**GET** `/api/v1/admin/mass_emails`

**Headers:**
```
Authorization: Bearer YOUR_AUTH_TOKEN
Content-Type: application/json
```

**Response:**
```json
{
  "statistics": {
    "total_users_with_providers": 47,
    "users_needing_password_updates": 46,
    "recently_updated_users": 1,
    "providers_needing_updates": 46
  },
  "providers_needing_updates": [
    {
      "id": 365,
      "name": "The Autism Clinic",
      "email": "julia@theautismclinicutah.com",
      "user_email": "julia@theautismclinicutah.com",
      "created_at": "2025-08-19T14:24:00.000Z",
      "user_created_at": "2025-08-19T14:24:00.000Z"
    }
  ]
}
```

### 2. Send Password Reminder Emails
**POST** `/api/v1/admin/mass_emails/send_password_reminders`

**Headers:**
```
Authorization: Bearer YOUR_AUTH_TOKEN
Content-Type: application/json
```

**Response:**
```json
{
  "success": true,
  "message": "Password reminder emails sent",
  "statistics": {
    "total_providers": 46,
    "emails_sent": 46,
    "errors": 0
  },
  "errors": []
}
```

### 3. Send System Update Emails
**POST** `/api/v1/admin/mass_emails/send_system_updates`

**Headers:**
```
Authorization: Bearer YOUR_AUTH_TOKEN
Content-Type: application/json
```

**Response:**
```json
{
  "success": true,
  "message": "System update emails sent",
  "statistics": {
    "total_providers": 169,
    "emails_sent": 169,
    "errors": 0
  },
  "errors": []
}
```

### 4. Preview Email
**GET** `/api/v1/admin/mass_emails/preview_email?provider_id=365`

**Headers:**
```
Authorization: Bearer YOUR_AUTH_TOKEN
Content-Type: application/json
```

**Response:**
```json
{
  "success": true,
  "subject": "Important: Update Your Autism Services Locator Account - The Autism Clinic",
  "to": "julia@theautismclinicutah.com",
  "html_content": "<!DOCTYPE html>...",
  "text_content": "Password Update Required..."
}
```

## Frontend Integration

### React Component
Use the provided `MassEmailComponent.jsx` as a starting point for your UI. The component includes:

- **Statistics Dashboard**: Shows counts of users and providers
- **Action Buttons**: Send password reminders or system updates
- **Provider List**: Table showing providers needing updates
- **Email Preview**: Preview emails before sending
- **Progress Tracking**: Real-time feedback during email sending

### Key Features
- ✅ **Batch Processing**: Sends emails in batches of 10 with delays
- ✅ **Error Handling**: Continues processing even if individual emails fail
- ✅ **Progress Tracking**: Shows real-time statistics
- ✅ **Email Preview**: Preview emails before sending
- ✅ **Confirmation Dialogs**: Prevents accidental mass sends

## Usage Examples

### JavaScript/Fetch
```javascript
// Get statistics
const response = await fetch('/api/v1/admin/mass_emails', {
  headers: {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json'
  }
});
const data = await response.json();
console.log('Providers needing updates:', data.statistics.providers_needing_updates);

// Send password reminders
const sendResponse = await fetch('/api/v1/admin/mass_emails/send_password_reminders', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json'
  }
});
const result = await sendResponse.json();
console.log('Emails sent:', result.statistics.emails_sent);
```

### Axios
```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: '/api/v1/admin/mass_emails',
  headers: {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json'
  }
});

// Get statistics
const { data } = await api.get('/');
console.log(data.statistics);

// Send password reminders
const result = await api.post('/send_password_reminders');
console.log(result.data);
```

## Security Notes

- All endpoints require admin authentication
- Emails are sent synchronously to ensure delivery
- Batch processing prevents server overload
- Confirmation dialogs prevent accidental sends

## Email Content

The system sends two types of emails:

1. **Password Update Reminders**: Sent to users created before 1 week ago
2. **System Updates**: Sent to all approved providers

Both emails include:
- Professional Autism Services Locator branding
- Clear instructions for account management
- Contact information: jordanwilliamson@autismserviceslocator.com, (801) 833-0284
- Login URL: https://www.autismserviceslocator.com/login
