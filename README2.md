# Intesis FJ-RC-WMP-1 (Fujitsu) Driver for BeoLiving Intelligence Gen 3

This driver provides a native IP integration for **Fujitsu RAC and VRF systems** using the **Intesis FJ-RC-WMP-1** WiFi Management Protocol (WMP) gateway.

## 📂 Project Structure
For the `.bli` package, ensure your directory is structured as follows:
- `manifest.json` (Driver configuration)
- `driver.lua` (Main logic)
- `README.md` (This file)
- `icon.png` (512x512 PNG icon)

## 🚀 Features
- **Full Control**: Power, Setpoint, Mode, and Fan Speed.
- **Bi-directional Feedback**: Real-time updates for ambient temperature and AC status.
- **Fujitsu Specifics**: Maintenance alerts (Filter Clean) and System Error Code reporting.
- **Auto-Discovery**: Supports BLI UDP Discovery on Port 3310.
- **Keep-Alive**: Automatic 45-second heartbeat to prevent Intesis 60s socket timeout.

## 🛠 Hardware Setup
1. Connect the **FJ-RC-WMP-1** to the Fujitsu 3-wire BWR bus.
2. Configure the gateway's WiFi using the [Intesis Maps Tool](https://www.intesis.com).
3. Ensure the gateway has a **Static IP** on your local network.

## ⚙️ BLI Configuration
1. Upload the `.bli` package via **Settings > Systems > Custom Drivers**.
2. Add a new System and select **Intesis WMP HVAC Gateway**.
3. Use **Discovery** or manually enter the Gateway IP (Port 3310).
4. Add a Resource of type **AC Indoor Unit**.
5. Set the **Unit ID** (Parameter) to match your Fujitsu unit (usually `1`).

## 📊 Mapping Tables

### Operation Modes

| Intesis Value | BLI State |
| :--- | :--- |
| `HEAT` | `Heat` |
| `COOL` | `Cool` |
| `DRY` | `Dry` |
| `FAN` | `Fan` |
| `AUTO` | `Auto` |

### Fan Speeds

| Intesis Value | BLI State |
| :--- | :--- |
| `1`, `2`, `3` | `Low`, `Medium`, `High` |
| `AUTO` | `Auto` |

## 🔍 Troubleshooting
- **Connection Drops**: The [Intesis WMP Protocol](https://www.hms-networks.com) drops idle TCP connections after 60s. The driver's internal timer handles this; verify the "ID" command is visible in the BLI Monitor.
- **Temperature Errors**: Temperatures are sent/received as integers (e.g., 22.5°C = 225). The driver automatically handles this scaling.
- **Filter Sign**: If the `filter_alarm` state is active, clean the unit filter and use the **Reset Filter** event in the BLI app.

---
*Developed for BeoLiving Intelligence Gen 3 environments.*
