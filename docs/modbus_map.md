# Modbus register map

Modbus TCP, CODESYS Control Win V3 x64 as **server** (slave), Node-RED as **client** (master).
Host `127.0.0.1`, port `502`, unit ID `1`. Addresses below are 0-based on the wire.

| Direction | Type | Address | Variable | Modbus function |
|---|---|---|---|---|
| Node-RED -> PLC | Holding register | 0 | `GVL_Modbus.hr_inputs` | FC6 write |
| PLC -> Node-RED | Input register | 0 | `GVL_Modbus.hr_status` | FC4 read |
| PLC -> Node-RED | Input register | 1 | `GVL_Modbus.hr_total` | FC4 read |
| PLC -> Node-RED | Input register | 2 | `GVL_Modbus.hr_small` | FC4 read |
| PLC -> Node-RED | Input register | 3 | `GVL_Modbus.hr_tall` | FC4 read |

Node-RED reads input registers 0 to 3 in one request (FC4, address 0, quantity 4, every 200 ms).

## `hr_inputs` (holding register 0)

| Bit | Value | Signal |
|---|---|---|
| 0 | 1 | S1 entry sensor (any box) |
| 1 | 2 | S2 tall sensor |
| 2 | 4 | S_EXIT sensor |
| 3 | 8 | Diverter feedback |
| 4 | 16 | E-stop healthy (1 = OK, 0 = pressed) |
| 5 | 32 | Start button |
| 6 | 64 | Stop button |
| 7 | 128 | Reset button |

Example: `16` = E-stop OK, nothing pressed. `48` = E-stop OK + Start.

## `hr_status` (input register 0)

| Bit | Value | Meaning |
|---|---|---|
| 0 | 1 | Motor running |
| 1 | 2 | Divert command active |
| 2 | 4 | Jam alarm (latched) |
| 3 | 8 | Diverter fail alarm (latched) |

Values add up: `9` = motor running + diverter fail.

## Important

Because `hr_inputs` is bound to the holding register, the Modbus server rewrites it
every PLC cycle. Values typed into it in the CODESYS online view are overwritten.
In this setup, Node-RED is the only writer of `hr_inputs`.
