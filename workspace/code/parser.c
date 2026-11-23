#include "parser.h"

int read_request(FILE *input, Request *request)
{
    return fscanf(input, "%31s %d %d %d %d",
                  request->base,
                  &request->evacuees,
                  &request->ships,
                  &request->capacity_per_ship,
                  &request->priority) == 5;
}
