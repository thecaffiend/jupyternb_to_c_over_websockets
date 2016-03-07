/* Based on
 * https://www.cs.utah.edu/~swalton/listings/sockets/programs/part2/chap6/simple-server.c
*/

/* driver.c */

#include <stdio.h>
#include <errno.h>
#include <sys/socket.h>
#include <resolv.h>
#include <arpa/inet.h>
#include <errno.h>

#define MY_PORT		60002
#define MAXBUF		1024

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

    // Echo back anything sent for now.
    send(clientfd, buffer, recv(clientfd, buffer, MAXBUF, 0), 0);

  }
  // Close client connection
  close(clientfd);

	// Clean up (should never get here!)
	close(sockfd);
	return 0;
}
