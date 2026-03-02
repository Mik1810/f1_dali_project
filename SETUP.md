# Setup & How to Run

## System Requirements

| Component | Requirement |
|---|---|
| SICStus Prolog | 4.6.0 at `/usr/local/sicstus4.6.0` (Linux/WSL) |
| Shell | `bash`, `tmux` |
| Python | 3.8+ (for `generate_agents.py` and dashboard) |
| Flask | Auto-installed in a local venv by `ui/run.sh` |
| Docker | Optional; required only for the Docker-based deployment |

---

## How to Run

### Native (WSL / Linux) — Not recommended

The configurations can be a little messy because it requires the SICStus interpreter and the DALI logic, but here is a step-by-step guide:

1. Clone the DALI repo from https://github.com/AAAI-DISIM-UnivAQ/DALI and navigate to the `DALI/Examples` folder.
2. Clone the project repo from https://github.com/Mik1810/f1_race under the `Examples` folder.

Then execute the following commands:

```bash
cd DALI/Examples/f1_race
bash startmas.sh
```

`startmas.sh` performs the following steps:
1. Kills any stale SICStus / tmux processes on port 3010-3019.
2. Runs `generate_agents.py` to sync DALI files with `agents.json`.
3. Launches all agents inside a single `tmux` session named `f1_race`.

---

### Web Dashboard — Recommended

If you want to use the web dashboard, which provides real-time logs and an animated circuit view, run the following commands:

```bash
cd f1_race
bash ui/run.sh
```

`run.sh` creates a local Python venv (`ui/.venv`) on the first run and installs Flask automatically. Subsequent launches skip `pip install` via a stamp file (`.venv/.installed_stamp`) and start directly.

Open http://localhost:5000 in a browser. The dashboard shows all agent panes side-by-side with real-time auto-scrolling. If `agents.json` is modified while the dashboard is open, it auto-detects the change within 5 seconds and rebuilds the grid without a page reload.

#### Dashboard Controls

| UI element | Function |
|---|---|
| **Restart MAS** | Kills SICStus + tmux session, reruns `startmas.sh` |
| **Deploy SC** | Sends deploy message to safety car immediately |
| **Recall SC** | Recalls the safety car |
| Agent / Command bar | Sends an arbitrary Prolog command to any agent pane |
| Pin button (↓) | Toggles auto-scroll for that pane |
| Clear button (×) | Clears pane output |
| Minimise button (−) | Minimises pane to tray |

#### Circuit Tab

The dashboard exposes two tabs:

- **Logs**: the default view showing all agent panes side-by-side with real-time output.
- **Circuit**: an animated canvas visualisation of the race circuit.

Clicking a tab label switches the view instantly; no page reload is required. The `Logs` tab remains fully active in the background while the `Circuit` tab is open, so no agent output is ever lost.

The **Circuit tab** features include:

- **Start lights sequence**: five red lights illuminate one per second before going out at race start, matching the semaphore agent's timing.
- **Car tokens**: each car is drawn as a coloured dot with its team border glow, a lap-count badge, and a driver label. Position on track reflects the real fraction of the lap elapsed.
- **Pit-stop indicator**: a car entering the pit lane is shown as stationary in the pit area for the duration of the stop.
- **Live sidebar**: an always-visible leaderboard lists cars in current race order with their accumulated times, updated after every lap.
- **Final podium**: once the race ends and all animations have played out, a modal overlay shows the final standings with positions and total times.

---

## Docker Deployment

### Architecture

The Docker Compose setup runs two containers that share a tmux socket volume, allowing the dashboard to read agent panes with zero modifications to the agent logic.

```
┌─────────────────────┐        ┌─────────────────────┐
│  mas (ubuntu:22.04) │        │  ui (python:3.11)   │
│  startmas.sh        │        │  dashboard.py       │
│  → tmux f1_race     │        │  Flask :5000        │
│  SICStus (ro mount) │        │  reads tmux panes   │
└────────┬────────────┘        └──────────┬──────────┘
         │                                │
         └──────────┬─────────────────────┘
                    │
                tmux_sock volume
                /tmp/tmux-shared
```

**Startup order** (managed by Docker healthchecks):
1. `ui` starts immediately and is healthy once `/api/config` responds.
2. `mas` waits for `ui` to be healthy, then runs `startmas.sh`.

### Quickstart

1. Clone the DALI repo from https://github.com/AAAI-DISIM-UnivAQ/DALI, then checkout a known-working commit, and navigate to the `DALI/Examples` folder:
   ```bash
   git checkout 255abcac25db7fe43fdbf7945656240bd61d25f2
   ```
2. Clone the project repo from https://github.com/Mik1810/f1_race under the `Examples` folder.

Then execute the following commands:

```bash
# 1. Navigate to the project folder
cd DALI/Examples/f1_race

# 2. Auto-detect SICStus and write .env  (run once)
bash docker/setup.sh

# 3. Build and start
docker compose up --build -d
```

The containers need a few seconds to start up and run the agents. Once ready, open http://localhost:5000 in a browser to view the dashboard.

### Environment Variables

The `mas` container needs the `SICSTUS_PATH` environment variable to locate the SICStus installation. This is set in `docker-compose.yml` and can be configured via a `.env` file in the project root. The setup is done by the `docker/setup.sh` script, which auto-detects the SICStus path on the host and writes it to `.env`. If needed, the variable can be set manually:

| Variable | Default | Description |
|---|---|---|
| `SICSTUS_PATH` | `/usr/local/sicstus4.6.0` | Host path to SICStus install, mounted read-only into the `mas` container |
