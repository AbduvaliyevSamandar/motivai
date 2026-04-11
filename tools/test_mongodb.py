#!/usr/bin/env python3
"""
MongoDB Atlas Connection Tester
Test your MongoDB Atlas connection before deployment
"""

import sys
from pymongo import MongoClient
from pymongo.errors import ServerSelectionTimeoutError, AuthenticationError
import argparse
from urllib.parse import urlparse

def test_mongodb_connection(connection_string: str) -> tuple[bool, str]:
    """
    Test MongoDB Atlas connection
    Returns: (success: bool, message: str)
    """
    try:
        print("🔌 Connecting to MongoDB Atlas...")
        print(f"    URL: {mask_password(connection_string)}")
        
        # Create client with timeout
        client = MongoClient(
            connection_string,
            serverSelectionTimeoutMS=5000,
            connectTimeoutMS=5000,
            retryWrites=True
        )
        
        # Test connection
        print("✓ Client created")
        
        # Ping the server
        result = client.admin.command('ping')
        print("✓ Ping successful:", result)
        
        # Get server info
        server_info = client.server_info()
        print(f"✓ Server version: {server_info.get('version', 'Unknown')}")
        
        # List databases
        databases = client.list_database_names()
        print(f"✓ Databases available: {len(databases)}")
        if databases:
            print(f"   Databases: {', '.join(databases[:5])}")
        
        # Test specific database
        print("\n📊 Testing database access...")
        parsed_url = urlparse(connection_string)
        db_name = parsed_url.path.lstrip('/')
        if not db_name:
            db_name = 'motivai'
        
        print(f"   Database: {db_name}")
        db = client[db_name]
        
        # List collections
        collections = db.list_collection_names()
        print(f"✓ Collections: {len(collections)}")
        if collections:
            print(f"   Collections: {', '.join(collections)}")
        
        # Test write permission (insert a test document)
        print("\n✍️  Testing write permissions...")
        test_collection = db['_test_connection']
        insert_result = test_collection.insert_one({'test': 'MongoDB connection successful'})
        print(f"✓ Document inserted: {insert_result.inserted_id}")
        
        # Read back
        found = test_collection.find_one({'test': 'MongoDB connection successful'})
        if found:
            print(f"✓ Document retrieved: {found}")
        
        # Delete test document
        delete_result = test_collection.delete_one({'test': 'MongoDB connection successful'})
        print(f"✓ Test document deleted")
        
        # Drop test collection
        test_collection.drop()
        print("✓ Test collection cleaned up")
        
        client.close()
        print("\n✅ MongoDB Atlas connection is working perfectly!")
        print(f"✓ Ready for deployment")
        
        return True, "Connection successful"
        
    except AuthenticationError as e:
        print(f"\n❌ Authentication failed!")
        print(f"Error: {str(e)}")
        print("\n💡 Troubleshooting:")
        print("  1. Check username and password in connection string")
        print("  2. Verify database user exists in MongoDB Atlas")
        print("  3. Make sure user password doesn't contain special chars (or they're URL encoded)")
        print("  4. Check user has required permissions")
        return False, f"Authentication error: {str(e)}"
        
    except ServerSelectionTimeoutError as e:
        print(f"\n❌ Connection timeout!")
        print(f"Error: {str(e)}")
        print("\n💡 Troubleshooting:")
        print("  1. Check cluster name in connection string")
        print("  2. Verify IP address is whitelisted in MongoDB Atlas")
        print("  3. Check network connectivity")
        print("  4. MongoDB Atlas might be unavailable")
        print("  5. Check your internet connection")
        return False, f"Connection timeout: {str(e)}"
        
    except Exception as e:
        print(f"\n❌ Unexpected error!")
        print(f"Error: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        return False, f"Error: {str(e)}"

def mask_password(connection_string: str) -> str:
    """Mask password in connection string for display"""
    if '@' in connection_string:
        prefix = connection_string.split('@')[0]  # mongodb+srv://user:pass
        suffix = connection_string.split('@')[1]  # cluster.mongodb.net/...
        
        # Extract username (before last :)
        if ':' in prefix:
            user_part = prefix.rsplit(':', 1)[0]  # mongodb+srv://user
            return f"{user_part}:***@{suffix}"
    
    return connection_string

def format_connection_string(host: str, username: str, password: str, database: str) -> str:
    """Build MongoDB Atlas connection string"""
    # URL encode password
    from urllib.parse import quote
    encoded_password = quote(password, safe='')
    
    return f"mongodb+srv://{username}:{encoded_password}@{host}/{database}"

def main():
    parser = argparse.ArgumentParser(
        description='Test MongoDB Atlas connection',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Test with full connection string
  python3 test_mongodb.py -c "mongodb+srv://user:pass@cluster.mongodb.net/motivai"
  
  # Build and test connection string
  python3 test_mongodb.py -u admin -p "password" -h "cluster0.xxxxx.mongodb.net" -d motivai
  
  # Interactive mode
  python3 test_mongodb.py -i
        """
    )
    
    parser.add_argument(
        '-c', '--connection',
        help='Full MongoDB connection string'
    )
    parser.add_argument(
        '-u', '--username',
        help='MongoDB username'
    )
    parser.add_argument(
        '-p', '--password',
        help='MongoDB password'
    )
    parser.add_argument(
        '-h', '--host',
        help='MongoDB Atlas host (e.g., cluster0.xxxxx.mongodb.net)'
    )
    parser.add_argument(
        '-d', '--database',
        default='motivai',
        help='Database name (default: motivai)'
    )
    parser.add_argument(
        '-i', '--interactive',
        action='store_true',
        help='Interactive mode - prompt for connection details'
    )
    
    args = parser.parse_args()
    
    connection_string = None
    
    # Interactive mode
    if args.interactive:
        print("╔════════════════════════════════════════════════════════════╗")
        print("║       MongoDB Atlas Connection String Builder              ║")
        print("╚════════════════════════════════════════════════════════════╝\n")
        
        print("Enter your MongoDB Atlas connection details:\n")
        
        username = input("Username: ").strip()
        if not username:
            print("❌ Username required")
            return
        
        password = input("Password: ").strip()
        if not password:
            print("❌ Password required")
            return
        
        host = input("Host (e.g., cluster0.xxxxx.mongodb.net): ").strip()
        if not host:
            print("❌ Host required")
            return
        
        database = input("Database name (default: motivai): ").strip() or "motivai"
        
        connection_string = format_connection_string(username, password, host, database)
        print()
    
    # Use provided connection string
    elif args.connection:
        connection_string = args.connection
    
    # Build from components
    elif args.username and args.password and args.host:
        connection_string = format_connection_string(
            args.host,
            args.username,
            args.password,
            args.database
        )
    
    else:
        print("❌ Missing arguments!")
        print("\nUsage options:")
        print("  1. Provide full connection string: -c 'mongodb+srv://...'")
        print("  2. Provide components: -u user -p pass -h host -d database")
        print("  3. Interactive mode: -i")
        print("\nRun 'python3 test_mongodb.py -h' for help")
        return
    
    # Test the connection
    print("\n╔════════════════════════════════════════════════════════════╗")
    print("║       Testing MongoDB Atlas Connection                     ║")
    print("╚════════════════════════════════════════════════════════════╝\n")
    
    success, message = test_mongodb_connection(connection_string)
    
    print(f"\n{'='*60}")
    if success:
        print("✅ TEST PASSED - Ready for deployment!")
        print("="*60)
        print("\nAdd this to your .env.production:")
        print(f"MONGODB_URL={connection_string}")
        sys.exit(0)
    else:
        print("❌ TEST FAILED - Fix connection issues before deploying")
        print("="*60)
        sys.exit(1)

if __name__ == '__main__':
    main()
