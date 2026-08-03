# JD Desk Hub Agent

This optional macOS helper runs explicit, user-defined profiles. It is deliberately separate from PIV authentication and needs no administrator rights.

Install a config:

```sh
mkdir -p "$HOME/Library/Application Support/JD Desk Hub"
cp automation/config.example.json "$HOME/Library/Application Support/JD Desk Hub/config.json"
```

Review and edit the profile names/actions, then test without launching anything:

```sh
python3 automation/desk_hub_agent.py --dry-run run work
```

Run:

```sh
python3 automation/desk_hub_agent.py run work
```

For Home Assistant or other privileged integrations, use a named macOS Shortcut whose credential is stored in Keychain. Do not put tokens in the JSON file. The agent rejects arbitrary shell commands and allows only apps, `http`/`https` URLs, named Shortcuts, and bounded delays.

A future F18/F19/F20 firmware gesture can invoke these profiles through macOS Shortcuts. V1 does not treat a raw sensor touch as authorization.
