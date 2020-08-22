#!/usr/bin/env bash

source venv/bin/activate

ansible-playbook --vault-password-file ~/.ansible/vault/default_key.txt -i hosts main.yml
