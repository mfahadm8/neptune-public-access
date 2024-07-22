Here's a README.md file based on your instructions:

---

# Prerequisites

Ensure you have the following prerequisites installed:

- **zip**: Install using Homebrew:
  ```bash
  brew install unzip zip
  ```

# Run

To create resources for your Neptune cluster, run the following command:

```bash
bash create.sh <lambda-function-name> <add-vpc (true/false)> <neptune cluster name>]
```

Replace `<neptune cluster name>` with your Neptune cluster identifier. For example:

```bash
bash create.sh PostConfirmationTrigger true db-neptune-1
```

# Destroy

To clean up and destroy the Neptune resources, use the following command:

```bash
bash destroy.sh
```

---

Feel free to adjust the commands and descriptions as needed for your specific setup and workflow.