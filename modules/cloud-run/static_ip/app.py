import requests
import sys
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_https():
    r = requests.get('https://ifconfig.me/ip')
    return 'HTTPS PROXY: You connected from IP address: ' + r.text

@app.route("/http")
def hello_http():
    r = requests.get('http://ifconfig.me/ip')
    return 'HTTP_PROXY: You connected from IP address: ' + r.text
    
@app.route("/no-proxy")
def hello_none():
    proxies = {
      "http": None,
      "https": None,
    }
    r = requests.get('http://ifconfig.me/all', proxies=proxies )
    return 'NO_PROXY: Result: ' + r.text    

@app.route("/exit")
def exit():
    """You can use this to trigger IP change on Cloud Run."""
    sys.exit(1)

