#!/usr/bin/env bash 
if ! host pve.hyddns.xyz >/dev/null; then
  ip -4 route | egrep '^default' | awk '{print $5}' | xargs -I{} resolvectl dns {} 8.8.8.8
fi
