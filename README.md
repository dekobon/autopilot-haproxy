# Autopilot Pattern HAProxy

*A re-usable HAProxy base image implemented according to the 
[Autopilot Pattern](http://autopilotpattern.io/) for automatic discovery and configuration.*

[![DockerPulls](https://img.shields.io/docker/pulls/dekobon/haproxy.svg)](https://registry.hub.docker.com/u/dekobon/haproxy/)
[![DockerStars](https://img.shields.io/docker/stars/dekobon/haproxy.svg)](https://registry.hub.docker.com/u/dekobon/haproxy/)

### A reusable HAProxy container image

The goal of this project is to create a HAProxy image that can be reused across 
environments without having to rebuild the entire image. Configuration of 
HAProxy is entirely via ContainerPilot `preStart` or `onChange` handlers.