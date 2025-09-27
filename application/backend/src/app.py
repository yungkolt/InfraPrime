# application/backend/src/app.py
from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import logging
from datetime import datetime
import psycopg2
from src.config import Config
from src.models import db, User, APICall

def create_app(config_class=Config):
    """Application factory pattern"""
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    # Initialize extensions
    db.init_app(app)
    CORS(app, origins=os.getenv('ALLOWED_ORIGINS', '*').split(','))
    
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    
    # Create tables within app context
    with app.app_context():
        try:
            db.create_all()
            logger.info("Database tables created successfully")
        except Exception as e:
            logger.error(f"Error creating database tables: {str(e)}")
    
    @app.route('/health', methods=['GET'])
    def health_check():
        """Health check endpoint for load balancer"""
        try:
            # Check database connection
            db.session.execute(db.text('SELECT 1'))
            db_status = "healthy"
        except Exception as e:
            logger.error(f"Database health check failed: {str(e)}")
            db_status = "unhealthy"
        
        # Log API call
        log_api_call('/health', 'GET')
        
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'environment': app.config.get('ENVIRONMENT', 'unknown'),
            'version': app.config.get('VERSION', '1.0.0'),
            'database': db_status,
            'service': 'backend-api'
        }), 200 if db_status == "healthy" else 503

    @app.route('/api/data', methods=['GET'])
    def get_data():
        """Get application data"""
        try:
            # Log API call
            log_api_call('/api/data', 'GET')
            
            # Get query parameters
            limit = request.args.get('limit', 10, type=int)
            
            # Sample data response
            data = {
                'message': 'API is working perfectly!',
                'environment': app.config.get('ENVIRONMENT', 'unknown'),
                'timestamp': datetime.utcnow().isoformat(),
                'total_requests': get_total_api_calls(),
                'server_info': {
                    'host': os.getenv('HOSTNAME', 'unknown'),
                    'region': os.getenv('AWS_REGION', 'us-east-1'),
                    'az': os.getenv('AWS_AZ', 'unknown')
                }
            }
            
            return jsonify(data), 200
            
        except Exception as e:
            logger.error(f"Error in get_data: {str(e)}")
            return jsonify({
                'error': 'Internal server error',
                'message': str(e)
            }), 500

    @app.route('/api/users', methods=['GET'])
    def get_users():
        """Get all users"""
        try:
            users = User.query.all()
            log_api_call('/api/users', 'GET')
            
            return jsonify({
                'users': [user.to_dict() for user in users],
                'count': len(users),
                'timestamp': datetime.utcnow().isoformat()
            }), 200
            
        except Exception as e:
            logger.error(f"Error in get_users: {str(e)}")
            return jsonify({'error': str(e)}), 500

    @app.route('/api/users', methods=['POST'])
    def create_user():
        """Create a new user"""
        try:
            data = request.get_json()
            
            if not data or 'name' not in data or 'email' not in data:
                return jsonify({'error': 'Name and email are required'}), 400
            
            # Check if user already exists
            existing_user = User.query.filter_by(email=data['email']).first()
            if existing_user:
                return jsonify({'error': 'User with this email already exists'}), 409
            
            # Create new user
            user = User(
                name=data['name'],
                email=data['email']
            )
            
            db.session.add(user)
            db.session.commit()
            
            log_api_call('/api/users', 'POST')
            logger.info(f"Created new user: {user.email}")
            
            return jsonify({
                'message': 'User created successfully',
                'user': user.to_dict()
            }), 201
            
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error in create_user: {str(e)}")
            return jsonify({'error': str(e)}), 500

    @app.route('/api/stats', methods=['GET'])
    def get_stats():
        """Get application statistics"""
        try:
            stats = {
                'total_users': User.query.count(),
                'total_api_calls': get_total_api_calls(),
                'health_checks': get_api_calls_count('/health'),
                'data_requests': get_api_calls_count('/api/data'),
                'uptime': get_uptime(),
                'timestamp': datetime.utcnow().isoformat()
            }
            
            log_api_call('/api/stats', 'GET')
            
            return jsonify(stats), 200
            
        except Exception as e:
            logger.error(f"Error in get_stats: {str(e)}")
            return jsonify({'error': str(e)}), 500

    @app.route('/api/test-db', methods=['GET'])
    def test_database():
        """Test database connectivity"""
        try:
            # Test raw SQL connection
            result = db.session.execute(db.text('SELECT NOW() as current_time, version() as pg_version'))
            row = result.fetchone()
            
            log_api_call('/api/test-db', 'GET')
            
            return jsonify({
                'database_status': 'connected',
                'current_time': str(row.current_time),
                'postgresql_version': row.pg_version,
                'connection_info': {
                    'host': app.config.get('DB_HOST', 'unknown'),
                    'database': app.config.get('DB_NAME', 'unknown'),
                    'port': app.config.get('DB_PORT', 5432)
                }
            }), 200
            
        except Exception as e:
            logger.error(f"Database test failed: {str(e)}")
            return jsonify({
                'database_status': 'error',
                'error': str(e)
            }), 503

    def log_api_call(endpoint, method):
        """Log API call to database"""
        try:
            api_call = APICall(
                endpoint=endpoint,
                method=method,
                timestamp=datetime.utcnow(),
                user_agent=request.headers.get('User-Agent'),
                ip_address=request.remote_addr
            )
            db.session.add(api_call)
            db.session.commit()
        except Exception as e:
            logger.error(f"Error logging API call: {str(e)}")
            db.session.rollback()

    def get_total_api_calls():
        """Get total number of API calls"""
        try:
            return APICall.query.count()
        except:
            return 0

    def get_api_calls_count(endpoint):
        """Get API calls count for specific endpoint"""
        try:
            return APICall.query.filter_by(endpoint=endpoint).count()
        except:
            return 0

    def get_uptime():
        """Calculate application uptime"""
        try:
            # Get the earliest API call as a proxy for start time
            first_call = APICall.query.order_by(APICall.timestamp.asc()).first()
            if first_call:
                uptime_seconds = (datetime.utcnow() - first_call.timestamp).total_seconds()
                return f"{int(uptime_seconds // 3600)}h {int((uptime_seconds % 3600) // 60)}m"
            return "Unknown"
        except:
            return "Unknown"

    @app.errorhandler(404)
    def not_found(error):
        """Handle 404 errors"""
        return jsonify({
            'error': 'Endpoint not found',
            'status': 404,
            'timestamp': datetime.utcnow().isoformat()
        }), 404

    @app.errorhandler(500)
    def internal_error(error):
        """Handle 500 errors"""
        logger.error(f"Internal server error: {str(error)}")
        db.session.rollback()
        return jsonify({
            'error': 'Internal server error',
            'status': 500,
            'timestamp': datetime.utcnow().isoformat()
        }), 500

    return app

# Create the app instance
app = create_app()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    logger = logging.getLogger(__name__)
    logger.info(f"Starting Flask app on port {port}")
    logger.info(f"Environment: {app.config.get('ENVIRONMENT', 'unknown')}")
    logger.info(f"Debug mode: {debug}")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug
    )
