import os
import socket
import time
import urllib.parse

def wait_proxy(addr):
    result = urllib.parse.urlsplit(addr)
    host  = result.hostname
    port = result.port
    if host is None or port is None:
        raise Exception('proxy url {} malformed'.format(addr))
    while True:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            s.connect((host,port))
            s.close()
            print('[wait_proxy] connected local socks5 proxy')
            break
        except Exception as e:
            print('[wait_proxy] cannot reach socket on {}:{}, retrying: {}'.format(host, port, e))
            time.sleep(1)

proxy = os.environ.get('HTTPS_PROXY', os.environ.get('HTTP_PROXY'))
if not proxy:
    raise Exception('HTTP_PROXY or HTTPS_PROXY environment variables are not set (e.g. socks5://localhost:5000)')
wait_proxy(proxy)
