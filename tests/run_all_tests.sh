#!/bin/bash

for i in `find . -name "test_*.lua" -type f`; do
    echo "Running unit test: $i"
    lua $i
done
