CFLAGS := -Wall -Wextra -MMD -MP -O3
CFLAGS += -I third-party/
CFLAGS += -I third-party/UDK2017/MdePkg/Include/

MACHINE := $(shell uname -m)
ifeq ($(MACHINE),x86_64)
    CFLAGS += -I third-party/UDK2017/MdePkg/Include/X64
else ifeq ($(patsubst i%86,Ia32,$(MACHINE)),Ia32)
    CFLAGS += -I third-party/UDK2017/MdePkg/Include/Ia32
else
    $(error Unsupported machine: '$(MACHINE)')
endif

PRG := smmstoretool

SRC := fv.c guids.c main.c storage.c utils.c vs.c
SRC := $(addprefix src/,$(SRC))

OBJ := $(SRC:.c=.o)
DEP := $(SRC:.c=.d)

.PHONY: all debug clean

all: $(PRG)

debug: CFLAGS += -O0 -g
debug: LDFLAGS += -g
debug: all

clean:
	-$(RM) $(OBJ) $(DEP)

$(PRG): $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

-include $(DEP)
