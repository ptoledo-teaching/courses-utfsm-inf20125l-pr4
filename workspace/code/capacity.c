#include "capacity.h"

int total_capacity(const Request *request)
{
    return request->ships * request->capacity_per_ship;
}

int has_enough_capacity(const Request *request)
{
    return total_capacity(request) >= request->evacuees;
}
