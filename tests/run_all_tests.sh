#!/bin/bash
rm ./luacov.stats.out
for i in `find . -name "test_*.lua" -type f`; do
    echo "Running unit test: $i"
    lua -lluacov $i
done

luacov

rm ./luacov.report.html
