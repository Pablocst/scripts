import sys

path = sys.argv[1]
old_ip = sys.argv[2]
new_ip = sys.argv[3]
f = open(path,'r')
filedata = f.read()
f.close()

newdata = filedata.replace(old_ip,new_ip)

f = open('path','w')
f.write(newdata)
f.close()
