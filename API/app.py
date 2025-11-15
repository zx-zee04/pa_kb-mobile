from flask import Flask, request, jsonify
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
from flask_cors import CORS
import numpy as np
import os

app = Flask(__name__)
CORS(app)  # izinkan akses dari Flutter

model = load_model('final_mango_cnn.keras')

classes = ['Early_ripe', 'Partially_ripe', 'Ripe', 'Rotten', 'Unripe']

@app.route('/')
def home():
    return jsonify({'message': 'Mango CNN API is running!'})

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400

    file = request.files['file']
    os.makedirs('uploads', exist_ok=True)
    file_path = os.path.join('uploads', file.filename)
    file.save(file_path)
    print("=== File diterima ===")
    print("Nama   :", file.filename)
    print("Path   :", file_path)
    print("Ukuran :", os.path.getsize(file_path), "bytes")

    # --- Preprocess gambar ---
    img = image.load_img(file_path, target_size=(224, 224))
    img_array = image.img_to_array(img) / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    # --- Prediksi ---
    preds = model.predict(img_array)
    result = classes[np.argmax(preds)]
    confidence = float(np.max(preds))

    return jsonify({
        'prediction': result,
        'confidence': round(confidence, 2)
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

