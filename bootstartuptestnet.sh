#!/bin/bash
python3exit=1
solanawork=1
ps -A | grep solana-valid || solanawork=0
if [[ $solanawork == 0 ]]
	then
	ps -A | grep python3 || python3exit=0
	if [[ $python3exit == 0 ]]
		then
		echo 'solana rebooting'
		systemctl stop solana 
		rm -rf /root/ledger/*
		fstrim -av 
		source $HOME/solana-snapshot-finder/venv/bin/activate
		python3 /root/solana-snapshot-finder/snapshot-finder.py --snapshot_path /root/ledger -r https://api.testnet.solana.com --max_download_speed 90 --min_download_speed 20 --num_of_retries 5
		systemctl start solana
		deactivate
		else echo 'solana already restarting'
	fi
else echo 'solana work'
fi
