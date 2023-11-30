# IO Performance Tests

This repository holds a set of tools to test the IO performance of a filesystem.
It was created to explore possible performance issues with the Ceph filesystem
on an internal cloud where certain pieces of software that are IO heavy see
very inconsistent performance. It uses general tooling like `dd` to remove any
effects from the client software.

It is aimed at Linux but will work on macOS too.
