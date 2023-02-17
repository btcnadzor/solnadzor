sudo apt-get update 
sudo apt-get upgrade -y
sudo apt-get install sysstat jq bc -y
sudo apt-get install build-essential
sudo for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > $i; done
sudo sysctl vm.swappiness=0
sudo echo "vm.swappiness=0" >> /etc/sysctl.conf
sudo apt install smartmontools

sudo sh -c "$(curl -sSfL https://release.solana.com/v1.13.6/install)"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
solana config set --url https://api.mainnet-beta.solana.com
solana config set --keypair $HOME/mainnet-validator-keypair.json

sudo bash -c "cat >/etc/sysctl.d/20-solana-udp-buffers.conf <<EOF
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728
EOF"

sudo sysctl -p /etc/sysctl.d/20-solana-udp-buffers.conf

sudo bash -c "cat >/etc/sysctl.d/20-solana-mmaps.conf <<EOF
vm.max_map_count = 1000000
EOF"

sudo sysctl -p /etc/sysctl.d/20-solana-mmaps.conf

solana-sys-tuner --user $(whoami) > sys-tuner.log 2>&1 &

bash -c "cat > $HOME/solana.service<<EOF
[Unit]
Description=Solana MB Node
After=network.target syslog.target
StartLimitIntervalSec=0
[Service]
User=$USER
Type=simple
Restart=always
RestartSec=1
LimitNOFILE=1024000
Environment="SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"
ExecStart=/root/.local/share/solana/install/active_release/bin/solana-validator \
--entrypoint entrypoint.mainnet-beta.solana.com:8001 \
--entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
--entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
--entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
--entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
--known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
--known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
--known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \
--known-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \
--only-known-rpc \
--wal-recovery-mode skip_any_corrupted_record \
--identity /root/mainnet-validator-keypair.json \
--vote-account /root/vote-account-keypair.json \
--ledger /root/ledger \
--limit-ledger-size 50000000 \
--dynamic-port-range 8000-8020 \
--log /root/solana.log \
--full-snapshot-interval-slots 25000 \
--incremental-snapshot-interval-slots 500 \
--maximum-full-snapshots-to-retain 4 \
--maximum-incremental-snapshots-to-retain 20 \
--maximum-local-snapshot-age 3000 \
--full-rpc-api \
--private-rpc \
--rpc-port 8899 \
--no-snapshot-fetch \
--disable-accounts-disk-index
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
[Install]
WantedBy=multi-user.target
EOF"


sudo ln -s $HOME/solana.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable solana.service
sudo systemctl start solana.service

cat > logrotate.sol <<EOF
$HOME/solana.log {
rotate 3
daily
missingok
compress
compresscmd /usr/bin/bzip2
compressext .bz2
postrotate
systemctl kill -s USR1 solana.service
endscript
}
EOF

sudo cp logrotate.sol /etc/logrotate.d/sol

sleep 10

sudo systemctl stop solana

sudo apt-get update \
&& sudo apt-get install python3-venv git -y \
&& git clone https://github.com/c29r3/solana-snapshot-finder.git \
&& cd solana-snapshot-finder \
&& python3 -m venv venv \
&& source ./venv/bin/activate \
&& pip3 install -r requirements.txt

python3 /root/solana-snapshot-finder/snapshot-finder.py --snapshot_path /root/ledger --max_download_speed 90 --min_download_speed 20 --num_of_retries 55

sudo systemctl start solana
deactivate
cd /root
solana-validator monitor
