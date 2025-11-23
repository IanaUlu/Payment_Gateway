"""Unit tests for BePay Payment Gateway."""
import unittest
import os
import sys
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from payment_processor import PaymentProcessor
from models import Transaction, TransactionDatabase
from config import Config


class TestPaymentProcessor(unittest.TestCase):
    """Test cases for payment processor."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.processor = PaymentProcessor()
        # Use test database
        self.processor.db.db_path = 'test_transactions.db'
        self.processor.db._init_db()
    
    def tearDown(self):
        """Clean up after tests."""
        if os.path.exists('test_transactions.db'):
            os.remove('test_transactions.db')
    
    def test_valid_payment(self):
        """Test processing a valid payment."""
        result = self.processor.process_payment(
            amount=100.00,
            currency='USD',
            card_number='4532015112830366',
            cvv='123',
            expiry_date='12/25',
            cardholder_name='John Doe',
            description='Test payment'
        )
        
        self.assertTrue(result['success'])
        self.assertIsNotNone(result['transaction_id'])
        self.assertEqual(result['amount'], 100.00)
        self.assertEqual(result['currency'], 'USD')
    
    def test_invalid_amount(self):
        """Test payment with invalid amount."""
        result = self.processor.process_payment(
            amount=-10.00,
            currency='USD',
            card_number='4532015112830366',
            cvv='123',
            expiry_date='12/25',
            cardholder_name='John Doe'
        )
        
        self.assertFalse(result['success'])
        self.assertIn('error', result)
    
    def test_invalid_currency(self):
        """Test payment with invalid currency."""
        result = self.processor.process_payment(
            amount=100.00,
            currency='XXX',
            card_number='4532015112830366',
            cvv='123',
            expiry_date='12/25',
            cardholder_name='John Doe'
        )
        
        self.assertFalse(result['success'])
        self.assertIn('Currency', result['error'])
    
    def test_invalid_card_number(self):
        """Test payment with invalid card number."""
        result = self.processor.process_payment(
            amount=100.00,
            currency='USD',
            card_number='1234567890123456',
            cvv='123',
            expiry_date='12/25',
            cardholder_name='John Doe'
        )
        
        self.assertFalse(result['success'])
        self.assertIn('card', result['error'].lower())
    
    def test_expired_card(self):
        """Test payment with expired card."""
        result = self.processor.process_payment(
            amount=100.00,
            currency='USD',
            card_number='4532015112830366',
            cvv='123',
            expiry_date='01/20',  # Expired
            cardholder_name='John Doe'
        )
        
        self.assertFalse(result['success'])
        self.assertIn('expired', result['error'].lower())
    
    def test_get_transaction(self):
        """Test retrieving a transaction."""
        # First create a transaction
        result = self.processor.process_payment(
            amount=50.00,
            currency='USD',
            card_number='4532015112830366',
            cvv='123',
            expiry_date='12/25',
            cardholder_name='Jane Doe'
        )
        
        transaction_id = result['transaction_id']
        
        # Retrieve it
        transaction = self.processor.get_transaction(transaction_id)
        
        self.assertIsNotNone(transaction)
        self.assertEqual(transaction['amount'], 50.00)
        self.assertEqual(transaction['cardholder_name'], 'Jane Doe')
    
    def test_refund_transaction(self):
        """Test refunding a transaction."""
        # Create a transaction
        result = self.processor.process_payment(
            amount=75.00,
            currency='USD',
            card_number='4532015112830366',
            cvv='123',
            expiry_date='12/25',
            cardholder_name='Test User'
        )
        
        transaction_id = result['transaction_id']
        
        # Refund it
        refund_result = self.processor.refund_transaction(transaction_id)
        
        self.assertTrue(refund_result['success'])
        self.assertEqual(refund_result['status'], 'refunded')


class TestTransaction(unittest.TestCase):
    """Test cases for Transaction model."""
    
    def test_transaction_creation(self):
        """Test creating a transaction."""
        transaction = Transaction(
            amount=100.00,
            currency='USD',
            card_number='4532015112830366',
            cvv='123',
            expiry_date='12/25',
            cardholder_name='John Doe'
        )
        
        self.assertEqual(transaction.amount, 100.00)
        self.assertEqual(transaction.currency, 'USD')
        self.assertIsNotNone(transaction.transaction_id)
    
    def test_card_masking(self):
        """Test card number masking."""
        transaction = Transaction(
            amount=100.00,
            currency='USD',
            card_number='4532015112830366',
            cvv='123',
            expiry_date='12/25',
            cardholder_name='John Doe'
        )
        
        masked = transaction._mask_card_number()
        self.assertTrue(masked.startswith('*'))
        self.assertTrue(masked.endswith('0366'))


if __name__ == '__main__':
    unittest.main()
