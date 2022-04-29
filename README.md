Operator Framework Bash Example
===============================

> A simple
> [Operator Framework](https://github.com/socketsupply/operatorframework)
> example written in Bash that makes use of
> POSIX [Named Pipes](https://en.wikipedia.org/wiki/Named_pipe) for IPC
> request IO

## Building

Compiling directly with the `op` command

```sh
op .
```

_With [bpkg](https://github.com/bpkg/bpkg):_

```sh
bpkg run build
```

## Running

```sh
op . -r -o
```

_or with [bpkg](https://github.com/bpkg/bpkg):_

```sh
bpkg run start
```

## IPC

```sh
bin/ipc <command> ...args ## URI style (key=value&key=value)
```

### Examples

```sh
bin/ipc stdout 'value=hello world'
```

```sh
bin/ipc getScreenSize
{"width":1503,"height":1002}
```

```sh
bin/ipc show 'window=0'
```

```sh
bin/ipc navigate 'window=0' "value=file://$PWD/src/index.html"
```

```sh
bin/ipc send 'window=0" 'event=data' 'value={"hello":"world"}'
```

## Development (live reaload)

```sh
bin/watch
```

Manually refreshing page

```sh
bin/ipc send 'window=0' 'event=refresh' 'value=0'
```

## License

MIT
