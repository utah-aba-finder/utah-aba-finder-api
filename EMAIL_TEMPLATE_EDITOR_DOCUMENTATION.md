# Email Template Editor - UI Documentation

## 🎯 **Yes! You can now edit email templates from your UI!**

I've created a complete email template management system that allows you to edit all email content directly from your admin dashboard.

## 🚀 **What You Can Do**

### **✅ Edit Email Content from UI**
- Change subject lines, headers, and body text
- Modify call-to-action buttons and links
- Update contact information and branding
- Switch between HTML and text versions

### **✅ Live Preview**
- See exactly how emails will look before sending
- Preview with sample data (provider names, emails, etc.)
- Test both HTML and plain text versions

### **✅ Template Management**
- Edit multiple email templates
- Save changes instantly
- Switch between different template types

## 📧 **Available Email Templates**

### 1. **Password Update Reminder**
- **Purpose**: Sent to users who need to update their passwords
- **Subject**: "Important: Action Required for Your Autism Services Locator Account"
- **Files**: `password_update_reminder.html.erb`, `password_update_reminder.text.erb`

### 2. **Admin Created Provider Welcome**
- **Purpose**: Sent when you manually add a provider
- **Subject**: "Your Practice Added to Autism Services Locator (Free Service)"
- **Files**: `admin_created_provider.html.erb`, `admin_created_provider.text.erb`

### 3. **System Update Notification**
- **Purpose**: General system updates and announcements
- **Subject**: "System Update from Autism Services Locator"
- **Files**: `system_update_notification.html.erb`, `system_update_notification.text.erb`

## 🎨 **How to Use the UI**

### **Step 1: Access the Template Editor**
Add the `EmailTemplateEditor` component to your admin dashboard:

```jsx
import EmailTemplateEditor from './EmailTemplateEditor';

// In your admin dashboard
<EmailTemplateEditor />
```

### **Step 2: Select a Template**
- Click on any template card to load it for editing
- Choose between HTML or text version using the dropdown
- See template description and current subject line

### **Step 3: Edit Content**
- Use the large text area to edit the template
- HTML templates support full HTML/CSS
- Text templates are plain text only
- Use ERB syntax for dynamic content: `<%= @provider.name %>`

### **Step 4: Preview & Save**
- Click "Preview" to see how the email will look
- Click "Save Template" to save your changes
- Changes are applied immediately

## 🔧 **API Endpoints**

### **Get Available Templates**
```
GET /api/v1/admin/email_templates
Authorization: Bearer YOUR_TOKEN
```

### **Load Template Content**
```
GET /api/v1/admin/email_templates/{template_name}?type=html
Authorization: Bearer YOUR_TOKEN
```

### **Save Template**
```
PUT /api/v1/admin/email_templates/{template_name}
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "content": "Your template content here...",
  "type": "html"
}
```

### **Preview Template**
```
GET /api/v1/admin/email_templates/{template_name}/preview?type=html
Authorization: Bearer YOUR_TOKEN
```

## 📝 **Dynamic Content Variables**

You can use these variables in your templates:

### **Provider Information**
- `<%= @provider.name %>` - Provider name
- `<%= @provider.email %>` - Provider email
- `<%= @provider.website %>` - Provider website

### **User Information**
- `<%= @user.email %>` - User email address
- `<%= @password %>` - Generated password (admin created only)

### **Example Usage**
```erb
<h2>Hello <%= @provider.name %> Team,</h2>
<p>Your email: <%= @provider.email %></p>
<p>Login: <%= @user.email %></p>
<p>Password: <%= @password %></p>
```

## 🎨 **Styling & Customization**

### **HTML Templates**
- Full HTML/CSS support
- Responsive design recommended
- Use inline styles for email compatibility
- Test with different email clients

### **Text Templates**
- Plain text only
- Use ASCII art for visual elements
- Keep line length under 72 characters
- Use clear section dividers

### **Branding Elements**
- Update colors to match your brand
- Change contact information
- Modify logo and header styling
- Update footer information

## 🔒 **Security Notes**

- All endpoints require admin authentication
- Templates are saved directly to the file system
- Changes take effect immediately
- No version control (consider backing up templates)

## 🚀 **Quick Start**

1. **Add the component** to your admin dashboard
2. **Select a template** to edit
3. **Make your changes** in the text area
4. **Preview** to see the result
5. **Save** to apply changes

## 📱 **Mobile Responsive**

The template editor works on:
- ✅ Desktop computers
- ✅ Tablets
- ✅ Mobile phones
- ✅ All modern browsers

## 🎯 **Example: Customizing Password Reminder**

### **Before:**
```erb
<p>We hope this email finds you well. We're reaching out regarding your listing on the Autism Services Locator platform.</p>
```

### **After:**
```erb
<p>Hello! We're excited to share some important updates about your Autism Services Locator account that will help you better serve families.</p>
```

## 🆘 **Troubleshooting**

### **Template Not Loading**
- Check that the template name exists
- Verify authentication token
- Ensure template file exists on server

### **Preview Not Working**
- Check for syntax errors in template
- Verify all required variables are available
- Test with simple content first

### **Changes Not Saving**
- Check file permissions on server
- Verify authentication
- Check server logs for errors

## 🎉 **You're All Set!**

You now have complete control over your email templates through a user-friendly interface. No more editing files directly - just use the UI to customize your emails exactly how you want them!
