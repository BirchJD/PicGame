#!/bin/bash

#/************************/
#/* Compile application. */
#/************************/
gpasm -w 1 -c PicGame_Part-7.asm

if [ $? -eq 0 ]
then
#/*********************/
#/* Link application. */
#/*********************/
   gplink -o PicGame_Part-7.hex PicGame_Part-7.o
fi

