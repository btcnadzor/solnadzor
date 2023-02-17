#!/bin/bash
ps -A | grep solana || systemctl stop solana && rm -rf /root/ledger/* && fstrim -av && source $HOME/solana-snapshot-finder/venv/bin/activate && python3 /root/solana-snapshot-finder/snapshot-finder.py --snapshot_path /root/ledger --max_download_speed 90 --min_download_speed 20 --num_of_retries 111 && systemctl start solana
