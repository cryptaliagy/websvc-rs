compose_cmd := "docker compose"
service := "websvc"

# Builds the specified docker container target. The default target is `dev`
build *args:
    {{ compose_cmd }} build {{ args }}

# Runs the service with `docker compose up`
up *args:
    {{ compose_cmd }} up {{ args }}

# Runs the specified command (default being starting the service), removing the container after exiting
run *args:
    {{ compose_cmd }} run {{ service }} {{ args }}

# Removes all running services
down *args:
    {{ compose_cmd }} down {{ args }}

# Executes a command in the running container. Note, this requires a container to already be running i.e. through `just up -d`
exec *args:
    {{ compose_cmd }} exec {{ service }} {{ args }}

# Executes the tests for the service inside the docker container. This must be run in either the dev or builder container, since 
# debug and prod don't have `cargo` installed.
test *args:
    just run bash -c '"cargo test --target $(arch)-unknown-linux-musl {{ args }}"'



alias b := build
alias bd := build
alias u := up
alias r := run
alias d := down
alias e := exec
alias t := test