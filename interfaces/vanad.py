from __future__ import division
from socket import socket, AF_INET, SOCK_STREAM
from time import time
from select import select

from struct import pack, unpack

RQT_GET = 0x00
RQT_ASSIGN = 0x01
RQT_DELETE = 0x02

def REQ_to_bytes(request, tablespace, key, value):
    return pack('!BBLL', request, tablespace, len(key), len(value)) + key + value

def GET_to_bytes(tablespace, key):
    return REQ_to_bytes(RQT_GET, tablespace, key, '')

def ASSIGN_to_bytes(tablespace, key, value):
    return REQ_to_bytes(RQT_ASSIGN, tablespace, key, value)

def DELETE_to_bytes(tablespace, key):
    return REQ_to_bytes(RQT_DELETE, tablespace, key, '')


def scan_frame(frame):
    """
    Scans a Vanad server reply frame, and asserts if this could be a frame.

    If this cannot be a valid frame, it will raise an exception of
    undefined type and arguments.

    Will return values if this is a valid frame
    @return: tuple (int resultcode, bytearray data)
    """
        # Unzip the header. Will throw if not sufficient bytes there
    resultcode, data_len = unpack('!BL', str(frame[:5]))

        # Check if frame is long enough, if not - throw
    if len(frame) < 5 + data_len: raise Exception

        # Extract data and rest of the data
    data = frame[5:5+data_len]

    return resultcode, data

class VanadConnection(object):
    """
    Class that represents a connection to a Vanad database

    Will autoreconnect upon detecting socket lossage and repeat the query, as needed
    Will behave smoothly even if user orders a query in the middle of database's
    restart.

    Will connect only if there'a need to do so.

    If database is reliably down for longer periods of time, this WILL HANG!
    """

    def __init__(self, address, connect_timeout=4, txrx_timeout=4, eo_timeout=8):
        """
        Connect to a remote database.

        @type address: tuple of (str address, int port)
        @param address: SOCK_STREAM-compatible address of target database

        @type connect_timeout: int
        @param connect_timeout: timeout in seconds that will be used during
                                connecting to database

        @type txrx_timeout: int
        @param txrx_timeout: timeout for Tx/Rx operations

        @type eo_timeout: int
        @param eo_timeout: timeout in which entire send or receive has to be completed
        """
        self.connect_timeout = connect_timeout
        self.txrx_timeout = txrx_timeout
        self.eo_timeout = eo_timeout

        self.remote_address = address
        self.connected = False
        self.last_activity = 0   # an int with time() of last activity
        self.socket = None      # a socket.socket object will be here

        self.default_tablespace = 0        # default tablespace

    def __shut_sock(self):
        try:
            self.socket.close()
        except:
            pass
        self.socket = None
        self.connected = False

    def __ensure_connected(self):
        """PRIVATE METHOD.
        Ensured that connection to database is on.
        If it isn't, it will make it so.
        If it can't be done, it will hang."""

        if time() - self.last_activity > 3:     # Connection down
            self.__shut_sock()

        while not self.connected:    # Assure that you are connected
            self.socket = socket(AF_INET, SOCK_STREAM)
            self.socket.settimeout(self.connect_timeout)
            try:
                self.socket.connect(self.remote_address)
            except:     # timeout or active denial
                try:
                    self.socket.close()
                except:
                    pass
                self.socket = None
            else:
                self.connected = True
                self.last_activity = time()
                self.socket.setblocking(0)

    def set_default_tablespace(self, id):
        """
        Sets a new tablespace as default one

        @type id: int in (0..255)
        @param id: number of new default tablespace
        """
        self.default_tablespace = id


    def __transact(self, to_send):
        """
        Transacts with the database. Will return value that got returned.
        Will raise exception if it could not be completed, and should be retried.
        """
        # Send now
        while len(to_send) > 0:
            bytes_sent = self.socket.send(to_send)
            to_send = to_send[bytes_sent:]

                    # will throw on socket dying awful death
            started_on = time()
            while True:
                rxs, txs, exs = select((self.socket, ), (self.socket, ), (), self.txrx_timeout)
                if len(txs) == 1: break     # Socket writable again
                if len(rxs) == 1: raise Exception   # Socket disconnected hard
                if len(txs) == len(rxs) == 0: raise Exception # Timeout
                    # Entire op timeout exceeded
                if time() - started_on > self.eo_timeout: raise Exception

        # Now, wait for reception
        started_on = time()
        received_data = bytearray()
        while True:
                rxs, txs, exs = select((self.socket, ), (), (), self.txrx_timeout)
                if len(rxs) == 0: raise Exception # Timeout
                    # Entire op timeout exceeded
                if time() - started_on > self.eo_timeout: raise Exception
                if len(rxs) == 1: # Socket ready or disconnected
                    data = self.socket.recv(1024)
                    if len(data) == 0: raise Exception # Socket disconnected

                    received_data += data

                    try:
                        result, value = scan_frame(received_data)
                    except:     # Frame not ready yet
                        continue
                    else:       # Frame completed
                        break
        self.last_activity = time()     # Note the activity
        if result == 0x01: return None  # Not found for GET's
        if len(value) == 0: return None # None and empty string have same meaning
        return value

    def get(self, key, tablespace=None):
        """
        Fetches a record from database.

        @type key: str
        @param key: Key to fetch with

        @type tablespace: int in (0..255), or None
        @param tablespace: number of tablespace to fetch from. If None,
                           default tablespace will be used
        """
        if tablespace == None: tablespace = self.default_tablespace

        self.__ensure_connected()
        while True:
            try:
                return self.__transact(GET_to_bytes(tablespace, key))
            except:
                self.__ensure_connected()

    def assign(self, key, value, tablespace=None):
        """
        Writes a record to database

        @type key: str
        @param key: Key to write

        @type value: str
        @param value: Value to write

        @type tablespace: int in (0..255), or None
        @param tablespace: number of tablespace to write to. If None,
                           default tablespace will be used
        """
        if tablespace == None: tablespace = self.default_tablespace

        self.__ensure_connected()
        while True:
            try:
                self.__transact(ASSIGN_to_bytes(tablespace, key, value))
                return
            except:
                self.__ensure_connected()

    def delete(self, key, tablespace=None):
        """
        Deletes a record from database

        @type key: str
        @param key: Key to delete

        @type tablespace: int in (0..255), or None
        @param tablespace: number of tablespace to write to. If None,
                           default tablespace will be used
        """
        if tablespace == None: tablespace = self.default_tablespace

        self.__ensure_connected()
        while True:
            try:
                self.__transact(DELETE_to_bytes(tablespace, key))
                return
            except:
                self.__ensure_connected()
