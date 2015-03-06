# Protocol Buffers 3

A tap for proto3 (PRERELEASE).

Currently supported compilers:

* Python
* Go

## Installation

This is a PRERELEASE so the commands are a little more verbose to make sure you know what you're doing.

Add the tap:
```
λ brew tap duggan/protobuf3
```

Run the install (add / remove flags for desired support):
```
λ brew install --HEAD protobuf3 --with-python --with-go`
```

Link it up:
```
λ brew link protobuf3
```

If you already have protocol buffers installed, you will need to run:

```
λ brew unlink protobuf
λ brew link protobuf3
```
