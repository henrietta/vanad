import vanad
import sys
import time
import string
import random
vnd = vanad.VanadConnection(('127.0.0.1', 1000))
vnd.set_default_tablespace(random.choice((0, 1, 2)))

test_writes = {}
for i in xrange(0, 10000):
    test_writes[''.join(random.choice(string.letters) for i in xrange(20))] = ''.join(random.choice(string.letters) for i in xrange(30))

lasttm = int(time.time())
cps = 0

print 'Calls per second are +- 1000'

while True:
 for k, v in test_writes.iteritems():
    vnd.assign(k, v)
    cps += 1

 if random.choice([True, False, False, False, False]):
    for k, v in test_writes.iteritems():
        cps += 1
        if vnd.get(k) != v:
            print 'Test failed, press ENTER to continue'
            raw_input()
            sys.exit()            

 if int(time.time()) != lasttm:
    print 'CallsPerSecond: %s' % cps
    cps = 0
    lasttm = int(time.time())
