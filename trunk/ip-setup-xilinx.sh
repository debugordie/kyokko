#!/bin/sh

for i in ${KYOKKO}/boards/*/ip/setup.tcl; do
  vivado -mode batch -source $i
done

