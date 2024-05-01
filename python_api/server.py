from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/marker', methods=['PUT'])
def marker_request_handler():
    json_body = request.get_json(silent = True)
    if json_body == None:
        return 'Bad Request\n', 400
    user_input = json_body.get('user-input')
    return jsonify({'message': user_input}), 200

if __name__ == '__main__':
    app.run(host = '0.0.0.0', port = 8090)