import hashlib
import os.path
import datetime

def md5_checksum(file_name):
    hash_md5 = hashlib.md5()
    with open(file_name, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def read_first_checksum(file_name):
    with open(file_name, 'r') as f:
        for line in f:
            checksum, filepath = line.rstrip().split('  ')
            return checksum

def file_mtime(path):
    mtime = os.path.getmtime(path)
    return datetime.datetime.utcfromtimestamp(mtime)
