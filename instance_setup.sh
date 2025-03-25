#!/bin/bash
# Update system and install dependencies
sudo yum update -y
sudo yum install -y python3 python3-pip sqlite

# Install Flask & dependencies
pip3 install flask flask-cors

# Create Flask app directory
mkdir -p /home/ec2-user/flask_app

# Create Flask API script
cat <<EOT > /home/ec2-user/flask_app/app.py
from flask import Flask, request, jsonify
import sqlite3

app = Flask(__name__)

DB_PATH = "/mnt/sqlite-data/my_database.db"

# GET all users
@app.route('/users', methods=['GET'])
def get_users():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users;")
    data = cursor.fetchall()
    conn.close()
    return jsonify(data)

# POST - Create a new user
@app.route('/create', methods=['POST'])
def create_user():
    try:
        data = request.get_json()
        name = data.get("name")

        if not name:
            return jsonify({"error": "Name is required"}), 400

        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("INSERT INTO users (name) VALUES (?)", (name,))
        conn.commit()
        conn.close()

        return jsonify({"message": "User created", "name": name}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOT

# Set up SQLite database on persistent storage
mkdir -p /mnt/sqlite-data
sqlite3 /mnt/sqlite-data/my_database.db <<EOSQL
  CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT);
  INSERT INTO users (name) VALUES ('Alice');
  INSERT INTO users (name) VALUES ('Bob');
  INSERT INTO users (name) VALUES ('Charlie');
EOSQL

# Run Flask App in Background
nohup python3 /home/ec2-user/flask_app/app.py > /home/ec2-user/flask.log 2>&1 &
