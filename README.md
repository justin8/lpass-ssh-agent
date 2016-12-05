# Lastpass ssh-agent Keyring

This script allows you to use passphrase protected SSH Keys which are unlocked by your Lastpass account. 

It saves you from having to remember many different passphrases and enter them every time you SSH into a host. Instead once every hour when you open a new terminal it will prompt you for your lastpass passphrase then every ssh-key will be automatically decrypted using their respective passphrases which are stored in your lastpass account. 

You can add new keys with a randomly generated passphrase or add a phrase to an existing key you have. 

It also works with Cloud9 (naturally). 

## Installation

```
git clone https://github.com/justin8/lpass-ssh-agent.git
cd lpass-ssh-agent
./keyring.sh install
```

## Usage

`./keyring.sh add-key ~/.ssh/[keyfile]` - Add an existing ssh key to the keyring

## License

MIT
