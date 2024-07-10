Here's a README.md file based on your instructions:

---

# Prerequisites

Ensure you have the following prerequisites installed:

- **bind**: Install using Homebrew:
  ```bash
  brew install bind
  ```

- **Python packages**: Install required Python packages:
  ```bash
  python3 -m pip install gremlinpython aiohttp==3.9.3 async-timeout==4.0.3
  ```

# Run

To create resources for your Neptune cluster, run the following command:

```bash
bash create.sh <neptune-cluster-name> [<domain-name>] [<neptune-sub-domain>]
```

Replace `<neptune cluster name>` with your Neptune cluster identifier. For example:

```bash
bash create.sh db-neptune-1 powerodd.com neptune-db.powerodd.com
```

# Test

After creating the Neptune resources, you can test the setup:

1. Use curl to check the status endpoint:
   ```bash
   curl https://neptune-db.powerodd.com:8182/status
   ```

2. Run the provided Python script to further test Neptune functionality:
   ```bash
   python3 test-neptune.py
   ```

# Destroy

To clean up and destroy the Neptune resources, use the following command:

```bash
bash destroy.sh
```

---

Feel free to adjust the commands and descriptions as needed for your specific setup and workflow.