import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.database.session import Base

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=False)
    note = Column(String, nullable=False)
    amount = Column(Integer, nullable=False)
    category = Column(String, nullable=False, default="Other")
    type = Column(String, nullable=False, default="OUT")
    payment_method = Column(String, nullable=False, default="tunai")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relasi ke detail item transaksi
    items = relationship("TransactionItem", back_populates="transaction", cascade="all, delete-orphan")

class TransactionItem(Base):
    __tablename__ = "transaction_items"

    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(Integer, ForeignKey("transactions.id"), nullable=False)
    note = Column(String, nullable=False)
    amount = Column(Integer, nullable=False)
    quantity = Column(Integer, nullable=False, default=1)

    transaction = relationship("Transaction", back_populates="items")

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=False)
    text = Column(String, nullable=False)
    is_ai = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)


