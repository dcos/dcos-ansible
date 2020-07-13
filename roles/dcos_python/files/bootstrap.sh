#!/bin/bash
set -e

# Move to home directory
cd ~

# Unpack pypy
tar -xjf $HOME/pypy.tar.bz2
rm -rf $HOME/pypy.tar.bz2
rm -rf $HOME/pypy
mv -n pypy*-portable pypy

# Prepare bin directory
mkdir -p $HOME/bin
cat > $HOME/bin/python <<EOF
#!/bin/bash
exec $HOME/pypy/bin/pypy "\$@"
EOF
chmod +x $HOME/bin/python

ln -s $HOME/pypy/bin/pip $HOME/bin/pip

# Verify python works
$HOME/bin/python --version

touch $HOME/.bootstrapped
