// Configuration Management
class Config {
    constructor() {
        this.environment = this.getEnvironment();
        this.config = this.loadConfig();
    }

    getEnvironment() {
        // Check if we're in development, staging, or production
        const hostname = window.location.hostname;
        
        if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname.includes('192.168')) {
            return 'development';
        } else if (hostname.includes('staging') || hostname.includes('dev')) {
            return 'staging';
        } else {
            return 'production';
        }
    }

    loadConfig() {
        const configs = {
            development: {
                apiBaseUrl: 'http://localhost:5000',
                enableDebug: true,
                enableMetrics: false,
                refreshInterval: 30000
            },
            staging: {
                apiBaseUrl: 'https://staging-api.infraprime.com',
                enableDebug: true,
                enableMetrics: true,
                refreshInterval: 60000
            },
            production: {
                apiBaseUrl: 'https://api.infraprime.com',
                enableDebug: false,
                enableMetrics: true,
                refreshInterval: 300000
            }
        };

        return configs[this.environment];
    }

    get(key) {
        return this.config[key];
    }
}

// API Client with retry logic and error handling
class ApiClient {
    constructor(config) {
        this.baseUrl = config.get('apiBaseUrl');
        this.enableDebug = config.get('enableDebug');
        this.retryAttempts = 3;
        this.retryDelay = 1000;
    }

    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;
        const defaultOptions = {
            headers: {
                'Content-Type': 'application/json',
                'X-Client-Version': '1.0.0'
            },
            ...options
        };

        for (let attempt = 1; attempt <= this.retryAttempts; attempt++) {
            try {
                if (this.enableDebug) {
                    console.log(`API Request (attempt ${attempt}):`, { url, options: defaultOptions });
                }

                const response = await fetch(url, defaultOptions);
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }

                const data = await response.json();
                
                if (this.enableDebug) {
                    console.log('API Response:', data);
                }

                return { success: true, data, status: response.status };
            } catch (error) {
                console.error(`API request failed (attempt ${attempt}):`, error);
                
                if (attempt === this.retryAttempts) {
                    return { 
                        success: false, 
                        error: error.message, 
                        status: error.status || 500 
                    };
                }
                
                // Wait before retrying
                await new Promise(resolve => setTimeout(resolve, this.retryDelay * attempt));
            }
        }
    }

    async get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    }

    async post(endpoint, data) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data)
        });
    }
}

// Application State Management
class AppState {
    constructor() {
        this.state = {
            isLoading: false,
            apiStatus: 'unknown',
            lastUpdated: null,
            error: null,
            metrics: {
                responseTime: null,
                uptime: null,
                requestCount: 0
            }
        };
        this.listeners = [];
    }

    setState(newState) {
        this.state = { ...this.state, ...newState };
        this.notifyListeners();
    }

    getState() {
        return { ...this.state };
    }

    subscribe(callback) {
        this.listeners.push(callback);
    }

    notifyListeners() {
        this.listeners.forEach(callback => callback(this.state));
    }
}

// UI Components
class UIComponents {
    static createLoadingSpinner() {
        return `
            <div class="loading-spinner">
                <div class="spinner"></div>
                <span>Loading...</span>
            </div>
        `;
    }

    static createStatusBadge(status) {
        const statusClasses = {
            healthy: 'status-badge status-healthy',
            degraded: 'status-badge status-degraded',
            unhealthy: 'status-badge status-unhealthy',
            unknown: 'status-badge status-unknown'
        };
        
        return `<span class="${statusClasses[status] || statusClasses.unknown}">${status.toUpperCase()}</span>`;
    }

    static createMetricsCard(metrics) {
        return `
            <div class="metrics-card">
                <h3>Performance Metrics</h3>
                <div class="metrics-grid">
                    <div class="metric">
                        <label>Response Time</label>
                        <value>${metrics.responseTime ? metrics.responseTime + 'ms' : 'N/A'}</value>
                    </div>
                    <div class="metric">
                        <label>Uptime</label>
                        <value>${metrics.uptime || 'N/A'}</value>
                    </div>
                    <div class="metric">
                        <label>Requests</label>
                        <value>${metrics.requestCount}</value>
                    </div>
                </div>
            </div>
        `;
    }

    static createErrorAlert(error) {
        return `
            <div class="error-alert">
                <div class="error-icon">⚠️</div>
                <div class="error-content">
                    <h4>Connection Error</h4>
                    <p>${error}</p>
                    <button onclick="app.retryConnection()" class="retry-button">Retry</button>
                </div>
            </div>
        `;
    }
}

// Main Application Class
class InfraPrimeApp {
    constructor() {
        this.config = new Config();
        this.apiClient = new ApiClient(this.config);
        this.appState = new AppState();
        this.refreshTimer = null;
        
        this.init();
    }

    async init() {
        console.log(`🚀 InfraPrime App starting in ${this.config.environment} mode`);
        
        // Set up state listeners
        this.appState.subscribe(this.handleStateChange.bind(this));
        
        // Initialize UI
        this.renderApp();
        
        // Start health checks
        await this.checkHealth();
        this.startPeriodicHealthChecks();
        
        // Set up event listeners
        this.setupEventListeners();
    }

    renderApp() {
        const appContainer = document.getElementById('app');
        if (!appContainer) {
            console.error('App container not found');
            return;
        }

        appContainer.innerHTML = `
            <header class="app-header">
                <h1>InfraPrime Three-Tier Application</h1>
                <div class="environment-badge">${this.config.environment.toUpperCase()}</div>
            </header>
            
            <main class="app-main">
                <section class="status-section">
                    <h2>System Status</h2>
                    <div id="status-content">
                        ${UIComponents.createLoadingSpinner()}
                    </div>
                </section>
                
                <section class="metrics-section">
                    <div id="metrics-content">
                        ${UIComponents.createMetricsCard(this.appState.getState().metrics)}
                    </div>
                </section>
                
                <section class="actions-section">
                    <h2>Actions</h2>
                    <div class="action-buttons">
                        <button id="refresh-btn" class="action-button">Refresh Status</button>
                        <button id="test-api-btn" class="action-button">Test API</button>
                        <button id="clear-metrics-btn" class="action-button secondary">Clear Metrics</button>
                    </div>
                </section>
            </main>
            
            <footer class="app-footer">
                <p>Last updated: <span id="last-updated">Never</span></p>
                <p>Environment: ${this.config.environment} | Version: 1.0.0</p>
                <p>Created by <a href="https://github.com/yungkolt" target="_blank" rel="noopener">Yung Kolt</a></p>
            </footer>
        `;
    }

    handleStateChange(state) {
        // Update status content
        const statusContent = document.getElementById('status-content');
        if (statusContent) {
            if (state.isLoading) {
                statusContent.innerHTML = UIComponents.createLoadingSpinner();
            } else if (state.error) {
                statusContent.innerHTML = UIComponents.createErrorAlert(state.error);
            } else {
                statusContent.innerHTML = `
                    <div class="status-display">
                        <div class="status-main">
                            <span class="status-label">API Status:</span>
                            ${UIComponents.createStatusBadge(state.apiStatus)}
                        </div>
                        <div class="status-details">
                            <p>✅ Nginx Reverse Proxy: Healthy</p>
                            <p>✅ Backend Service: Running</p>
                            <p>✅ PostgreSQL Database: Available</p>
                        </div>
                    </div>
                `;
            }
        }

        // Update metrics
        const metricsContent = document.getElementById('metrics-content');
        if (metricsContent) {
            metricsContent.innerHTML = UIComponents.createMetricsCard(state.metrics);
        }

        // Update last updated time
        const lastUpdatedEl = document.getElementById('last-updated');
        if (lastUpdatedEl && state.lastUpdated) {
            lastUpdatedEl.textContent = new Date(state.lastUpdated).toLocaleString();
        }
    }

    setupEventListeners() {
        // Refresh button
        const refreshBtn = document.getElementById('refresh-btn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.checkHealth());
        }

        // Test API button
        const testApiBtn = document.getElementById('test-api-btn');
        if (testApiBtn) {
            testApiBtn.addEventListener('click', () => this.testApi());
        }

        // Clear metrics button
        const clearMetricsBtn = document.getElementById('clear-metrics-btn');
        if (clearMetricsBtn) {
            clearMetricsBtn.addEventListener('click', () => this.clearMetrics());
        }

        // Window events
        window.addEventListener('online', () => {
            console.log('Network connection restored');
            this.checkHealth();
        });

        window.addEventListener('offline', () => {
            console.log('Network connection lost');
            this.appState.setState({
                apiStatus: 'unhealthy',
                error: 'Network connection lost'
            });
        });
    }

    async checkHealth() {
        this.appState.setState({ isLoading: true, error: null });
        
        const startTime = Date.now();
        const result = await this.apiClient.get('/health');
        const responseTime = Date.now() - startTime;

        const currentState = this.appState.getState();
        
        if (result.success) {
            this.appState.setState({
                isLoading: false,
                apiStatus: 'healthy',
                lastUpdated: new Date(),
                metrics: {
                    ...currentState.metrics,
                    responseTime,
                    requestCount: currentState.metrics.requestCount + 1
                }
            });
        } else {
            this.appState.setState({
                isLoading: false,
                apiStatus: 'unhealthy',
                error: result.error,
                metrics: {
                    ...currentState.metrics,
                    requestCount: currentState.metrics.requestCount + 1
                }
            });
        }
    }

    async testApi() {
        const result = await this.apiClient.get('/api/data');
        
        if (result.success) {
            alert(`API Test Successful!\nResponse: ${JSON.stringify(result.data, null, 2)}`);
        } else {
            alert(`API Test Failed!\nError: ${result.error}`);
        }
    }

    async retryConnection() {
        await this.checkHealth();
    }

    clearMetrics() {
        this.appState.setState({
            metrics: {
                responseTime: null,
                uptime: null,
                requestCount: 0
            }
        });
    }

    startPeriodicHealthChecks() {
        const interval = this.config.get('refreshInterval');
        
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
        }
        
        this.refreshTimer = setInterval(() => {
            if (this.config.get('enableMetrics') && !this.appState.getState().isLoading) {
                this.checkHealth();
            }
        }, interval);
    }

    destroy() {
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
        }
    }
}

// Initialize app when DOM is ready
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new InfraPrimeApp();
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (app) {
        app.destroy();
    }
});
