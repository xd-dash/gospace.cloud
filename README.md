# gospace.cloud

Pinned composition of the qualified `xd-dash/pyspace` Python 3.12 Gen1 host and `dash-xd/gospace` Go/WASM runtime.

`default.xml` is an Android `repo` manifest. Both projects are pinned to immutable commit SHAs; `repo sync -c` therefore reconstructs the exact qualified source pair rather than following development branches.

## Materialize the composition

From an empty workspace:

```sh
repo init -u https://github.com/xd-dash/gospace.cloud.git -m default.xml
repo sync -c
```

The resulting tree is:

```text
pyspace/   # xd-dash/pyspace hardcopy

gospace/   # dash-xd/gospace runtime
```

The pinned pyspace hardcopy was promoted from `dash-xd/pyspace-minimal` commit `d35454f76009a31511986c69ea5a3a6e17a0ca44` after Huram exact-pair qualification run `33489648752`. The manifest pins its parentless canonical hardcopy commit `0414a1d66c5fffa279a9666185c46825cc5caaa2`. Gospace is pinned to `ce45df85bf49c4bd398a8722c73dcc7cc3c07ed5`.

## Lightweight Gen1 deployment

The deployment bundles a Linux/amd64 gospace binary into the Python source tree and deploys pyspace as the Cloud Function:

```sh
export GCLOUD_PROJECT_ID=your-project
export GCLOUD_REGION=us-west1
export FUNCTION_NAME=gospace
bash deploy.sh
```

`PYSPACE_GOSPACE_BINARY=/workspace/bin/gospace` is set at deployment time. Pyspace registers that backend during function initialization but does not start the process then. `ProcessSupervisor` lazy-starts gospace on the first request that reaches the gospace fallback and reuses it while the Cloud Functions instance remains warm.

No public control token is configured by this lightweight deployment. Pyspace creates a private per-instance gospace token for its local resolver. If remote runtime loading of Python modules or cold WASM is required, inject `PYSPACE_CONTROL_TOKEN` and/or `GOSPACE_CONTROL_TOKEN` through the deployment's secret-management path rather than committing credentials to this repository.

The function is private by default (`--no-allow-unauthenticated`).
