%{
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>

//input parameter
extern char* g_ptr;
extern char* g_lim;

#undef YY_INPUT
#define YY_INPUT(b, r, ms)(r = my_yyinput(b,ms))
static int my_yyinput(char* buf, int max);

//cmd parameter
#define MAX_ARG_CNT 256
static char* g_argv[MAX_ARG_CNT];
static int g_argc = 0;

static void add_arg(const char* xarg);
static void reset_args();

//cmd handlers
static void exec_simple_cmd();

//HHShell's function
static int look_for_cd();
static void look_for_pipe();
static void look_for_dup2();
%}

%%
[^ \t\n]+	{add_arg(yytext);}
\n	{exec_simple_cmd(); reset_args();}
.	  ;
%%

static void add_arg(const char* arg)
{
	char* t;
	if((t = malloc(strlen(arg) + 1)) == NULL)
	{
		perror("Failed to allocate memory");
		return;
	}
	strcpy(t, arg);
	g_argv[g_argc] = t;
	++g_argc;
	g_argv[g_argc] = 0;
}
static void reset_args()
{
	int i;
	for (i = 0; i < g_argc; ++i)
	{
		free(g_argv[i]);
		g_argv[i] = 0;
	}
	g_argc = 0;
}
static void exec_simple_cmd()
{
	//look for cd cmd
	if (look_for_cd() == 1)
	{
		return;
	}
	
	pid_t childpid;
	int status;
	if((childpid = fork()) == -1)
	{
		perror("Failed to fork child");
		return;
	}
	if (childpid == 0)
	{
		//look for pipe cmd
		look_for_pipe();

		//look for dup2
		look_for_dup2();
	}
	waitpid(childpid, &status, 0);
}
static int my_yyinput(char* buf, int max)
{
	int n;
	n = g_lim - g_ptr;
	if (n > max) n = max;
	if (n > 0) 
	{
		memcpy(buf, g_ptr, n);
		g_ptr += n;
	}
	return n;
}
static int look_for_cd()
{
	if (strcmp(g_argv[0], "cd") == 0)
	{
		if (g_argv[1] == NULL || g_argv[2] != NULL) 
		{
			perror("command 'cd' parameter?");
			return;
		}
            	chdir(g_argv[1]);
		return 1;
	}
	else return 0;
}
static void look_for_pipe()
{
	for(int i = 0; g_argv[i] != NULL; ++i)
        {
           	if(strcmp(g_argv[i], "|") == 0) 
		{
			if (g_argv[i + 1] == NULL) perror("command '|' parameter?"),exit(1);
			g_argv[i] = NULL;
			int fd[2];
			pipe(fd);
			pid_t cmd;
			if ((cmd = fork()) == -1)
			{
				perror("Failed to fork child");
				return;
			}
			if (cmd == 0)
			{
				dup2(fd[1], STDOUT_FILENO);
            			dup2(fd[1], STDERR_FILENO);
            			execvp(g_argv[0], g_argv);
				perror("Failed tp execute command");
            			exit(1);
			}
			else 
			{
				int status_tmp;
				waitpid(cmd, &status_tmp, 0);
				dup2(fd[0], STDIN_FILENO);
				close(fd[0]);
				close(fd[1]);
            			execvp(g_argv[i + 1], &g_argv[i + 1]);
				perror("Failed tp execute command");
     				exit(1);
			}
		}
	}
}
static void look_for_dup2()
{
	for(int i = 0; g_argv[i] != NULL; ++i)
        {
      		if(strcmp(g_argv[i], ">") == 0) 
		{
			if (g_argv[i + 1] == NULL) perror("command '>' parameter?"),exit(1);
			g_argv[i] = NULL;
			int fd = open(g_argv[i + 1], O_RDWR|O_CREAT|O_TRUNC, 0664);
        		if(fd == -1) perror("open error"),exit(1);
        		dup2(fd, 1);
        		close(fd);
		}
	}
	execvp(g_argv[0], g_argv);
	perror("Failed tp execute command");
	exit(1);
}
