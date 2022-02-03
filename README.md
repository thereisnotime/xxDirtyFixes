# xxDirtyFixes
Collection of various dirty fixes


## Pritunl "Monitor"
- Runs every 5 minutes by default with systemd (systemctl status xxpritunl-monitor)
- Restarts pritunl and mongod services every 5 minutes if they are down
- Reissues SSL and restarts the pritunl service if https://localhost does not open the Pritunl web interface

Oneliner setup:
```bash
bash <(curl -s https://raw.githubusercontent.com/thereisnotime/xxDirtyFixes/master/xxpritunl-monitor.sh)
```
