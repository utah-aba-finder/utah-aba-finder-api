import React, { useState, useEffect } from 'react';

const EmailTemplateEditor = () => {
  const [templates, setTemplates] = useState({});
  const [selectedTemplate, setSelectedTemplate] = useState(null);
  const [templateContent, setTemplateContent] = useState('');
  const [templateType, setTemplateType] = useState('html');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [preview, setPreview] = useState(null);
  const [message, setMessage] = useState('');

  // Fetch available templates
  const fetchTemplates = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/admin/email_templates', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      const data = await response.json();
      setTemplates(data.templates);
    } catch (error) {
      console.error('Error fetching templates:', error);
      setMessage('Error loading templates');
    } finally {
      setLoading(false);
    }
  };

  // Load template content
  const loadTemplate = async (templateName) => {
    setLoading(true);
    try {
      const response = await fetch(`/api/v1/admin/email_templates/${templateName}?type=${templateType}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      const data = await response.json();
      if (data.content) {
        setTemplateContent(data.content);
        setSelectedTemplate(templateName);
      } else {
        setMessage('Template not found');
      }
    } catch (error) {
      console.error('Error loading template:', error);
      setMessage('Error loading template');
    } finally {
      setLoading(false);
    }
  };

  // Save template
  const saveTemplate = async () => {
    if (!selectedTemplate) return;
    
    setSaving(true);
    try {
      const response = await fetch(`/api/v1/admin/email_templates/${selectedTemplate}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          content: templateContent,
          type: templateType
        })
      });
      const data = await response.json();
      if (data.success) {
        setMessage('Template saved successfully!');
        setTimeout(() => setMessage(''), 3000);
      } else {
        setMessage(`Error: ${data.error}`);
      }
    } catch (error) {
      console.error('Error saving template:', error);
      setMessage('Error saving template');
    } finally {
      setSaving(false);
    }
  };

  // Preview template
  const previewTemplate = async () => {
    if (!selectedTemplate) return;
    
    try {
      const response = await fetch(`/api/v1/admin/email_templates/${selectedTemplate}/preview?type=${templateType}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      const data = await response.json();
      if (data.success) {
        setPreview(data);
      } else {
        setMessage(`Preview error: ${data.error}`);
      }
    } catch (error) {
      console.error('Error previewing template:', error);
      setMessage('Error previewing template');
    }
  };

  useEffect(() => {
    fetchTemplates();
  }, []);

  const templateOptions = Object.entries(templates).map(([key, template]) => ({
    key,
    ...template
  }));

  return (
    <div className="email-template-editor">
      <h2>Email Template Editor</h2>
      
      {message && (
        <div className={`message ${message.includes('Error') ? 'error' : 'success'}`}>
          {message}
        </div>
      )}

      <div className="template-selector">
        <h3>Select Template</h3>
        <div className="template-list">
          {templateOptions.map((template) => (
            <div 
              key={template.key}
              className={`template-card ${selectedTemplate === template.key ? 'selected' : ''}`}
              onClick={() => loadTemplate(template.key)}
            >
              <h4>{template.name}</h4>
              <p>{template.description}</p>
              <small>Subject: {template.subject}</small>
            </div>
          ))}
        </div>
      </div>

      {selectedTemplate && (
        <div className="template-editor">
          <div className="editor-header">
            <h3>Edit Template: {templates[selectedTemplate]?.name}</h3>
            <div className="editor-controls">
              <select 
                value={templateType} 
                onChange={(e) => setTemplateType(e.target.value)}
                className="template-type-selector"
              >
                <option value="html">HTML</option>
                <option value="text">Text</option>
              </select>
              <button 
                onClick={previewTemplate}
                className="btn btn-outline"
                disabled={loading}
              >
                Preview
              </button>
              <button 
                onClick={saveTemplate}
                className="btn btn-primary"
                disabled={saving || loading}
              >
                {saving ? 'Saving...' : 'Save Template'}
              </button>
            </div>
          </div>

          <div className="editor-content">
            <textarea
              value={templateContent}
              onChange={(e) => setTemplateContent(e.target.value)}
              placeholder="Enter your email template content here..."
              className="template-textarea"
              rows={20}
            />
          </div>

          {preview && (
            <div className="preview-section">
              <h4>Preview</h4>
              <div className="preview-info">
                <p><strong>Subject:</strong> {preview.subject}</p>
                <p><strong>To:</strong> {preview.to}</p>
              </div>
              <div className="preview-content">
                {templateType === 'html' ? (
                  <div dangerouslySetInnerHTML={{ __html: preview.html_content }} />
                ) : (
                  <pre>{preview.text_content}</pre>
                )}
              </div>
            </div>
          )}
        </div>
      )}

      <style jsx>{`
        .email-template-editor {
          padding: 20px;
          max-width: 1400px;
          margin: 0 auto;
        }
        
        .message {
          padding: 15px;
          margin: 20px 0;
          border-radius: 5px;
          font-weight: 500;
        }
        
        .message.success {
          background: #d4edda;
          border: 1px solid #c3e6cb;
          color: #155724;
        }
        
        .message.error {
          background: #f8d7da;
          border: 1px solid #f5c6cb;
          color: #721c24;
        }
        
        .template-selector {
          margin: 20px 0;
        }
        
        .template-list {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: 15px;
          margin: 15px 0;
        }
        
        .template-card {
          background: #f8f9fa;
          padding: 20px;
          border-radius: 8px;
          border: 2px solid #e9ecef;
          cursor: pointer;
          transition: all 0.2s;
        }
        
        .template-card:hover {
          border-color: #007bff;
          background: #f0f8ff;
        }
        
        .template-card.selected {
          border-color: #007bff;
          background: #e3f2fd;
        }
        
        .template-card h4 {
          margin: 0 0 10px 0;
          color: #333;
        }
        
        .template-card p {
          margin: 0 0 10px 0;
          color: #666;
          font-size: 14px;
        }
        
        .template-card small {
          color: #888;
          font-size: 12px;
        }
        
        .template-editor {
          margin: 30px 0;
          border: 1px solid #dee2e6;
          border-radius: 8px;
          overflow: hidden;
        }
        
        .editor-header {
          background: #f8f9fa;
          padding: 20px;
          border-bottom: 1px solid #dee2e6;
          display: flex;
          justify-content: space-between;
          align-items: center;
          flex-wrap: wrap;
          gap: 15px;
        }
        
        .editor-header h3 {
          margin: 0;
          color: #333;
        }
        
        .editor-controls {
          display: flex;
          gap: 10px;
          align-items: center;
        }
        
        .template-type-selector {
          padding: 8px 12px;
          border: 1px solid #ced4da;
          border-radius: 4px;
          background: white;
        }
        
        .btn {
          padding: 8px 16px;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          font-size: 14px;
          font-weight: 500;
        }
        
        .btn:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
        
        .btn-primary {
          background: #007bff;
          color: white;
        }
        
        .btn-outline {
          background: transparent;
          border: 1px solid #007bff;
          color: #007bff;
        }
        
        .editor-content {
          padding: 0;
        }
        
        .template-textarea {
          width: 100%;
          border: none;
          padding: 20px;
          font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
          font-size: 14px;
          line-height: 1.5;
          resize: vertical;
          min-height: 400px;
        }
        
        .template-textarea:focus {
          outline: none;
        }
        
        .preview-section {
          border-top: 1px solid #dee2e6;
          padding: 20px;
          background: #f8f9fa;
        }
        
        .preview-section h4 {
          margin: 0 0 15px 0;
          color: #333;
        }
        
        .preview-info {
          background: white;
          padding: 15px;
          border-radius: 4px;
          margin-bottom: 15px;
        }
        
        .preview-info p {
          margin: 5px 0;
          color: #666;
        }
        
        .preview-content {
          background: white;
          padding: 20px;
          border-radius: 4px;
          border: 1px solid #dee2e6;
          max-height: 500px;
          overflow-y: auto;
        }
        
        .preview-content pre {
          white-space: pre-wrap;
          font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
          font-size: 12px;
          line-height: 1.4;
        }
        
        .loading {
          text-align: center;
          padding: 40px;
          color: #666;
        }
      `}</style>
    </div>
  );
};

export default EmailTemplateEditor;
