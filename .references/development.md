# Development

## Podman

Install [Podman Desktop](https://podman-desktop.io/docs/installation/macos-install).
Complete onboarding to create and start a Podman machine.
Java and Gradle run inside the build container.

From the project directory:

```sh
podman build -t localhost/srecore:dev .
podman run -d --name srecore --memory=512m \
  -p 127.0.0.1:8080:8080 localhost/srecore:dev
```

Open http://localhost:8080/ for the landing page or
http://localhost:8080/docs for API documentation.

```sh
podman logs srecore
curl --fail http://localhost:8080/actuator/health
podman stop srecore
```

Use `podman start srecore` to restart it. After code changes, build again,
stop and remove the old container with `podman rm srecore`, then repeat the run
command. In-memory database contents disappear when the application stops.

## VS Code Dev Containers

Open this project in a VS Code development container when working on the code.
The Podman commands above run the packaged application separately.

The root `Dockerfile` builds and tests the app, then packages it in a Java runtime
image. `.devcontainer/Dockerfile` provides Java, Git, and the SSH client for VS Code.
VS Code mounts the source folder, and you run Gradle as needed. Keep the Java
version in both Dockerfiles aligned with the Gradle toolchain.

1. Install the **Dev Containers** extension in VS Code.
2. In VS Code user settings, set `dev.containers.dockerPath` to `podman`.
3. Start the Podman machine with `podman machine start` if it is stopped.
4. Open the project folder in VS Code. Run **Dev Containers: Reopen in Container**
   from the Command Palette. VS Code builds and starts the development container.
5. In the container's terminal, run `./gradlew bootRun` to start the application.

Open http://localhost:8080/. Stop any separately running application container
first with `podman stop srecore` on the host so port 8080 is available.
Press Ctrl+C in the container terminal to stop the application.

The `.devcontainer` configuration is local and Git-ignored. On a fresh checkout,
create it with **Dev Containers: Add Dev Container Configuration Files**, using
a Java 25 development Dockerfile in `.devcontainer`, with this build configuration
and forwarding port 8080:

```json
"build": {
  "dockerfile": "Dockerfile"
}
```

Existing configurations may also require local
Git configuration files and signing mounts; make sure their source paths exist
before opening the container. Keep personal settings out of Git.

After changing the container configuration, run **Dev Containers: Rebuild Container**.
See [VS Code's Podman setup](https://code.visualstudio.com/remote/advancedcontainers/docker-options).

## Git signing

The development container needs `openssh-client`: Git uses its `ssh-keygen`
command to sign commits. The application container does not need it.

The current setup uses a signing key copied into the development container:

1. Keep an SSH signing key pair outside the repository, named `id_ed25519`
   and `id_ed25519.pub`.
2. In the local `.devcontainer/devcontainer.json`, mount that host directory
   read-only at `/mnt/signing-source`.
3. Keep your personal Git configuration in the ignored
   `.references/devcontainer.gitconfig`. It is mounted read-only and used as
   the container's global Git configuration.
4. Reopen the development container. Its startup script copies the keys into
   `/root/.signing`, with directory permissions `700`, private-key permissions
   `600`, and public-key permissions `644`.

Inside the container, run these commands from the repository:

```sh
git config --local gpg.format ssh
git config --local user.signingkey /root/.signing/id_ed25519
git config --local commit.gpgsign true
```

Set your Git author name and email in the local configuration. New commits will
be signed automatically. For GitHub verification, register the public key on your
account as a signing key.

This setup does not require host SSH-agent forwarding. If the private key has a
passphrase, load it into an agent inside the development container:

```sh
eval "$(ssh-agent -s)"
ssh-add /root/.signing/id_ed25519
```

That agent is available to this terminal and its child processes. VS Code's Git
interface needs access to the same agent to use it.

Keep both keys and personal configuration out of Git and image builds. The
private key is present inside the running development container; it is not
included in the application image.

Check the settings without creating a commit:

```sh
git config --get gpg.format
git config --get user.signingkey
git config --get commit.gpgsign
```

See the [Git signing settings](https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat).
