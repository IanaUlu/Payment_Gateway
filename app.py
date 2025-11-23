"""BePay Payment Gateway API Application."""
from flask import Flask, request, jsonify
from flask_cors import CORS
from config import Config
from payment_processor import PaymentProcessor
from security import require_api_key, validate_json


app = Flask(__name__)
app.config.from_object(Config)
CORS(app)

processor = PaymentProcessor()


@app.route('/', methods=['GET'])
def index():
    """API root endpoint."""
    return jsonify({
        'name': 'BePay Payment Gateway',
        'version': '1.0.0',
        'status': 'online',
        'endpoints': {
            'process_payment': 'POST /api/payment',
            'get_transaction': 'GET /api/transaction/<id>',
            'refund_transaction': 'POST /api/refund/<id>',
            'get_transactions': 'GET /api/transactions',
            'health': 'GET /api/health'
        }
    })


@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'message': 'Payment gateway is running'
    })


@app.route('/api/payment', methods=['POST'])
@require_api_key
@validate_json('amount', 'currency', 'card_number', 'cvv', 'expiry_date', 'cardholder_name')
def process_payment():
    """Process a payment transaction."""
    data = request.get_json()
    
    result = processor.process_payment(
        amount=data['amount'],
        currency=data['currency'],
        card_number=data['card_number'],
        cvv=data['cvv'],
        expiry_date=data['expiry_date'],
        cardholder_name=data['cardholder_name'],
        description=data.get('description', '')
    )
    
    status_code = 200 if result['success'] else 400
    return jsonify(result), status_code


@app.route('/api/transaction/<transaction_id>', methods=['GET'])
@require_api_key
def get_transaction(transaction_id):
    """Get transaction details."""
    transaction = processor.get_transaction(transaction_id)
    
    if transaction:
        return jsonify(transaction)
    else:
        return jsonify({
            'error': 'Transaction not found',
            'transaction_id': transaction_id
        }), 404


@app.route('/api/refund/<transaction_id>', methods=['POST'])
@require_api_key
def refund_transaction(transaction_id):
    """Refund a transaction."""
    result = processor.refund_transaction(transaction_id)
    
    status_code = 200 if result['success'] else 400
    return jsonify(result), status_code


@app.route('/api/transactions', methods=['GET'])
@require_api_key
def get_transactions():
    """Get all transactions."""
    limit = request.args.get('limit', 100, type=int)
    transactions = processor.get_all_transactions(limit)
    
    return jsonify({
        'count': len(transactions),
        'transactions': transactions
    })


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({
        'error': 'Not found',
        'message': 'The requested resource was not found'
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    return jsonify({
        'error': 'Internal server error',
        'message': 'An unexpected error occurred'
    }), 500


if __name__ == '__main__':
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=Config.DEBUG
    )
