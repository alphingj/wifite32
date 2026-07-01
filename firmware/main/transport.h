#ifndef TRANSPORT_H_
#define TRANSPORT_H_
#include <stdint.h>
#include <stddef.h>
#include "proto.h"
wifite_status_t transport_init(void);
wifite_status_t transport_process(void);
#endif
