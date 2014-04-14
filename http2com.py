# vim: tabstop=4 shiftwidth=4 softtabstop=4
# HTTP 2 COM Service
# Copyright 2013 IGpython UK
# All Rights Reserved.
# Developer: Dairon Medina <dairon.medina AT gmail DOT com>
import os, sys
import inspect
import ConfigParser, codecs

import serial
import eventlet
from eventlet import wsgi
import httplib
import ftplib
import urllib
import SocketServer
import BaseHTTPServer
import json



ROOT = os.path.dirname(sys.executable)
path = lambda *a: os.path.join(ROOT, *a)

settings = ConfigParser.ConfigParser()
settings.read(path('config/settings.conf'))

class Http2ComServer(object):
    
    def bridge(self, env, start_response):
        port = settings.get('SERIAL', 'PORT')
        self.ser = serial.Serial(port=port, baudrate=settings.getint('SERIAL', 'BAUDRATE'), parity=settings.get('SERIAL', 'PARITY'), stopbits=settings.getint('SERIAL', 'STOPBITS'),bytesize=settings.getint('SERIAL', 'BYTESIZE'))

        if self.ser is not None:
            data = env['PATH_INFO'][1:]
            if settings.getboolean('SERIAL', 'ADDENDLINE'):
                data = str(data) + '\n\r'
            print data
            self.ser.write(data)
            raw = self.ser.readline()
            self.ser.close()
            start_response('200 OK', [('Content-Type', 'application/json')])
            response = {'status': 'ok', 'content': str(raw)}
            return json.dumps(response)
        else:
            start_response('200 OK', [('Content-Type', 'application/json')])
            response = {'status': 'error', 'content': 'Serial port dont return any response or there is no device connected to it.'}
            return json.dumps(response)

    def run(self):
        """
        Run the WSGI Server
        """
        sever = wsgi.server(eventlet.listen(('', settings.getint('WEBSERVER', 'PORT'))), self.bridge, keepalive=False)
        server.kil
        self.ser.close()

if __name__ == "__main__":
    srv = Http2ComServer()
    srv.run()
