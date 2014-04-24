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

Windows
------
 * [Tkabber-pack](https://github.com/tkabber/Tkabber-pack/releases/latest)
 * unzip [pjsiptcl binaries](https://www.dropbox.com/s/82xazksklxaqo7b/pjsiptcl0.1.zip) to `%PROGRAM_FILES%\Tkabber-pack\tcl\lib`
 * unzip [sipcall plugin](https://www.dropbox.com/s/0583lpocfv5nhnq/sipcall.zip) to `%APPDATA%\Tkabber\plugins`
