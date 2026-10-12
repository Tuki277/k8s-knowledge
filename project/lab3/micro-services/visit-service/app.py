import os
import redis
from flask import Flask, jsonify

app = Flask(__name__)
r = redis.Redis(host=os.getenv("REDIS_HOST", "localhost"), port=6379, decode_responses=True)


@app.get("/visits")
def get_visits():
    return jsonify(count=int(r.get("visits") or 0))


@app.post("/visits")
def add_visit():
    return jsonify(count=r.incr("visits"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3002)
