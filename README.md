# F1 Race — DALI Multi-Agent Simulation

A Formula 1 race simulation built with the **DALI Multi-Agent System** framework.  
Two reactive agents — **Ferrari** and **McLaren** — communicate through the LINDA blackboard, exchanging race events across 5 simulated laps.

---

## Agents

| Agent | File | Car |
|-------|------|-----|
| `ferrari` | `mas/ferrari.txt` | Ferrari SF-24 |
| `mclaren` | `mas/mclaren.txt` | McLaren MCL38 |

### Race flow (event chain)

```
User ──send_message(start_race)──► Ferrari
                                       │ lap_1_done
                                       ▼
                                    McLaren
                                       │ lap_2_done
                                       ▼
                                    Ferrari  (pits!)
                                       │ ferrari_pitted
                                       ▼
                                    McLaren  (pits!)
                                       │ mclaren_pitted
                                       ▼
                                    Ferrari
                                       │ final_lap
                                       ▼
                                    McLaren
                                       │ finish
                                       ▼
                                    Ferrari  ✓ CHEQUERED FLAG
```

Each agent reacts to incoming events and fires the next event to its rival, simulating a 5-lap race.

---

## How to Run

### Linux / WSL (recommended)

```bash
cd DALI/Examples/f1_race
bash startmas.sh
```

Requirements: `tmux`, SICStus Prolog 4.6.0 installed at `/usr/local/sicstus4.6.0`.  
Edit `SICSTUS_HOME` in `startmas.sh` if your installation path differs.

### Windows (native)

1. Edit `startmas.bat` and set `sicstus_home` to your SICStus install path.
2. Double-click `startmas.bat`.

---

## Starting the Race

Once all windows/panes are open, in the **User Agent** window type:

```prolog
ferrari.
user.
send_message(start_race, user).
```

You will see the two agents exchanging messages across 5 laps.

### Expected output (summary)

```
Ferrari [LAP 1/5]: LIGHTS OUT AND AWAY WE GO! ...
McLaren [LAP 2/5]: Ferrari completed lap 1. Norris is matching pace! ...
Ferrari [LAP 3/5]: Gap to McLaren is 1.2 seconds. Box box box! ...
McLaren [LAP 3/5]: Ferrari in the pits! McLaren takes virtual P1! ...
Ferrari [LAP 4/5]: McLaren exits pit lane on hard tyres! ...
McLaren [LAP 5/5]: FINAL LAP! Norris goes for the overtake on DRS! ...
Ferrari [LAP 5/5]: CHEQUERED FLAG! Ferrari wins the Grand Prix! FORZA FERRARI!
```

---

## Shutdown

```bash
# Linux / WSL
pkill sicstus

# Windows
taskkill /IM spwin.exe /F
```

---

## Project Structure

```
f1_race/
├── startmas.sh          # Launch script for Linux/WSL
├── startmas.bat         # Launch script for Windows
├── mas/
│   ├── ferrari.txt      # Ferrari agent DALI source
│   └── mclaren.txt      # McLaren agent DALI source
├── conf/
│   ├── communication.con  # FIPA communication policy
│   ├── makeconf.sh / .bat # Generates agent config files
│   └── startagent.sh / .bat # Starts a single agent
├── work/                # Runtime: compiled agent files (auto-generated)
└── log/                 # Runtime: agent logs (auto-generated)
```

---

## DALI Syntax Reference (used in this project)

| Syntax | Meaning | Example |
|--------|---------|---------|
| `nameE:> Body.` | React to external event `name` | `start_raceE:> write('Go!').` |
| `messageA(agent, msg)` | Send a message to another agent | `messageA(mclaren, send_message(lap_done, ferrari)).` |
| `write(...)` | Print to console | `write('Ferrari pits!').` |
| `:- Goal.` | Directive (runs at load time) | `:- write('Agent ready!').` |

---

## Extending the Simulation

To add more events or cars:
1. Add a new `.txt` file in `mas/` with the agent's DALI rules.
2. Add corresponding event handlers in the other agents.
3. Re-run `startmas`.

Ideas for extension:
- Add a **Safety Car** agent that broadcasts `safety_car` events.
- Add **lap times** using DALI's `deltaT` time annotation.
- Add a **Race Director** agent managing flags (yellow, red, DRS zones).
