#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define PORT 9025
#define BUFFER_SIZE 4096

// Buffer allocation for heavy payload simulation
char streaming_buffer[1024 * 512]; 

void handle_client(int sock, char *req) {
    if (strncmp(req, "GET /status", 11) == 0) {
        const char *resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"active\",\"title_id\":\"CUSA05730\",\"paired\":true}";
        send(sock, resp, strlen(resp), 0);
    } else if (strncmp(req, "INSTALL_PKG:", 12) == 0) {
        char *url = req + 12;
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "curl -s -X POST http://127.0.0.1:9090/api/install -d '{\"type\":\"direct\",\"url\":\"%s\"}'", url);
        system(cmd);
        const char *resp = "HTTP/1.1 200 OK\r\n\r\nPKG_INSTALL_ACK";
        send(sock, resp, strlen(resp), 0);
    } else {
        const char *resp = "HTTP/1.1 200 OK\r\n\r\nPS4_HYBRID_ENGINE_READY";
        send(sock, resp, strlen(resp), 0);
    }
}

int main() {
    int server_fd, client_sock;
    struct sockaddr_in addr;
    int opt = 1;
    int addrlen = sizeof(addr);
    char buf[BUFFER_SIZE] = {0};

    memset(streaming_buffer, 0xAA, sizeof(streaming_buffer));

    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) exit(EXIT_FAILURE);
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) exit(EXIT_FAILURE);
    if (listen(server_fd, 5) < 0) exit(EXIT_FAILURE);

    while (1) {
        if ((client_sock = accept(server_fd, (struct sockaddr *)&addr, (socklen_t*)&addrlen)) >= 0) {
            memset(buf, 0, BUFFER_SIZE);
            read(client_sock, buf, BUFFER_SIZE - 1);
            handle_client(client_sock, buf);
            close(client_sock);
        }
    }
    return 0;
}
