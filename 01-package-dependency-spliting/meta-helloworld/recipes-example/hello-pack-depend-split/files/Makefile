CC = gcc
CFLAGS = -Wall

all: hello_depen hello_pack_split hello_run_time_depen 

hello_depen: hello_depen.c
	$(CC) hello_depen.c $(CFLAGS) -lcurl -o hello_depen

hello_pack_split: hello_pack_split.c 
	$(CC) hello_pack_split.c  $(CFLAGS) -lcurl -o hello_pack_split 

hello_run_time_depen: hello_run_time_depen.c
	$(CC) hello_run_time_depen.c $(CFLAGS) -lcurl -o hello_run_time_depen 

clean:
	rm -f hello_depen hello_pack_split hello_run_time_depen

