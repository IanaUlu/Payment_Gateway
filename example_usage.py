"""Example usage of BePay Payment Gateway."""
import requests
import json


# Configuration
API_URL = 'http://localhost:5000'
API_KEY = 'dev-api-key-change-in-production'

headers = {
    'Content-Type': 'application/json',
    'X-API-Key': API_KEY
}


def check_health():
    """Check if the gateway is running."""
    response = requests.get(f'{API_URL}/api/health')
    print('Health Check:', response.json())


def process_payment_example():
    """Example: Process a payment."""
    payment_data = {
        'amount': 99.99,
        'currency': 'USD',
        'card_number': '4532015112830366',  # Valid test card number
        'cvv': '123',
        'expiry_date': '12/25',
        'cardholder_name': 'John Doe',
        'description': 'Test payment'
    }
    
    response = requests.post(
        f'{API_URL}/api/payment',
        headers=headers,
        json=payment_data
    )
    
    print('\nProcess Payment:')
    print(json.dumps(response.json(), indent=2))
    
    if response.status_code == 200:
        return response.json().get('transaction_id')
    return None


def get_transaction_example(transaction_id):
    """Example: Get transaction details."""
    response = requests.get(
        f'{API_URL}/api/transaction/{transaction_id}',
        headers=headers
    )
    
    print('\nGet Transaction:')
    print(json.dumps(response.json(), indent=2))


def refund_transaction_example(transaction_id):
    """Example: Refund a transaction."""
    response = requests.post(
        f'{API_URL}/api/refund/{transaction_id}',
        headers=headers
    )
    
    print('\nRefund Transaction:')
    print(json.dumps(response.json(), indent=2))


def get_all_transactions_example():
    """Example: Get all transactions."""
    response = requests.get(
        f'{API_URL}/api/transactions?limit=10',
        headers=headers
    )
    
    print('\nAll Transactions:')
    print(json.dumps(response.json(), indent=2))


if __name__ == '__main__':
    print('=== BePay Payment Gateway - Example Usage ===\n')
    
    # Check health
    check_health()
    
    # Process a payment
    transaction_id = process_payment_example()
    
    if transaction_id:
        # Get transaction details
        get_transaction_example(transaction_id)
        
        # Get all transactions
        get_all_transactions_example()
        
        # Refund the transaction
        refund_transaction_example(transaction_id)
