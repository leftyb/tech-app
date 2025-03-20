from flask import Flask, jsonify
import time

app = Flask(__name__)

@app.route('/api/message', methods=['GET'])
def get_message():
    response = {
        "message": "Automate all the things!",
        "timestamp": int(time.time())
    }
    return jsonify(response)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
