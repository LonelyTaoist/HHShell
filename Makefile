CC = gcc
CFLAGS = -g -Wall
LEXSRC = parse.lex
SRC = HHShell.c lex.yy.c
all:
	flex $(LEXSRC)
	$(CC) $(CFLAGS) -o HHShell $(SRC) -lfl
