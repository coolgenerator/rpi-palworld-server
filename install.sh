# update
sudo apt update && sudo apt upgrade -y

# install dependencies
sudo apt install curl cmake git build-essential gcc-arm-linux-gnueabihf libc6:armhf libncurses5:armhf libstdc++6:armhf -y

# create palworld user
sudo useradd palworld -m
sudo -u palworld -s

# install box64
cd ~/
git clone https://github.com/ptitSeb/box64
cd box64

mkdir build
cd build
cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)

sudo make install

# install box86
cd ~/
git clone https://github.com/ptitSeb/box86
cd box86

sudo dpkg --add-architecture armhf
sudo apt update

mkdir build
cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)
sudo make install

sudo systemctl restart systemd-binfmt

# install steamcmd
mkdir ~/steamcmd
cd ~/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
./steamcmd.sh
quit

# install steamworks sdk and link the library
./steamcmd.sh +force_install_dir ~/steamworkssdk +@sSteamCmdForcePlatformType linux +login anonymous +app_update 1007 validate +quit
mkdir -p ~/.steam/sdk64
cp ~/steamworkssdk/linux64/steamclient.so ~/.steam/sdk64/

# install palworld server
./steamcmd.sh +force_install_dir ~/palworldserver +@sSteamCmdForcePlatformType linux +login anonymous +app_update 2394010 validate +quit
cd ~/palworldserver/
cp ~/palworldserver/DefaultPalWorldSettings.ini ~/palworldserver/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini

exit

cat << 'palworldService' > /etc/systemd/system/palworld.service
[Unit]
Description=Palworld Server
Wants=network-online.target
After=network-online.target

[Service]
User=palworld
Group=palworld
WorkingDirectory=/home/palworld/
ExecStartPre=/home/palworld/steamcmd/steamcmd.sh +force_install_dir '/home/palworld/palworldserver' +login anonymous +app_update 2394010 +quit
ExecStart=/home/palworld/palworldserver/PalServer.sh -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS > /dev/null
Restart=always

[Install]
WantedBy=multi-user.target
palworldService

sudo systemctl daemon-reload
sudo systemctl enable palworld
# sudo systemctl start palworld

echo "Palworld server has been installed and started, please reboot and start the service"