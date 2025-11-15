MangoScan – Mango Ripeness Detection App

Aplikasi mobile berbasis Flutter untuk mendeteksi tingkat kematangan mangga menggunakan model CNN (Convolutional Neural Network).
MangoScan dapat mendeteksi 5 kelas kematangan:
  ~Early_ripe (awal matang)
  ~Partially_ripe (setengah matang)
  ~Ripe (matang)
  ~Rotten (busuk)
  ~Unripe (mentah)
Aplikasi ini terhubung dengan backend API berbasis Flask yang memproses gambar dengan model deep learning.

Fitur Aplikasi
  ~Menggunakan kamera HP untuk mengambil gambar mangga
  ~Mengunggah gambar ke API untuk diprediksi
  ~Menampilkan hasil prediksi + persentase kepercayaan
  ~Menampilkan deskripsi khusus sesuai kelas kematangan
  ~Bisa upload dari galeri
  ~Interface modern, ringan, dan mudah digunakan

Frontend (Mobile App)
Flutter
  ~Dart
  ~Camera Plugin
  ~Image Picker
  ~HTTP Multipart Upload
Backend (API Server)
  ~Python
  ~Flask
  ~TensorFlow / Keras
  ~NumPy
  ~Flask-CORS

  🚀 Cara Menjalankan API (Flask Backend)

Pastikan Python 3.8+ sudah terpasang.

1) Install dependencies
pip install flask flask-cors tensorflow numpy

2) Jalankan API

Pastikan berada pada direktori yang sama dengan app.py dan model:

python app.py


Jika berhasil, output akan tampil seperti:

* Running on http://127.0.0.1:5000
* Running on http://0.0.0.0:5000


API sekarang siap menerima gambar melalui:

Endpoint: /predict

Method: POST
Type: Multipart Form
Field: file

Contoh via Postman:

Method: POST

URL: http://localhost:5000/predict

Body → form-data → file → pilih gambar

🌐 Cara Hosting API dengan Ngrok (Agar Flutter Bisa Mengakses)

Pastikan ngrok sudah terpasang dan authtoken sudah di-setup.

1) Jalankan API seperti biasa
python app.py

2) Expose port 5000 dengan ngrok
ngrok http 5000


Ngrok akan mengeluarkan URL seperti:

Forwarding https://xxxxx.ngrok-free.app → http://localhost:5000


Salin URL tersebut dan masukkan ke Flutter:

var uri = Uri.parse("https://xxxxx.ngrok-free.app/predict");

📱 Cara Menggunakan Aplikasi (Flutter App)
1) Instal dependensi Flutter

Pada folder app Flutter:

flutter pub get

2) Jalankan di perangkat HP

Pastikan HP terkoneksi:

flutter run -d <device_id>


Contoh:

flutter run -d I2213

3) Cara Menggunakan MangoScan

Buka aplikasi MangoScan

Pilih:

Scan foto langsung dari kamera, atau

Ambil gambar dari galeri

Tekan tombol kamera

Aplikasi akan mengirim gambar ke API

Hasil prediksi tampil:

Nama kelas kematangan

Persentase confidence

Deskripsi kondisi mangga

Lihat hasil lengkap pada halaman “Hasil”
