# Qubic-init
## Usage
```
git clone https://github.com/DreamGallery/qubic-init.git
cd qubic-init
```
### Install on Dedicated servers 
The default threads for `Dedicated servers` such as 7950x is 16
```
chmod +x qubic-init.sh
./qubic-init.sh $TOKEN [$alias] [$threads] [$qli-version]
```
### Install on VPS
The default threads for `VPS` is 2
```
chmod +x qubic-vps.sh
./qubic-vps.sh $TOKEN [$alias] [$threads] [$qli-version]
```
### Update qli client version
```
chmod +x update.sh
./update.sh $qli-version
```
### Change the threads
```
chmod +x changethreads.sh
./changethreads.sh $threads
```
### Delete qubic
```
chmod +x delete.sh
./delete.sh
```
## V2-Uasge
Use -h/--help for more details.
