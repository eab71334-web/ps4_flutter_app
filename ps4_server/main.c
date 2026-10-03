#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define PORT 9025

int main() {
    int server_fd, new_socket;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("Socket failed");
        exit(EXIT_FAILURE);
    }

    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }

    if (listen(server_fd, 3) < 0) {
        perror("Listen failed");
        exit(EXIT_FAILURE);
    }

    printf("PS4 Hybrid Host Engine Server running on port %d\n", PORT);

    while (1) {
        if ((new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen)) < 0) {
            continue;
        }

        char buffer[1024] = {0};
        read(new_socket, buffer, 1024);

        // JSON response containing sample PS4 Library Games for the mobile app
        const char *json_response = 
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: application/json\r\n"
            "Access-Control-Allow-Origin: *\r\n"
            "Connection: close\r\n\r\n"
            "{"
              "\"status\":\"success\","
              "\"pin_code\":\"849201\","
              "\"games\":["
                "{\"name\":\"God of War Ragnarok\", \"title_id\":\"CUSA34388\"},"
                "{\"name\":\"Elden Ring\", \"title_id\":\"CUSA28863\"},"
                "{\"name\":\"Gran Turismo 7\", \"title_id\":\"CUSA24721\"}"
              "]"
            "}";

        write(new_socket, json_response, strlen(json_response));
        close(new_socket);
    }

    return 0;
}
