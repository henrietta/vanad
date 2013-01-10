Vanad is a peculiarly fast associative persistent portable in-memory string-string database.

+ **portable**: little endian? big endian? the data dump files are portable. Just move them across systems, no conversion needed!
+ **persistent**: when Vanad receives SIGTERM it dumps it's data to disk. When it starts up, it reads it. It's that easy.
+ **in-memory**: all data is kept in memory for fast reference
+ **string-string**: your keys are arrays of bytes. your values are arrays of bytes.
+ **database**: it talks over TCP

See project wiki for more info, see LICENSE for license text
