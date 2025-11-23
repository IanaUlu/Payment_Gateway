"""Transaction models for BePay Payment Gateway."""
import json
import sqlite3
import uuid
from datetime import datetime, timezone
from config import Config


class Transaction:
    """Transaction model representing a payment transaction."""
    
    def __init__(self, amount, currency, card_number, cvv, expiry_date, 
                 cardholder_name, description='', transaction_id=None, 
                 status='pending', created_at=None):
        """Initialize a transaction."""
        self.transaction_id = transaction_id or str(uuid.uuid4())
        self.amount = float(amount)
        self.currency = currency.upper()
        self.card_number = card_number
        self.cvv = cvv
        self.expiry_date = expiry_date
        self.cardholder_name = cardholder_name
        self.description = description
        self.status = status
        self.created_at = created_at or datetime.now(timezone.utc).isoformat()
        
    def to_dict(self):
        """Convert transaction to dictionary."""
        return {
            'transaction_id': self.transaction_id,
            'amount': self.amount,
            'currency': self.currency,
            'card_number': self._mask_card_number(),
            'cardholder_name': self.cardholder_name,
            'description': self.description,
            'status': self.status,
            'created_at': self.created_at
        }
    
    def _mask_card_number(self):
        """Mask card number for security."""
        if len(self.card_number) >= 4:
            return '*' * (len(self.card_number) - 4) + self.card_number[-4:]
        return '****'


class TransactionDatabase:
    """Database manager for transactions."""
    
    def __init__(self, db_path=None):
        """Initialize database connection."""
        self.db_path = db_path or Config.DATABASE_PATH
        self._init_db()
    
    def _init_db(self):
        """Initialize database schema."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
                transaction_id TEXT PRIMARY KEY,
                amount REAL NOT NULL,
                currency TEXT NOT NULL,
                card_number TEXT NOT NULL,
                cvv TEXT NOT NULL,
                expiry_date TEXT NOT NULL,
                cardholder_name TEXT NOT NULL,
                description TEXT,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
        ''')
        conn.commit()
        conn.close()
    
    def save_transaction(self, transaction):
        """
        Save a transaction to the database.
        
        WARNING: This is a demonstration implementation only.
        In production, you MUST:
        1. NEVER store CVV codes (PCI DSS requirement)
        2. Encrypt or tokenize card numbers before storage
        3. Use a payment processor that handles card data
        4. Follow PCI DSS compliance standards
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO transactions 
            (transaction_id, amount, currency, card_number, cvv, expiry_date,
             cardholder_name, description, status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            transaction.transaction_id,
            transaction.amount,
            transaction.currency,
            transaction.card_number,  # WARNING: Should be encrypted/tokenized in production
            transaction.cvv,  # WARNING: Should NEVER be stored in production
            transaction.expiry_date,
            transaction.cardholder_name,
            transaction.description,
            transaction.status,
            transaction.created_at
        ))
        conn.commit()
        conn.close()
    
    def get_transaction(self, transaction_id):
        """Retrieve a transaction by ID."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute(
            'SELECT * FROM transactions WHERE transaction_id = ?',
            (transaction_id,)
        )
        row = cursor.fetchone()
        conn.close()
        
        if row:
            return Transaction(
                amount=row[1],
                currency=row[2],
                card_number=row[3],
                cvv=row[4],
                expiry_date=row[5],
                cardholder_name=row[6],
                description=row[7],
                transaction_id=row[0],
                status=row[8],
                created_at=row[9]
            )
        return None
    
    def update_transaction_status(self, transaction_id, status):
        """Update transaction status."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute(
            'UPDATE transactions SET status = ? WHERE transaction_id = ?',
            (status, transaction_id)
        )
        conn.commit()
        conn.close()
    
    def get_all_transactions(self, limit=100):
        """Get all transactions with optional limit."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute(
            'SELECT * FROM transactions ORDER BY created_at DESC LIMIT ?',
            (limit,)
        )
        rows = cursor.fetchall()
        conn.close()
        
        transactions = []
        for row in rows:
            transactions.append(Transaction(
                amount=row[1],
                currency=row[2],
                card_number=row[3],
                cvv=row[4],
                expiry_date=row[5],
                cardholder_name=row[6],
                description=row[7],
                transaction_id=row[0],
                status=row[8],
                created_at=row[9]
            ))
        return transactions
