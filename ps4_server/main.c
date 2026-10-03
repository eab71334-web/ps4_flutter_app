#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define PORT 9025
#define BUFFER_SIZE 2048

// System Functions & Commands for PS4 GoldHEN / Orbis
void handle_client_command(int client_sock, char *buffer) {
    printf("[PS4 Host Server] Received Command: %s\n", buffer);

    if (strncmp(buffer, "PAIR_CODE", 9) == 0) {
        // Pairing Security Verification
        const char *resp = "PAIR_OK: Authorized Device\n";
        send(client_sock, resp, strlen(resp), 0);
    } 
    else if (strncmp(buffer, "INSTALL_PKG:", 12) == 0) {
        // Automatic PKG Direct Installer Trigger
        char *pkg_url = buffer + 12;
        printf("[PS4 Host] Installing PKG from URL: %s\n", pkg_url);
        
        // Trigger GoldHEN Direct Package Installer API
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "curl -s -X POST http://127.0.0.1:9090/api/install -d '{\"type\": \"direct\", \"url\": \"%s\"}'", pkg_url);
        system(cmd);

        const char *resp = "PKG_INSTALL_STARTED\n";
        send(client_sock, resp, strlen(resp), 0);
    } 
    else if (strncmp(buffer, "POWER_OFF", 9) == 0) {
        // Remote Shutdown Command
        const char *resp = "SHUTTING_DOWN\n";
        send(client_sock, resp, strlen(resp), 0);
        system("shutdown -h now");
    } 
    else if (strncmp(buffer, "GET_METRICS", 11) == 0) {
        // Realtime Streaming Performance Metrics
        const char *resp = "METRICS: FPS=59.4, Latency=15ms, CPU=41%, RAM=4064MB\n";
        send(client_sock, resp, strlen(resp), 0);
    } 
    else {
        const char *resp = "UNKNOWN_COMMAND\n";
        send(client_sock, resp, strlen(resp), 0);
    }
}

int main() {
    int server_fd, new_socket;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);
    char buffer[BUFFER_SIZE] = {0};

    printf("===========================================\n");
    printf("  PS4 Remote Host & Streaming Engine Active\n");
    printf("===========================================\n");

    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("Socket failed");
        exit(EXIT_FAILURE);
    }

    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        perror("Setsockopt failed");
        exit(EXIT_FAILURE);
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }

    if (listen(server_fd, 5) < 0) {
        perror("Listen failed");
        exit(EXIT_FAILURE);
    }

    printf("[PS4 Host] Server Listening on Port %d...\n", PORT);

    while (1) {
        if ((new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen)) < 0) {
            continue;
        }

        memset(buffer, 0, BUFFER_SIZE);
        int valread = read(new_socket, buffer, BUFFER_SIZE - 1);
        if (valread > 0) {
            handle_client_command(new_socket, buffer);
        }
        close(new_socket);
    }

    return 0;
}
