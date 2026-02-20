# F1 Race — DALI Multi-Agent Simulation

A Formula 1 race simulation built with the **DALI Multi-Agent System** framework.  
Four reactive agents communicate through the LINDA blackboard. The **Pit Wall** coordinates the race flow and generates **probabilistic events** (safety car, rain) automatically — no user injection required.

---

## Agents

| Agent | Instance | Type | Ruolo |
|-------|----------|------|-------|
| `semaphore` | `mas/instances/semaphore.txt` | `semaphoreType` | Raccoglie i segnali `ready`, esegue la sequenza luci F1 e avvia la gara |
| `ferrari` | `mas/instances/ferrari.txt` | `ferrariCar` | Auto Ferrari SF-24 |
| `mclaren` | `mas/instances/mclaren.txt` | `mclarenCar` | Auto McLaren MCL38 |
| `pitwall` | `mas/instances/pitwall.txt` | `pitWallType` | Muretto box, coordinatore e generatore di eventi casuali |
| `safety_car` | `mas/instances/safety_car.txt` | `safetyCarType` | Safety car |

### Race flow (5 laps, alternating turns)

```
All agents ──send_message(ready)──► Semaphore
                                        │ (waits 4/4 ready signals)
                                        │ send_message(start_race)
                                        ▼
                                    Ferrari  ── lap_done_ferrari ──►  PitWall
                                                                          │ rolls random lap time
                                                                          │ lap_go_mclaren
                                                                          ▼
                                                                      McLaren  ── lap_done_mclaren ──►  PitWall
                                                                                                            │ rolls random lap time
                                                                                                            │ random_track_event (SC / Rain / clear)
                                                                                                            │ prints standings
                                                                                                            │ if lap < 5: lap_go_ferrari
                                                                                                            │ if lap = 5: declare_winner
                                                                                                            ▼
                                                                                                        ...repeat 5 times...
```

At any point a car's **internal event** (`engine_failureI` or `push_lapI`) can fire autonomously and send a message to PitWall, interrupting the normal flow.

---

### Timing system (lower total time = winner)

| Event | Time change |
|---|---|
| Each lap | `+ random(60..90)` seconds |
| Pit stop | `+ 25s` |
| Safety car (20% chance per lap) | `+ 10s` to both cars |
| Heavy rain (20% chance per lap) | `+ 5s` to both cars |
| Push lap (internal event, 10% chance) | `- 3s` |
| Engine failure / DNF (internal event, 0.2% chance) | `time = 9999s` → race ends immediately |

---

### DALI event types used

**External events** (`nameE:>`) — reactive, triggered by a message from another agent:
- `start_raceE` — lights out signal from semaphore; asserts `race_started` and sends first lap
- `lap_go_ferrariE`, `lap_go_mclarenE` — pitwall tells a car to begin its next lap
- `lap_done_ferrariE`, `lap_done_mclarenE` — car finishes a lap; pitwall adds random lap time
- `pit_done_ferrariE`, `pit_done_mclarenE` — car finishes a pit stop; pitwall adds +25s
- `ferrari_engine_failureE`, `mclaren_engine_failureE` — DNF notification; sets time to 9999s
- `ferrari_push_lapE`, `mclaren_push_lapE` — fastest-lap bonus; subtracts 3s
- `race_endE` — sent by pitwall to ferrari/mclaren after `declare_winner`; asserts local `race_over` to stop internal events
- `rain_warningE`, `safety_car_deployedE`, `retire_*E` — cosmetic notifications to car agents

**Internal events** (`nameI:>`) — proactive, fire when a condition becomes true:
```prolog
% In ferrariCar.txt / mclarenCar.txt
engine_failure_ferrari :-
    race_started,                       % only after race begins
    \+ race_over,                       % only while race is live
    \+ engine_failure_ferrari_fired,    % fire at most once
    random(0, 1000, R), R < 2.        
engine_failure_ferrariI:>
    assert(engine_failure_ferrari_fired),
    send_m(pitwall, send_message(ferrari_engine_failure, ferrari)).

push_lap_ferrari :-
    race_started,
    \+ race_over,
    random(0, 100, R), R < 10.
push_lap_ferrariI:>
    send_m(pitwall, send_message(ferrari_push_lap, ferrari)).
```

**Non-determinism** — `random_track_event/0` in PitWall, rolled after every McLaren lap:
```prolog
random_track_event :-
    random(0, 10, R),
    if(R < 2, /* 20% SAFETY CAR */, if(R < 4, /* 20% RAIN */, /* 60% clear */)).
```

---

## How to Run

### 1 — Start the MAS (WSL / Linux) (not reccomended)

```bash
cd DALI/Examples/f1_race
bash startmas.sh
```

Requirements: `tmux` and SICStus Prolog 4.6.0 at `/usr/local/sicstus4.6.0`.

### 2 — Launch the Web Dashboard (recommended)

In a **second WSL terminal** (leave the MAS running):

```bash
cd DALI/Examples/f1_race
bash ui/run.sh
```

`run.sh` creates a local Python venv (`ui/.venv`) on first run and installs Flask automatically — no system-wide pip needed.

Then open **http://localhost:5000** in your browser.

The dashboard shows all 6 agent panes side-by-side, auto-scrolling in real time.  
Use the toolbar buttons to control the race — no tmux scrolling needed.

### 3 — Start the Race

The race starts **automatically** when hitted the **&#8635; Restart MAS** button. As each agent initialises, it sends a `ready` message
to the `semaphore` agent. Once all 4 agents (ferrari, mclaren, pitwall, safety_car)
have reported ready, the semaphore runs the F1 lights sequence (5 lights on, 2 s pause,
lights out) and then fires `start_race` automatically.

---

## Dashboard Features

| UI element | Function |
|---|---|
| **&#8635; Restart MAS** | Sends `pkill sicstus` + `restartmas.sh` |
| **⚠ Deploy SC** | Deploys the safety car immediately |
| **✓ Recall SC** | Recalls the safety car |
| **Agent: / Command:** bar | Send any arbitrary Prolog command to any agent pane |
| ↓ pin button (top-right of each pane) | Toggle auto-scroll for that pane |
| x button (top-right of each pane) | clear the console output |
| - button (top-right of each pane) | minimize the console |

---

## Shutdown

```bash
tmux kill-session -t f1_race   # stop the MAS
# Ctrl+C in the dashboard terminal to stop Flask
```

---

## Project Structure

```
f1_race/
├── startmas.sh          # Launch script for Linux/WSL
├── ui/
│   ├── dashboard.py     # Web dashboard (Flask, polls tmux panes)
│   ├── run.sh           # Wrapper: creates venv + launches dashboard
│   └── requirements.txt # pip: flask
├── mas/
│   ├── instances/
│   │   ├── semaphore.txt    # → semaphoreType
│   │   ├── ferrari.txt      # → ferrariCar
│   │   ├── mclaren.txt      # → mclarenCar
│   │   ├── pitwall.txt      # → pitWallType
│   │   └── safety_car.txt   # → safetyCarType
│   └── types/
│       ├── semaphoreType.txt   # Sequenza luci F1, poi lancia start_race
│       ├── ferrariCar.txt   # Ferrari DALI logic
│       ├── mclarenCar.txt   # McLaren DALI logic
│       ├── pitWallType.txt  # Pit wall coordinator + random event generator
│       └── safetyCarType.txt # Safety car logic
├── conf/
│   ├── communication.con    # FIPA communication policy
│   ├── makeconf.sh / .bat   # Generates agent config files
│   └── startagent.sh / .bat # Starts a single agent
├── build/               # Runtime: merged type+instance files (auto-generated)
├── work/                # Runtime: compiled agent files (auto-generated)
└── log/                 # Runtime: agent logs (auto-generated)
```

---

## DALI Syntax Reference (used in this project)

| Syntax | Meaning | Example |
|--------|---------|---------|
| `nameE:> Body.` | React to external event `name` | `start_raceE:> write('Go!').` |
| `messageA(agent, msg)` | Send a message (top-level only) | `messageA(mclaren, send_message(lap_done, ferrari)).` |
| `send_m(agent, msg)` | Send a message (safe inside `if/3`) | `send_m(safety_car, send_message(deploy, pitwall)).` |
| `random(Low, High, R)` | Random integer `Low =< R < High` | `random(0, 10, R).` |
| `if(Cond, Then, Else)` | Conditional | `if(R < 5, send_m(...), true).` |
| `\+ Goal` | Negation-as-failure (succeeds if Goal fails) | `\+ race_over` |
| `:- Goal.` | Directive (runs at load time) | `:- write('Agent ready!').` |
