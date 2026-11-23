#include <stdio.h>

#include "capacity.h"
#include "priority.h"
#include "report.h"

void print_request_report(int index, const Request *request)
{
    int capacity = total_capacity(request);

    printf("Solicitud %03d: %s | base=%s | capacidad=%d/%d | prioridad=%s\n",
           index,
           has_enough_capacity(request) ? "OK" : "ALERTA",
           request->base,
           capacity,
           request->evacuees,
           priority_label(request->priority));
}
