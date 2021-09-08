# angle-interfaces

## Description

This repo contains the interfaces for the contracts of Angle Protocol.

It is split in three different files:

- `IAngle.sol`: contains the user-facing functions of the contracts of the protocol
- `IAngleGovernance.sol`: contains the functions for which only the different governor addresses (and in some cases the guardian) addresses are allowed
- `IAngleKeeper.sol`: lists for each contract the different functions with which keepers can interact to perform actions that are beneficial to the protocol

## Protocol Architecture

![Angle Protocol Smart Contract Architecture](./AngleArchitectureSchema.png)
