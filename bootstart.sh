#!/bin/bash
python3exit=1
ps -A | grep python3 || python3exit=0
if [[ $python3exit == 0 ]]
then
systemctl stop solana && rm -rf /root/ledger/* && fstrim -av && source $HOME/solana-snapshot-finder/venv/bin/activate && python3 /root/solana-snapshot-finder/snapshot-finder.py --snapshot_path /root/ledger --max_download_speed 90 --min_download_speed 20 --num_of_retries 5 && systemctl start solana
else echo 'already restarting'
fi
