#include <stdio.h>

#include "parser.h"
#include "report.h"

int main(void)
{
    int request_count = 0;

    if (scanf("%d", &request_count) != 1)
    {
        fprintf(stderr, "Error: no se pudo leer la cantidad de solicitudes.\n");
        return 1;
    }

    for (int i = 1; i <= request_count; i++)
    {
        Request request;

        if (!read_request(stdin, &request))
        {
            fprintf(stderr, "Error: solicitud incompleta en la linea %d.\n", i);
            return 1;
        }

        print_request_report(i, &request);
    }

    return 0;
}
