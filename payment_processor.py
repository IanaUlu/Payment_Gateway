"""Payment processor for BePay Payment Gateway."""
import re
from datetime import datetime
from config import Config
from models import Transaction, TransactionDatabase


class PaymentProcessor:
    """Core payment processing engine."""
    
    def __init__(self):
        """Initialize payment processor."""
        self.db = TransactionDatabase()
    
    def process_payment(self, amount, currency, card_number, cvv, 
                       expiry_date, cardholder_name, description=''):
        """
        Process a payment transaction.
        
        Args:
            amount: Transaction amount
            currency: Currency code (USD, EUR, etc.)
            card_number: Credit card number
            cvv: Card verification value
            expiry_date: Card expiry date (MM/YY format)
            cardholder_name: Name on the card
            description: Optional transaction description
            
        Returns:
            dict: Transaction result with status and details
        """
        # Validate inputs
        validation_result = self._validate_payment(
            amount, currency, card_number, cvv, expiry_date
        )
        if not validation_result['valid']:
            return {
                'success': False,
                'error': validation_result['error'],
                'transaction_id': None
            }
        
        # Create transaction
        transaction = Transaction(
            amount=amount,
            currency=currency,
            card_number=card_number,
            cvv=cvv,
            expiry_date=expiry_date,
            cardholder_name=cardholder_name,
            description=description
        )
        
        # Process payment (in real implementation, this would connect to payment network)
        processing_result = self._process_with_payment_network(transaction)
        
        # Update transaction status
        transaction.status = 'success' if processing_result else 'failed'
        
        # Save to database
        self.db.save_transaction(transaction)
        
        return {
            'success': processing_result,
            'transaction_id': transaction.transaction_id,
            'amount': transaction.amount,
            'currency': transaction.currency,
            'status': transaction.status,
            'created_at': transaction.created_at
        }
    
    def _validate_payment(self, amount, currency, card_number, cvv, expiry_date):
        """Validate payment details."""
        # Validate amount
        try:
            amount = float(amount)
            if amount < Config.MIN_TRANSACTION_AMOUNT:
                return {
                    'valid': False,
                    'error': f'Amount must be at least {Config.MIN_TRANSACTION_AMOUNT}'
                }
            if amount > Config.MAX_TRANSACTION_AMOUNT:
                return {
                    'valid': False,
                    'error': f'Amount cannot exceed {Config.MAX_TRANSACTION_AMOUNT}'
                }
        except (ValueError, TypeError):
            return {'valid': False, 'error': 'Invalid amount'}
        
        # Validate currency
        if currency.upper() not in Config.SUPPORTED_CURRENCIES:
            return {
                'valid': False,
                'error': f'Currency must be one of {Config.SUPPORTED_CURRENCIES}'
            }
        
        # Validate card number (basic Luhn algorithm)
        if not self._validate_card_number(card_number):
            return {'valid': False, 'error': 'Invalid card number'}
        
        # Validate CVV
        if not re.match(r'^\d{3,4}$', str(cvv)):
            return {'valid': False, 'error': 'Invalid CVV'}
        
        # Validate expiry date
        if not self._validate_expiry_date(expiry_date):
            return {'valid': False, 'error': 'Invalid or expired card'}
        
        return {'valid': True}
    
    def _validate_card_number(self, card_number):
        """Validate card number using Luhn algorithm."""
        # Remove spaces and dashes
        card_number = re.sub(r'[\s-]', '', str(card_number))
        
        # Check if all digits
        if not card_number.isdigit():
            return False
        
        # Check length (13-19 digits for most cards)
        if len(card_number) < 13 or len(card_number) > 19:
            return False
        
        # Luhn algorithm
        total = 0
        reverse_digits = card_number[::-1]
        
        for i, digit in enumerate(reverse_digits):
            n = int(digit)
            if i % 2 == 1:
                n *= 2
                if n > 9:
                    n -= 9
            total += n
        
        return total % 10 == 0
    
    def _validate_expiry_date(self, expiry_date):
        """Validate card expiry date."""
        try:
            # Parse MM/YY format
            if '/' not in expiry_date:
                return False
            
            month, year = expiry_date.split('/')
            month = int(month)
            year = int(year)
            
            # Validate month
            if month < 1 or month > 12:
                return False
            
            # Convert 2-digit year to 4-digit
            if year < 100:
                year += 2000
            
            # Check if expired
            now = datetime.now()
            expiry = datetime(year, month, 1)
            
            return expiry >= datetime(now.year, now.month, 1)
            
        except (ValueError, AttributeError):
            return False
    
    def _process_with_payment_network(self, transaction):
        """
        Process payment with payment network.
        
        In a real implementation, this would connect to payment processors
        like Stripe, PayPal, or bank networks. For this demo, we simulate
        success based on basic rules.
        """
        # Simulate processing - in reality, this would call external APIs
        # For demo purposes, we approve all valid transactions
        return True
    
    def get_transaction(self, transaction_id):
        """Retrieve transaction details."""
        transaction = self.db.get_transaction(transaction_id)
        if transaction:
            return transaction.to_dict()
        return None
    
    def refund_transaction(self, transaction_id):
        """Refund a transaction."""
        transaction = self.db.get_transaction(transaction_id)
        
        if not transaction:
            return {
                'success': False,
                'error': 'Transaction not found'
            }
        
        if transaction.status != 'success':
            return {
                'success': False,
                'error': 'Can only refund successful transactions'
            }
        
        # Process refund (in real implementation, connect to payment network)
        self.db.update_transaction_status(transaction_id, 'refunded')
        
        return {
            'success': True,
            'transaction_id': transaction_id,
            'status': 'refunded'
        }
    
    def get_all_transactions(self, limit=100):
        """Get all transactions."""
        transactions = self.db.get_all_transactions(limit)
        return [t.to_dict() for t in transactions]
