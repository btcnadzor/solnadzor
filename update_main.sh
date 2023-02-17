solana-install init v1.14.15
sudo solana-sys-tuner --user $(whoami) > sys-tuner.log 2>&1 &
solana-validator wait-for-restart-window && sudo systemctl stop solana
sudo rm -rf /root/ledger/*
fstrim -av
source $HOME/solana-snapshot-finder/venv/bin/activate && python3 /root/solana-snapshot-finder/snapshot-finder.py --snapshot_path /root/ledger --max_download_speed 90 --min_download_speed 20 --num_of_retries 555
sudo systemctl start solana
deactivate
cd /root
solana-validator monitor
