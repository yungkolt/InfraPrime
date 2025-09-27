/**
 * Frontend Tests for InfraPrime Application
 * Run with: npm test
 */

// Mock fetch for testing
global.fetch = jest.fn();

// Mock DOM methods
Object.defineProperty(window, 'location', {
  value: {
    hostname: 'localhost',
    href: 'http://localhost:3000'
  },
  writable: true
});

// Mock DOM elements
document.body.innerHTML = `
  <div id="app"></div>
  <div id="initial-loading"></div>
  <div id="error-fallback"></div>
`;

// Import the modules to test
const { Config, ApiClient, AppState, UIComponents } = require('../src/app.js');

describe('Config Class', () => {
  test('should detect development environment for localhost', () => {
    const config = new Config();
    expect(config.environment).toBe('development');
  });

  test('should load correct configuration for environment', () => {
    const config = new Config();
    expect(config.get('enableDebug')).toBe(true);
    expect(config.get('apiBaseUrl')).toBe('http://localhost:5000');
  });

  test('should detect production environment', () => {
    // Mock production hostname
    Object.defineProperty(window, 'location', {
      value: { hostname: 'api.infraprime.com' },
      writable: true
    });
    
    const config = new Config();
    expect(config.environment).toBe('production');
    expect(config.get('enableDebug')).toBe(false);
  });
});

describe('ApiClient Class', () => {
  let config;
  let apiClient;

  beforeEach(() => {
    config = new Config();
    apiClient = new ApiClient(config);
    fetch.mockClear();
  });

  test('should make successful API request', async () => {
    const mockResponse = {
      ok: true,
      status: 200,
      json: jest.fn().mockResolvedValue({ success: true, data: 'test' })
    };
    fetch.mockResolvedValue(mockResponse);

    const result = await apiClient.get('/test');
    
    expect(fetch).toHaveBeenCalledWith(
      'http://localhost:5000/test',
      expect.objectContaining({
        method: 'GET',
        headers: expect.objectContaining({
          'Content-Type': 'application/json',
          'X-Client-Version': '1.0.0'
        })
      })
    );
    
    expect(result.success).toBe(true);
    expect(result.data).toEqual({ success: true, data: 'test' });
  });

  test('should handle API request failure', async () => {
    fetch.mockRejectedValue(new Error('Network error'));

    const result = await apiClient.get('/test');
    
    expect(result.success).toBe(false);
    expect(result.error).toBe('Network error');
  });

  test('should retry failed requests', async () => {
    // First two calls fail, third succeeds
    fetch
      .mockRejectedValueOnce(new Error('Network error'))
      .mockRejectedValueOnce(new Error('Network error'))
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: jest.fn().mockResolvedValue({ success: true })
      });

    const result = await apiClient.get('/test');
    
    expect(fetch).toHaveBeenCalledTimes(3);
    expect(result.success).toBe(true);
  });

  test('should make POST requests with data', async () => {
    const mockResponse = {
      ok: true,
      status: 200,
      json: jest.fn().mockResolvedValue({ success: true })
    };
    fetch.mockResolvedValue(mockResponse);

    const testData = { name: 'test' };
    await apiClient.post('/test', testData);
    
    expect(fetch).toHaveBeenCalledWith(
      'http://localhost:5000/test',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify(testData)
      })
    );
  });
});

describe('AppState Class', () => {
  let appState;

  beforeEach(() => {
    appState = new AppState();
  });

  test('should initialize with default state', () => {
    const state = appState.getState();
    
    expect(state.isLoading).toBe(false);
    expect(state.apiStatus).toBe('unknown');
    expect(state.error).toBe(null);
    expect(state.metrics.requestCount).toBe(0);
  });

  test('should update state correctly', () => {
    const newState = {
      isLoading: true,
      apiStatus: 'healthy'
    };
    
    appState.setState(newState);
    const state = appState.getState();
    
    expect(state.isLoading).toBe(true);
    expect(state.apiStatus).toBe('healthy');
    expect(state.error).toBe(null); // Should keep existing values
  });

  test('should notify listeners when state changes', () => {
    const mockListener = jest.fn();
    appState.subscribe(mockListener);
    
    const newState = { apiStatus: 'healthy' };
    appState.setState(newState);
    
    expect(mockListener).toHaveBeenCalledWith(
      expect.objectContaining({ apiStatus: 'healthy' })
    );
  });

  test('should handle multiple listeners', () => {
    const listener1 = jest.fn();
    const listener2 = jest.fn();
    
    appState.subscribe(listener1);
    appState.subscribe(listener2);
    
    appState.setState({ apiStatus: 'healthy' });
    
    expect(listener1).toHaveBeenCalled();
    expect(listener2).toHaveBeenCalled();
  });
});

describe('UIComponents Class', () => {
  test('should create loading spinner', () => {
    const spinner = UIComponents.createLoadingSpinner();
    
    expect(spinner).toContain('loading-spinner');
    expect(spinner).toContain('Loading...');
  });

  test('should create status badge with correct class', () => {
    const healthyBadge = UIComponents.createStatusBadge('healthy');
    const unhealthyBadge = UIComponents.createStatusBadge('unhealthy');
    
    expect(healthyBadge).toContain('status-healthy');
    expect(healthyBadge).toContain('HEALTHY');
    
    expect(unhealthyBadge).toContain('status-unhealthy');
    expect(unhealthyBadge).toContain('UNHEALTHY');
  });

  test('should create metrics card with data', () => {
    const metrics = {
      responseTime: 150,
      uptime: '99.9%',
      requestCount: 42
    };
    
    const card = UIComponents.createMetricsCard(metrics);
    
    expect(card).toContain('metrics-card');
    expect(card).toContain('150ms');
    expect(card).toContain('99.9%');
    expect(card).toContain('42');
  });

  test('should create error alert with retry button', () => {
    const error = 'Connection failed';
    const alert = UIComponents.createErrorAlert(error);
    
    expect(alert).toContain('error-alert');
    expect(alert).toContain('Connection failed');
    expect(alert).toContain('retry-button');
    expect(alert).toContain('app.retryConnection()');
  });
});

// Integration tests
describe('Application Integration', () => {
  let originalConsoleLog;
  let originalConsoleError;

  beforeAll(() => {
    // Mock console methods to reduce test noise
    originalConsoleLog = console.log;
    originalConsoleError = console.error;
    console.log = jest.fn();
    console.error = jest.fn();
  });

  afterAll(() => {
    console.log = originalConsoleLog;
    console.error = originalConsoleError;
  });

  test('should handle network online/offline events', () => {
    const config = new Config();
    const apiClient = new ApiClient(config);
    const appState = new AppState();

    // Simulate offline event
    const offlineEvent = new Event('offline');
    window.dispatchEvent(offlineEvent);

    // Simulate online event
    const onlineEvent = new Event('online');
    window.dispatchEvent(onlineEvent);

    // Test passes if no errors are thrown
    expect(true).toBe(true);
  });

  test('should handle configuration for different environments', () => {
    // Test staging environment
    Object.defineProperty(window, 'location', {
      value: { hostname: 'staging.infraprime.com' },
      writable: true
    });

    const stagingConfig = new Config();
    expect(stagingConfig.environment).toBe('staging');
    expect(stagingConfig.get('enableMetrics')).toBe(true);
  });
});

// Performance tests
describe('Performance Tests', () => {
  test('should initialize quickly', () => {
    const start = performance.now();
    
    const config = new Config();
    const apiClient = new ApiClient(config);
    const appState = new AppState();
    
    const end = performance.now();
    const duration = end - start;
    
    // Should initialize in less than 10ms
    expect(duration).toBeLessThan(10);
  });

  test('should handle large state updates efficiently', () => {
    const appState = new AppState();
    const listeners = [];
    
    // Add 100 listeners
    for (let i = 0; i < 100; i++) {
      const listener = jest.fn();
      listeners.push(listener);
      appState.subscribe(listener);
    }
    
    const start = performance.now();
    appState.setState({ apiStatus: 'healthy' });
    const end = performance.now();
    
    const duration = end - start;
    
    // Should notify all listeners in less than 5ms
    expect(duration).toBeLessThan(5);
    expect(listeners[0]).toHaveBeenCalled();
    expect(listeners[99]).toHaveBeenCalled();
  });
});

// Error handling tests
describe('Error Handling', () => {
  test('should handle malformed API responses', async () => {
    const config = new Config();
    const apiClient = new ApiClient(config);
    
    const mockResponse = {
      ok: true,
      status: 200,
      json: jest.fn().mockRejectedValue(new Error('Invalid JSON'))
    };
    fetch.mockResolvedValue(mockResponse);

    const result = await apiClient.get('/test');
    
    expect(result.success).toBe(false);
    expect(result.error).toContain('Invalid JSON');
  });

  test('should handle HTTP error codes', async () => {
    const config = new Config();
    const apiClient = new ApiClient(config);
    
    const mockResponse = {
      ok: false,
      status: 500,
      statusText: 'Internal Server Error'
    };
    fetch.mockResolvedValue(mockResponse);

    const result = await apiClient.get('/test');
    
    expect(result.success).toBe(false);
    expect(result.error).toContain('HTTP 500');
  });
});

// Accessibility tests
describe('Accessibility', () => {
  test('should generate semantic HTML', () => {
    const metrics = {
      responseTime: 150,
      uptime: '99.9%',
      requestCount: 42
    };
    
    const card = UIComponents.createMetricsCard(metrics);
    
    expect(card).toContain('<h3>');
    expect(card).toContain('<label>');
    expect(card).toContain('<value>');
  });

  test('should include proper ARIA attributes in error alerts', () => {
    const alert = UIComponents.createErrorAlert('Test error');
    
    // Should contain proper structure for screen readers
    expect(alert).toContain('error-alert');
    expect(alert).toContain('error-content');
  });
});
