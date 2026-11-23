#ifndef REQUEST_H
#define REQUEST_H

#define BASE_NAME_SIZE 32

typedef struct
{
    char base[BASE_NAME_SIZE];
    int evacuees;
    int ships;
    int capacity_per_ship;
    int priority;
} Request;

#endif
