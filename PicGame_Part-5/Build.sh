#!/bin/bash

#/************************/
#/* Compile application. */
#/************************/
gpasm -w 1 -c PicGame_Part-5.asm

if [ $? -eq 0 ]
then
#/*********************/
#/* Link application. */
#/*********************/
   gplink -o PicGame_Part-5.hex PicGame_Part-5.o
fi

