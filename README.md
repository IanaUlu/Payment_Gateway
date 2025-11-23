# BePay Payment Gateway

A secure and flexible payment gateway API built with Python and Flask. BePay provides a simple REST API for processing payments, managing transactions, and handling refunds.

## Features

- 💳 Process credit card payments
- 🔍 Transaction lookup and tracking
- 💰 Refund processing
- 🔒 API key authentication
- ✅ Card validation (Luhn algorithm)
- 📊 Transaction history
- 🌍 Multi-currency support (USD, EUR, GBP, JPY)

## Installation

### Prerequisites

- Python 3.7 or higher
- pip package manager

### Setup

1. Clone the repository:
```bash
git clone https://github.com/IanaUlu/Payment_Gateway.git
cd Payment_Gateway
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. (Optional) Configure environment variables:
Create a `.env` file in the project root:
```env
SECRET_KEY=your-secret-key-here
API_KEY=your-api-key-here
REQUIRE_API_KEY=True
PORT=5000
DEBUG=False
```

## Running the Application

Start the payment gateway server:

```bash
python app.py
```

The API will be available at `http://localhost:5000`

## API Documentation

### Authentication

All API endpoints (except health check) require an API key. Include it in the request headers:

```
X-API-Key: your-api-key-here
```

Default API key for development: `dev-api-key-change-in-production`

### Endpoints

#### 1. Health Check
Check if the gateway is running.

```
GET /api/health
```

**Response:**
```json
{
  "status": "healthy",
  "message": "Payment gateway is running"
}
```

#### 2. Process Payment
Process a new payment transaction.

```
POST /api/payment
```

**Request Body:**
```json
{
  "amount": 99.99,
  "currency": "USD",
  "card_number": "4532015112830366",
  "cvv": "123",
  "expiry_date": "12/25",
  "cardholder_name": "John Doe",
  "description": "Product purchase"
}
```

**Response (Success):**
```json
{
  "success": true,
  "transaction_id": "uuid-here",
  "amount": 99.99,
  "currency": "USD",
  "status": "success",
  "created_at": "2025-11-23T14:00:00.000000"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Invalid card number",
  "transaction_id": null
}
```

#### 3. Get Transaction
Retrieve details of a specific transaction.

```
GET /api/transaction/<transaction_id>
```

**Response:**
```json
{
  "transaction_id": "uuid-here",
  "amount": 99.99,
  "currency": "USD",
  "card_number": "************0366",
  "cardholder_name": "John Doe",
  "description": "Product purchase",
  "status": "success",
  "created_at": "2025-11-23T14:00:00.000000"
}
```

#### 4. Refund Transaction
Refund a previously successful transaction.

```
POST /api/refund/<transaction_id>
```

**Response:**
```json
{
  "success": true,
  "transaction_id": "uuid-here",
  "status": "refunded"
}
```

#### 5. Get All Transactions
Retrieve a list of all transactions.

```
GET /api/transactions?limit=100
```

**Response:**
```json
{
  "count": 10,
  "transactions": [
    {
      "transaction_id": "uuid-here",
      "amount": 99.99,
      "currency": "USD",
      "card_number": "************0366",
      "cardholder_name": "John Doe",
      "status": "success",
      "created_at": "2025-11-23T14:00:00.000000"
    }
  ]
}
```

## Usage Example

See `example_usage.py` for a complete example of using the API:

```bash
# Start the server in one terminal
python app.py

# Run the example in another terminal
python example_usage.py
```

## Testing

Run the test suite:

```bash
python test_payment_gateway.py
```

## Configuration

The following environment variables can be configured:

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY` | `dev-secret-key-change-in-production` | Flask secret key |
| `API_KEY` | `dev-api-key-change-in-production` | API authentication key |
| `DATABASE_PATH` | `transactions.db` | SQLite database file path |
| `REQUIRE_API_KEY` | `True` | Enable/disable API key requirement |
| `HOST` | `0.0.0.0` | Server host |
| `PORT` | `5000` | Server port |
| `DEBUG` | `False` | Debug mode |

## Supported Payment Cards

The gateway validates card numbers using the Luhn algorithm. Test card numbers:

- Visa: `4532015112830366`
- Mastercard: `5425233430109903`
- American Express: `374245455400126`
- Discover: `6011000991001201`

## Supported Currencies

- USD (US Dollar)
- EUR (Euro)
- GBP (British Pound)
- JPY (Japanese Yen)

## Security Features

- API key authentication
- Card number validation (Luhn algorithm)
- Card number masking in responses
- Expiry date validation
- Amount validation (min/max limits)
- Currency validation
- Secure data storage

## Project Structure

```
Payment_Gateway/
├── app.py                      # Main Flask application
├── config.py                   # Configuration management
├── models.py                   # Transaction models and database
├── payment_processor.py        # Payment processing logic
├── security.py                 # Security middleware
├── example_usage.py            # Usage examples
├── test_payment_gateway.py     # Unit tests
├── requirements.txt            # Python dependencies
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## Development

### Adding New Features

1. Add new endpoints in `app.py`
2. Implement business logic in `payment_processor.py`
3. Update models in `models.py` if needed
4. Add tests in `test_payment_gateway.py`
5. Update this README

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

This project is provided as-is for educational and development purposes.

## Disclaimer

⚠️ **CRITICAL SECURITY WARNING:** This is a demonstration payment gateway for educational purposes only.

**DO NOT USE IN PRODUCTION** without addressing these critical security issues:

### PCI DSS Compliance Issues:
1. **CVV Storage**: This demo stores CVV codes, which violates PCI DSS. CVV must NEVER be stored.
2. **Card Data**: Card numbers are stored unencrypted. In production, use tokenization or encryption.
3. **No Real Payment Processing**: This doesn't connect to actual payment processors.

### Required for Production:
1. Remove CVV storage entirely
2. Implement card tokenization (use services like Stripe, PayPal, or Braintree)
3. Replace default API keys with strong, random keys
4. Implement proper SSL/TLS encryption (HTTPS only)
5. Add comprehensive logging and monitoring
6. Implement rate limiting and DDoS protection
7. Add fraud detection systems
8. Follow PCI DSS compliance requirements
9. Implement proper error handling and recovery
10. Add database encryption and backups
11. Conduct regular security audits
12. Use a production WSGI server (not Flask dev server)

**This code is for learning purposes only. Using it in production could expose you to data breaches, legal liability, and regulatory penalties.**

## Support

For issues, questions, or contributions, please open an issue on GitHub.
