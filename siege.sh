#!/bin/sh

siege -c25 -t2M -i -d5 -f siege_requests -R .siegerc
