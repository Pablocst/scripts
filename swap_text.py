import sys

path = sys.argv[0:]
old_ip = sys.argv[1:]
new_ip = sys.argv[2:]
f = open(path,'r')
filedata = f.read()
f.close()

newdata = filedata.replace(old_ip,new_ip)

f = open(fileout,'w')
f.write(newdata)
f.close()
