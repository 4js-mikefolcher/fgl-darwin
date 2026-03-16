#!/bin/bash

cwd=$(pwd)
export FGLGUI=0
export TERM=xterm
export FGLPROFILE=${cwd}/dbs/postgres/fglprofile.pgs

cd ${cwd}/bin
fglrun ifx_menu.42r
