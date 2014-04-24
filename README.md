Installation
============
Debian/Ubuntu
------
 * pjsiptcl extension:
```
git clone https://github.com/vitalyster/pjsiptcl.git
apt-get install tcl-dev libpjproject-dev
cd pjsiptcl
./configure --prefix=/usr && make
sudo make install
```
 * Tkabber plugin:
```
git clone https://github.com/vitalyster/sipcall.git
ln -s ~/.tkabber/plugins/sipcall sipcall
```
