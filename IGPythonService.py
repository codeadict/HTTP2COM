# vim: tabstop=4 shiftwidth=4 softtabstop=4
# HTTP 2 COM Service
# Copyright 2013 IGpython UK
# All Rights Reserved.
# Developer: Dairon Medina <dairon.medina AT gmail DOT com>
from win32api import CloseHandle, GetLastError, SetConsoleCtrlHandler
import win32serviceutil
import win32service
import win32event
import servicemanager
import traceback
import logging
import time
import os, sys
import inspect
import ConfigParser, codecs
import serial
import socket
import eventlet
import eventlet.wsgi
import json
import httplib
import ftplib
import urllib
import SocketServer
import BaseHTTPServer

ROOT = os.path.dirname(sys.executable)
path = lambda *a: os.path.join(ROOT, *a)

settings = ConfigParser.ConfigParser()
settings.read(path('config/settings.conf'))

def bridge(env, start_response):
        """
        The main SERVER
        """
        port = settings.get('SERIAL', 'PORT')
        ser = serial.Serial(port=port, baudrate=settings.getint('SERIAL', 'BAUDRATE'), parity=settings.get('SERIAL', 'PARITY'), stopbits=settings.getint('SERIAL', 'STOPBITS'),bytesize=settings.getint('SERIAL', 'BYTESIZE'), timeout=30)

        headers = [('Content-Type', 'application/json'), ('Access-Control-Allow-Origin', '*'), ('Access-Control-Allow-Methods', '*'), ('Access-Control-Max-Age', '3628800')]
        if ser is not None:
                data = env['PATH_INFO'][1:]
                if settings.getboolean('SERIAL', 'ADDENDLINE'):
                        data = str(data) + '\n\r'
                #print data

                ser.write(data)
                raw = ser.readline()
                start_response('200 OK', headers)
                response = {'status': 'ok', 'content': str(raw)}
                return json.dumps(response)
        else:
                start_response('200 OK', headers)
                response = {'status': 'error', 'content': 'Serial port dont return any response or there is no device connected to it.'}
                return json.dumps(response)

class IGPythonService(win32serviceutil.ServiceFramework):
        _svc_name_ = 'IGpython HTTP2CCOM Service'
        _svc_description_ = 'IGpython HTTP2COM Service. Takes requests on HTTP port and relays to COM serial.'
        _scv_display_name_ ='TCP to COM - WSGI Server'
        def __init__(self, args):
                win32serviceutil.ServiceFramework.__init__(self, args)
                # create an event that SvcDoRun can wait on and SvcStop
                # can set.
#                self.stop_event = win32event.CreateEvent(None, 0, 0, None)
                self._server = None
                self._protocol = eventlet.wsgi.HttpProtocol
                bind_addr = ('', settings.getint('WEBSERVER', 'PORT'))
                self._socket = eventlet.listen(bind_addr)
                SetConsoleCtrlHandler(lambda x: True, True)
                self.hWaitStop = win32event.CreateEvent(None,0,0,None)

        def SvcStop(self):
                self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
                if self._server is not None:
                        self._socket.close()
                        self._server = None
                win32event.SetEvent(self.hWaitStop)
                self.ReportServiceStatus(win32service.SERVICE_STOPPED)
                self.run = False 

        def SvcDoRun(self):
                servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,
                              servicemanager.PYS_SERVICE_STARTED,
                              (self._svc_name_,''))
                self.run = True
                try:
                        self._server = eventlet.wsgi.server(self._socket, bridge, keepalive=False, debug=False, log_output=False)
                except:
                        servicemanager.LogErrorMsg(traceback.format_exc()) # if error print it to event log
                        os._exit(-1)#return some value other than 0 to os so that service knows to restart


if __name__ == '__main__':
    win32serviceutil.HandleCommandLine(IGPythonService)