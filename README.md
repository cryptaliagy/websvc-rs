# Rust Web Service

This is a template repository meant to be used as a starting point for developing a new Rust-based microservice. This handles most of the key bootstrapping elements that I require when creating a new service.

## Features

1. A lib crate with configuration pulled from environment variables
1. A fairing to use as a request profiler / access log
1. A bin crate that sets up the main rocket server
1. Logging configuration pulling from the environment
1. A route to read the runtime configs
1. A multipart `Dockerfile` to create containers using statically-linked binaries for:
   - Development, with all build tools & code available as the first stage
   - Building the prod release binary
   - A debug prod container based on `alpine` that includes the binary, a shell, and a package manager
   - A runner prod container based on `scratch` that includes exclusively the binary.
1. A `docker-compose` file for version-tracked default docker execution commands.
1. A `justfile` with basic commands. For more information on [`just`](https://just.systems), see their website.
   > NOTE: this is added for convenience to make calling the compose commands a little faster. I personally believe there is a lot of value in knowing how these things work at a high level, or at minimum knowing how to call these docker commands yourself. As such, any `just` command will also print off what it runs before running it.

### Benchmarks & Performance

Since this is a demo service with only two routes (one in production), there is no service benchmarks offered. However, I've done some very basic benchmarking of image size and runtime memory cost of the images for curiosity's sake.

As of 27-02-2023, these are the stats (with, of course, some variability):

| Image   | Image Size | Running Memory After Startup | Running Memory After 1k Requests |
| ------- | ---------- | ---------------------------- | -------------------------------- |
| dev     | 4.53 GB    | 1.332 MiB                    | 1.52 MiB                         |
| builder | 5.3 GB     | 1.324 MiB                    | 1.516 MiB                        |
| debug   | 11.5 MB    | 932 KiB                      | 1.16 MiB                         |
| prod    | 4.44 MB    | 924 KiB                      | 1.23 MiB                         |

Additionally, I make some performance guarantees about service runtime as part of a test in [`src/main.rs`](src/main.rs): The heartbeat route, under default configurations, should execute < 1 ms using the debug profile, and < 200 μs in release profile. This should hold relatively well even under more performance-constrained machines since Rust is very performant and the code is very simple; under my machine (i7-1185G7 @ 3.00GHz), `/heartbeat` requests took ~200 μs under debug and ~20-50 μs under release configurations.

Requests were run using the following python script:

```py
import asyncio
import httpx


async def query(n: int = 1000):
    async with httpx.AsyncClient() as client:
        for _ in range(n):
            await client.get("http://localhost:8000/heartbeat")


if __name__ == "__main__":
    import sys

    arg = sys.argv[1:]

    if len(arg) > 1:
        print("Invalid arg")
        sys.exit(1)

    arg = 1000 if len(arg) == 0 else int(arg[0])

    asyncio.run(query(arg))
```

### Why `scratch`?

The decision to use scratch is 3-fold:

1. Smallest possible binary. The final prod image contains only the resulting binary, which allows it to be incredibly small (~4 mb)
1. Reduce attack surface. There's nothing additional in the container to exploit than the service itself.
1. Reduce container scanning false-positives. With nothing other than the binary in the image, you will never get a security scanner complaint due to an unused dependency, since
   no unused dependencies are bundled in.

### Why include a `debug` container?

Depending on the circumstance, it can still be useful to debug the application using additional tools that I haven't thought of or pre-packaged. The debug container based on `alpine` allows installation of additional debugging tools, but I don't really think it'll come up much. Most debugging / testing should be done in the `dev` container that contains a full suite of rust tools and the actual source code.

## How to use

> Note:

1. Create a new repository templated from this repo
1. Use a global find + replace (CTRL+SHIFT+H on VSCode) to replace "websvc" with the name of your service
1. Use a global find + replace to replace "WEBSVC" with the capitalized name of your service. This is used in the `config.rs` file.
   > Note, if your service name uses dashes in its name, you will need to replace `<service>-<name>` with `<service>_<name>` in `main.rs` and use underscores in the capitalized version
