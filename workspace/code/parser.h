#ifndef PARSER_H
#define PARSER_H

#include <stdio.h>

#include "request.h"

int read_request(FILE *input, Request *request);

#endif
