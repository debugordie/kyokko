#!/bin/sh

quartus_ipgenerate ${KYOKKO}/boards/c10gx/ip/ip_management.qpf --simulation=verilog --synthesis=verilog
quartus_ipgenerate ${KYOKKO}/boards/hawkeye/ip/ip_management.qpf --simulation=verilog --synthesis=verilog
quartus_ipgenerate ${KYOKKO}/boards/de10pro-b/ip/ip_management.qpf --simulation=verilog --synthesis=verilog
