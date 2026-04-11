# Mock in-memory storage for testing when MongoDB is unavailable
import logging
from typing import Optional, Dict, List
from bson import ObjectId

logger = logging.getLogger(__name__)

class MockCollection:
    """Mock MongoDB collection using in-memory dict storage"""
    
    def __init__(self, name: str, storage: Dict):
        self.name = name
        self.storage = storage
    
    async def find_one(self, query: dict) -> Optional[dict]:
        """Find first matching document"""
        logger.debug(f"MockCollection.find_one({self.name}): query={query}, storage_size={len(self.storage)}")
        for doc_id, doc in self.storage.items():
            if self._matches(doc, query):
                result = doc.copy()
                logger.debug(f"  -> Found: {result.get('_id', 'no_id')}")
                return result
        logger.debug(f"  -> Not found")
        return None
    
    async def insert_one(self, document: dict):
        """Insert single document"""
        if "_id" not in document:
            document["_id"] = str(ObjectId())
        doc_id = str(document["_id"])
        self.storage[doc_id] = document.copy()
        logger.debug(f"MockCollection.insert_one({self.name}): inserted {doc_id}")
        
        # Return a result object with inserted_id
        class InsertResult:
            def __init__(self, doc_id):
                self.inserted_id = doc_id
        return InsertResult(document["_id"])
    
    async def update_one(self, query: dict, update: dict):
        """Update single document"""
        for key, doc in self.storage.items():
            if self._matches(doc, query):
                if "$set" in update:
                    doc.update(update["$set"])
                else:
                    doc.update(update)
                logger.debug(f"MockCollection.update_one({self.name}): updated {key}")
                
                class UpdateResult:
                    def __init__(self):
                        self.modified_count = 1
                return UpdateResult()
        
        class UpdateResult:
            def __init__(self):
                self.modified_count = 0
        return UpdateResult()
    
    async def find(self, query: dict = None):
        """Find all matching documents"""
        results = []
        for doc in self.storage.values():
            if query is None or self._matches(doc, query):
                results.append(doc.copy())
        return results
    
    async def create_index(self, *args, **kwargs):
        """Mock index creation"""
        pass
    
    def _matches(self, doc: dict, query: dict) -> bool:
        """Check if document matches query"""
        for key, value in query.items():
            doc_val = doc.get(key)
            
            # Handle ObjectId comparison
            if isinstance(value, ObjectId):
                if isinstance(doc_val, str):
                    try:
                        doc_val = ObjectId(doc_val)
                    except:
                        return False
                if doc_val != value:
                    return False
            # Handle string comparison (case-insensitive for emails)
            elif key == "email":
                if isinstance(doc_val, str):
                    doc_val = doc_val.lower()
                if isinstance(value, str):
                    value = value.lower()
                if doc_val != value:
                    return False
            else:
                if doc_val != value:
                    return False
        return True

class MockDatabase:
    """Mock MongoDB database using in-memory storage"""
    
    def __init__(self):
        self._storage = {
            'users': {},
            'tasks': {},
            'progress': {},
            'plans': {},
            'chat_messages': {},
            'leaderboard': {},
        }
        self._collections = {}
    
    def __getattr__(self, name: str):
        """Get or create mock collection"""
        if name.startswith('_'):
            return object.__getattribute__(self, name)
        
        if name not in self._collections:
            storage = self._storage.get(name, {})
            self._collections[name] = MockCollection(name, storage)
        
        return self._collections[name]

# Global mock database instance
mock_db = MockDatabase()

def get_mock_db():
    """Get mock database instance"""
    return mock_db
