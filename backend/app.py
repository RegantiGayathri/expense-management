
import os
import mysql.connector
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash

load_dotenv()

app = Flask(__name__)
CORS(app)


def get_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "expense_management_db"),
    )


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"message": "API is running"}), 200


@app.route("/api/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}

    name = str(data.get("name", "")).strip()
    email = str(data.get("email", "")).strip().lower()
    password = str(data.get("password", ""))

    if not name or not email or not password:
        return jsonify({"message": "Please fill in all fields"}), 400

    if len(password) < 8:
        return jsonify({"message": "Password must be at least 8 characters"}), 400

    connection = None
    cursor = None

    try:
        connection = get_connection()
        cursor = connection.cursor()

        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            return jsonify({"message": "Email already registered"}), 409

        password_hash = generate_password_hash(password)

        cursor.execute(
            "INSERT INTO users (name, email, password_hash) VALUES (%s, %s, %s)",
            (name, email, password_hash),
        )
        connection.commit()

        return jsonify({"message": "Account created successfully"}), 201

    except mysql.connector.Error:
        app.logger.exception("Registration database error")
        return jsonify({"message": "Database error. Check your connection settings."}), 500

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()


@app.route("/api/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}

    email = str(data.get("email", "")).strip().lower()
    password = str(data.get("password", ""))

    if not email or not password:
        return jsonify({"message": "Email and password are required"}), 400

    connection = None
    cursor = None

    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            "SELECT id, name, email, password_hash FROM users WHERE email = %s",
            (email,),
        )
        user = cursor.fetchone()

        if not user or not check_password_hash(user["password_hash"], password):
            return jsonify({"message": "Invalid email or password"}), 401

        return jsonify({
            "message": "Login successful",
            "user": {
                "id": user["id"],
                "name": user["name"],
                "email": user["email"],
            },
        }), 200

    except mysql.connector.Error:
        app.logger.exception("Login database error")
        return jsonify({"message": "Database error. Check your connection settings."}), 500

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()
            
@app.route("/api/transactions", methods=["GET"])
def get_transactions():
    user_id = request.args.get("user_id", type=int)

    if not user_id:
        return jsonify({"message": "user_id is required"}), 400

    connection = None
    cursor = None

    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT t.id, t.title, t.amount, t.type,
                   c.name AS category,
                   t.transaction_date AS date,
                   t.description
            FROM transactions t
            LEFT JOIN categories c ON t.category_id = c.id
            WHERE t.user_id = %s
            ORDER BY t.transaction_date DESC, t.id DESC
            """,
            (user_id,),
        )

        rows = cursor.fetchall()

        for row in rows:
            row["amount"] = float(row["amount"])
            row["date"] = str(row["date"])
            row["category"] = row["category"] or "Other"
            row["description"] = row["description"] or ""

        return jsonify(rows), 200

    except mysql.connector.Error:
        app.logger.exception("Could not load transactions")
        return jsonify({"message": "Could not load transactions"}), 500

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()


@app.route("/api/transactions", methods=["POST"])
def add_transaction():
    data = request.get_json(silent=True) or {}

    user_id = data.get("user_id")
    title = str(data.get("title", "")).strip()
    transaction_type = str(data.get("type", "")).strip().lower()
    category = str(data.get("category", "Other")).strip()
    description = str(data.get("description", "")).strip()
    date = str(data.get("date", ""))[:10]

    try:
        amount = float(data.get("amount", 0))
        if amount <= 0:
            raise ValueError()
    except (ValueError, TypeError):
        return jsonify({"message": "Enter a valid positive amount"}), 400

    if not user_id or not title or transaction_type not in ("income", "expense") or not date:
        return jsonify({"message": "Please provide valid transaction details"}), 400

    connection = None
    cursor = None

    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("SELECT id FROM users WHERE id = %s", (user_id,))
        if not cursor.fetchone():
            return jsonify({"message": "User not found"}), 404

        cursor.execute(
            "SELECT id FROM categories WHERE name = %s AND type = %s",
            (category, transaction_type),
        )
        category_row = cursor.fetchone()

        if category_row:
            category_id = category_row["id"]
        else:
            cursor.execute(
                "INSERT INTO categories (name, type) VALUES (%s, %s)",
                (category, transaction_type),
            )
            category_id = cursor.lastrowid

        cursor.execute(
            """
            INSERT INTO transactions
                (user_id, title, amount, type, category_id,
                 transaction_date, description)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                user_id, title, amount, transaction_type,
                category_id, date, description,
            ),
        )

        transaction_id = cursor.lastrowid
        connection.commit()

        return jsonify({
            "message": "Transaction saved successfully",
            "id": transaction_id,
        }), 201

    except mysql.connector.Error:
        if connection:
            connection.rollback()
        app.logger.exception("Could not save transaction")
        return jsonify({"message": "Could not save transaction"}), 500

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()


@app.route("/api/transactions/<int:transaction_id>", methods=["PUT"])
def update_transaction(transaction_id):
    data = request.get_json(silent=True) or {}
    user_id = data.get("user_id")
    title = str(data.get("title", "")).strip()
    transaction_type = str(data.get("type", "")).strip().lower()
    category = str(data.get("category", "Other")).strip()
    description = str(data.get("description", "")).strip()
    date = str(data.get("date", ""))[:10]

    try:
        amount = float(data.get("amount", 0))
        if amount <= 0:
            raise ValueError()
    except (ValueError, TypeError):
        return jsonify({"message": "Enter a valid positive amount"}), 400

    if not user_id or not title or transaction_type not in ("income", "expense") or not date:
        return jsonify({"message": "Please provide valid transaction details"}), 400

    connection = None
    cursor = None

    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            "SELECT id FROM categories WHERE name = %s AND type = %s",
            (category, transaction_type),
        )
        category_row = cursor.fetchone()

        if category_row:
            category_id = category_row["id"]
        else:
            cursor.execute(
                "INSERT INTO categories (name, type) VALUES (%s, %s)",
                (category, transaction_type),
            )
            category_id = cursor.lastrowid

        cursor.execute(
            """
            UPDATE transactions
            SET title=%s, amount=%s, type=%s, category_id=%s,
                transaction_date=%s, description=%s
            WHERE id=%s AND user_id=%s
            """,
            (
                title, amount, transaction_type, category_id,
                date, description, transaction_id, user_id,
            ),
        )

        if cursor.rowcount == 0:
            cursor.execute(
                "SELECT id FROM transactions WHERE id=%s AND user_id=%s",
                (transaction_id, user_id),
            )
            if not cursor.fetchone():
                connection.rollback()
                return jsonify({"message": "Transaction not found"}), 404

        connection.commit()
        return jsonify({"message": "Transaction updated successfully"}), 200

    except mysql.connector.Error:
        if connection:
            connection.rollback()
        app.logger.exception("Could not update transaction")
        return jsonify({"message": "Could not update transaction"}), 500

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()


@app.route("/api/transactions/<int:transaction_id>", methods=["DELETE"])
def delete_transaction(transaction_id):
    user_id = request.args.get("user_id", type=int)

    if not user_id:
        return jsonify({"message": "user_id is required"}), 400

    connection = None
    cursor = None

    try:
        connection = get_connection()
        cursor = connection.cursor()

        cursor.execute(
            "DELETE FROM transactions WHERE id=%s AND user_id=%s",
            (transaction_id, user_id),
        )

        if cursor.rowcount == 0:
            return jsonify({"message": "Transaction not found"}), 404

        connection.commit()
        return jsonify({"message": "Transaction deleted successfully"}), 200

    except mysql.connector.Error:
        if connection:
            connection.rollback()
        app.logger.exception("Could not delete transaction")
        return jsonify({"message": "Could not delete transaction"}), 500

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
