# Conveyor Sorting Line: CODESYS PLC + Node-RED HMI

A simulated conveyor sorting line. A PLC program written in IEC 61131-3 Structured Text
runs on the **CODESYS Control Win** soft PLC and talks over **Modbus TCP** to a
**Node-RED** dashboard. The dashboard also simulates the belt, the boxes and the sensors,
so the whole project runs on one PC with no hardware.

<!-- Add a screenshot of the running dashboard here:
![Dashboard](docs/dashboard.png)
-->

## What it does

Boxes travel along a belt past an inspection point with two sensors: a low sensor (S1)
that sees every box, and a high sensor (S2) that only sees tall boxes. Small boxes ride
to the end of the belt. Tall boxes are pushed into a side chute by a diverter.

```
 spawn -> [S1 low + S2 high] ---- travel delay ---- [DIVERTER] ---- [EXIT] -> end
                                                        |
                                                  tall-box chute
```

### PLC features

- Start / Stop / Reset with a seal-in circuit
- E-stop using normally-closed logic (a lost signal stops the belt)
- Box classification (small or tall) using a falling edge (`F_TRIG`) on S1
- Timed diverter pulse after a travel delay (`TON` timers)
- Counters: total, small, tall
- **Jam alarm:** S1 blocked for more than 3 s while running; latched until Reset
- **Diverter fail alarm:** no feedback within 300 ms of the divert command; latched until Reset

### Dashboard features

- Animated belt with boxes, sensor zones and diverter zone
- Lamps for RUN, JAM, DIVERTER FAULT, E-STOP
- Counters, including boxes pushed to the chute and boxes that reached the end
- START / STOP / RESET / SPAWN BOX buttons and an auto-spawn switch
- Fault-injection switches: E-stop, blocked sensor (jam), stuck diverter

## Architecture

```
Node-RED (belt simulation + dashboard)
        |  Modbus TCP, port 502
        |  write: holding register 0   (sensors + buttons packed into bits)
        |  read:  input registers 0-3  (status bits + counters)
CODESYS Control Win (ConveyorCtrl, Structured Text)
```

The control program only sees signals such as `s1_item` and `divert_cmd`. The simulation is
the "fake plant", so it could be replaced by real I/O without changing the control logic.
The full register layout is in [docs/modbus_map.md](docs/modbus_map.md).

## Requirements

- CODESYS V3.5 SP16 or newer with **CODESYS Control Win V3 x64** (the Modbus TCP Server
  Device package must be available in the Add Device list)
- Node.js 18 or newer (LTS) and Node-RED
- Node-RED packages: `node-red-contrib-modbus`, `node-red-dashboard`

## Setup

### 1. CODESYS

1. Create a Standard project with the device **CODESYS Control Win V3 x64** and ST as the language.
2. Add a Global Variable List named `GVL_Modbus` and paste [plc/GVL_Modbus.st](plc/GVL_Modbus.st).
3. Add a Program POU named `ConveyorCtrl` (Structured Text).
   - Top pane: [plc/ConveyorCtrl_declarations.st](plc/ConveyorCtrl_declarations.st)
   - Bottom pane: [plc/ConveyorCtrl_body.st](plc/ConveyorCtrl_body.st)
4. In `PLC_PRG`, call `ConveyorCtrl();`.
5. Add an **Ethernet** adapter under the device. Log out first, then set the **Network interface**
   to a connected adapter of your PC (Browse is greyed out while logged in).
6. Add a **Modbus_TCP_Server_Device** under the Ethernet adapter (port 502, unit ID 1).
7. In its I/O mapping, bind:
   - Holding register [0] to `GVL_Modbus.hr_inputs`
   - Input registers [0] to [3] to `hr_status`, `hr_total`, `hr_small`, `hr_tall`
8. Build (F11), log in (Alt+F8), and start (F5).

### 2. Node-RED

1. Install Node.js (LTS), then run:
   ```
   npm install -g --unsafe-perm node-red
   node-red
   ```
2. In the editor (`http://localhost:1880`), install `node-red-contrib-modbus` and `node-red-dashboard`
   through **Manage palette**.
3. Import a flow:
   - [node-red/conveyor_flow_full.json](node-red/conveyor_flow_full.json) if present: complete, with the Modbus nodes already wired.
   - [node-red/conveyor_flow.json](node-red/conveyor_flow.json): the simulation and dashboard only. Add a
     Modbus Read (FC4, address 0, quantity 4, 200 ms) connected to **Store PLC status**, and a Modbus Write
     (FC6, address 0) connected to the first output of **Simulation**. Server: `127.0.0.1`, port `502`, unit ID `1`.
4. Deploy and open `http://localhost:1880/ui`.

### 3. Try it

1. Click **START**: the RUN lamp turns green.
2. Click **SPAWN BOX** or switch on **Auto spawn boxes**.
3. Tall boxes are pushed off at the diverter and counted.
4. Try the fault switches, then clear them with **RESET** and **START**.

## Lessons learned

- **Holding vs input registers.** Mapping the written word to a holding register and the outputs to
  input registers keeps the direction of each signal clear.
- **Mapped variables get overwritten.** Once `hr_inputs` is bound to a Modbus register, typing a value
  in the CODESYS online view has no lasting effect. Node-RED must write it.
- **The soft PLC needs a network interface.** The Modbus server only started listening after the
  Ethernet adapter was linked to a real network interface.
- **Old Node.js versions fail.** Node 16 is too old for current Node-RED releases.
- **Timing ties the simulation to the PLC.** The belt speed and diverter position are chosen to match
  the PLC's 2 s travel delay.

## Limitations

- The PLC tracks **one box at a time**; the simulation spawns boxes accordingly.
- This is a simulation, **not a certified safety system**. A real line would need hardware safety
  circuits, for example a safety-rated E-stop.

## Ideas for extension

- FIFO queue to track several boxes at once
- Lost-box alarm using the exit sensor and a timeout
- Manual / Auto mode with a jog button
- Belt speed setpoint and a throughput (boxes per minute) trend chart
- Replace the simulation with real sensors and I/O

## License

MIT, see [LICENSE](LICENSE).
