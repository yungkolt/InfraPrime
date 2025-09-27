-- Development sample data for InfraPrime
-- This file is loaded only in development environment

INSERT INTO health_checks (status, response_time_ms, details) VALUES
('healthy', 45, '{"service": "api", "version": "1.0.0"}'),
('healthy', 52, '{"service": "database", "connections": 5}'),
('healthy', 38, '{"service": "redis", "memory_usage": "15%"}'),
('degraded', 156, '{"service": "api", "warning": "High response time"}'),
('healthy', 41, '{"service": "api", "version": "1.0.0"}');

INSERT INTO api_requests (method, path, status_code, response_time_ms, ip_address) VALUES
('GET', '/health', 200, 45, '127.0.0.1'),
('GET', '/api/data', 200, 120, '127.0.0.1'),
('POST', '/api/data', 201, 85, '127.0.0.1'),
('GET', '/health', 200, 42, '127.0.0.1'),
('GET', '/api/metrics', 200, 67, '127.0.0.1');

INSERT INTO application_metrics (metric_name, metric_value, metric_type, labels) VALUES
('http_requests_total', 1524, 'counter', '{"method": "GET", "status": "200"}'),
('http_request_duration_seconds', 0.045, 'histogram', '{"method": "GET", "endpoint": "/health"}'),
('database_connections_active', 5, 'gauge', '{"pool": "main"}'),
('memory_usage_bytes', 134217728, 'gauge', '{"component": "api"}'),
('redis_connected_clients', 3, 'gauge', '{"instance": "main"}');

-- Development users for testing
INSERT INTO users (username, email, password_hash, is_admin) VALUES
('testuser', 'test@infraprime.local', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGi.RI/VwBrXFgdW', false),
('developer', 'dev@infraprime.local', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGi.RI/VwBrXFgdW', false),
('manager', 'manager@infraprime.local', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGi.RI/VwBrXFgdW', true)
ON CONFLICT (email) DO NOTHING;
