#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>

/**
 * Serial Msg IPC
 * Demonstrates kernal message queuing
 */

int open_queue( key_t keyval )
{
	int     qid;

	if((qid = msgget( keyval, (IPC_CREAT+IPC_EXCL) )) == -1)
	{
		return(-1);
	}

	return(qid);
}

int close_queue( int qid )
{
	struct msqid_ds buf;
	if( msgctl(qid, IPC_RMID, &buf) == -1)
	{
		return(-1);
	}
	return(0);
}

int main()
{
	int qid;
	key_t msgkey;

	struct serial_msg {
		long mtype;
		char serial_char;
	} msg;

	// Generate IPC key value with ftok()
	msgkey = ftok(".", 1203);

	// Create the queue
	if ((qid = open_queue(msgkey)) == -1) {
		perror("open_queue");
		exit(1);
	}

	if (close_queue(qid) == 0) {
		printf("Closed queue %d", qid);
	}

    printf("Message queue id: %d\n", qid);
    return 0;
}









