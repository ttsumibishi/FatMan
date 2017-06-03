#!/bin/bash

cd ~lmdracos/blindies
until /home/lmdracos/blindies/blindies.rb; do
    echo "Blindies crashed with exit code $?.  Respawning.." >&2
    sleep 2
done
