#include <iostream>
#include <fstream>
#include <string>
#include <fcntl.h>    
#include <unistd.h>  
#include <cstring>  
#include <errno.h> 
using namespace std;

void writeToFile(int fd) {
    string data;
    cout << "Enter the data to write:";
    cin.ignore(); // Clear the input buffer
    getline(cin, data);

    ssize_t bytesWritten = write(fd, data.c_str(), data.size());
    if (bytesWritten == -1) {
        cerr << "Error writing to file: " << strerror(errno) << endl;
    } else {
        cout << "Successfully wrote " << bytesWritten << " bytes: " << data << endl;
    }
}

void readFromFile(int fd) {
    char buffer[256];
    ssize_t bytesRead = read(fd, buffer, sizeof(buffer) - 1);
    if (bytesRead == -1) {
        cerr << "Error reading from file: " << strerror(errno) << endl;
    } else {
        buffer[bytesRead] = '\0'; // Null-terminate the buffer
        cout << "Read " << bytesRead << " bytes: " << buffer << endl;
    }
}

int main() {
    const char* device = "/dev/nokia5110_0";
    int fd = open(device, O_RDWR); // Open file with read/write permissions

    if (fd == -1) {
        cerr << "Error opening " << device << ": " << strerror(errno) << endl;
        return 1;
    }

    int choice = 0;
    do {
        std::cout << "\nChoose an option:\n"
                  << "1. Write to file\n"
                  << "2. Read from file\n"
                  << "3. Exit\n"
                  << "Enter your choice: ";
        cin >> choice;

        switch (choice) {
            case 1:
                writeToFile(fd);
                break;
            case 2:
                readFromFile(fd);
                break;
            case 3:
                cout << "Exiting program." << endl;
                break;
            default:
                cout << "Invalid choice. Please try again." << endl;
        }
    } while (choice != 3);

    close(fd);
    return 0;
}

