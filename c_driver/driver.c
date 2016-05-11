/* Based on
 * https://www.cs.utah.edu/~swalton/listings/sockets/programs/part2/chap6/simple-server.c
*/

/* driver.c */

#include <stdio.h>
#include <errno.h>
#include <sys/socket.h>
#include <resolv.h>
#include <arpa/inet.h>
#include <string.h>
#include "mainheader.h"
#include "scommon.h"

// Comment out to remove debug prints
#define DEBUG

#define MY_PORT		60002
#define MAXBUF		4096

/*
 * Print the incoming buffer in hex.
 */
static int printBuffer(char *buffer, size_t sz){
    printf("**********************BUFFER**********************\n");
    for(int i = 0; i < sz; i++){
        printf(":%02X", buffer[i]);
    }
    printf("\n**********************END BUFFER******************\n");
    return 1;
}

/*
 * Process the buffer. In this case, convert to an MH_ITEM_LIST_t and print.
 */
static int processBuffer(char *buffer, size_t sz) {
    // TODO: if buffer size is 0, return...
    MH_ITEM_LIST_t itemlist;
    memset(&itemlist, 0, sizeof(MH_ITEM_LIST_t));
    // without checking (bad), copy the buffer contents into the itemlist.
    // NOTE: if expecting more than the one type (MH_ITEM_LIST_t), some
    //       other functionality is needed.
    memcpy(&itemlist, buffer, sz);

    printf("**************************************************\n");
    printf("Received buffer in driver. As an MH_ITEM_LIST_t:\n");
    printf("\tSC_HEADER_t:\n");
    printf("\t\tType  : %i\n", itemlist.header.type);
    printf("\t\tStatus: %i\n", itemlist.header.status);
    printf("\t\tCode  : %u\n", itemlist.header.code);
    printf("\t\tLength: %u (num items in list)\n", itemlist.header.length);
    for (int i = 0; i < itemlist.header.length; i++){
        printf("\tMH_LIST_ITEM_t[%i]:\n", i);
        printf("\t\tItem Type    : %i\n", itemlist.itemList[i].itemType);
        printf("\t\tSC Msg Type  : %i\n", itemlist.itemList[i].scMsgType);
        printf("\t\tName         : %s\n", itemlist.itemList[i].nameStr);
    }
    printf("**************************************************\n");
    return 1;
}

int main(int Count, char *Strings[]) {
  // server vars
  int sockfd;
	struct sockaddr_in self;
	char buffer[MAXBUF];

  // client vars
  int clientfd;
  struct sockaddr_in client_addr;
  int addrlen=sizeof(client_addr);


	// Create streaming socket
  if ( (sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0 ) {
		perror("Socket");
		exit(errno);
	}

	// Initialize address/port structure
	bzero(&self, sizeof(self));
	self.sin_family = AF_INET;
	self.sin_port = htons(MY_PORT);
	self.sin_addr.s_addr = INADDR_ANY;

	// Assign a port number to the socket
  if ( bind(sockfd, (struct sockaddr*)&self, sizeof(self)) != 0 ) {
		perror("socket--bind");
		exit(errno);
	}

	// Make it a "listening socket"
	if ( listen(sockfd, 20) != 0 ) {
		perror("socket--listen");
		exit(errno);
	}

  // wait for a connection
  printf("Waiting on client connection...\n");

  while(1) {
    // accept a connection. for this we only have one client, so once
    // connected, break from here and start proessing messages.
    clientfd = accept(sockfd, (struct sockaddr*)&client_addr, &addrlen);
    printf("%s:%d connected\n", inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
    break;
  }

  while (1) {
    // TODO: need to send a signal to break this loop from a client
    //MH_ITEM_LIST_t itemlist;
    size_t recsz = 0;

    // zero the buffer
    memset(buffer, 0, MAXBUF);

    // TODO: Add some error checking...
    recsz = recv(clientfd, buffer, MAXBUF, 0);


    // now process the received stuff
    if(recsz > 0){
#ifdef DEBUG
        printBuffer(buffer, recsz);
#endif
        processBuffer(buffer, recsz);
    }

    // send back what we got
    send(clientfd, buffer, recsz, 0);
  }
  // Close client connection
  close(clientfd);

	// Clean up (should never get here!)
	close(sockfd);
	return 0;
}
