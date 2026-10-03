Target = ps4_remote_host
OutPath = bin

CC = clang
CFLAGS = -target x86_64-pc-freebsd12-elf -fPIC -O2 -Wall
LDFLAGS = -fuse-ld=lld -shared

SRCS = main.c
OBJS = $(SRCS:.c=.o)

all: $(Target).elf

$(Target).elf: $(OBJS)
	mkdir -p $(OutPath)
	$(CC) $(OBJS) -o $(OutPath)/$@ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(OBJS) $(OutPath)
