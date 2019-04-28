#!/bin/bash

echo "Type your ssh user id:"
read ssh_user

echo "Type your ssh user pass:"
read -s ssh_pass

echo "Type your ssh public key (1-line):"
read pubkey

echo "Type your github token:"
read github_token

echo "Type your W3/IBMID id:"
read w3id

echo "Type your W3/IBMID password:"
read -s w3pass


echo ssh_user: "$ssh_user" > $HOME/.ansible_vault
echo ssh_pass: "$ssh_pass" >> $HOME/.ansible_vault
echo pubkey: "$pubkey" >> $HOME/.ansible_vault
echo github_token: "$github_token" >> $HOME/.ansible_vault
echo w3id: "$w3id" >> $HOME/.ansible_vault
echo w3pass: "$w3pass" >> $HOME/.ansible_vault

ansible-vault encrypt $HOME/.ansible_vault
