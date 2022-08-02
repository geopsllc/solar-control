# Core v4 Management Tool

## Installation

```sh
git clone https://github.com/geopsllc/solar-control -b testnet
cd core-control
./ccontrol.sh arg1 [arg2]
```

| arg1 | arg2 | Description |
| --- | --- | --- |
| `install` | `core` | Install Core |
| `reinstall` | `core` | Reinstall Core |
| `update` | `core`/`self`/`check` | Update Core / Core-Control / Check |
| `remove` | `core`/`self` | Remove Core / Core-Control |
| `secret` | `set`/`clear` | Delegate Secret Set / Clear |
| `start` | `relay`/`forger`/`all` | Start Core Services |
| `restart` | `relay`/`forger`/`all`/`safe` | Restart Core Services |
| `stop` | `relay`/`forger`/`all` | Stop Core Services |
| `status` | `relay`/`forger`/`all` | Show Core Services Status |
| `logs` | `relay`/`forger`/`all` | Show Core Logs |
| `system` | `info`/`update` | System Info / Update |
| `config` | `reset` | Reset Config Files to Defaults |
| `rollback` | | Rollback to Specified Height |

## General
This is a Streamlined CLI-Based Core v4 Management Tool. 
- Installs fail2ban for ssh, and ufw allowing only ssh and the cores ports.
- For start/restart/stop/status/logs you can skip the 'all' argument as it's the default.
- For install/reinstall you can skip the 'core' argument as it's the default.
- For update you can skip the 'check' argument as it's the default.
- For system you can skip the 'info' argument as it's the default.
- Using the 'restart safe' arguments requires the round-monitor core plugin and restarts the core services when safe to do so in 
order to avoid missing a block.
- When setting a delegate secret just type your secret after the 'set' argument without quotes.
- When doing a rollback just type the desired height after the 'rollback' argument.
- Rollback will stop the running processes, do the rollback and start the processes that were online.
- The script adds an alias named 'ccontrol' on first run. On your next shell login you'll be able to call the script from anywhere
using: ccontrol arg1 [arg2]. It also has autocomplete functionality for all possible arguments.
- Using the 'config reset' arguments will stop the core processes, delete your existing configs and replace them with the defaults.
If you're running a forger and/or have custom settings, you should add them again.
- On first run the tool exposes the core-cli with the project name, e.g. ark for project Ark. It will be accessible after logout.
- Do not run as root!

## Changelog

### 4.0
- updated for Solar Core 4.x

### 3.2
- initial release

## Security

If you discover a security vulnerability within this package, please open an issue. All security vulnerabilities will be promptly addressed.

## Credits

- [All Contributors](../../contributors)
- [Georgi Stoyanov](https://github.com/geopsllc)

## License

[MIT](LICENSE) © [geopsllc](https://github.com/geopsllc)
