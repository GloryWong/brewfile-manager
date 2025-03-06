# brewfile-manager

Homebrew Brewfile upload, download and install

## Upload

Execute below command will:
1. Create or update Brewfile in local
2. Upload the Brewfile to the given gist

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/GloryWong/brewfile-manager/HEAD/upload.sh)"
```

> You will be prompted to enter a gist id and the github access token. So you need to have a gist or [create new gist](https://gist.github.com/) and use the gist id (the last part of the page url); you need to have a [personal access token](https://github.com/settings/tokens) and make sure the **Create gists** permission is checked.

## Download and install

Todo...