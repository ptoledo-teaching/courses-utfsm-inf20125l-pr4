#ifndef CAPACITY_H
#define CAPACITY_H

#include "request.h"

int total_capacity(const Request *request);
int has_enough_capacity(const Request *request);

#endif
