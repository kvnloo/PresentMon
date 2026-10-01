# PresentData ETL evidence packet

Upstream context: https://github.com/GameTechDev/PresentMon/issues/605

## Goal

Capture a machine-specific bad interval and determine whether ETL replay reproduces delayed/incomplete PresentData frame completion.

## Capture procedure

When a Windows test machine is available:

1. reproduce the frame-data drop / delayed-update symptom;
2. capture ETL during a known-bad interval;
3. capture synchronized PresentMon service/client logs;
4. note exact wall-clock start/end of the visibly bad interval;
5. replay the ETL;
6. check whether replay reproduces the same delayed completion behavior;
7. minimize to the shortest useful failing interval if practical.

## Metadata

Record:

- PresentMon commit/build
- Windows build
- CPU/GPU
- GPU driver
- display topology
- refresh / VRR
- application
- presentation mode
- overlay configuration

## Per-frame timeline

For affected frames, reconstruct:

```text
ETW event arrival
  -> PresentData state transition
  -> frame completion
  -> metric emission
```

Classify the earliest divergence as:

- unexpected event sequence;
- missing event;
- delayed event; or
- PresentData state-machine handling.

Do not infer root cause from zero-valued overlay samples alone.

## Deliverables

- [ ] ETL
- [ ] synchronized logs
- [ ] exact reproduction steps
- [ ] replay result
- [ ] shortest useful failing interval
- [ ] candidate regression fixture if deterministic
- [ ] upstream-ready evidence note for `GameTechDev/PresentMon#605`


## Ready-to-run wrapper

The repository's existing `Tools\\start_etl_collection.cmd` and
`Tools\\stop_etl_collection.cmd` are wrapped without changing their provider
set. Start/stop must run from an Administrator PowerShell.

```powershell
.\\experiments\\e2e-latency\\capture-etl.ps1 -Action start -OutputDir .\\latency-results\\bad-run
# Reproduce the issue briefly.
.\\experiments\\e2e-latency\\capture-etl.ps1 -Action stop -OutputDir .\\latency-results\\bad-run
.\\experiments\\e2e-latency\\capture-etl.ps1 -Action replay -OutputDir .\\latency-results\\bad-run -PresentMonExe <path-to-PresentMon.exe>
```

The directory retains the environment receipt, capture timestamps,
`trace.etl`, and `replay.csv`.
