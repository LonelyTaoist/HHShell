#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <sys/types.h>

#define PROMPT_STRING "[HHShell]$"
#define QUIT_STRING "exit\n"

static char inbuf[MAX_CANON];
char* g_ptr;
char* g_lim;

extern void yylex();

int main (void)
{
	for (;;)
	{
		if (fputs(PROMPT_STRING, stdout) == EOF) continue;
		if (fgets(inbuf, MAX_CANON, stdin) == NULL) continue;
		if (strcmp(inbuf, QUIT_STRING) == 0) break;
		g_ptr = inbuf;
		g_lim = inbuf + strlen(inbuf);
		yylex();
	}
	return 0;
}
