#include <stdio.h>
#include <string.h>

int main(int argv, char *argc[])
{
	unsigned int i;

	if (argv != 2)
		return 1;

	for (i = 0; i < strlen(argc[1]); i++)
		printf("%02x", argc[1][i]);

	return 0;
}
