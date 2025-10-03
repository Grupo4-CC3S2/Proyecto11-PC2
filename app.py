import os
import time
import random
from flask import Flask, jsonify

app = Flask(__name__)

# Cargar variables de entorno con valores por defecto
RELEASE = os.getenv("RELEASE", "v1.0.0")
PORT = int(os.getenv("PORT", "8080"))  # asegurar que sea int
MESSAGE = os.getenv("MESSAGE", "Hola, PC2!")
SLOW_COUNTER = int(os.getenv("SLOW_COUNTER", "3"))


# Endpoint raíz
@app.route("/", methods=["GET"])
def root():
    data = {
        "message": MESSAGE,
        "release": RELEASE,
        "status": "running"
    }
    print("[/] →", data, flush=True)
    return jsonify(data), 200

# Endpoint de salud
@app.route("/salud", methods=["GET"])
def salud():
    data = {"status": "ok", "release": RELEASE}
    print("[/salud] →", data, flush=True)
    return jsonify(data), 200

# Endpoint de configuración (muestra valores activos de entorno)
@app.route("/config", methods=["GET"])
def config():
    data = {"RELEASE": RELEASE, "PORT": PORT, "MESSAGE": MESSAGE}
    print("[/config] →", data, flush=True)
    return jsonify(data), 200

# Endpoint con latencia artificial
@app.route("/lento", methods=["GET"])
def lento():
    global SLOW_COUNTER
    if SLOW_COUNTER > 0:
        SLOW_COUNTER -= 1
        delay = random.uniform(1.0, 2.0)  # entre 500ms y 2s
    else:
        delay = random.uniform(0.1, 0.5)  # entre 100ms y 400ms
    time.sleep(delay)
    data = {"status": "ok", "delay_seconds": round(delay, 3)}
    print("[/lento] →", data, flush=True)
    return jsonify(data), 200

# Endpoint que devuelve error 404
@app.route("/notfound", methods=["GET"])
def notfound():
    data = {"error": "recurso no encontrado"}
    print("[/notfound] →", data, flush=True)
    return jsonify(data), 404

# Endpoint que devuelve error 500
@app.route("/falla", methods=["GET"])
def falla():
    data = {"error": "fallo interno"}
    print("[/falla] →", data, flush=True)
    return jsonify(data), 500

@app.route("/restart", methods=["GET"])
def restart():
    global SLOW_COUNTER
    SLOW_COUNTER = int(os.getenv("SLOW_COUNTER", "3"))
    data = {"status": "ok"}
    print("[/restart] →", data, flush=True)
    return jsonify(data), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT, debug=True)
