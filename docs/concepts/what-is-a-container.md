# What Is A Container?

A container is a portable scientific workspace.

For Hermes, it can help to think of the container as:

- a portable lab bench,
- a field station in a box,
- a reproducible set of tools,
- a way for everyone to start from the same environment.

## Plain-Language Terms

| Term | Meaning |
| --- | --- |
| Image | The packaged recipe: tools, scripts, services, defaults |
| Container | A running copy of that image |
| Volume | Durable storage attached to a container |
| Bind mount | A host folder made visible inside the container |
| Docker Compose | A simple way to start several related services together |

## Why Containers Help Science

Containers reduce "it works on my laptop" problems. They make it easier to reproduce the same software environment later, share it with collaborators, and separate runtime tools from durable project memory.

## What Containers Do Not Solve

Containers do not replace backups, review, provenance, data licenses, security, or scientific judgment. Treat them as helpful infrastructure, not a guarantee.

!!! note "Ephemeral container, persistent working group repo"
    The container can be stopped and rebuilt. The project memory should live in git, mounted workspace folders, volumes, or external storage.

