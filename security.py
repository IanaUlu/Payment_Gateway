"""Security middleware for BePay Payment Gateway."""
from functools import wraps
from flask import request, jsonify
from config import Config


def require_api_key(f):
    """Decorator to require API key authentication."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not Config.REQUIRE_API_KEY:
            return f(*args, **kwargs)
        
        api_key = request.headers.get('X-API-Key')
        
        if not api_key:
            return jsonify({
                'error': 'API key is required',
                'message': 'Please provide X-API-Key header'
            }), 401
        
        if api_key != Config.API_KEY:
            return jsonify({
                'error': 'Invalid API key',
                'message': 'The provided API key is invalid'
            }), 403
        
        return f(*args, **kwargs)
    
    return decorated_function


def validate_json(*required_fields):
    """Decorator to validate required JSON fields."""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not request.is_json:
                return jsonify({
                    'error': 'Invalid request',
                    'message': 'Content-Type must be application/json'
                }), 400
            
            data = request.get_json()
            missing_fields = [field for field in required_fields if field not in data]
            
            if missing_fields:
                return jsonify({
                    'error': 'Missing required fields',
                    'message': f'Required fields: {", ".join(missing_fields)}'
                }), 400
            
            return f(*args, **kwargs)
        
        return decorated_function
    
    return decorator
