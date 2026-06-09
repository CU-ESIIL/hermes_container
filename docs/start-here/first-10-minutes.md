# First 10 Minutes

## 1. Prepare local settings

```bash
cp .env.example .env
```

## 2. Initialize the workspace

```bash
make init-working-group
make doctor
```

## 3. Build and launch

```bash
make build
make up
```

## 4. Open the interfaces

- Hermes gateway: `http://127.0.0.1:18789`
- Filesystem and GitHub manager: `http://127.0.0.1:8090`
- JupyterLab: `http://127.0.0.1:8888/lab?token=hermes`

## 5. Validate the appliance

```bash
scripts/check_auth.sh
make smoke-test
```

You should now have a running Hermes workbench, a visible workspace, and a verified local runtime.
