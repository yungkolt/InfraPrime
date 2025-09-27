"""
Backend test suite for InfraPrime API
Run with: python -m pytest tests/ -v --cov=src --cov-report=html
"""

import pytest
import json
import os
import sys

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from src.app import create_app
from src.models import db, User, APICall

class TestConfig:
    """Test configuration"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = 'test-secret-key'
    ENVIRONMENT = 'testing'
    VERSION = '1.0.0'

@pytest.fixture
def app():
    """Create application for testing"""
    app = create_app(TestConfig)
    
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()

@pytest.fixture
def client(app):
    """Test client"""
    return app.test_client()

@pytest.fixture
def sample_users(app):
    """Create sample users for testing"""
    with app.app_context():
        user1 = User(name='Test User 1', email='test1@example.com')
        user2 = User(name='Test User 2', email='test2@example.com')
        
        db.session.add(user1)
        db.session.add(user2)
        db.session.commit()
        
        return [user1, user2]

class TestHealthEndpoints:
    """Test health check endpoints"""
    
    def test_health_check_success(self, client):
        """Test basic health check"""
        response = client.get('/health')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['status'] == 'healthy'
        assert 'timestamp' in data
        assert 'version' in data
        assert data['service'] == 'backend-api'
        assert data['environment'] == 'testing'
    
    def test_health_check_includes_database_status(self, client):
        """Test health check includes database status"""
        response = client.get('/health')
        data = json.loads(response.data)
        assert 'database' in data
        assert data['database'] == 'healthy'

class TestAPIDataEndpoint:
    """Test /api/data endpoint"""
    
    def test_api_data_success(self, client):
        """Test /api/data endpoint"""
        response = client.get('/api/data')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['message'] == 'API is working perfectly!'
        assert data['environment'] == 'testing'
        assert 'timestamp' in data
        assert 'server_info' in data
        assert 'total_requests' in data

class TestUsersEndpoints:
    """Test user management endpoints"""
    
    def test_get_users_empty(self, client):
        """Test getting users when none exist"""
        response = client.get('/api/users')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert 'users' in data
        assert 'count' in data
        assert data['count'] == 0
        assert len(data['users']) == 0
    
    def test_get_users_with_data(self, client, sample_users):
        """Test getting users when data exists"""
        response = client.get('/api/users')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['count'] == 2
        assert len(data['users']) == 2
        
        # Check user structure
        user = data['users'][0]
        assert 'id' in user
        assert 'name' in user
        assert 'email' in user
        assert 'created_at' in user
        assert 'updated_at' in user
    
    def test_create_user_success(self, client):
        """Test creating a new user"""
        user_data = {
            'name': 'New Test User',
            'email': 'newtest@example.com'
        }
        
        response = client.post('/api/users',
                             data=json.dumps(user_data),
                             content_type='application/json')
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['message'] == 'User created successfully'
        assert 'user' in data
        assert data['user']['name'] == 'New Test User'
        assert data['user']['email'] == 'newtest@example.com'
    
    def test_create_user_missing_name(self, client):
        """Test creating user with missing name"""
        user_data = {
            'email': 'test@example.com'
        }
        
        response = client.post('/api/users',
                             data=json.dumps(user_data),
                             content_type='application/json')
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
        assert 'required' in data['error'].lower()
    
    def test_create_user_missing_email(self, client):
        """Test creating user with missing email"""
        user_data = {
            'name': 'Test User'
        }
        
        response = client.post('/api/users',
                             data=json.dumps(user_data),
                             content_type='application/json')
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
    
    def test_create_user_duplicate_email(self, client, sample_users):
        """Test creating user with duplicate email"""
        user_data = {
            'name': 'Another User',
            'email': 'test1@example.com'  # Same as first sample user
        }
        
        response = client.post('/api/users',
                             data=json.dumps(user_data),
                             content_type='application/json')
        
        assert response.status_code == 409
        data = json.loads(response.data)
        assert 'error' in data
        assert 'already exists' in data['error']

class TestStatsEndpoint:
    """Test statistics endpoint"""
    
    def test_stats_endpoint(self, client, sample_users):
        """Test /api/stats endpoint"""
        response = client.get('/api/stats')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert 'total_users' in data
        assert 'total_api_calls' in data
        assert 'health_checks' in data
        assert 'data_requests' in data
        assert 'uptime' in data
        assert 'timestamp' in data
        
        assert data['total_users'] == 2  # From sample_users

class TestDatabaseEndpoint:
    """Test database connectivity endpoint"""
    
    def test_database_test_endpoint(self, client):
        """Test /api/test-db endpoint"""
        response = client.get('/api/test-db')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['database_status'] == 'connected'
        assert 'current_time' in data
        assert 'connection_info' in data

class TestInputValidation:
    """Test input validation"""
    
    def test_invalid_json(self, client):
        """Test handling of invalid JSON"""
        response = client.post('/api/users',
                             data='invalid json',
                             content_type='application/json')
        
        assert response.status_code == 400
    
    def test_empty_request_body(self, client):
        """Test empty request body"""
        response = client.post('/api/users',
                             data='',
                             content_type='application/json')
        
        assert response.status_code == 400

class TestErrorHandling:
    """Test error handling"""
    
    def test_404_error(self, client):
        """Test 404 error handling"""
        response = client.get('/nonexistent-endpoint')
        assert response.status_code == 404
        
        data = json.loads(response.data)
        assert 'error' in data
        assert data['status'] == 404
    
    def test_method_not_allowed(self, client):
        """Test method not allowed"""
        response = client.patch('/health')
        assert response.status_code == 405

class TestDatabaseModels:
    """Test database models"""
    
    def test_user_model_creation(self, app):
        """Test User model"""
        with app.app_context():
            user = User(name='Model Test User', email='modeltest@example.com')
            db.session.add(user)
            db.session.commit()
            
            # Verify user was created
            found_user = User.query.filter_by(email='modeltest@example.com').first()
            assert found_user is not None
            assert found_user.name == 'Model Test User'
            assert found_user.id is not None
            assert found_user.created_at is not None
    
    def test_api_call_model(self, app):
        """Test APICall model"""
        with app.app_context():
            api_call = APICall(
                endpoint='/test',
                method='GET',
                user_agent='test-agent',
                ip_address='127.0.0.1'
            )
            db.session.add(api_call)
            db.session.commit()
            
            # Verify API call was logged
            found_call = APICall.query.filter_by(endpoint='/test').first()
            assert found_call is not None
            assert found_call.method == 'GET'
            assert found_call.timestamp is not None

class TestAPICounting:
    """Test API request counting"""
    
    def test_api_calls_are_counted(self, client):
        """Test that API calls are being counted"""
        # Make several requests
        client.get('/health')
        client.get('/api/data')
        client.get('/api/users')
        
        # Check stats to see if calls were counted
        response = client.get('/api/stats')
        data = json.loads(response.data)
        
        # Should have at least the calls we just made
        assert data['total_api_calls'] >= 4  # 3 above + 1 for stats call

if __name__ == '__main__':
    pytest.main(['-v'])
