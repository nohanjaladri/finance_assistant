import datetime
from sqlalchemy import Column, Integer, String, DateTime
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
