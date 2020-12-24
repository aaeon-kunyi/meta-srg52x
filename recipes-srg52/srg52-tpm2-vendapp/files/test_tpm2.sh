#!/bin/bash

echo -e "get tpm firmware revsion"
./aSkCmd -getversion2

echo -e ""
echo -e "tpm2 selftest"
./aSkCmd -selftest2
