#!/bin/bash
echo 'REBOOT testnet'
pause=15
read -t 10 -p "сколько подождать до перезагрузки (15мин)" pause
let pause=$pause*60
sleep $pause
echo 'solana rebooting'
systemctl stop solana 
rm -rf /root/ledger/*
fstrim -av 
source $HOME/solana-snapshot-finder/venv/bin/activate
python3 /root/solana-snapshot-finder/snapshot-finder.py --snapshot_path /root/ledger -r https://api.testnet.solana.com --max_download_speed 90 --min_download_speed 20 --num_of_retries 5
systemctl start solana
deactivate
exit
