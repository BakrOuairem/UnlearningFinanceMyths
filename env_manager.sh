#!/bin/bash

# env_manager.sh
# A bash script to manage Python virtual environments using 'venv'.

# Function to display usage information for the script.
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Manage Python virtual environments."
    echo ""
    echo "Commands:"
    echo "  -c, --create      Create a new virtual environment."
    echo "  -d, --delete      Delete an existing virtual environment."
    echo "  -R, --run         Provide instructions to activate an environment."
    echo "  -S, --stop        Provide instructions to deactivate an environment."
    echo ""
    echo "Options:"
    echo "  -n <name>         Specify the name of the virtual environment (e.g., my_env)."
    echo "                    Required for -c, -d, and -R commands."
    echo "  -r <file>         Specify a requirements.txt file for package installation (used with -c)."
    echo "                    Optional for -c command."
    echo "  -h, --help        Display this help message."
    echo ""
    echo "Examples:"
    echo "  # Create a new environment named 'my_project_env' and install packages from requirements.txt"
    echo "  $0 -c -n my_project_env -r requirements.txt"
    echo ""
    echo "  # Delete an existing environment named 'my_project_env'"
    echo "  $0 -d -n my_project_env"
    echo ""
    echo "  # Get instructions to activate 'my_project_env'"
    echo "  $0 -R -n my_project_env"
    echo ""
    echo "  # Get instructions to deactivate the current environment"
    echo "  $0 -S"
    exit 1
}

# Initialize variables to store command and options.
VENV_NAME=""
REQUIREMENTS_FILE=""
COMMAND=""

# Parse command-line arguments using a while loop.
# This allows for flexible ordering of options and commands.
while (( "$#" )); do
    case "$1" in
        -c|--create)
            COMMAND="create"
            shift # Move to the next argument
            ;;
        -d|--delete)
            COMMAND="delete"
            shift
            ;;
        -R|--run)
            COMMAND="run"
            shift
            ;;
        -S|--stop)
            COMMAND="stop"
            shift
            ;;
        -n)
            # Check if the next argument exists and is not another option (starts with -)
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                VENV_NAME="$2"
                shift 2 # Consume both -n and its value
            else
                echo "Error: -n requires a non-empty argument (environment name)." >&2
                usage
            fi
            ;;
        -r)
            # Check if the next argument exists and is not another option (starts with -)
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                REQUIREMENTS_FILE="$2"
                shift 2 # Consume both -r and its value
            else
                echo "Error: -r requires a non-empty argument (requirements file path)." >&2
                usage
            fi
            ;;
        -h|--help)
            usage # Display help and exit
            ;;
        *)
            echo "Error: Unknown option or invalid argument '$1'." >&2
            usage # Display help and exit for unknown arguments
            ;;
    esac
done

# Function to create a Python virtual environment.
create_env() {
    # Ensure an environment name is provided.
    if [ -z "$VENV_NAME" ]; then
        echo "Error: Environment name (-n) is required for the 'create' command." >&2
        usage
    fi

    # Check if the virtual environment directory already exists.
    if [ -d "$VENV_NAME" ]; then
        echo "Environment '$VENV_NAME' already exists. Skipping creation."
        return 0 # Exit successfully as the environment already exists.
    fi

    echo "Creating virtual environment '$VENV_NAME'..."
    # Use python3 -m venv to create the environment.
    python3 -m venv "$VENV_NAME"

    # Check the exit status of the previous command.
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create virtual environment '$VENV_NAME'." >&2
        exit 1
    fi

    # If a requirements file is specified, install packages.
    if [ -n "$REQUIREMENTS_FILE" ]; then
        # Check if the requirements file actually exists.
        if [ ! -f "$REQUIREMENTS_FILE" ]; then
            echo "Warning: Requirements file '$REQUIREMENTS_FILE' not found. Skipping package installation." >&2
        else
            echo "Installing packages from '$REQUIREMENTS_FILE'..."
            # Activate the environment temporarily within this script's subshell
            # to ensure pip installs into the correct environment.
            source "$VENV_NAME/bin/activate"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to activate environment for package installation." >&2
                exit 1
            fi
            pip install -r "$REQUIREMENTS_FILE"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to install packages from '$REQUIREMENTS_FILE'. Please check the file content." >&2
                deactivate # Attempt to deactivate even on failure.
                exit 1
            fi
            deactivate # Deactivate the environment after installation.
        fi
    fi
    echo "Virtual environment '$VENV_NAME' created successfully."
}

# Function to delete a Python virtual environment.
delete_env() {
    # Ensure an environment name is provided.
    if [ -z "$VENV_NAME" ]; then
        echo "Error: Environment name (-n) is required for the 'delete' command." >&2
        usage
    fi

    # Check if the virtual environment directory exists before attempting to delete.
    if [ ! -d "$VENV_NAME" ]; then
        echo "Environment '$VENV_NAME' does not exist. Nothing to delete."
        return 0 # Exit successfully as there's nothing to do.
    fi

    echo "Deleting virtual environment '$VENV_NAME'..."
    # Remove the environment directory recursively and forcefully.
    rm -rf "$VENV_NAME"

    # Check the exit status of the previous command.
    if [ $? -ne 0 ]; then
        echo "Error: Failed to delete virtual environment '$VENV_NAME'." >&2
        exit 1
    fi
    echo "Virtual environment '$VENV_NAME' deleted successfully."
}

# Function to provide instructions for activating a virtual environment.
# A bash script cannot activate an environment for the parent shell directly.
run_env() {
    # Ensure an environment name is provided.
    if [ -z "$VENV_NAME" ]; then
        echo "Error: Environment name (-n) is required for the 'run' command." >&2
        usage
    fi

    # Check if the virtual environment directory exists.
    if [ ! -d "$VENV_NAME" ]; then
        echo "Error: Environment '$VENV_NAME' does not exist. Cannot provide activation instructions." >&2
        exit 1
    fi

    echo "To activate the environment '$VENV_NAME', run the following command in your terminal:"
    echo ""
    echo "    source $VENV_NAME/bin/activate"
    echo ""
    echo "Once activated, your terminal prompt will typically change to include '($VENV_NAME)'."
    echo "You can then run Python scripts or commands within this environment."
}

# Function to provide instructions for deactivating a virtual environment.
# Deactivation must be done manually in the shell where the environment is active.
stop_env() {
    echo "To deactivate the current virtual environment, run the following command in your terminal:"
    echo ""
    echo "    deactivate"
    echo ""
    echo "This command only works if a virtual environment is currently active in your shell."
    echo "If no environment is active, running 'deactivate' will do nothing or show an error."
}

# Main execution logic: Determine which command to run based on parsed arguments.
if [ -z "$COMMAND" ]; then
    echo "Error: No command specified. Please use -c (create), -d (delete), -R (run), or -S (stop)." >&2
    usage # Display usage if no command is given.
fi

case "$COMMAND" in
    create)
        create_env
        ;;
    delete)
        delete_env
        ;;
    run)
        run_env
        ;;
    stop)
        stop_env
        ;;
    *)
        # This case should ideally not be reached if argument parsing is correct,
        # but it's a fallback for safety.
        echo "Error: Invalid command '$COMMAND'." >&2
        usage
        ;;
esac