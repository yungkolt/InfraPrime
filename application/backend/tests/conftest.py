"""
Test configuration and utilities for InfraPrime backend tests
"""

import pytest
import os
import tempfile
from unittest.mock import Mock

# Test configuration
class TestConfig:
    """Configuration for testing environment"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = 'test-secret-key-never-use-in-production'
    JWT_SECRET_KEY = 'test-jwt-secret-never-use-in-production'
    WTF_CSRF_ENABLED = False
    PRESERVE_CONTEXT_ON_EXCEPTION = False

def pytest_configure():
    """Configure pytest"""
    # Set environment variables for testing
    os.environ['FLASK_ENV'] = 'testing'
    os.environ['DATABASE_URL'] = 'sqlite:///:memory:'

@pytest.fixture(scope='session')
def app_config():
    """App configuration fixture"""
    return TestConfig

# Common test utilities
def assert_json_response(response, expected_status=200):
    """Assert JSON response format and status"""
    assert response.status_code == expected_status
    assert response.content_type == 'application/json'
    return response.get_json()

def create_auth_headers(token):
    """Create authorization headers"""
    return {'Authorization': f'Bearer {token}'}

# Mock objects for testing
class MockRedis:
    """Mock Redis for testing"""
    def __init__(self):
        self.data = {}
    
    def get(self, key):
        return self.data.get(key)
    
    def set(self, key, value, ex=None):
        self.data[key] = value
    
    def delete(self, key):
        if key in self.data:
            del self.data[key]

class MockCloudWatch:
    """Mock CloudWatch for testing"""
    def __init__(self):
        self.metrics = []
    
    def put_metric_data(self, **kwargs):
        self.metrics.append(kwargs)
