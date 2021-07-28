import requests
import socket
import string 
import sys
import threading

wordlist = sys.argv[1]     # SET CUSTOM WORDLIS
        
     
     



with open(wordlist, 'r') as f:
     for line in f.read().splitlines():
        proxiesdef = {'http': 'socks5://localhost:9050','https': 'socks5://localhost:9050'}
        passwds = line
        print(line)
        r =requests.get('http://macaxeirateste.tk/xmlrpc.php', proxies=proxiesdef)
        #r =requests.post('http://macaxeirateste.tk/xmlrpc.php', data=line, proxies=proxiesdef)
        print(r.text)

     
    
#data = {'username':'Olivia','password':'123'}

