# Intesis FJ-RC-WMP-1 (Fujitsu HVAC) Driver for BLI Gen 3

This driver provides a native IP integration for **Fujitsu RAC/VRF systems** using the **Intesis FJ-RC-WMP-1** WiFi Management Protocol (WMP) gateway.

## Features
- **Bidirectional Control**: Power, Setpoint, Mode, and Fan Speed.
- **Real-time Feedback**: Ambient temperature and status updates.
- **Fujitsu Specifics**: Filter cleaning alerts and system error code reporting.
- **Auto-Discovery**: Support for BLI UDP discovery (Port 3310).
- **Multi-Unit Support**: Integration for systems with multiple indoor units.

## Hardware Configuration
1. Ensure the **FJ-RC-WMP-1** is connected to the Fujitsu 3-wire BWR bus.
2. Connect the gateway to your local network via WiFi using the [Intesis configuration tool](https://www.intesis.com).
3. **Important**: Verify the **Internal Unit ID** (usually `1`) assigned to the AC unit in the Intesis web interface.

## BLI Setup Instructions
1. Upload the `.bli` package to your **BeoLiving Intelligence** via `Settings -> Systems -> Custom Drivers`.
2. Click **Add System** and select **Intesis WMP HVAC Gateway**.
3. Use the **Discovery** button to find the gateway on your network, or manually enter the **IP Address**.
4. Add a resource of type **AC Indoor Unit**.
5. In the resource parameters, enter the **Intesis Unit ID** (default is `1`).

## Resource States & Events
- **Power**: ON/OFF control.
- **Mode**: Heat, Cool, Dry, Fan, Auto.
- **Fan Speed**: Low, Medium, High, Auto.
- **Filter Alarm**: Boolean state indicating if the Fujitsu filter needs cleaning.
- **Error Code**: Displays Fujitsu system faults (e.g., `COMM` errors).

## **Intesis WMP to BeoLiving Intelligence (BLI) Mapping**

To ensure the BLI interface displays the correct icons and controls, the following mappings are used between the **Intesis ASCII** strings and the **BLI Climate Resource** states.

#### **1. Operation Mode Mapping (`MODE`)**

| Intesis Value | BLI State Value | Description |
| :--- | :--- | :--- |
| `HEAT` | `Heat` | Heating mode |
| `COOL` | `Cool` | Cooling mode |
| `DRY` | `Dry` | Dehumidification |
| `FAN` | `Fan` | Ventilation only |
| `AUTO` | `Auto` | Automatic mode |

#### **2. Fan Speed Mapping (`FANSP`)**

| Intesis Value | BLI State Value |
| :--- | :--- |
| `1` | `Low` |
| `2` | `Medium` |
| `3` | `High` |
| `4` | `Top` (if supported) |
| `AUTO` | `Auto` |

#### **3. Vane/Louver Position (`VANE`)**

| Intesis Value | BLI State Value |
| :--- | :--- |
| `1` to `5` | `Step 1` to `Step 5` |
| `SWING` | `Swing` |
| `AUTO` | `Auto` |

---

> **Note:** When sending commands from BLI to Intesis, the driver converts these values back to uppercase (e.g., `Heat` becomes `HEAT`) and terminates with a `\r` character per the [Intesis WMP Specification](https://www.hms-networks.com).


## Technical Notes
- **Protocol**: ASCII over TCP/IP (Port 3310).
- **Keep-Alive**: The driver sends an `ID` command every 45 seconds to prevent the Intesis 60-second idle timeout.
- **Temperature Scaling**: Temperatures are handled with 1-decimal precision (multiplied/divided by 10) per [Intesis WMP Specifications](https://www.hms-networks.com).

## Support
For technical protocol details, refer to the [HMS Networks WMP Documentation](https://www.hms-networks.com).
