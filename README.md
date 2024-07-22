Here's a README.md file based on your instructions:

---

# Prerequisites

Ensure you have the following prerequisites installed:

- **zip**: Install using Homebrew:
  ```bash
  brew install unzip zip
  ```

- Make sure that for each of the folder, the structure looks like:
  **LambdaFunctionName/src** 
    - index.js
      - index.handler

# Run

To create resources for your Neptune cluster, run the following command:

```bash
bash create.sh <lambda-function-name> <add-vpc (true/false)> <neptune cluster name>]
```

Replace `<neptune cluster name>` with your Neptune cluster identifier. For example:

```bash
bash create.sh PostConfirmationTrigger2 true db-neptune-1
```
