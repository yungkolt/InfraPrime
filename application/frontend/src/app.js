// application/frontend/src/app.js
class ThreeTierApp {
    constructor() {
        this.apiBaseUrl = this.getApiBaseUrl();
        this.init();
    }

    getApiBaseUrl() {
        // In production, this would be set via environment variables
        const hostname = window.location.hostname;
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
            return 'http://localhost:5000';
        }
        return window.location.origin.replace(':3000', ':5000'); // For local dev
    }

    init() {
        this.setupEventListeners();
        this.checkInitialConnection();
        this.loadUsers();
        this.startMetricsUpdates();
    }

    setupEventListeners() {
        // API Testing buttons
        document.getElementById('health-btn').addEventListener('click', () => this.checkHealth());
        document.getElementById('data-btn').addEventListener('click', () => this.getData());
        document.getElementById('stats-btn').addEventListener('click', () => this.getStats());
        document.getElementById('db-test-btn').addEventListener('click', () => this.testDatabase());

        // User management
        document.getElementById('add-user-btn').addEventListener('click', () => this.addUser());
        document.getElementById('refresh-users-btn').addEventListener('click', () => this.loadUsers());

        // Enter key support for user form
        document.getElementById('user-name').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addUser();
        });
        document.getElementById('user-email').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addUser();
        });
    }

    async makeApiRequest(endpoint, options = {}) {
        const startTime = performance.now();
        
        try {
            this.showLoadingOverlay();
            
            const response = await fetch(`${this.apiBaseUrl}${endpoint}`, {
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                ...options
            });

            const endTime = performance.now();
            const responseTime = Math.round(endTime - startTime);
            
            this.updateResponseTime(responseTime);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            this.updateConnectionStatus('connected');
            
            return data;
        } catch (error) {
            console.error('API request failed:', error);
            this.updateConnectionStatus('error');
            throw error;
        } finally {
            this.hideLoadingOverlay();
        }
    }

    async checkInitialConnection() {
        try {
            await this.makeApiRequest('/health');
        } catch (error) {
            console.error('Initial connection check failed:', error);
        }
    }

    async checkHealth() {
        try {
            const data = await this.makeApiRequest('/health');
            this.displayResult('health-result', data, 'success');
        } catch (error) {
            this.displayResult('health-result', { error: error.message }, 'error');
        }
    }

    async getData() {
        try {
            const data = await this.makeApiRequest('/api/data');
            this.displayResult('data-result', data, 'success');
        } catch (error) {
            this.displayResult('data-result', { error: error.message }, 'error');
        }
    }

    async getStats() {
        try {
            const data = await this.makeApiRequest('/api/stats');
            this.displayResult('stats-result', data, 'success');
            this.updateMetrics(data);
        } catch (error) {
            this.displayResult('stats-result', { error: error.message }, 'error');
        }
    }

    async testDatabase() {
        try {
            const data = await this.makeApiRequest('/api/test-db');
            this.displayResult('db-test-result', data, 'success');
        } catch (error) {
            this.displayResult('db-test-result', { error: error.message }, 'error');
        }
    }

    async addUser() {
        const name = document.getElementById('user-name').value.trim();
        const email = document.getElementById('user-email').value.trim();

        if (!name || !email) {
            this.showNotification('Please fill in both name and email fields', 'error');
            return;
        }

        try {
            const data = await this.makeApiRequest('/api/users', {
                method: 'POST',
                body: JSON.stringify({ name, email })
            });

            this.showNotification('User added successfully!', 'success');
            document.getElementById('user-name').value = '';
            document.getElementById('user-email').value = '';
            this.loadUsers();
        } catch (error) {
            this.showNotification(`Failed to add user: ${error.message}`, 'error');
        }
    }

    async loadUsers() {
        try {
            const data = await this.makeApiRequest('/api/users');
            this.displayUsers(data.users);
            document.getElementById('total-users').textContent = data.count || 0;
        } catch (error) {
            document.getElementById('users-container').innerHTML = 
                `<p class="error">Failed to load users: ${error.message}</p>`;
        }
    }

    displayUsers(users) {
        const container = document.getElementById('users-container');
        
        if (users.length === 0) {
            container.innerHTML = '<p class="no-data">No users found. Add some users to get started!</p>';
            return;
        }

        const usersHtml = users.map(user => `
            <div class="user-card">
                <div class="user-info">
                    <h4>${this.escapeHtml(user.name)}</h4>
                    <p>${this.escapeHtml(user.email)}</p>
                    <small>Created: ${new Date(user.created_at).toLocaleDateString()}</small>
                </div>
                <div class="user-actions">
                    <i class="fas fa-user-check"></i>
                </div>
            </div>
        `).join('');

        container.innerHTML = usersHtml;
    }

    displayResult(elementId, data, type) {
        const element = document.getElementById(elementId);
        const jsonString = JSON.stringify(data, null, 2);
        element.textContent = jsonString;
        element.className = `result-box ${type}`;
        
        // Auto-scroll to show result
        element.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    updateConnectionStatus(status) {
        const statusElement = document.getElementById('connection-status');
        
        switch (status) {
            case 'connected':
                statusElement.className = 'status-badge connected';
                statusElement.innerHTML = '<i class="fas fa-check-circle"></i> Connected';
                break;
            case 'error':
                statusElement.className = 'status-badge error';
                statusElement.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Connection Error';
                break;
            default:
                statusElement.className = 'status-badge checking';
                statusElement.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Checking...';
        }
    }

    updateResponseTime(time) {
        document.getElementById('response-time').textContent = `${time}ms`;
    }

    updateMetrics(stats) {
        if (stats.total_api_calls) {
            document.getElementById('api-calls').textContent = stats.total_api_calls;
        }
        if (stats.total_users !== undefined) {
            document.getElementById('total-users').textContent = stats.total_users;
        }
        if (stats.uptime) {
            document.getElementById('uptime').textContent = stats.uptime;
        }
    }

    startMetricsUpdates() {
        // Update metrics every 30 seconds
        setInterval(() => {
            this.getStats();
        }, 30000);
    }

    showLoadingOverlay() {
        document.getElementById('loading-overlay').classList.remove('hidden');
    }

    hideLoadingOverlay() {
        document.getElementById('loading-overlay').classList.add('hidden');
    }

    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.innerHTML = `
            <i class="fas ${type === 'success' ? 'fa-check-circle' : type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'}"></i>
            ${message}
        `;

        // Add to page
        document.body.appendChild(notification);

        // Trigger animation
        setTimeout(() => notification.classList.add('show'), 100);

        // Remove after 5 seconds
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => document.body.removeChild(notification), 300);
        }, 5000);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new ThreeTierApp();
});

// application/frontend/src/styles.css
:root {
    --primary-color: #2563eb;
    --secondary-color: #64748b;
    --success-color: #059669;
    --error-color: #dc2626;
    --warning-color: #d97706;
    --background-color: #f8fafc;
    --surface-color: #ffffff;
    --text-primary: #1e293b;
    --text-secondary: #64748b;
    --border-color: #e2e8f0;
    --border-radius: 8px;
    --shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
    --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', sans-serif;
    line-height: 1.6;
    color: var(--text-primary);
    background-color: var(--background-color);
    overflow-x: hidden;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1rem;
}

/* Header */
.header {
    background: linear-gradient(135deg, var(--primary-color), #3b82f6);
    color: white;
    padding: 2rem 0;
    box-shadow: var(--shadow-lg);
}

.header .container {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 1rem;
}

.header h1 {
    font-size: 2rem;
    font-weight: 700;
}

.header h1 i {
    margin-right: 0.5rem;
}

.status-indicator {
    display: flex;
    align-items: center;
}

.status-badge {
    padding: 0.5rem 1rem;
    border-radius: 2rem;
    font-size: 0.875rem;
    font-weight: 500;
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.status-badge.connected {
    background-color: rgba(5, 150, 105, 0.2);
    color: #059669;
    border: 1px solid rgba(5, 150, 105, 0.3);
}

.status-badge.error {
    background-color: rgba(220, 38, 38, 0.2);
    color: #dc2626;
    border: 1px solid rgba(220, 38, 38, 0.3);
}

.status-badge.checking {
    background-color: rgba(100, 116, 139, 0.2);
    color: #64748b;
    border: 1px solid rgba(100, 116, 139, 0.3);
}

/* Main Content */
.main {
    padding: 3rem 0;
}

section {
    margin-bottom: 4rem;
}

section h2 {
    font-size: 1.875rem;
    font-weight: 700;
    color: var(--text-primary);
    margin-bottom: 2rem;
    text-align: center;
}

/* Architecture Section */
.architecture-diagram {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 2rem;
    flex-wrap: wrap;
    margin: 3rem 0;
}

.tier {
    background: var(--surface-color);
    border-radius: var(--border-radius);
    padding: 2rem;
    box-shadow: var(--shadow);
    text-align: center;
    min-width: 200px;
    flex: 1;
    max-width: 300px;
}

.tier i {
    font-size: 3rem;
    margin-bottom: 1rem;
}

.frontend-tier i { color: #06b6d4; }
.backend-tier i { color: #8b5cf6; }
.database-tier i { color: #059669; }

.tier h3 {
    font-size: 1.25rem;
    font-weight: 600;
    margin-bottom: 0.5rem;
}

.arrow {
    font-size: 2rem;
    color: var(--text-secondary);
    font-weight: bold;
}

/* API Section */
.api-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 2rem;
    margin: 2rem 0;
}

.api-card {
    background: var(--surface-color);
    border-radius: var(--border-radius);
    padding: 2rem;
    box-shadow: var(--shadow);
    border: 1px solid var(--border-color);
}

.api-card h3 {
    font-size: 1.25rem;
    font-weight: 600;
    margin-bottom: 1rem;
    color: var(--text-primary);
}

.api-card h3 i {
    margin-right: 0.5rem;
    color: var(--primary-color);
}

/* Buttons */
.btn {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: var(--border-radius);
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
    text-decoration: none;
}

.btn-primary {
    background-color: var(--primary-color);
    color: white;
}

.btn-primary:hover {
    background-color: #1d4ed8;
    transform: translateY(-1px);
    box-shadow: var(--shadow-lg);
}

.btn-success {
    background-color: var(--success-color);
    color: white;
}

.btn-success:hover {
    background-color: #047857;
}

.btn-secondary {
    background-color: var(--secondary-color);
    color: white;
}

.btn-sm {
    padding: 0.5rem 1rem;
    font-size: 0.75rem;
}

/* Result Boxes */
.result-box {
    background-color: #f1f5f9;
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    padding: 1rem;
    margin-top: 1rem;
    font-family: 'Monaco', 'Courier New', monospace;
    font-size: 0.875rem;
    white-space: pre-wrap;
    word-break: break-all;
    max-height: 300px;
    overflow-y: auto;
}

.result-box.success {
    background-color: #f0fdf4;
    border-color: #bbf7d0;
    color: #166534;
}

.result-box.error {
    background-color: #fef2f2;
    border-color: #fecaca;
    color: #991b1b;
}

/* User Management */
.user-management {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
}

.user-form, .users-list {
    background: var(--surface-color);
    border-radius: var(--border-radius);
    padding: 2rem;
    box-shadow: var(--shadow);
    border: 1px solid var(--border-color);
}

.form-group {
    margin-bottom: 1rem;
}

.form-group input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    font-size: 1rem;
}

.form-group input:focus {
    outline: none;
    border-color: var(--primary-color);
    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}

.users-container {
    max-height: 400px;
    overflow-y: auto;
}

.user-card {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    margin-bottom: 0.5rem;
    background: #f9fafb;
}

.user-info h4 {
    font-size: 1rem;
    font-weight: 600;
    margin-bottom: 0.25rem;
}

.user-info p {
    color: var(--text-secondary);
    font-size: 0.875rem;
    margin-bottom: 0.25rem;
}

.user-info small {
    color: var(--text-secondary);
    font-size: 0.75rem;
}

.user-actions i {
    color: var(--success-color);
    font-size: 1.25rem;
}

/* Metrics */
.metrics-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    margin: 2rem 0;
}

.metric-card {
    background: var(--surface-color);
    border-radius: var(--border-radius);
    padding: 2rem;
    box-shadow: var(--shadow);
    text-align: center;
    border: 1px solid var(--border-color);
}

.metric-card i {
    font-size: 2rem;
    color: var(--primary-color);
    margin-bottom: 1rem;
}

.metric-card h3 {
    font-size: 1rem;
    font-weight: 600;
    color: var(--text-secondary);
    margin-bottom: 0.5rem;
}

.metric-value {
    font-size: 2rem;
    font-weight: 700;
    color: var(--text-primary);
}

/* Footer */
.footer {
    background-color: var(--text-primary);
    color: white;
    padding: 2rem 0;
    text-align: center;
}

.footer .container {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 1rem;
}

.tech-stack {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.tech-stack i {
    font-size: 1.5rem;
}

/* Loading Overlay */
.loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    z-index: 9999;
    color: white;
}

.loading-overlay.hidden {
    display: none;
}

.spinner {
    width: 50px;
    height: 50px;
    border: 3px solid rgba(255, 255, 255, 0.3);
    border-top: 3px solid white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* Notifications */
.notification {
    position: fixed;
    top: 2rem;
    right: 2rem;
    padding: 1rem 1.5rem;
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-lg);
    z-index: 10000;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    transform: translateX(400px);
    transition: transform 0.3s ease;
}

.notification.show {
    transform: translateX(0);
}

.notification.success {
    background-color: var(--success-color);
    color: white;
}

.notification.error {
    background-color: var(--error-color);
    color: white;
}

.notification.info {
    background-color: var(--primary-color);
    color: white;
}

/* Responsive Design */
@media (max-width: 768px) {
    .architecture-diagram {
        flex-direction: column;
    }
    
    .arrow {
        transform: rotate(90deg);
    }
    
    .user-management {
        grid-template-columns: 1fr;
    }
    
    .header .container {
        flex-direction: column;
        text-align: center;
    }
    
    .footer .container {
        flex-direction: column;
    }
}

/* Utility Classes */
.hidden { display: none !important; }
.loading { text-align: center; color: var(--text-secondary); }
.error { color: var(--error-color); }
.no-data { text-align: center; color: var(--text-secondary); font-style: italic; }
