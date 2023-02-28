if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi


echo "==========UPDATING PACKAGES=========="
sleep 2

sudo apt-get update && sudo apt-get upgrade -y 

echo "==========INSTALLING LINUX DEPENDENCIES=========="
sleep 2

sudo apt-get install git wget curl make

echo "==========INSTALLING GO=========="
sleep 2

if [ ! -f "go1.20.1.linux-amd64.tar.gz" ]; then
    wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz
fi

rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin


echo "==========DOWNLOADING NIBIRU PACKAGES=========="
sleep 2

git clone https://github.com/NibiruChain/nibiru
cd nibiru

echo "==========INSTALLING NIBIRU PACKAGES=========="
sleep 2

git checkout v0.19.2
make install

echo "==========SETUP NODE=========="
sleep 2

if [ ! $NIBIRU_MONIKER ]; then
    read -p "Masukan moniker: " NIBIRU_MONIKER
    echo 'export NIBIRU_MONIKER='\"${NIBIRU_MONIKER}\" >> $HOME/.bash_profile
fi

CHAIN_ID=nibiru-itn-1

nibid init $NIBIRU_MONIKER --chain-id $CHAIN_ID
nibid config chain-id $CHAIN_ID

curl https://anode.team/Nibiru/test/genesis.json > ~/.nibid/config/genesis.json
curl https://anode.team/Nibiru/test/addrbook.json > ~/.nibid/config/addrbook.json

SEEDS=""
PEERS="dd58949cab9bf75a42b556d04d3a4b1bbfadd8b5@144.76.97.251:40656"
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.nibid/config/config.toml


sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025unibi\"/" $HOME/.nibid/config/app.toml

sudo tee /etc/systemd/system/nibid.service > /dev/null <<EOF
[Unit]
Description=nibiru
After=network-online.target

[Service]
User=$USER
ExecStart=$(which nibid) start
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && sudo systemctl enable nibid
sudo systemctl restart nibid && journalctl -fu nibid -o cat
