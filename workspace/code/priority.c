#include "priority.h"

const char *priority_label(int priority)
{
    if (priority >= 90)
    {
        return "CRITICA";
    }

    if (priority >= 60)
    {
        return "ALTA";
    }

    return "NORMAL";
}
