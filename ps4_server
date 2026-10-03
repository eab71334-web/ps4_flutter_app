#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define PORT 9025
#define BUFFER_SIZE 1024

void process_mobile_signal(int client_fd) {
    char buffer[BUFFER_SIZE] = {0};
    read(client_fd, buffer, BUFFER_SIZE);

    if (strstr(buffer, "WAKE_PING") != NULL) {
        char *reply = "PS4_HOST_ACTIVE_GOLDHEN_READY";
        send(client_fd, reply, strlen(reply), 0);
    } 
    else if (strstr(buffer, "START_STREAM") != NULL) {
        char *reply = "STREAM_PIPELINE_OK";
        send(client_fd, reply, strlen(reply), 0);
    }
    close(client_fd);
}

int main(void) {
    int server_fd, client_fd;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        return -1;
    }

    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        return -1;
    }

    if (listen(server_fd, 3) < 0) {
        return -1;
    }

    while (1) {
        if ((client_fd = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen)) >= 0) {
            process_mobile_signal(client_fd);
        }
        usleep(10000);
    }

    return 0;
}
