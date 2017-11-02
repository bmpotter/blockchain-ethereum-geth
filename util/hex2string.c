#include <stdio.h>
#include <string.h>

char nibbletochar(char c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	if (c >= 'a' && c <= 'f')
		return c - 'a' + 10;
	if (c >= 'A' && c <= 'F')
		return c - 'A' + 10;

	return 255;
}

int main(int argv, char *argc[])
{
	unsigned int i, j;

	if (argv != 2)
		return 1;

	j = (strlen(argc[1])/2) << 1;

	for (i = 0; i < j; i+=2)
		printf("%c", (char) (nibbletochar(argc[1][i]) << 4) | nibbletochar(argc[1][i+1]));

	return 0;
}
